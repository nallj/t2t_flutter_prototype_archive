import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:t2t_flutter_prototype/constants/request_status.dart';
import 'package:t2t_flutter_prototype/constants/service_type.dart';
import 'package:t2t_flutter_prototype/constants/user_type.dart';
import 'package:t2t_flutter_prototype/constants/view_state.dart';
import 'package:t2t_flutter_prototype/models/active_request_consumer.dart';
import 'package:t2t_flutter_prototype/models/consumer_driver_info.dart';
import 'package:t2t_flutter_prototype/models/destination.dart';
import 'package:t2t_flutter_prototype/models/location.dart';
import 'package:t2t_flutter_prototype/models/request_participant.dart';
import 'package:t2t_flutter_prototype/models/service_request.dart';
import 'package:t2t_flutter_prototype/repositories/active_request_consumer_repository.dart';
import 'package:t2t_flutter_prototype/repositories/business_repository.dart';
import 'package:t2t_flutter_prototype/repositories/fleet_vehicle_repository.dart';
import 'package:t2t_flutter_prototype/repositories/request_repository.dart';
import 'package:t2t_flutter_prototype/repositories/uploaded_image_repository.dart';
import 'package:t2t_flutter_prototype/repositories/user_repository.dart';
import 'package:t2t_flutter_prototype/services/debug_service.dart';
import 'package:t2t_flutter_prototype/services/uploaded_image_service.dart';
import 'package:t2t_flutter_prototype/services/user_service.dart';
import 'package:t2t_flutter_prototype/src/logic/location.dart';
import 'package:t2t_flutter_prototype/src/logic/request_participant.dart';

enum UserProceedAction {
  ACCEPT_DESTINATION_ADDRESS,
}

class InitCustomerScreen extends RequestParticipantEvent {}
class CustomerCreateRequest extends RequestParticipantEvent {
  Destination destination;
  CustomerCreateRequest({ required this.destination });
}
class CustomerCancelRequest extends RequestParticipantEvent {}
class DriverInfoRequest extends RequestParticipantEvent {
  String driverUserId;
  DriverInfoRequest({ required this.driverUserId });
}

class ScheduleCustomerBloc extends RequestParticipantBloc {

  ScheduleCustomerBloc({ required LocationBloc locationBloc })
    : super(UserType.Customer, locationBloc: locationBloc) {

    on<CustomerCreateRequest>((event, emit) async {
      await _saveRequest(emit, event.destination);
    });
    on<CustomerCancelRequest>((event, emit) {
      _cancelRequest(emit);
    });

    on<InitCustomerScreen>((event, emit) async {
      await _attemptRecoverActiveRequest(emit);
    });
  }

  Future<void> _addRequestListener(Emitter<RequestParticipantState> emit, String requestId) async {

    //! This has got to go somewhere.
    currentRequest$ = RequestRepository
      .getStream(requestId);

    await emit.forEach(currentRequest$!, onData: (ServiceRequest? request) {
      return _handleRequestUpdate(request)!;
    }, onError: (error, stackTrace) {
        final meh = RequestParticipantState();
        return meh;
    });
  }

  _attemptRecoverActiveRequest(Emitter<RequestParticipantState> emit) async {
    final requestId = await _recoverActiveRequestId();
    await _handleRecoveredActiveRequest(emit, requestId);
  }

  _cancelRequest(Emitter<RequestParticipantState> emit) async {
    final user = await UserService.getUserDataLogin();

    final userId = user.id;
    final requestId = getCurrentRequestId();

    final deleteActiveRequest = (_) {
      ActiveRequestConsumerRepository
        .delete(userId)
        .then((_) {
          // setViewState(ViewState.PROVIDER_NOT_CALLED);
          clearCurrentRequest(emit, viewStateChange: ViewState.PROVIDER_NOT_CALLED);
        });
    };

    RequestRepository
      .update(
        requestId,
        {
          'status': RequestStatus.CUSTOMER_CANCELED
        }
      )
      .then(deleteActiveRequest);
  }

  _emitViewStateChange(Emitter<RequestParticipantState> emit, ViewState viewState) {
    final newState = RequestParticipantState(
      viewState: viewState,
      userProceed: state.userProceed,
      currentRequest: state.currentRequest,
      logoutAction: state.logoutAction,
    );
    emit(newState);
  }

  RequestParticipantState _getViewStateChange(ViewState viewState, { ServiceRequest? currentRequest }) {
    final newState = RequestParticipantState(
      viewState: viewState,
      userProceed: state.userProceed,
      currentRequest: currentRequest,
      logoutAction: state.logoutAction,
    );
    return newState;
  }

