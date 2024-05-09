part of 'request_participant.dart';

class RequestParticipantState {
  // Position? currentLocation;
  ViewState? viewState;
  UserProceedAction? userProceed;
  ServiceRequest? currentRequest;
  BuildContext? logoutAction;
  ConsumerDriverInfo? driverInfo;

  RequestParticipantState({
    // this.currentLocation,
    this.viewState,
    this.userProceed,
    this.currentRequest,
    this.logoutAction,
    this.driverInfo
  });
}
