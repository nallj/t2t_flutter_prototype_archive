part of 'provider_select.dart';

abstract class ProviderSelectState {}

class SearchingWithNoneFound extends ProviderSelectState {}
class ErrorOccurred extends ProviderSelectState {}

class SearchingWithRequestsFound extends ProviderSelectState {
  List<QueryDocumentSnapshot<Object?>> availableRequests = [];

  SearchingWithRequestsFound(List<QueryDocumentSnapshot<Object?>> newRequests){
    availableRequests = availableRequests + newRequests;
  }
}

class ActiveRequestFound extends ProviderSelectState {
  final activeReq;
  ActiveRequestFound(this.activeReq);
}
