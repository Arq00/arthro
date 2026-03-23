// lib/controllers/health_controller.dart
// MVC Controller — pure state management only.
// No Firestore, no HTTP, no GPS here.
// All external I/O is delegated to HealthService.

import 'dart:async';
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/health_model.dart';
import '../services/health_service.dart';

enum HealthStep {
  symptomQuestions, // Step 1a: RAPID3 sliders / radio
  bodyHeatmap,      // Step 1b: Interactive body joint map
  morningStiffness, // Step 1c: Stiffness duration + weather
  result,           // Calculated RAPID3 result
  lifestyle,        // Lifestyle recommendations
}

class HealthController extends ChangeNotifier {
  final String _passedUserId;
  final HealthService _service;

  HealthController({
    required String userId,
    HealthService? service,
  }) : _passedUserId = userId,
       _service = service ?? HealthService.instance;

  /// Always resolves to a real non-empty UID.
  /// Falls back to FirebaseAuth.currentUser if the passed value was empty.
  String get userId {
    if (_passedUserId.isNotEmpty) return _passedUserId;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) dev.log('[HealthController] WARNING: userId is still empty! User may not be signed in.');
    return uid;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STEP STATE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  HealthStep _currentStep = HealthStep.symptomQuestions;
  HealthStep get currentStep => _currentStep;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RAPID3 QUESTIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  List<Rapid3Question> _questions = [];
  List<Rapid3Question> get questions => _questions;
  bool _questionsLoading = true;
  bool get questionsLoading => _questionsLoading;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // USER ANSWERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  double _painValue     = 0;
  double _functionValue = 0; // avg of 10 sub-questions (0-3)
  double _globalValue   = 0;

  double get painValue     => _painValue;
  double get functionValue => _functionValue;
  double get globalValue   => _globalValue;

  // 10 function sub-questions — populated from DB, fallback to hardcoded
  final List<double> functionAnswers = List.filled(10, 0);
  List<String> functionSubQuestions = const [
    'Dress yourself',
    'Get in/out of bed',
    'Lift a cup to mouth',
    'Walk on flat ground',
    'Wash/dry body',
    'Bend to pick up item',
    'Turn regular faucets',
    'Get in/out of a car',
    'Do outdoor tasks',
    'Participate in activities',
  ];

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BODY HEATMAP
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final List<BodyJoint> bodyJoints = _buildJoints();
  List<String> get selectedJoints =>
      bodyJoints.where((j) => j.isSelected).map((j) => j.id).toList();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // MORNING STIFFNESS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  int _stiffnessMinutes = 0;
  int get stiffnessMinutes => _stiffnessMinutes;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STRESS LEVEL  (0–10, step 0.5)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  double _stressLevel = 0.0;
  double get stressLevel => _stressLevel;

  /// <4 = Low, 4–7.5 = Average, >7.5 = High
  String get stressLabel => SymptomLog.stressLabel(_stressLevel);
  String get stressTier  => SymptomLog.stressTier(_stressLevel);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WEATHER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  WeatherData? _weather;
  WeatherData? get weather => _weather;
  bool _weatherLoading = false;
  bool get weatherLoading => _weatherLoading;

  /// True when weather is unavailable AND no city is saved yet — shows picker
  bool get showCityPicker =>
      _weather != null && _weather!.isUnavailable;

  /// The city the user manually chose (empty if using GPS or not set yet)
  String get savedCity => _weather?.cityName ?? '';

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RAPID3 RESULT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  double _rapid3Score = 0;
  String _rapid3Tier  = 'REMISSION';
  double get rapid3Score => _rapid3Score;
  String get rapid3Tier  => _rapid3Tier;
  Rapid3TierDefinition? _tierDef;
  Rapid3TierDefinition? get tierDef => _tierDef;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LIFESTYLE DATA
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  List<ExerciseRecommendation> _exercises = [];
  List<ExerciseRecommendation> get exercises => _exercises;
  NutritionRecommendation? _nutrition;
  NutritionRecommendation? get nutrition => _nutrition;
  bool _lifestyleLoading = false;
  bool get lifestyleLoading => _lifestyleLoading;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // EXERCISE SELECTION (min 2 required)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final Set<String> _selectedExerciseIds = {};
  Set<String> get selectedExerciseIds => _selectedExerciseIds;

