import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/models/service_request.dart';
import 'package:t2t_flutter_prototype/providers/request_provider.dart';

class RequestRepository {

  static String create() => RequestProvider.create();

  static Future<void> createOrReplace(ServiceRequest request) {
    final requestId = request.id;
    final map = request.toFirestoreMap();
    return RequestProvider.upsert(requestId, map);
  }

  static ServiceRequest? _firestoreMapToRequest(FirestoreMap? map) {
    final noDataProvided = map == null;
    if (noDataProvided) {
      return null;
    }

    final request = ServiceRequest.withFirstoreMap(map!);
    return request;
  }

  static Future<ServiceRequest?> get(String requestId) async {
    final snapshot = await RequestProvider.get(requestId);
    final data = snapshot.data();

    final noDataProvided = data == null;
    if (noDataProvided) {
      return null;
    }

    final request = ServiceRequest.withFirstoreMap(data!);
    return request;
  }

  static Future<ServiceRequest> getOrThrow(String requestId) async {
    final request = await RequestRepository.get(requestId);

    final noRequestFound = request == null;
    if (noRequestFound) {
      throw AssertionError("No request was found associated with $requestId");
    }
    return request!;
  }

  static Stream<ServiceRequest?> getStream(String requestId) {
    return RequestProvider
      .getStream(requestId)
      .map<ServiceRequest?>((snapshot) {
        final data = snapshot.data();
        return RequestRepository._firestoreMapToRequest(data);
      });
  }

  static Stream<QuerySnapshot<FirestoreMap>> getWaitingForProviderRequests() =>
    RequestProvider.getWaitingForProviderRequests();

  static Future<void> replace(ServiceRequest request) {
    final requestId = request.id;
    final map = request.toFirestoreMap();
    return RequestProvider.update(requestId, map);
  }

  static Future<void> update(String requestId, FirestoreMap updateMap) =>
    RequestProvider.update(requestId, updateMap);
}
