import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';

const _COLLECTION_KEY = COLLECTION_ACTIVE_REQUEST_PROVIDER;

class ActiveRequestProviderProvider {

  static Future<void> create(String requestId) async {
    _throwIfStringIdEmpty(requestId, "Request");

    await FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc(requestId)
      .set({});
  }

  static Future<void> delete(String requestId) {
    _throwIfStringIdEmpty(requestId, "Request");

    return FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc(requestId)
      .delete();
  }

  static Future<DocumentSnapshot<FirestoreMap>> get(String requestId) {
    _throwIfStringIdEmpty(requestId, "Request");

    return FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc(requestId)
      .get();
  }

  static Future<QuerySnapshot<FirestoreMap>> getByUserId(String userId) {
    _throwIfStringIdEmpty(userId, "User");

    return FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .where('userId', isEqualTo: userId)
      .get();
  }

  static void _throwIfStringIdEmpty(String id, String idName) {
    final idNotProvided = id.isEmpty;
    if (idNotProvided) {
      throw AssertionError('$id ID was not provided.');
    }
  }

  // TODO: Stop storing isActive and status here; the later should only live on `request`.
  static Future<void> update(String requestId, FirestoreMap updateMap) {
    _throwIfStringIdEmpty(requestId, "Request");

    return FirebaseFirestore
      .instance
        .collection(_COLLECTION_KEY)
        .doc(requestId)
        .update(updateMap);
  }

  static Future<void> upsert(String requestId, FirestoreMap setMap) {
    _throwIfStringIdEmpty(requestId, "Request");

    return FirebaseFirestore
      .instance
        .collection(_COLLECTION_KEY)
        .doc(requestId)
        .set(setMap);
  }
}