  bool isExerciseSelected(String id) => _selectedExerciseIds.contains(id);
  bool get hasMinimumExercisesSelected => _selectedExerciseIds.length >= 2;

  void toggleExerciseSelection(String id) {
    if (_selectedExerciseIds.contains(id)) {
      _selectedExerciseIds.remove(id);
    } else {
      _selectedExerciseIds.add(id);
    }
    notifyListeners();
  }

  List<ExerciseRecommendation> get selectedExercises =>
      _exercises.where((e) => _selectedExerciseIds.contains(e.id)).toList();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // EXERCISE SESSION TIMER + PAUSE/RESUME
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  bool   _sessionActive     = false;
  bool   _sessionPaused     = false;
  int    _sessionElapsedSec = 0;
  int    _pausedAtSec       = 0;   // elapsed when paused — saved to DB
  Timer? _sessionTimer;
  ExerciseRecommendation? _activeExercise;
  double _painBeforeExercise = 0;
  double _painAfterExercise  = 0;
  bool   _exerciseDone       = false;

  // Per-exercise completion tracking: exerciseId → true/false
  final Map<String, bool> _exerciseCompletionMap = {};

  // Per-exercise pause tracking: exerciseId → pausedAtSec (0 = not paused)
  final Map<String, int> _exercisePauseMap = {};

  bool   get sessionActive      => _sessionActive;
  bool   get sessionPaused      => _sessionPaused;
  int    get sessionElapsedSec  => _sessionElapsedSec;
  int    get pausedAtSec        => _pausedAtSec;
  ExerciseRecommendation? get activeExercise => _activeExercise;
  double get painBeforeExercise => _painBeforeExercise;
  double get painAfterExercise  => _painAfterExercise;
  bool   get exerciseDone       => _exerciseDone;

  bool isExerciseCompleted(String id) => _exerciseCompletionMap[id] ?? false;
  /// Returns saved pause time in seconds, or 0 if not paused
  int  exercisePausedSec(String id)   => _exercisePauseMap[id] ?? 0;
  bool isExercisePaused(String id)    => (_exercisePauseMap[id] ?? 0) > 0;
  int get completedExerciseCount =>
      _exerciseCompletionMap.values.where((v) => v).length;

  // True when all selected exercises are done
  bool get allSelectedExercisesDone =>
      _selectedExerciseIds.isNotEmpty &&
      _selectedExerciseIds.every((id) => _exerciseCompletionMap[id] == true);

