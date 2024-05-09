import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/models/active_request_consumer.dart';
import 'package:t2t_flutter_prototype/providers/active_request_consumer_provider.dart';
import 'package:t2t_flutter_prototype/services/debug_service.dart';

class ActiveRequestConsumerRepository {

  static Future<void> createOrReplace(ActiveRequestConsumer activeRequest) {
    final requestId = activeRequest.requestId;
    final map = activeRequest.toFirestoreMap();
    return ActiveRequestConsumerProvider.upsert(requestId, map);
  }

  static Future<void> delete(String userId) =>
    ActiveRequestConsumerProvider.delete(userId);

  static Future<ActiveRequestConsumer?> get(String requestId) async {
    final snapshot = await ActiveRequestConsumerProvider.get(requestId);
    final data = snapshot.data();

    final noDataProvided = data == null;
    if (noDataProvided) {
      return null;
    }

    final request = ActiveRequestConsumer.withFirstoreMap(data!);
    return request;
  }

  static Future<ActiveRequestConsumer?> getByUserId(String userId) async {
    final snapshot = await ActiveRequestConsumerProvider.getByUserId(userId);


    final noDataProvided = snapshot.docs.length == 0;
    if (noDataProvided) {
      return null;
    }

    final tooManyDocsReturned = snapshot.docs.length > 1;
    if (tooManyDocsReturned) {
      DebugService.pr('Too many active requests associated with single user.', 'ActiveRequestConsumerRepository.getByUserId');
    }

    final data = snapshot.docs[0].data();
    final request = ActiveRequestConsumer.withFirstoreMap(data);
    return request;
  }

  static Future<void> replace(ActiveRequestConsumer activeRequest) {
    final requestId = activeRequest.requestId;
    final map = activeRequest.toFirestoreMap();
    return ActiveRequestConsumerProvider.update(requestId, map);
  }

  static Future<void> update(String requestId, FirestoreMap updateMap) =>
    ActiveRequestConsumerProvider.update(requestId, updateMap);
}
