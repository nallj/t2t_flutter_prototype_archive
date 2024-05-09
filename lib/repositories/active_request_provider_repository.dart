import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/models/active_request_provider.dart';
import 'package:t2t_flutter_prototype/providers/active_request_provider_provider.dart';
import 'package:t2t_flutter_prototype/services/debug_service.dart';

class ActiveRequestProviderRepository {

  static Future<void> createOrReplace(ActiveRequestProvider activeRequest) {
    final requestId = activeRequest.requestId;
    final map = activeRequest.toFirestoreMap();
    return ActiveRequestProviderProvider.upsert(requestId, map);
  }

  static Future<void> delete(String userId) =>
    ActiveRequestProviderProvider.delete(userId);

  static Future<ActiveRequestProvider?> get(String requestId) async {
    final snapshot = await ActiveRequestProviderProvider.get(requestId);
    final data = snapshot.data();

    final noDataProvided = data == null;
    if (noDataProvided) {
      return null;
    }

    final request = ActiveRequestProvider.withFirstoreMap(data!);
    return request;
  }

  static Future<ActiveRequestProvider?> getByUserId(String userId) async {
    final snapshot = await ActiveRequestProviderProvider.getByUserId(userId);

    final noDataProvided = snapshot.docs.length == 0;
    if (noDataProvided) {
      return null;
    }

    final tooManyDocsReturned = snapshot.docs.length > 1;
    if (tooManyDocsReturned) {
      DebugService.pr('Too many active requests associated with single user.', 'ActiveRequestProviderRepository.getByUserId');
    }

    final data = snapshot.docs[0].data();
    final request = ActiveRequestProvider.withFirstoreMap(data);
    return request;
  }

  static Future<void> replace(ActiveRequestProvider activeRequest) {
    final requestId = activeRequest.requestId;
    final map = activeRequest.toFirestoreMap();
    return ActiveRequestProviderProvider.update(requestId, map);
  }

  static Future<void> update(String requestId, FirestoreMap updateMap) =>
    ActiveRequestProviderProvider.update(requestId, updateMap);
}