  String get formattedSessionTime {
    final m = (_sessionElapsedSec ~/ 60).toString().padLeft(2, '0');
    final s = (_sessionElapsedSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String formattedTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // NUTRITION LOGGING
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final List<String> _loggedFoods = [];
  int  _loggedVegetables = 0;
  int  _loggedFruits     = 0;
  int  _loggedWater      = 0;
  bool _nutritionDone    = false;

  List<String> get loggedFoods    => _loggedFoods;
  int  get loggedVegetables       => _loggedVegetables;
  int  get loggedFruits           => _loggedFruits;
  int  get loggedWater            => _loggedWater;
  bool get nutritionDone          => _nutritionDone;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TODAY'S STATUS (checked on login)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  bool    _todaySymptomLogged    = false; // true = already logged today
  bool    _todayExerciseDone     = false; // true = exercise logged today
  bool    _todayNutritionDone    = false; // true = nutrition logged today
  String? _todayTier;                     // today's RAPID3 tier from DB
  double? _todayScore;                    // today's RAPID3 score from DB

  bool    get todaySymptomLogged => _todaySymptomLogged;
  bool    get todayExerciseDone  => _todayExerciseDone;
  bool    get todayNutritionDone => _todayNutritionDone;
  String? get todayTier          => _todayTier;
  double? get todayScore         => _todayScore;

  // True if user should skip symptom questions and go straight to lifestyle
  bool get shouldSkipToLifestyle =>
      _todaySymptomLogged && _exercises.isNotEmpty;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // UI STATE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  bool    _saving   = false;
  String? _errorMsg;
  bool    get saving   => _saving;
  String? get errorMsg => _errorMsg;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // INIT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> init() async {
    // Run in parallel: questions + weather + today's log check
    await Future.wait([
      _loadQuestions(),
      _checkTodayLog(),
    ]);
    _loadWeather(); // fire-and-forget
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CHECK TODAY'S LOG ON LOGIN
  // If user already completed RAPID3 today → skip to result/lifestyle
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _checkTodayLog() async {
    try {
      // 1. Check symptom log
      final logData = await _service.fetchTodaySymptomLog(userId);
      if (logData != null) {
        _todaySymptomLogged = true;
        _rapid3Score  = (logData['rapid3Score'] as num?)?.toDouble() ?? 0;
        _rapid3Tier   = logData['rapid3Tier'] as String? ?? 'REMISSION';
        _todayScore   = _rapid3Score;
        _todayTier    = _rapid3Tier;

        // Restore tier definition
        _tierDef = await _service.fetchTierDefinition(_rapid3Tier)
            ?? _fallbackTierDef(_rapid3Tier);

        // 2. Load lifestyle data for this tier
        await _loadLifestyle();

        // 3. Check lifestyle progress
        final progressData = await _service.fetchTodayLifestyleProgress(userId);
        if (progressData != null) {
          // Restore per-exercise completion AND pause states from DB
          final exerciseLogs = progressData['exerciseLogs'] as Map?;
          if (exerciseLogs != null) {
            exerciseLogs.forEach((id, entry) {
              final e = entry as Map?;
              if (e == null) return;
              final completed  = (e['completed'] as bool?) ?? false;
              final paused     = (e['paused']    as bool?) ?? false;
              final pausedSec  = (e['pausedAtSec'] as num?)?.toInt() ?? 0;
              if (completed) {
                _exerciseCompletionMap[id.toString()] = true;
              } else if (paused && pausedSec > 0) {
                _exercisePauseMap[id.toString()] = pausedSec;
              }
            });
          }

          // Legacy support: old exerciseLogged.completed field
          final legacyEx = progressData['exerciseLogged'] as Map?;
          if (legacyEx != null && (legacyEx['completed'] as bool? ?? false)) {
            final exName = legacyEx['exerciseName'] as String? ?? '';
            // Mark all exercises with matching name as done (best effort)
            _exercises.where((e) => e.name == exName).forEach((e) {
              _exerciseCompletionMap[e.id] = true;
            });
          }

          _todayExerciseDone  = _exerciseCompletionMap.values.any((v) => v);
          _exerciseDone       = _todayExerciseDone;

          final nutr = progressData['nutritionLogged'] as Map?;
          _todayNutritionDone = (nutr?['completed'] as bool?) ?? false;
          _nutritionDone = _todayNutritionDone;

          // Restore nutrition counts if available
          if (nutr != null) {
            _loggedVegetables = (nutr['vegetablesConsumed'] as num?)?.toInt() ?? 0;
            _loggedFruits     = (nutr['fruitConsumed']      as num?)?.toInt() ?? 0;
            _loggedWater      = (nutr['waterGlasses']       as num?)?.toInt() ?? 0;
            final foods = nutr['foodsLogged'] as List?;
            if (foods != null) _loggedFoods.addAll(foods.cast<String>());
          }
        }

        // 4. Jump straight to lifestyle — symptom already done today
        _currentStep = HealthStep.lifestyle;
      }
    } catch (e) {
      dev.log('[HealthController] _checkTodayLog failed: $e');
      // If check fails, start fresh — user will retake from beginning
    }
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LOAD QUESTIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _loadQuestions() async {
    try {
      _questions = await _service.fetchQuestions();
      // Update function sub-questions from DB if available
      final funcQ = _questions.where((q) => q.category == 'function').firstOrNull;
      if (funcQ?.subQuestions != null && funcQ!.subQuestions!.isNotEmpty) {
        functionSubQuestions = funcQ.subQuestions!;
      }
    } catch (e) {
      dev.log('[HealthController] fetchQuestions failed: $e');
      _questions = _fallbackQuestions();
    }
    _questionsLoading = false;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LOAD WEATHER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _loadWeather() async {
    _weatherLoading = true;
    notifyListeners();
    _weather = await _service.fetchWeather(userId: userId);
    _weatherLoading = false;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ANSWER SETTERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void setPain(double v)   { _painValue   = v; notifyListeners(); }
  void setGlobal(double v) { _globalValue = v; notifyListeners(); }

  void setFunctionAnswer(int index, double v) {
    functionAnswers[index] = v;
    _functionValue =
        functionAnswers.reduce((a, b) => a + b) / functionAnswers.length;
    notifyListeners();
  }

  void setStiffnessMinutes(int v) { _stiffnessMinutes = v; notifyListeners(); }
  void setStressLevel(double v)   { _stressLevel = (v * 2).round() / 2; notifyListeners(); } // snap to 0.5
  void setPainBefore(double v)    { _painBeforeExercise = v; notifyListeners(); }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WEATHER — CITY FALLBACK
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Called when user taps "change" on the source badge.
  /// Clears saved city and resets weather to unavailable so picker shows again.
  Future<void> clearSavedCity() async {
    await _service.saveUserCity(userId: userId, city: '');
    _weather = WeatherData.unavailable();
    notifyListeners();
  }
  /// Shows loading state while fetching.
  Future<void> setCityAndRefetch(String city) async {
    if (city.trim().isEmpty) return;
    _weatherLoading = true;
    notifyListeners();

    // 1. Persist city so it survives app restarts
    await _service.saveUserCity(userId: userId, city: city.trim());

    // 2. Fetch weather for that city
    final weather = await _service.fetchWeatherByCity(city.trim());
    _weather = weather ?? WeatherData.unavailable();

    _weatherLoading = false;
    notifyListeners();
  }
  void setPainAfter(double v)     { _painAfterExercise  = v; notifyListeners(); }

  void toggleJoint(String jointId) {
    final joint = bodyJoints.firstWhere((j) => j.id == jointId);
    joint.cycleSeverity();
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STEP NAVIGATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void goToStep(HealthStep step) { _currentStep = step; notifyListeners(); }
  void nextToHeatmap()   => goToStep(HealthStep.bodyHeatmap);
  void nextToStiffness() => goToStep(HealthStep.morningStiffness);
  void goToLifestyle()   => goToStep(HealthStep.lifestyle);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CALCULATE RAPID3 → SAVE → LOAD LIFESTYLE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> calculateAndShowResult() async {
    // 1. Calculate score + tier (pure math — no I/O)
    _rapid3Score = SymptomLog.calculateRapid3(
      _painValue, _functionValue, _globalValue,
    );
    _rapid3Tier = SymptomLog.tierFromScore(_rapid3Score);

    // 2. Fetch tier definition from DB (fallback if unavailable)
    _tierDef = await _service.fetchTierDefinition(_rapid3Tier)
        ?? _fallbackTierDef(_rapid3Tier);

    // 3. Show result screen immediately — don't make user wait
    _currentStep = HealthStep.result;
    notifyListeners();

    // 4. Save symptom log in background (don't block UI)
    _saveSymptomLog();

    // 5. Pre-load lifestyle while user reads the result screen
    _loadLifestyle();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BACKGROUND: SAVE SYMPTOM LOG
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _saveSymptomLog() async {
    final now     = DateTime.now();
    final dateStr = HealthService.dateString(now);
    final log = SymptomLog(
      logId:                   'log_${dateStr}_${now.millisecondsSinceEpoch}',
      userId:                  userId,
      logDate:                 dateStr,
      pain:                    _painValue,
      function:                _functionValue,
      globalAssessment:        _globalValue,
      rapid3Score:             _rapid3Score,
      rapid3Tier:              _rapid3Tier,
      affectedJoints:          selectedJoints,
      morningStiffnessMinutes: _stiffnessMinutes,
      stressLevel:             _stressLevel,      // new field — safe default 0.0 for old docs
      createdAt:               now,
    );
    try {
      await _service.saveSymptomLog(log);
    } catch (e) {
      dev.log('[HealthController] _saveSymptomLog failed: $e');
      _errorMsg = 'Could not save symptom log';
      notifyListeners();
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BACKGROUND: LOAD LIFESTYLE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> _loadLifestyle() async {
    _lifestyleLoading = true;
    notifyListeners();
    try {
      final exercises = await _service.fetchExercises(_rapid3Tier);
      _exercises = exercises.isNotEmpty
          ? exercises
          : _fallbackExercises(_rapid3Tier);

      final nutrition = await _service.fetchNutrition(_rapid3Tier);
      _nutrition = nutrition ?? _fallbackNutrition(_rapid3Tier);
    } catch (e) {
      dev.log('[HealthController] _loadLifestyle failed: $e');
      _exercises = _fallbackExercises(_rapid3Tier);
      _nutrition = _fallbackNutrition(_rapid3Tier);
    }
    _lifestyleLoading = false;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // EXERCISE SESSION TIMER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// Start a fresh session (phase 0 → 1)
  /// If exercise has a saved pause time, restores it and jumps straight to active phase
  void startExerciseSession(ExerciseRecommendation exercise, {bool resumeFromPause = false}) {
    _activeExercise    = exercise;
    // If resuming from a DB-saved pause, restore elapsed time
    _sessionElapsedSec = resumeFromPause ? (_exercisePauseMap[exercise.id] ?? 0) : 0;
    _sessionPaused     = false;
    _sessionActive     = true;
    _exerciseDone      = false;
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionElapsedSec++;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Resume a previously paused session
  void resumeExerciseSession() {
    if (!_sessionPaused || _activeExercise == null) return;
    _sessionPaused = false;
    _sessionActive = true;
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionElapsedSec++;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Pause: stop timer + save current elapsed time to DB immediately
  Future<void> pauseExerciseSession() async {
    _sessionTimer?.cancel();
    _sessionActive = false;
    _sessionPaused = true;
    _pausedAtSec   = _sessionElapsedSec;
    notifyListeners();
    // Save pause state immediately so it survives app close
    try {
      await _service.saveExercisePause(
        userId:      userId,
        dateStr:     HealthService.dateString(DateTime.now()),
        exerciseId:  _activeExercise?.id ?? '',
        exerciseName: _activeExercise?.name ?? '',
        pausedAtSec: _pausedAtSec,
        rapid3Tier:  _rapid3Tier,
        rapid3Score: _rapid3Score,
        painBefore:  _painBeforeExercise,
      );
    } catch (e) {
      dev.log('[HealthController] pauseExerciseSession save failed: $e');
    }
    // Record paused time in-memory so lifestyle_view shows Resume button
    if (_activeExercise != null) {
      _exercisePauseMap[_activeExercise!.id] = _pausedAtSec;
    }
    notifyListeners();
  }

  /// Stop (finish) session — moves to pain-after phase
  void stopExerciseSession() {
    _sessionTimer?.cancel();
    _sessionActive = false;
    _sessionPaused = false;
    _exerciseDone  = true;
    notifyListeners();
  }

  /// Mark an exercise as fully completed after save
  void markExerciseCompleted(String exerciseId) {
    _exerciseCompletionMap[exerciseId] = true;
    _exercisePauseMap.remove(exerciseId); // clear any saved pause — fully done
    if (allSelectedExercisesDone) _exerciseDone = true;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SAVE EXERCISE LOG
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> saveExerciseLog() async {
    _saving = true;
    notifyListeners();
    try {
      final exId = _activeExercise?.id ?? '';
      await _service.saveExerciseProgress(
        userId:                userId,
        dateStr:               HealthService.dateString(DateTime.now()),
        rapid3Score:           _rapid3Score,
        rapid3Tier:            _rapid3Tier,
        exerciseId:            exId,
        exerciseName:          _activeExercise?.name ?? '',
        actualDurationMinutes: _sessionElapsedSec ~/ 60,
        actualDurationSec:     _sessionElapsedSec,
        painBefore:            _painBeforeExercise,
        painAfter:             _painAfterExercise,
      );
      if (exId.isNotEmpty) markExerciseCompleted(exId);
    } catch (e, stack) {
      dev.log('[HealthController] saveExerciseLog FAILED: $e$stack');
      _errorMsg = 'Could not save exercise log: $e';
    }
    _saving = false;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // NUTRITION COUNTER SETTERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void incrementVegetables()    { _loggedVegetables++;                             notifyListeners(); }
  void decrementVegetables()    { if (_loggedVegetables > 0) _loggedVegetables--;  notifyListeners(); }
  void incrementFruits()        { _loggedFruits++;                                 notifyListeners(); }
  void decrementFruits()        { if (_loggedFruits > 0) _loggedFruits--;          notifyListeners(); }
  void incrementWater()         { _loggedWater++;                                  notifyListeners(); }
  void decrementWater()         { if (_loggedWater > 0) _loggedWater--;            notifyListeners(); }
  void addFoodItem(String f)    { _loggedFoods.add(f);    notifyListeners(); }
  void removeFoodItem(String f) { _loggedFoods.remove(f); notifyListeners(); }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SAVE NUTRITION LOG
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> saveNutritionLog() async {
    _saving = true;
    notifyListeners();
    try {
      final target = _nutrition?.vegetablesTarget ?? 5;
      final pct    = ((_loggedVegetables / target) * 100).clamp(0, 100).round();
      await _service.saveNutritionProgress(
        userId:             userId,
        dateStr:            HealthService.dateString(DateTime.now()),
        rapid3Tier:         _rapid3Tier,
        rapid3Score:        _rapid3Score,
        vegetablesConsumed: _loggedVegetables,
        fruitConsumed:      _loggedFruits,
        waterGlasses:       _loggedWater,
        foodsLogged:        List.from(_loggedFoods),
        adherencePercent:   pct,
      );
      // Mark as logged (shows checkmark) but user can still update until next day
      _nutritionDone = true;
    } catch (e, stack) {
      dev.log('[HealthController] saveNutritionLog FAILED: $e$stack');
      _errorMsg = 'Could not save nutrition log: $e';
    }
    _saving = false;
    notifyListeners();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RESET
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void reset() {
    _currentStep   = HealthStep.symptomQuestions;
    _painValue     = 0;
    _functionValue = 0;
    _globalValue   = 0;
    for (var i = 0; i < functionAnswers.length; i++) functionAnswers[i] = 0;
    for (final j in bodyJoints) { j.isSelected = false; j.severity = 'none'; }
    _stiffnessMinutes  = 0;
    _stressLevel       = 0.0;
    _sessionActive     = false;
    _sessionPaused     = false;
    _exerciseDone      = false;
    _sessionElapsedSec = 0;
    _pausedAtSec       = 0;
    _selectedExerciseIds.clear();
    _exerciseCompletionMap.clear();
    _exercisePauseMap.clear();
    _loggedVegetables  = 0;
    _loggedFruits      = 0;
    _loggedWater       = 0;
    _loggedFoods.clear();
    _nutritionDone = false;
    _errorMsg      = null;
    _sessionTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STATIC — body joints (hardcoded: anatomy never changes)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static List<BodyJoint> _buildJoints() => [
    BodyJoint(id: 'neck',           label: 'Neck'),
    BodyJoint(id: 'left_shoulder',  label: 'L Shoulder'),
    BodyJoint(id: 'right_shoulder', label: 'R Shoulder'),
    BodyJoint(id: 'left_elbow',     label: 'L Elbow'),
    BodyJoint(id: 'right_elbow',    label: 'R Elbow'),
    BodyJoint(id: 'left_wrist',     label: 'L Wrist'),
    BodyJoint(id: 'right_wrist',    label: 'R Wrist'),
    BodyJoint(id: 'left_hand',      label: 'L Hand'),
    BodyJoint(id: 'right_hand',     label: 'R Hand'),
    BodyJoint(id: 'lower_back',     label: 'Lower Back'),
    BodyJoint(id: 'left_hip',       label: 'L Hip'),
    BodyJoint(id: 'right_hip',      label: 'R Hip'),
    BodyJoint(id: 'left_knee',      label: 'L Knee'),
    BodyJoint(id: 'right_knee',     label: 'R Knee'),
    BodyJoint(id: 'left_ankle',     label: 'L Ankle'),
    BodyJoint(id: 'right_ankle',    label: 'R Ankle'),
    BodyJoint(id: 'left_foot',      label: 'L Foot'),
    BodyJoint(id: 'right_foot',     label: 'R Foot'),
  ];

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STATIC — fallback data (when DB is unreachable)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static List<Rapid3Question> _fallbackQuestions() => [
    const Rapid3Question(
      id: 'pain', questionNumber: 1,
      question: 'How much pain have you had because of your condition over the past week?',
      questionDetail: 'Rate your pain on a scale of 0-10',
      minValue: 0, maxValue: 10,
      minLabel: 'No pain', maxLabel: 'Severe pain',
      unit: '/10', type: 'slider', category: 'pain',
    ),
    Rapid3Question(
      id: 'function_config', questionNumber: 2,
      question: 'How much difficulty did you have with daily activities?',
      questionDetail: 'Rate each activity (0 = No difficulty, 3 = Unable to do)',
      minValue: 0, maxValue: 3,
      minLabel: 'No difficulty', maxLabel: 'Unable to do',
      unit: '/3', type: 'radio', category: 'function',
      options: const [
        Rapid3Option(value: 0, label: 'No difficulty'),
        Rapid3Option(value: 1, label: 'Some difficulty'),
        Rapid3Option(value: 2, label: 'Much difficulty'),
        Rapid3Option(value: 3, label: 'Unable to do'),
      ],
    ),
    const Rapid3Question(
      id: 'global', questionNumber: 3,
      question: 'Considering all the ways in which illness and health conditions may affect you at this time, please indicate below how are you doing?',
      questionDetail: 'Rate your overall health status',
      minValue: 0, maxValue: 10,
      minLabel: 'Very well', maxLabel: 'Very poor',
      unit: '/10', type: 'slider', category: 'global',
    ),
  ];

  static Rapid3TierDefinition _fallbackTierDef(String tier) {
    final defs = <String, Rapid3TierDefinition>{
      'REMISSION': Rapid3TierDefinition(tierId: 'REMISSION', tierName: 'Remission',           emoji: '🟢', colorHex: '#10B981', rapid3Min: 0, rapid3Max: 1,  statusText: 'Your RA is well-controlled!',      statusDescription: 'Excellent disease control.',                            alert: false, alertMessage: ''),
      'LOW':       Rapid3TierDefinition(tierId: 'LOW',       tierName: 'Low Activity',        emoji: '🟡', colorHex: '#F59E0B', rapid3Min: 1, rapid3Max: 2,  statusText: 'Good control - maintain it!',      statusDescription: 'Good disease control with some caution needed.',         alert: false, alertMessage: ''),
      'MODERATE':  Rapid3TierDefinition(tierId: 'MODERATE',  tierName: 'Moderate Activity',   emoji: '🟠', colorHex: '#F97316', rapid3Min: 2, rapid3Max: 4,  statusText: 'Active disease - modify lifestyle', statusDescription: 'Disease is active - adapt lifestyle to support recovery.', alert: false, alertMessage: ''),
      'HIGH':      Rapid3TierDefinition(tierId: 'HIGH',      tierName: 'High Activity/Flare', emoji: '🔴', colorHex: '#EF4444', rapid3Min: 4, rapid3Max: 10, statusText: 'Flare - Call your doctor!',         statusDescription: 'High disease activity - seek medical advice.',           alert: true,  alertMessage: 'Call your rheumatologist - may need medication adjustment.'),
    };
    return defs[tier] ?? defs['MODERATE']!;
  }

  static List<ExerciseRecommendation> _fallbackExercises(String tier) {
    final data = <String, List<ExerciseRecommendation>>{
      'REMISSION': [ExerciseRecommendation(id: 'r1', name: 'Brisk Walking',   duration: '30-40 min', type: 'Aerobic',     intensity: 'Moderate',   jointImpact: 'Low',      benefits: ['Cardiovascular fitness', 'Mood improvement'], instructions: ['Wear supportive shoes', 'Walk at conversational pace'], warnings: [],                        equipmentNeeded: 'Comfortable shoes',  difficulty: 'Easy',      tier: 'REMISSION')],
      'LOW':       [ExerciseRecommendation(id: 'l1', name: 'Gentle Walking',  duration: '25-30 min', type: 'Aerobic',     intensity: 'Moderate',   jointImpact: 'Low',      benefits: ['Maintain fitness'],                            instructions: ['Monitor pain levels'],                                 warnings: [],                        equipmentNeeded: 'Comfortable shoes',  difficulty: 'Easy',      tier: 'LOW'),
                   ExerciseRecommendation(id: 'l2', name: 'Yoga',            duration: '25-30 min', type: 'Flexibility', intensity: 'Low-Moderate',jointImpact: 'Very Low', benefits: ['Flexibility', 'Stress relief'],                 instructions: ['Go at your own pace'],                                 warnings: [],                        equipmentNeeded: 'Yoga mat (optional)',difficulty: 'Easy',      tier: 'LOW')],
      'MODERATE':  [ExerciseRecommendation(id: 'm1', name: 'Gentle Yoga',    duration: '15-20 min', type: 'Flexibility', intensity: 'LOW',         jointImpact: 'Very Low', benefits: ['Pain relief', 'Flexibility'],                   instructions: ['Do in comfortable space', 'Breathe deeply'],           warnings: ['Stop if pain increases'], equipmentNeeded: 'Yoga mat (optional)',difficulty: 'Easy',      tier: 'MODERATE'),
                   ExerciseRecommendation(id: 'm2', name: 'Tai Chi',        duration: '15-20 min', type: 'Mind-Body',   intensity: 'LOW',         jointImpact: 'Very Low', benefits: ['Balance', 'Calm'],                              instructions: ['Follow guided video'],                                 warnings: [],                        equipmentNeeded: 'None',              difficulty: 'Easy',      tier: 'MODERATE')],
      'HIGH':      [ExerciseRecommendation(id: 'h1', name: 'Range of Motion',duration: '5-10 min',  type: 'ROM',         intensity: 'PROTECTIVE',  jointImpact: 'Minimal',  benefits: ['Prevent stiffness'],                           instructions: ['Move gently', 'Can be done in bed'],                   warnings: ['Stop if sharp pain'],    equipmentNeeded: 'Bed or chair',      difficulty: 'Very Easy', tier: 'HIGH')],
    };
    return data[tier] ?? data['MODERATE']!;
  }

  static NutritionRecommendation _fallbackNutrition(String tier) {
    final data = <String, NutritionRecommendation>{
      'REMISSION': NutritionRecommendation(id: 'n_r', name: 'Balanced Diet',                description: 'Mix of all food groups',        dailyGoal: '5+ veg + 2 fruits',            vegetablesTarget: 5, fruitsTarget: 2, waterGlassesTarget: 8,  focusArea: 'Whole foods',            examples: ['Spinach, broccoli, carrots', 'Apple, blueberries', 'Chicken, fish, tofu'], avoidFoods: [],                                          tips: ['Eat a variety of colors', 'Choose whole grains'],        tier: 'REMISSION'),
      'LOW':       NutritionRecommendation(id: 'n_l', name: 'Whole Food Diet',              description: 'Focus on unprocessed foods',    dailyGoal: '4-5 veg + 2 fruits',           vegetablesTarget: 5, fruitsTarget: 2, waterGlassesTarget: 8,  focusArea: 'Omega-3 foods',          examples: ['Salmon, sardines', 'Leafy greens', 'Walnuts, flaxseed'],                   avoidFoods: ['Limit processed foods'],                   tips: ['Add omega-3 rich foods daily'],                         tier: 'LOW'),
      'MODERATE':  NutritionRecommendation(id: 'n_m', name: 'Anti-Inflammatory Diet',       description: 'Strict anti-inflammatory diet', dailyGoal: '5+ deep-color veg + 2 fruits', vegetablesTarget: 5, fruitsTarget: 2, waterGlassesTarget: 8,  focusArea: 'Fatty fish 2-3x/week',   examples: ['Salmon, sardines', 'Spinach, kale', 'Blueberries'],                         avoidFoods: ['Processed foods', 'Excess sugar', 'Fast food'], tips: ['Deep-color vegetables', 'Eliminate processed foods'], tier: 'MODERATE'),
      'HIGH':      NutritionRecommendation(id: 'n_h', name: 'Aggressive Anti-Inflammatory', description: 'Emergency nutrition support',   dailyGoal: '6+ antioxidant veg + omega-3', vegetablesTarget: 6, fruitsTarget: 2, waterGlassesTarget: 10, focusArea: 'Daily omega-3 essential', examples: ['Blueberries especially', 'Spinach, kale', 'Salmon, flaxseed'],               avoidFoods: ['ALL processed foods', 'Any added sugar', 'Alcohol'], tips: ['Strict adherence critical', 'Daily omega-3 essential'],  tier: 'HIGH'),
    };
    return data[tier] ?? data['MODERATE']!;
  }
}