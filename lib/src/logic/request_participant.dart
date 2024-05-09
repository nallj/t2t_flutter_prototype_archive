import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:t2t_flutter_prototype/constants/request_status.dart';

import 'package:t2t_flutter_prototype/constants/user_type.dart';
import 'package:t2t_flutter_prototype/constants/view_state.dart';
import 'package:t2t_flutter_prototype/models/consumer_driver_info.dart';
import 'package:t2t_flutter_prototype/models/request_participant.dart';
import 'package:t2t_flutter_prototype/models/service_request.dart';
import 'package:t2t_flutter_prototype/services/debug_service.dart';
import 'package:t2t_flutter_prototype/services/user_service.dart';
import 'package:t2t_flutter_prototype/src/logic/location.dart';

part 'request_participant_state.dart';

enum UserProceedAction {
  ACCEPT_DESTINATION_ADDRESS,
}

abstract class RequestParticipantEvent {}

class UserLogout extends RequestParticipantEvent {
  BuildContext context;
  UserLogout({ required this.context });
}
class SetCurrentRequest extends RequestParticipantEvent {
  ServiceRequest request;
  SetCurrentRequest({ required this.request });
}
class InitiateRequest extends SetCurrentRequest {
  InitiateRequest({ required request }) : super(request: request);
}
class ClearCurrentRequest extends RequestParticipantEvent {}
class SetCurrentLocation extends RequestParticipantEvent {
  Position location;
  SetCurrentLocation({ required this.location });
}
class SetViewState extends RequestParticipantEvent {
  ViewState viewState;
  SetViewState({ required this.viewState });
}

class RequestParticipantBloc extends Bloc<RequestParticipantEvent, RequestParticipantState> {

  Stream<ServiceRequest?>? currentRequest$;
  StreamSubscription? currReq$;

  final LocationBloc locationBloc;

  StreamSubscription? _firestoreMapWatch;

  RequestParticipantBloc(UserType userType, { required this.locationBloc }) : super(RequestParticipantState()) {
    DebugService.pr('CONSTRUCTOR RequestParticipantBloc', 'RequestParticipant(userType)');

    on<UserLogout>((event, emit) => _logout(event.context));

    // This event is about saving the request to state. No reaction necessary.
    on<SetCurrentRequest>((event, emit) {
      final newState = RequestParticipantState(
        viewState: state.viewState,
        userProceed: state.userProceed,
        currentRequest: event.request,
        logoutAction: state.logoutAction,
      );
      emit(newState);
    });

    // TODO: If nothing other than TerminateRequestWatch uses this, consider moving to provider_engaged NEW bloc.
    on<ClearCurrentRequest>((event, emit) {
      clearCurrentRequest(emit);
    });

    on<SetCurrentLocation>((event, emit) {
      final location = event.location!;
      var viewState = state.viewState;

      final isCurrentRequestIdSet = isRequestSet();

      if (isCurrentRequestIdSet) {
        UserService.updateCurrentLocationOnRequest(
          getCurrentRequestId()!,
          location.latitude,
          location.longitude,
          location.heading,
          userType,
          'request_participant.on<SetCurrentLocation>'
        );
      } else {
        viewState = ViewState.PROVIDER_NOT_CALLED;
        //! According to the screen's _bloc.currentLocationStream.listen((position), this is supposed to be _setWaitingForProviderStatus
        // viewState = ViewState.WAITING_FOR_PROVIDER;
      }

      final newState = RequestParticipantState(
        viewState: viewState,
        userProceed: state.userProceed,
        currentRequest: state.currentRequest,
        logoutAction: state.logoutAction,
      );
      emit(newState);
    });

    on<SetViewState>((event, emit) {
      final newState = RequestParticipantState(
        viewState: event.viewState,
        userProceed: state.userProceed,
        currentRequest: state.currentRequest,
        logoutAction: state.logoutAction,
      );
      emit(newState);
    });
  }

