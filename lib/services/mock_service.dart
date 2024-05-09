import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:t2t_flutter_prototype/constants/request_status.dart';
import 'package:t2t_flutter_prototype/constants/service_type.dart';
import 'package:t2t_flutter_prototype/models/active_request_consumer.dart';
import 'package:t2t_flutter_prototype/models/active_request_provider.dart';
import 'package:t2t_flutter_prototype/models/destination.dart';
import 'package:t2t_flutter_prototype/models/location.dart';
import 'package:t2t_flutter_prototype/models/request_participant.dart';
import 'package:t2t_flutter_prototype/models/service_request.dart';
import 'package:t2t_flutter_prototype/repositories/active_request_consumer_repository.dart';
import 'package:t2t_flutter_prototype/repositories/active_request_provider_repository.dart';
import 'package:t2t_flutter_prototype/repositories/request_repository.dart';

class MockService {

  // Transition from consumer WAITING_FOR_PROVIDER to PROVIDER_COMMITTED.
  static fakeProviderAcceptJob(fakeRequestId) {
    // final customerId = 'WDTVDsj1Kvd5KImoyh3GAYwD8yV2';
    final providerId = 'YrnF8hpo7XhJN4ux4oboI63NwLB2';

    final fakeProviderMap = {
      'userId': providerId,
      'name': 'Provider Rofl',
      'email': 'p@p.com',
      'type': 'provider',
      'latitude': 29.653657,
      'longitude': -82.325293,
      'heading': 315.0,
      'locationTimestamp': Timestamp.now(),
    };

    final nextStatus = RequestStatus.PROVIDER_COMMITTED;
    final requestUpdate = {
      'provider': fakeProviderMap,
      'status': nextStatus,
    };

    RequestRepository
      .update(fakeRequestId, requestUpdate)
      .then((_) {
        final activeRequestUpdate = {
          'status': nextStatus,
        };
        ActiveRequestConsumerRepository
          .update(fakeRequestId, activeRequestUpdate)
          .then((_) {
            ActiveRequestProvider
              .create(fakeRequestId)
              .then((activeRequestProvider) {
                final activeRequestProviderUpdate = {
                  'status': nextStatus,
                  'requestId': fakeRequestId,
                  'userId': providerId,
                };

                ActiveRequestProviderRepository.update(fakeRequestId, activeRequestProviderUpdate);
              });
          });
      });
  }

  // Transition from consumer PROVIDER_COMMITTED to WAITING_FOR_PROVIDER.
  static undoFakeProviderAcceptJob(fakeRequestId) {
    final nextStatus = RequestStatus.WAITING_FOR_PROVIDER;
    final requestUpdate = {
      'provider': null,
      'status': nextStatus,
    };

    RequestRepository
      .update(fakeRequestId, requestUpdate)
      .then((_) {
        final activeRequestUpdate = {
          'status': nextStatus,
        };
        ActiveRequestConsumerRepository.update(fakeRequestId, activeRequestUpdate);
        ActiveRequestProviderRepository.delete(fakeRequestId);
      });
  }

  static fakeConsumerSaveJob() {

    // From schedule_customer[view]._callProvider
    final destination = new Destination();
    destination.state = "Florida";
    destination.city = "Gainesville";
    destination.zip = "32608";
    destination.street = "3515 SW 39 Blvd";
    destination.latitude = 29.6171854;
    destination.longitude = -82.3754767;

    // From schedule_customer[logic]._saveRequest

    final customerId = 'WDTVDsj1Kvd5KImoyh3GAYwD8yV2';
    final customer = RequestParticipant();
    customer.userId = customerId;
    customer.email = 'c@c.com';
    customer.name = 'customer lol (mocked)';
    final lat = 29.653657;
    final lon = -82.325293;
    final heading = 45.2;
    customer.updateLocation(lat, lon, heading);

    final request = new ServiceRequest();
    final requestId = request.id;

    // TODO: Choose what type of job they want.
    request.type = ServiceType.TOW;

    request.customer = customer;
    request.origin = new Location(lat, lon);
    request.destination = destination;
    request.status = RequestStatusType.WAITING_FOR_PROVIDER;
    request.requestTimestamp = Timestamp.now();

    // //! Moved here to try and capture first publish.
    // _addRequestListener(emit, requestId);

    RequestRepository.createOrReplace(request);

    ActiveRequestConsumer
      .create(requestId)
      .then((activeRequest) {
        activeRequest.userId = customerId;
        activeRequest.requestTimestamp = request.requestTimestamp;
        activeRequest.isActive = true;

        // TODO: Consider not having this here. This is already expressed on the `request` document.
        activeRequest.status = RequestStatusType.WAITING_FOR_PROVIDER;

        ActiveRequestConsumerRepository.replace(activeRequest);
      });
  }

}
