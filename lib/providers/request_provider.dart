import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/constants/request_status.dart';

const _COLLECTION_KEY = COLLECTION_REQUEST;

class RequestProvider {

  static String create() {
    final newRequest = FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc();
    return newRequest.id;
  }

  static Future<void> delete(String userId) {
    _throwIfStringIdEmpty(userId, "User");

    return FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc(userId)
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

  static Stream<DocumentSnapshot<FirestoreMap>> getStream(String requestId) {
    _throwIfStringIdEmpty(requestId, "Request");

    return FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc(requestId)
      .snapshots();
  }

  static Stream<QuerySnapshot<FirestoreMap>> getWaitingForProviderRequests() {
    return FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .where(statusKey, isEqualTo: RequestStatus.WAITING_FOR_PROVIDER)
      .snapshots();
  }

  static void _throwIfStringIdEmpty(String id, String idName) {
    final idNotProvided = id.isEmpty;
    if (idNotProvided) {
      throw AssertionError('$id ID was not provided.');
    }
  }

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
