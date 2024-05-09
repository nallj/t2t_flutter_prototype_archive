import 'package:t2t_flutter_prototype/models/uploaded_image.dart';
import 'package:t2t_flutter_prototype/providers/uploaded_image_provider.dart';

class UploadedImageRepository {

  static Future<UploadedImage> get(String id) async {
    final data = await UploadedImageProvider.getOrThrow(id);
    final uploadedImage = UploadedImage.withFirstoreMap(data);
    return uploadedImage;
  }
}