  Future<void> _handleRecoveredActiveRequest(Emitter<RequestParticipantState> emit, String? requestId) async {
    final activeRequestExists = requestId != null;
    if (activeRequestExists) {
      await _addRequestListener(emit, requestId!);
    } else {
      _emitViewStateChange(emit, ViewState.PROVIDER_NOT_CALLED);
    }
  }

  RequestParticipantState? _handleRequestUpdate(ServiceRequest? request) {
    final isRequestProvided = request != null;
    if (isRequestProvided) {
      final status = request!.status;
      switch (status) {
        case RequestStatusType.WAITING_FOR_PROVIDER:
          return _getViewStateChange(ViewState.WAITING_FOR_PROVIDER, currentRequest: request);
        case RequestStatusType.PROVIDER_COMMITTED:
          // Can't do async call in emitter.forEach
          // final driverInfo = await _getDriverInfo(request.provider!.userId);
          return _getViewStateChange(ViewState.PROVIDER_COMMITTED, currentRequest: request);
        case RequestStatusType.PROVIDER_AT_SCENE:
          throw Exception('Not implemented');
        case RequestStatusType.PROVIDER_TOWING:
          return _getViewStateChange(ViewState.PROVIDER_TOWING, currentRequest: request);
        case RequestStatusType.JOB_FINISHED:
          return _getViewStateChange(ViewState.JOB_FINISHED, currentRequest: request);
        case RequestStatusType.CUSTOMER_CANCELED:
        case RequestStatusType.PROVIDER_CANCELED:
        case RequestStatusType.CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED:
          break;
      }
    }
    return null; // temporary thing for testing emit.forEach
  }

  Future<ConsumerDriverInfo> getDriverInfo(String driverUserId) async {
    // TODO: The app puts the new provider info on the provider user record (see T2T-45).
    final driverUser = await UserRepository.getUserOrThrow(driverUserId, "Provider doesn't exist.");

    final businessId = driverUser.businessId;
    final businessIdNotProvided = businessId == null;
    if (businessIdNotProvided) {
      throw Exception("Provider doesn't have a business ID.");
    }
    final business = await BusinessRepository.get(businessId!);
    final businessName = business.name;


    final iconId = driverUser.iconId;
    final iconIdNotProvided = iconId == null;
    if (iconIdNotProvided) {
      throw Exception("Provider doesn't have an icon ID.");
    }


    final driverInfo = ConsumerDriverInfo(
      driverUser.name,
      businessName,
    );
    return driverInfo;
  }

  Future<String?> _recoverActiveRequestId() async {
    final userNotAuthed = !(await UserService.isAuthedUser());
    if (userNotAuthed) {
      // return null;
      DebugService.pr('Unauthed user in schedule_customer view.', '_recoverActiveRequestId');
      //! This happens whenever I log out.
      //! Is /|\ still accurate?
      throw Exception('How did you even get here?');
    }

    final currentUser = await UserService.getCurrentUser();
    final userId = currentUser.uid;

    final activeReq = await ActiveRequestConsumerRepository.getByUserId(userId);

    final activeRequestExists = activeReq != null;
    if (activeRequestExists) {
      final requestId = activeReq!.requestId;
      return requestId;
    }
  }

  // TODO: Handle failure to save.
  Future<void> _saveRequest(Emitter<RequestParticipantState> emit, Destination destination) async {
    final customerUser = await UserService.getUserDataLogin();
    final customer = RequestParticipant.fromUser(customerUser);
    final customerId = customer.userId;

    final customerLocationNotSet = !isCurrentLocationSet();
    if (customerLocationNotSet) {
      throw Exception("Can't save request. Customer location is not set.");
    }

    final currentLocation = locationBloc.state.currentLocation;
    final lat = currentLocation!.latitude;
    final lon = currentLocation.longitude;
    final heading = currentLocation.heading;
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

    RequestRepository.createOrReplace(request);

    final activeRequest = await ActiveRequestConsumer.create(requestId);
    activeRequest.userId = customerId;
    activeRequest.requestTimestamp = request.requestTimestamp;
    activeRequest.isActive = true;

    // TODO: Consider not having this here. This is already expressed on the `request` document.
    activeRequest.status = RequestStatusType.WAITING_FOR_PROVIDER;

    ActiveRequestConsumerRepository.replace(activeRequest);

    //! Moved here to try and capture first publish.
    await _addRequestListener(emit, requestId);
  }
}
