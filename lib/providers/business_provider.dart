import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';

const _COLLECTION_KEY = COLLECTION_BUSINESS;

class BusinessProvider {

  static Future<FirestoreMap> getOrThrow(String id) async {
    final snapshot = await FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc(id)
      .get();
    final businessData = snapshot.data();
    final noBusinessData = businessData == null;
    if (noBusinessData) {
      throw Exception('No business data found for this ID.');
    }
    return businessData!;
  }
}
