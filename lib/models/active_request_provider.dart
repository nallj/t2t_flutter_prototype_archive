import 'package:t2t_flutter_prototype/constants/firestore.dart';

import 'package:t2t_flutter_prototype/constants/request_status.dart';
import 'package:t2t_flutter_prototype/providers/active_request_provider_provider.dart';

class ActiveRequestProvider {
  // late bool isActive;
  late String requestId;
  // late Timestamp requestTimestamp;
  late RequestStatusType status;
  late String userId;

  /// Use in tendem with the static create function.
  ActiveRequestProvider._create(String requestId) {
    this.requestId = requestId;
  }

  ActiveRequestProvider.withFirstoreMap(FirestoreMap firestoreMap) {
    fromFirestoreMap(firestoreMap);
  }

  static Future<ActiveRequestProvider> create(String requestId) async {
    final activeRequestConsumer = ActiveRequestProvider._create(requestId);
    await ActiveRequestProviderProvider.create(requestId);
    return activeRequestConsumer;
  }

  void fromFirestoreMap(FirestoreMap map) {
    requestId = map[requestIdKeyInQuestion];
    // isActive = map[isActiveKey];
    userId = map[userIdKey];
    status = RequestStatus.toRequestStatusType(map[statusKey]);
    // requestTimestamp = map[requestTimestampKey];
  }

  FirestoreMap toFirestoreMap() {
    final firestoreMap = {
      'requestId': requestId,
      // 'isActive': isActive,
      'userId': userId,
      'status': RequestStatus.getDbString(status),
      // 'requestTimestamp': requestTimestamp
    };
    return firestoreMap;
  }
}
