import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/constants/request_status.dart';
import 'package:t2t_flutter_prototype/constants/service_type.dart';
import 'package:t2t_flutter_prototype/constants/user_type.dart';
import 'package:t2t_flutter_prototype/models/destination.dart';
import 'package:t2t_flutter_prototype/models/location.dart';
import 'package:t2t_flutter_prototype/models/request_participant.dart';
import 'package:t2t_flutter_prototype/repositories/request_repository.dart';

class ServiceRequest {
  late String id;
  late ServiceType type;
  late RequestParticipant customer;
  RequestParticipant? provider;
  late Location origin;
  late Destination destination;
  late RequestStatusType status;
  late Timestamp requestTimestamp;

  ServiceRequest() {
    id = RequestRepository.create();
  }

  ServiceRequest.withFirstoreMap(Map<String, dynamic> firestoreMap) {
    fromFirestoreMap(firestoreMap);
  }

  void fromFirestoreMap(Map<String, dynamic> map) {

    id = map[requestIdKeyInQuestion];
    // type = ServiceTypeString.toServiceType(map[typeKey]);
    customer = RequestParticipant.withFirstoreMap(map[requestCustomerKey]);
    customer.userType = UserType.Customer;

    final providerData = map[requestProviderKey];
    final providerDataProvided = providerData != null;
    if (providerDataProvided) {
      provider = RequestParticipant.withFirstoreMap(providerData);
      customer.userType = UserType.Provider;
    }

    origin = Location.withFirstoreMap(map[requestOriginKey]);
    destination = Destination.withFirstoreMap(map[requestDestinationKey]);
    status = RequestStatus.toRequestStatusType(map[statusKey]);
    requestTimestamp = map[requestTimestampKey];
  }

  Map<String, dynamic> toFirestoreMap() {
    final firestoreMap = {
      'requestId': id,
      'customer': customer.toFirestoreMap(includeLocation: true),
      'origin': origin.toFirestoreMap(),
      'destination': destination.toFirestoreMap(),
      'serviceType': _serviceTypeToDbString(),
      // 'latitude': customer.getLatitude(), // TODO: But I'm already storing the customer on this document. Admittedly, I'm thinking of getting rid of that since I don't know a practical reason to store a lat/lon (that's up-to-date all the time) on the customer record.
      // 'longitude': customer.getLatitude(),
      'status': RequestStatus.getDbString(status),
      'requestTimestamp': requestTimestamp
    };
    final isProviderSet = provider != null;
    if (isProviderSet) {
      firestoreMap['provider'] = provider!.toFirestoreMap(includeLocation: true);
    }
    return firestoreMap;
  }

  _serviceTypeToDbString() {
    switch (type) {
      case ServiceType.FLAT_TIRE:
        return ServiceTypeString.FLAT_TIRE;
      case ServiceType.LOCKED_VEHICLE:
        return ServiceTypeString.LOCKED_VEHICLE;
      case ServiceType.WONT_START:
        return ServiceTypeString.WONT_START;
      case ServiceType.TOW:
        return ServiceTypeString.TOW;
      case ServiceType.FLATBED_TOW:
        return ServiceTypeString.FLATBED_TOW;
    }
    throw Exception('Unknown service type selected.');
  }
}
