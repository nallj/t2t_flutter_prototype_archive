import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/constants/request_status.dart';
import 'package:t2t_flutter_prototype/providers/active_request_consumer_provider.dart';

class ActiveRequestConsumer {
  late bool isActive;
  late String requestId;
  late Timestamp requestTimestamp;
  late RequestStatusType status;
  late String userId;

  /// Use in tendem with the static create function.
  ActiveRequestConsumer._create(String requestId) {
    this.requestId = requestId;
  }

  ActiveRequestConsumer.withFirstoreMap(FirestoreMap firestoreMap) {
    fromFirestoreMap(firestoreMap);
  }

  static Future<ActiveRequestConsumer> create(String requestId) async {
    final activeRequestConsumer = ActiveRequestConsumer._create(requestId);
    await ActiveRequestConsumerProvider.create(requestId);
    return activeRequestConsumer;
  }

  void fromFirestoreMap(FirestoreMap map) {
    requestId = map[requestIdKeyInQuestion];
    isActive = map[isActiveKey];
    userId = map[userIdKey];
    status = RequestStatus.toRequestStatusType(map[statusKey]);
    requestTimestamp = map[requestTimestampKey];
  }

  Map<String, dynamic> toFirestoreMap() {
    final firestoreMap = {
      'requestId': requestId,
      'isActive': isActive,
      'userId': userId,
      'status': RequestStatus.getDbString(status),
      'requestTimestamp': requestTimestamp
    };
    return firestoreMap;
  }
}
