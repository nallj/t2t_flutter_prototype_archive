import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';

import 'package:t2t_flutter_prototype/constants/request_status.dart';
import 'package:t2t_flutter_prototype/constants/user_type.dart';
import 'package:t2t_flutter_prototype/constants/view_state.dart';
import 'package:t2t_flutter_prototype/models/service_request.dart';
import 'package:t2t_flutter_prototype/repositories/request_repository.dart';
import 'package:t2t_flutter_prototype/services/user_service.dart';
import 'package:t2t_flutter_prototype/src/logic/location.dart';
import 'package:t2t_flutter_prototype/src/logic/request_participant.dart';

class WatchNewRequest extends RequestParticipantEvent {
  String? requestId;
  WatchNewRequest({ @required this.requestId });
}

// TODO: Proper BLoC pattern makes use of subjects for communication both ways.
class ProviderEngagedBloc extends RequestParticipantBloc {

  //! This never was the customer's location apparently. _setProviderLocation sets this...
  // Position? customerLocation;

  ProviderEngagedBloc({ required LocationBloc locationBloc })
    : super(UserType.Provider, locationBloc: locationBloc) {

    on<WatchNewRequest>((event, emit) {
      final requestId = event.requestId!;

      RequestRepository
        .getOrThrow(requestId)
        .then((req) {
          _handleRequestUpdate(req);
        });

      currentRequest$ = RequestRepository
        .getStream(requestId);

      currentRequest$!.listen((req) {
        _handleRequestUpdate(req);
      });

      this.locationBloc.stream.listen((locationState) {
        final location = locationState.currentLocation ?? locationState.lastKnownLocation;
        _handleLocationUpdateForRequest(requestId)(location);
      });
    });

    //! See ClearCurrentRequest in request_participant bloc
    // on<TerminateRequestWatch>((event, emit) {
  }

  _handleLocationUpdateForRequest(String requestId) => (Position location) {
    var viewState = state.viewState;
    //! Not necessary - keep state in bloc
    // _setProviderLocation(position);

    final isRequestSet = this.isRequestSet();
    // _isRequestSet ensures _currentRequest is not null.
    final isCommited = isRequestSet && RequestStatus.isCommitedStatus(state.currentRequest!.status);

    if (isRequestSet && isCommited) {
      // POTENTIAL DYING POINT
      // This will _always_ trigger a request update.
      UserService.updateCurrentLocationOnRequest(
        requestId,
        location.latitude,
        location.longitude,
        location.heading,
        UserType.Provider,
        'provider_engaged._handleLocationUpdateForRequest'
      );
    } else {
      // Should this be in the else or just at the end of the handler?
      // _setWaitingForProviderStatus();

      viewState = ViewState.WAITING_FOR_PROVIDER; // ??? is this right?
    }

    final newState = RequestParticipantState(
      // currentLocation: location,
      viewState: viewState,
      userProceed: state.userProceed,
      currentRequest: state.currentRequest,
      logoutAction: state.logoutAction,
    );
    emit(newState);
  };

  _handleRequestUpdate(ServiceRequest? requestUpdate) {
    // TODO: seems to retrigger upon opening phone after close/returning to app.

    final hasData = requestUpdate != null;
    if (hasData) {
      //_setAndPublishCurrentRequest(data!);

      final newState = RequestParticipantState(
        // currentLocation: state.currentLocation,
        viewState: state.viewState,
        userProceed: state.userProceed,
        currentRequest: requestUpdate,
        logoutAction: state.logoutAction,
      );
      //! This function is not being called in an .on function so this shouldn't work.
      emit(newState);

    } else {
      // TODO: Awaiting a real life example of this. Then handle it. Perhaps with a generic
      // This definitely happens if the request record is manually deleted.
      // "something went wrong with the current request" message
      throw Exception('Now how did you get here?');
      // This happens if the record gets deleted.
      // Can happen when an active request is recovered but the target record is not present (ID mismatch)
    }
  }
}
