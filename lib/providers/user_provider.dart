import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';

const _COLLECTION_KEY = COLLECTION_USER;

class UserProvider {

  static Future<FirestoreMap?> _getUser(String userId) async {
    final userSnapshot = await FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc(userId)
      .get();
    return userSnapshot.data();
  }

  static Future<FirestoreMap> getUserOrThrow(String userId, String exMessage) async {
    final userData = await UserProvider._getUser(userId);
    final noUserData = userData == null;
    if (noUserData) {
      throw Exception(exMessage);
    }
    return userData!;
  }

  static Future<void> upsert(String userId, FirestoreMap updateMap) {
    return FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc(userId)
      .set(updateMap);
  }
}