  /// Nullify current request stream and emit state with no current request.
  ///
  /// Optionally specify a [viewStateChange] when staying on the same screen (e.g. schedule_customer).
  clearCurrentRequest(Emitter<RequestParticipantState> emit, { ViewState? viewStateChange }) { // Emitter<RequestParticipantState> emit) {
    currentRequest$ = null;

    final newState = RequestParticipantState(
      // currentLocation: state.currentLocation,
      viewState: viewStateChange ?? state.viewState,
      userProceed: state.userProceed,
      currentRequest: null,
      logoutAction: state.logoutAction,
    );
    emit(newState);
  }

  getCurrentRequestId() {
    final noCurrentRequest = state.currentRequest == null;
    if (noCurrentRequest) {
      final error = 'No current request in state.';

      DebugService.pr(error, 'RequestParticipant.getCurrentRequestId');
      throw new Exception(error);
    }
    return state.currentRequest!.id;
  }

  ServiceRequest getCurrentRequestOrThrow() {
    final request = state.currentRequest;
    final isRequestNotSet = request == null;
    if (isRequestNotSet) {
      DebugService.pr('Current request is not set!', 'RequestParticipant.getCurrentRequestOrThrow');
      throw Exception('ouch');
    }
    return request!;
  }

  RequestParticipant getProviderFromRequestOrThrow() {
    final request = getCurrentRequestOrThrow();
    final provider = request.provider;
    final providerNotSet = provider == null;
    if (providerNotSet) {
      DebugService.pr('Current request provider is not set!', 'RequestParticipant.getProviderFromRequestOrThrow');
      throw Exception('ouch');
    }
    return provider!;
  }

  double getRequestOrigLat() => getCurrentRequestOrThrow().origin.latitude;
  double getRequestOrigLon() => getCurrentRequestOrThrow().origin.longitude;
  double getRequestDestLat() => getCurrentRequestOrThrow().destination.latitude;
  double getRequestDestLon() => getCurrentRequestOrThrow().destination.longitude;

  double getCustomerLatFromRequest() => getCurrentRequestOrThrow().customer.latitude;
  double getCustomerLonFromRequest() => getCurrentRequestOrThrow().customer.longitude;
  double getCustomerHeadingFromRequest() => getCurrentRequestOrThrow().customer.heading;
  double getProviderLatFromRequest() => getProviderFromRequestOrThrow().latitude;
  double getProviderLonFromRequest() => getProviderFromRequestOrThrow().longitude;
  double getProviderHeadingFromRequest() => getProviderFromRequestOrThrow().heading;

  ViewState getViewStateFromRequestStatus() {
    final currentRequest = getCurrentRequestOrThrow();

    switch (currentRequest.status) {
      case RequestStatusType.WAITING_FOR_PROVIDER:
        return ViewState.WAITING_FOR_PROVIDER;
      case RequestStatusType.PROVIDER_COMMITTED:
        return ViewState.PROVIDER_COMMITTED;
      case RequestStatusType.PROVIDER_TOWING:
        return ViewState.PROVIDER_TOWING;
      case RequestStatusType.JOB_FINISHED:
        return ViewState.JOB_FINISHED;
      default:
        final message = 'No mapping exists between current request status and view state.';
        DebugService.pr(message, 'RequestParticipant.getViewStateFromRequestStatus');
        throw Exception(message);
    }
  }

  ViewState getViewStateWithPotentiallyNoCurrentRequest() {
    final request = state.currentRequest;
    final requestNotSet = request == null;
    if (requestNotSet) {
      return ViewState.PROVIDER_NOT_CALLED;
    }
    return getViewStateFromRequestStatus();
  }

  // TODO: Get rid of this dependence on the bloc.
  isCurrentLocationSet() {
    return locationBloc.state.currentLocation != null;
  }

  // TODO: Get rid of this dependence on the bloc.
  isRequestSetRaw() {
    return state.currentRequest != null;
  }

  isRequestSet() {
    final noCurentRequest = !isRequestSetRaw();
    if (noCurentRequest) {
      return false;
    }

    String? currentRequestId = state.currentRequest!.id;
    return currentRequestId.isNotEmpty;
  }

  _logout(BuildContext context) {
    UserService.logout(context);
  }
}
