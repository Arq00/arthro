import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/connection_request_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // AUTHENTICATION METHODS
  // ============================================================

  Future<void> registerUser(
  String email,
  String password,
  String fullName,
  String username,
  String role,
) async {
  try {
    // 1. Try creating the user
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Send verification email
    await userCredential.user!.sendEmailVerification();

    // 3. Create Firestore user
    UserModel user = UserModel(
      uid: userCredential.user!.uid,
      email: email,
      fullName: fullName,
      username: username,
      role: role,
      patientId: null,
      guardianId: null,
      linkCode: null,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      throw Exception("Email already exists");
    }
    rethrow;
  }
}


  Future<UserModel?> loginUser(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // FOR DUMMY DATA NEW USER
    /*if (!userCredential.user!.emailVerified) {
      await _auth.signOut();
      throw Exception("Please verify your email before logging in.");
    }*/
    
    return await fetchUserByUid(userCredential.user!.uid);
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ============================================================
  // USER PROFILE METHODS
  // ============================================================

  Future<UserModel?> fetchUserByUid(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> updateUsername(String uid, String newUsername) async {
    await _firestore.collection('users').doc(uid).update({
      'username': newUsername,
    });
  }

  Future<void> updatePassword(String newPassword) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No authenticated user.");
    await user.updatePassword(newPassword);
  }

  // ============================================================
  // GUARDIAN SYSTEM LOGIC 
  // ============================================================

  Future<void> updateLinkCode(String uid, String code) async {
    await _firestore.collection('users').doc(uid).update({'linkCode': code, 'linkCodeCreatedAt': FieldValue.serverTimestamp(),});
  }

  Future<UserModel?> findPatientByCode(String code) async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('linkCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    
    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    final timestamp = data['linkCodeCreatedAt'] as Timestamp?;
    if (timestamp != null) {
      final createdAt = timestamp.toDate();
      if (DateTime.now().difference(createdAt).inMinutes > 30) {
        return null; // expired
      }
    }

     return UserModel.fromMap(data);
  }
   // -------------------------
  // Pending Requests Stream
  // -------------------------
  Stream<ConnectionRequest?> streamPendingRequest(String patientId) {
    return _firestore
        .collection('connectionRequests')
        .doc(patientId)
        .snapshots()
        .map((doc) => doc.exists
            ? ConnectionRequest.fromMap(doc.data() as Map<String, dynamic>)
            : null);
  }

  /// [GUARDIAN SIDE] Sends a connection request to the patient's ID
  Future<void> sendConnectionRequest(ConnectionRequest request) async {
    await _firestore
        .collection('connectionRequests')
        .doc(request.patientId) // Use patientId as doc name so they can listen to it
        .set(request.toMap());
  }

  Future<ConnectionRequest?> fetchPendingRequest(String patientId) async {
    final doc = await _firestore.collection('connectionRequests').doc(patientId).get();
    if (!doc.exists) return null;
    return ConnectionRequest.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// [PATIENT SIDE] Finalizes the link by updating both documents in an Atomic Batch
  Future<void> establishLink(String patientId, String guardianId) async {
    WriteBatch batch = _firestore.batch();

    batch.update(_firestore.collection('users').doc(patientId), {
      'guardianId': guardianId,
      'linkCode': null, 
      'linkCodeCreatedAt': null,
    });

    batch.update(_firestore.collection('users').doc(guardianId), {
      'patientId': patientId,
    });

    // 3. Delete the request document from the handshake collection
    batch.delete(_firestore.collection('connectionRequests').doc(patientId));

    await batch.commit();
  }

  /// [PATIENT SIDE] Reject the request
  Future<void> rejectRequest(String patientId) async {
    await _firestore.collection('connectionRequests').doc(patientId).delete();
  }

  Future<void> revokeGuardianship(UserModel currentUser) async {
  final batch = _firestore.batch();
  if (currentUser.role == 'patient' && currentUser.guardianId != null) {
    batch.update(_firestore.collection('users').doc(currentUser.uid), {'guardianId': null});
    batch.update(_firestore.collection('users').doc(currentUser.guardianId!), {'patientId': null});
  } else if (currentUser.role == 'guardian' && currentUser.patientId != null) {
    batch.update(_firestore.collection('users').doc(currentUser.uid), {'patientId': null});
    batch.update(_firestore.collection('users').doc(currentUser.patientId!), {'guardianId': null});
  }
  await batch.commit();
}
}