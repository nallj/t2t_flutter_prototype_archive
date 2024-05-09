import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';

const _COLLECTION_KEY = COLLECTION_UPLOADED_IMAGE;

class UploadedImageProvider {

  static Future<FirestoreMap> getOrThrow(String id) async {
    final snapshot = await FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc(id)
      .get();
    final imageData = snapshot.data();
    final noImageData = imageData == null;
    if (noImageData) {
      throw Exception('No uploaded image data found for this ID.');
    }
    return imageData!;
  }
}
