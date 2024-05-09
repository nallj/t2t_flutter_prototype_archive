import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/constants/uploaded_image_type.dart';
import 'package:t2t_flutter_prototype/services/uploaded_image_service.dart';

class UploadedImage {
  late String id;
  late String bucketFile;
  late UploadedImageType type;

  UploadedImage(this.id, this.bucketFile, this.type);

  UploadedImage.withFirstoreMap(FirestoreMap firestoreMap) {
    fromFirestoreMap(firestoreMap);
  }

  void fromFirestoreMap(FirestoreMap map) {
    id = map[idKey];
    bucketFile = map[bucketFileKey];
    type = UploadedImageService.getTypeFromDbInt(map[typeKey]);
  }

  FirestoreMap toFirestoreMap() {
    final firestoreMap = {
      'id': id,
      'bucketFile': bucketFile,
      'type': type
    };
    return firestoreMap;
  }
}