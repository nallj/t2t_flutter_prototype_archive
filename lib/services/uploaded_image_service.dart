import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'dart:io';
import 'dart:typed_data';

import 'package:t2t_flutter_prototype/constants/uploaded_image_type.dart';

final BUCKET_URI = 'gs://t2t_business_images';

class UploadedImageService {

  static UploadedImageType getTypeFromDbInt(int dbInt) {
    final isDriver = dbInt == UploadedImageTypes.DRIVER;
    return isDriver ? UploadedImageType.Driver : UploadedImageType.FleetVehicle;
  }

  static int getDbStringFromType(UploadedImageType type) {
    return type == UploadedImageType.Driver ? UploadedImageTypes.DRIVER : UploadedImageTypes.FLEET_VEHICLE;
  }

  // Download a file from Google Cloud Storage.
  // static Future downloadFile(
  //   storage.StorageApi api,
  //   String bucket,
  //   String object,
  //   String file
  // ) async {
  //   final media = await api.objects.get(
  //     bucket,
  //     object,
  //     downloadOptions: storage.DownloadOptions.fullMedia
  //   ) as storage.Media;
  //   var fileStream = new File(file).openWrite();
  //   final thing = await media.stream.pipe(fileStream);
  //   return thing;
  // }

  // static Future<Stream<List<int>>> getFileStream(
  //   storage.StorageApi api,
  //   String bucket,
  //   String object
  // ) async {
  //   final media = await api.objects.get(
  //     bucket,
  //     object,
  //     downloadOptions: storage.DownloadOptions.fullMedia
  //   ) as storage.Media;
  //   return media.stream;
  // }

  // TODO: T2T-46 | Build a Go microservice to interact with the Google buckets.
  // ref: https://cloud.google.com/community/tutorials/telepresence-and-gke
  static Future<Stream<List<int>>> getImageFromBucket(String bucketFile) async {

    final jsonCredentials = await rootBundle.loadString('assets/credentials/bucket_credentials.json');

    // Read the service account credentials from the file.
    // final jsonCredentials = new File('assets/credentials/bucket_credentials.json').readAsStringSync();
    final credentials = new auth.ServiceAccountCredentials.fromJson(jsonCredentials);

    // Get an HTTP authenticated client using the service account credentials.
    // TODO: This can't be the right scope...
    // But it probably doesn't matter when this gets moved to a microservice.
    final scopes = [storage.StorageApi.devstorageReadOnlyScope];
    final client = await auth.clientViaServiceAccount(credentials, scopes);

    final api = new storage.StorageApi(client);

    // final imageBytesStream = await getFileStream(api, 't2t_business_images', bucketFile);

    final media = await api.objects.get(
      BUCKET_URI,
      bucketFile,
      downloadOptions: storage.DownloadOptions.fullMedia
    ) as storage.Media;
    final imageBytesStream = media.stream;
    final imageBytes = await imageBytesStream.first;

    //! TODO: Need client.close(), but is this before or after the stream is used up?

    // storage.Bucket(name: 't2t_business_images')
    // final store = new storage.Storage(client, 'my-project');
    // final bucket = store.bucket('');
    // // final bucket = await storage.createBucket('my-bucket');
    // // new File('my-file.txt').openRead().pipe(bucket.write('my-object'));

    // final imageBytesStream = bucket.read(bucketFile);
    return imageBytesStream;
  }

  static Future<Uint8List> getImageFromStream(Stream<List<int>> stream) async {
    var list = List<int>.empty();
    // await for (final val in stream) {
    //   list.add(val);
    // }
    list = await stream.first;
    return Uint8List.fromList(list);
  }
}
