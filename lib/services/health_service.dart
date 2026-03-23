// lib/services/health_service.dart
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import '../models/health_model.dart';

class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // OpenWeatherMap — GPS path only. Free tier, 60 calls/min.
  // Sign up at https://openweathermap.org/api → copy API key here.
  static const String _owmApiKey = 'YOUR_OPENWEATHERMAP_API_KEY';

  // ─── READ: rapid3Question ────────────────────────────────────────────────
  Future<List<Rapid3Question>> fetchQuestions() async {
    final snap = await _db.collection('rapid3Question').get();
    dev.log('[HS] rapid3Question docs: ${snap.docs.map((d) => d.id).toList()}');
    final docs = {for (final d in snap.docs) d.id: d.data()};
    final painDoc    = docs['pain'];
    final globalDoc  = docs['global'];
    final funcConfig = docs['function_config'];
    final subQTexts  = docs.entries
        .where((e) => e.value['category'] == 'function' && e.key != 'function_config')
        .toList()
      ..sort((a, b) {
        final na = a.value['questionNumber'];
        final nb = b.value['questionNumber'];
        return (na is num ? na : 99).compareTo(nb is num ? nb : 99);
      });
    final result = <Rapid3Question>[];
    if (painDoc != null) {
      result.add(Rapid3Question.fromMap({...painDoc, 'id': 'pain',
        'questionNumber': 1, 'type': painDoc['type'] ?? 'slider', 'category': 'pain'}));
    }
    if (funcConfig != null) {
      result.add(Rapid3Question.fromMap({...funcConfig, 'id': 'function_config',
        'questionNumber': 2, 'type': 'radio', 'category': 'function',
        'subQuestions': subQTexts.map((e) => e.value['question'] as String? ?? '').toList()}));
    }
    if (globalDoc != null) {
      result.add(Rapid3Question.fromMap({...globalDoc, 'id': 'global',
        'questionNumber': 3, 'type': globalDoc['type'] ?? 'slider', 'category': 'global'}));
    }
    dev.log('[HS] fetchQuestions: ${result.length} questions');
    return result;
  }

  // ─── READ: rapid3def ─────────────────────────────────────────────────────
  Future<Rapid3TierDefinition?> fetchTierDefinition(String tier) async {
    final doc = await _db.collection('rapid3def').doc(tier).get();
    if (!doc.exists || doc.data() == null) return null;
    return Rapid3TierDefinition.fromMap(doc.data()!);
  }

  // ─── READ: recommendation_templates (exercises) ──────────────────────────
  // Field name variants per tier:
  //   HIGH/REMISSION: exerciseRecommendation (singular)
  //   LOW:            exerciseRecommendatins (typo — missing 'o')
  //   MODERATE:       exerciseRecommendations (plural, correct)
  // Intensity typos: itensity / intenstity (handled below)
  Future<List<ExerciseRecommendation>> fetchExercises(String tier) async {
    dev.log('[HS] fetchExercises: tier=$tier');
    final data = await _fetchRecoTemplate(tier);
    if (data == null) { dev.log('[HS] fetchExercises: no template found'); return []; }

    final raw = (data['exerciseRecommendations'] ??
                 data['exerciseRecommendation']  ??
                 data['exerciseRecommendatins']  ?? []) as List;
    dev.log('[HS] exercises raw count: ${raw.length}');

    return raw.map((e) {
      final m     = Map<String, dynamic>.from(e as Map);
      final rawId = m['id']?.toString() ?? '';
      // Prefix tier so HIGH_1 != MODERATE_1 — Firestore map keys must be unique
      final uid   = rawId.isNotEmpty
          ? '${tier}_$rawId'
          : '${tier}_${(m['name'] as String? ?? '').replaceAll(' ', '_')}';
      return ExerciseRecommendation(
        id:              uid,
        name:            m['name']           ?? '',
        duration:        m['duration']       ?? '',
        type:            m['type']           ?? '',
        intensity:       m['intensity'] ?? m['itensity'] ?? m['intenstity'] ?? '',
        jointImpact:     m['jointImpact']    ?? '',
        benefits:        List<String>.from(m['benefits']     ?? []),
        instructions:    List<String>.from(m['instructions'] ?? []),
        warnings:        List<String>.from(m['warnings']     ?? []),
        equipmentNeeded: m['equipmentNeeded'] ?? '',
        difficulty:      m['difficulty']     ?? '',
        tier:            tier,
      );
    }).toList();
  }

  // ─── READ: nutrition_library ─────────────────────────────────────────────
  // Documents are NOT named by tier — each document has tierId / tier field.
  // Known documents:
  //   "high_aggressive_anti_inflammatory"  tierId=HIGH
  //   "moderate_anti_inflammatory"         tierId=MODERATE
  //   "remission_balanced_diet"            tierId=REMISSION
  //   (no LOW document — LOW falls back to REMISSION Balanced Diet)
  //
  // servings is a nested map:
  //   HIGH:    { antioxidantVegetables:6, fruits:2 }
  //   MODERATE:{ vegetables:5, fruits:2, grains:3, protein:3 }
  //   REMISSION:{ vegetables:5, fruits:2, grains:3, protein:3, dairy:2 }
  Future<NutritionRecommendation?> fetchNutrition(String tier) async {
    dev.log('[HS] fetchNutrition: tier=$tier');

    var docSnap = await _queryNutritionDoc(tier);

    // LOW has no dedicated document — use REMISSION Balanced Diet
    if (docSnap == null && tier == 'LOW') {
      dev.log('[HS] fetchNutrition: LOW missing, falling back to REMISSION');
      docSnap = await _queryNutritionDoc('REMISSION');
    }

    if (docSnap == null) {
      dev.log('[HS] fetchNutrition: NOT FOUND for tier=$tier');
      return null;
    }

    final d = docSnap.data() as Map<String, dynamic>;
    dev.log('[HS] fetchNutrition: found "${d['name']}" for tier=$tier');

    final servings  = (d['servings'] as Map<String, dynamic>?) ?? {};
    // HIGH uses antioxidantVegetables, others use vegetables
    final vegTarget = (servings['vegetables'] as num?)?.toInt()
                   ?? (servings['antioxidantVegetables'] as num?)?.toInt()
                   ?? _parseLeadingInt(d['dailyGoal'], fallback: 5);
    final fruTarget = (servings['fruits'] as num?)?.toInt() ?? 2;
    final watTarget = _parseLeadingInt(d['waterIntake'], fallback: 8);

    return NutritionRecommendation(
      id:                 d['id']?.toString() ?? tier,
      name:               d['name']           ?? '',
      description:        d['description']    ?? '',
      dailyGoal:          d['dailyGoal']       ?? '',
      vegetablesTarget:   vegTarget,
      fruitsTarget:       fruTarget,
      waterGlassesTarget: watTarget,
      focusArea:          d['focusArea']       ?? '',
      examples:           List<String>.from(d['examples']   ?? []),
      avoidFoods:         List<String>.from(d['avoidFoods'] ?? []),
      tips:               List<String>.from(d['tips']       ?? []),
      tier:               tier,
    );
  }

  Future<QueryDocumentSnapshot?> _queryNutritionDoc(String tier) async {
    // Primary: query by tierId
    var snap = await _db.collection('nutrition_library')
        .where('tierId', isEqualTo: tier).limit(1).get();
    if (snap.docs.isNotEmpty) return snap.docs.first;
    // Fallback: query by tier field
    snap = await _db.collection('nutrition_library')
        .where('tier', isEqualTo: tier).limit(1).get();
    return snap.docs.isNotEmpty ? snap.docs.first : null;
  }

  // ─── PRIVATE: fetch recommendation_templates doc ─────────────────────────
  // MODERATE stored as "Moderate" (title case) in Firestore
  Future<Map<String, dynamic>?> _fetchRecoTemplate(String tier) async {
    var doc = await _db.collection('recommendation_templates').doc(tier).get();
    if (doc.exists && doc.data() != null) { return doc.data(); }
    final tc = tier[0].toUpperCase() + tier.substring(1).toLowerCase();
    doc = await _db.collection('recommendation_templates').doc(tc).get();
    if (doc.exists && doc.data() != null) { return doc.data(); }
    dev.log('[HS] _fetchRecoTemplate: NOT FOUND tier=$tier');
    return null;
  }

  static int _parseLeadingInt(dynamic raw, {required int fallback}) {
    if (raw == null) return fallback;
    final m = RegExp(r'(\d+)').firstMatch(raw.toString());
    return int.tryParse(m?.group(1) ?? '') ?? fallback;
  }

  // ─── READ: today's symptom log ───────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchTodaySymptomLog(String userId) async {
    final today = dateString(DateTime.now());
    final doc = await _db.collection('users').doc(userId)
        .collection('symptomLogs').doc('log_$today').get();
    return (doc.exists && doc.data() != null) ? doc.data() : null;
  }

  // ─── READ: today's lifestyle progress ───────────────────────────────────
  Future<Map<String, dynamic>?> fetchTodayLifestyleProgress(String userId) async {
    final today = dateString(DateTime.now());
    final doc = await _db.collection('users').doc(userId)
        .collection('userLifestyleProgress').doc('progress_$today').get();
    return (doc.exists && doc.data() != null) ? doc.data() : null;
  }

  // ─── READ: lifestyleReco (backwards compat) ──────────────────────────────
  Future<Map<String, dynamic>?> fetchLifestyleReco(String tier) async {
    final doc = await _db.collection('lifestyleReco').doc(tier).get();
    return (doc.exists && doc.data() != null) ? doc.data() : null;
  }

  // ─── WRITE: symptomLogs + user tier fields ───────────────────────────────
  // IMPORTANT: uses set(merge:true) on userRef — NOT update() — because
  // update() throws NOT_FOUND if the user doc doesn't exist yet.
  // set(merge:true) creates the doc if missing, or merges fields if it exists.
  Future<void> saveSymptomLog(SymptomLog log) async {
    dev.log('[HS] saveSymptomLog: userId=${log.userId} tier=${log.rapid3Tier}');
    final batch  = _db.batch();

    // Write symptom log subcollection doc
    final logRef = _db.collection('users').doc(log.userId)
        .collection('symptomLogs').doc('log_${log.logDate}');
    batch.set(logRef, log.toMap());

    // Update tier fields on user doc — use set(merge) so it never throws
    final userRef = _db.collection('users').doc(log.userId);
    batch.set(userRef, {
      'activeRapid3Tier':  log.rapid3Tier,
      'activeRapid3Score': log.rapid3Score,
      'tierUpdatedAt':     Timestamp.fromDate(log.createdAt),
      'tierLogDate':       log.logDate,
    }, SetOptions(merge: true));

    await batch.commit();
    dev.log('[HS] saveSymptomLog ✓ tier=${log.rapid3Tier} score=${log.rapid3Score}');
  }

  // ─── WRITE: completed exercise ───────────────────────────────────────────
  // Two-step write:
  //   1. set(merge:true)  → creates document if it doesn't exist
  //   2. update() with dot-notation key "exerciseLogs.HIGH_1"
  //      → writes ONLY that one map key; sibling entries untouched
  Future<void> saveExerciseProgress({
    required String userId,
    required String dateStr,
    required double rapid3Score,
    required String rapid3Tier,
    required String exerciseId,
    required String exerciseName,
    required int    actualDurationMinutes,
    required int    actualDurationSec,
    required double painBefore,
    required double painAfter,
  }) async {
    dev.log('[HS] saveExerciseProgress: $exerciseName id=$exerciseId');
    final now    = DateTime.now();
    final safeId = exerciseId.isNotEmpty ? exerciseId : exerciseName.replaceAll(' ', '_');
    final ref    = _db.collection('users').doc(userId)
        .collection('userLifestyleProgress').doc('progress_$dateStr');

    // Step 1: ensure doc exists (set with merge creates if missing)
    await ref.set({
      'progressId':   'progress_$dateStr',
      'userId':       userId,
      'progressDate': dateStr,
      'rapid3Score':  rapid3Score,
      'rapid3Tier':   rapid3Tier,
      'timestamp':    Timestamp.fromDate(now).millisecondsSinceEpoch,
      'updatedAt':    Timestamp.fromDate(now).millisecondsSinceEpoch,
    }, SetOptions(merge: true));

    // Step 2: write only this exercise's entry using dot-notation
    await ref.update({
      'exerciseLogs.$safeId': {
        'exerciseId':   safeId,
        'exerciseName': exerciseName,
        'completed':    true,
        'durationMin':  actualDurationMinutes,
        'durationSec':  actualDurationSec,
        'painBefore':   painBefore,
        'painAfter':    painAfter,
        'completedAt':  Timestamp.fromDate(now).millisecondsSinceEpoch,
      },
      'updatedAt': Timestamp.fromDate(now).millisecondsSinceEpoch,
    });
    dev.log('[HS] saveExerciseProgress: $exerciseName ✓');
  }

  // ─── WRITE: exercise pause state ─────────────────────────────────────────
  Future<void> saveExercisePause({
    required String userId,
    required String dateStr,
    required String exerciseId,
    required String exerciseName,
    required int    pausedAtSec,
    required String rapid3Tier,
    required double rapid3Score,
    required double painBefore,
  }) async {
    dev.log('[HS] saveExercisePause: $exerciseName pausedAt=${pausedAtSec}s');
    final now    = DateTime.now();
    final safeId = exerciseId.isNotEmpty ? exerciseId : exerciseName.replaceAll(' ', '_');
    final ref    = _db.collection('users').doc(userId)
        .collection('userLifestyleProgress').doc('progress_$dateStr');

    // Step 1: ensure doc exists
    await ref.set({
      'progressId':   'progress_$dateStr',
      'userId':       userId,
      'progressDate': dateStr,
      'rapid3Tier':   rapid3Tier,
      'rapid3Score':  rapid3Score,
      'timestamp':    Timestamp.fromDate(now).millisecondsSinceEpoch,
      'updatedAt':    Timestamp.fromDate(now).millisecondsSinceEpoch,
    }, SetOptions(merge: true));

    // Step 2: write only this exercise's pause entry
    await ref.update({
      'exerciseLogs.$safeId': {
        'exerciseId':   safeId,
        'exerciseName': exerciseName,
        'completed':    false,
        'paused':       true,
        'pausedAtSec':  pausedAtSec,
        'durationMin':  pausedAtSec ~/ 60,
        'painBefore':   painBefore,
        'pausedAt':     Timestamp.fromDate(now).millisecondsSinceEpoch,
      },
      'updatedAt': Timestamp.fromDate(now).millisecondsSinceEpoch,
    });
    dev.log('[HS] saveExercisePause: $exerciseName at ${pausedAtSec}s ✓');
  }

  // ─── WRITE: nutrition log ────────────────────────────────────────────────
  // merge:true preserves exerciseLogs already written today
  Future<void> saveNutritionProgress({
    required String userId,
    required String dateStr,
    required String rapid3Tier,
    required double rapid3Score,
    required int    vegetablesConsumed,
    required int    fruitConsumed,
    required int    waterGlasses,
    required List<String> foodsLogged,
    required int    adherencePercent,
  }) async {
    dev.log('[HS] saveNutritionProgress: veg=$vegetablesConsumed fruit=$fruitConsumed water=$waterGlasses');
    final now = DateTime.now();
    await _db.collection('users').doc(userId)
        .collection('userLifestyleProgress').doc('progress_$dateStr')
        .set({
      'progressId':   'progress_$dateStr',
      'userId':       userId,
      'progressDate': dateStr,
      'rapid3Tier':   rapid3Tier,
      'rapid3Score':  rapid3Score,
      'nutritionLogged': {
        'completed':          true,
        'vegetablesConsumed': vegetablesConsumed,
        'fruitConsumed':      fruitConsumed,
        'waterGlasses':       waterGlasses,
        'foodsLogged':        foodsLogged,
        'adherencePercent':   adherencePercent,
        'savedAt':            Timestamp.fromDate(now).millisecondsSinceEpoch,
      },
      'timestamp': Timestamp.fromDate(now).millisecondsSinceEpoch,
      'updatedAt': Timestamp.fromDate(now).millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    dev.log('[HS] saveNutritionProgress ✓');
  }

  // ─── WEATHER ─────────────────────────────────────────────────────────────
  // ─── WEATHER: 3-path resolution ─────────────────────────────────────────
  //
  //  Path A — GPS granted:
  //    Geolocator → lat/lon → OpenWeatherMap → WeatherData (source: gps)
  //
  //  Path B — GPS denied, city saved in Firestore:
  //    Firestore users/{uid}/weatherCity → Open-Meteo geocoding → lat/lon
  //    → Open-Meteo weather → WeatherData (source: manualCity)
  //
  //  Path C — GPS denied, no city:
  //    Returns WeatherData.unavailable() → UI shows city picker
  //
  //  Never throws. All errors fall through to the next path or unavailable.

  /// Main entry point called by HealthController._loadWeather()
  /// [userId] needed to look up a saved city (path B).
  Future<WeatherData> fetchWeather({required String userId}) async {
    // ── Path A: try GPS ───────────────────────────────────────────────
    try {
      var perm = await geo.Geolocator.checkPermission();
      if (perm == geo.LocationPermission.denied) {
        perm = await geo.Geolocator.requestPermission();
      }
      if (perm == geo.LocationPermission.always ||
          perm == geo.LocationPermission.whileInUse) {
        final pos = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.low,
        ).timeout(const Duration(seconds: 6));
        final weather = await _fetchByCoords(pos.latitude, pos.longitude);
        if (weather != null) {
          dev.log('[HS] fetchWeather ✓ path=GPS lat=${pos.latitude}');
          return weather;
        }
      }
    } catch (e) {
      dev.log('[HS] fetchWeather GPS failed: $e');
    }

    // ── Path B: try saved city ────────────────────────────────────────
    try {
      final city = await loadUserCity(userId);
      if (city != null && city.isNotEmpty) {
        final weather = await fetchWeatherByCity(city);
        if (weather != null) {
          dev.log('[HS] fetchWeather ✓ path=city city=$city');
          return weather;
        }
      }
    } catch (e) {
      dev.log('[HS] fetchWeather city path failed: $e');
    }

    // ── Path C: unavailable ───────────────────────────────────────────
    dev.log('[HS] fetchWeather → unavailable (no GPS, no city)');
    return WeatherData.unavailable();
  }

  /// GPS path: OpenWeatherMap with lat/lon.
  /// Returns null on any error so caller can fall through.
  Future<WeatherData?> _fetchByCoords(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lon&appid=$_owmApiKey&units=metric',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        return WeatherData.fromApi(jsonDecode(res.body) as Map<String, dynamic>);
      }
      dev.log('[HS] OWM status ${res.statusCode}');
    } catch (e) {
      dev.log('[HS] _fetchByCoords error: $e');
    }
    return null;
  }

  /// City path (public — also called when user manually sets city):
  ///   1. Open-Meteo geocoding: city name → lat/lon
  ///   2. Open-Meteo weather: lat/lon → current weather
  /// Open-Meteo is free, no API key, no rate limit for reasonable use.
  /// Returns null on any error so caller can fall through.
  Future<WeatherData?> fetchWeatherByCity(String city) async {
    try {
      // Step 1 — geocoding
      final geoUri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeComponent(city)}&count=1&language=en&format=json',
      );
      final geoRes = await http.get(geoUri).timeout(const Duration(seconds: 6));
      if (geoRes.statusCode != 200) return null;
      final geoJson = jsonDecode(geoRes.body) as Map<String, dynamic>;
      final results = geoJson['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final loc    = results.first as Map<String, dynamic>;
      final lat    = (loc['latitude']  as num).toDouble();
      final lon    = (loc['longitude'] as num).toDouble();
      final resolvedCity = (loc['name'] as String? ?? city);

      // Step 2 — weather
      final wxUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current_weather=true'
        '&hourly=relativehumidity_2m,surface_pressure'
        '&forecast_days=1',
      );
      final wxRes = await http.get(wxUri).timeout(const Duration(seconds: 6));
      if (wxRes.statusCode != 200) return null;
      return WeatherData.fromOpenMeteo(
        jsonDecode(wxRes.body) as Map<String, dynamic>,
        resolvedCity,
      );
    } catch (e) {
      dev.log('[HS] fetchWeatherByCity($city) error: $e');
      return null;
    }
  }

  // ─── CITY PERSISTENCE ────────────────────────────────────────────────────
  // Stored on the user document so it syncs across devices automatically.

  /// Save the user's chosen city to Firestore.
  Future<void> saveUserCity({
    required String userId,
    required String city,
  }) async {
    try {
      await _db.collection('users').doc(userId).set(
        {'weatherCity': city},
        SetOptions(merge: true),
      );
      dev.log('[HS] saveUserCity ✓ city=$city');
    } catch (e) {
      dev.log('[HS] saveUserCity failed: $e');
    }
  }

  /// Load the saved city string from Firestore.
  /// Returns null if not set or on error.
  Future<String?> loadUserCity(String userId) async {
    try {
      final snap = await _db.collection('users').doc(userId)
          .get(const GetOptions(source: Source.serverAndCache));
      return snap.data()?['weatherCity'] as String?;
    } catch (e) {
      dev.log('[HS] loadUserCity failed: $e');
      return null;
    }
  }

  static String dateString(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}