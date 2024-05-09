import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:t2t_flutter_prototype/repositories/active_request_provider_repository.dart';
import 'package:t2t_flutter_prototype/repositories/request_repository.dart';
import 'package:t2t_flutter_prototype/services/user_service.dart';

part 'provider_select_state.dart';

class ProviderSelectInit{
  var requests;
}

class ProviderSelectBloc extends Bloc<ProviderSelectInit, ProviderSelectState> {
  // ignore: close_sinks
  StreamController<QuerySnapshot>? providerRequestsStream = StreamController<QuerySnapshot>();

  ProviderSelectBloc() : super(SearchingWithNoneFound()) {
    on<ProviderSelectInit>((event, emit) async {
      // Initialize the available requests as empty
      try {
        final userNotAuthed = !(await UserService.isAuthedUser());
        if (userNotAuthed) {
          throw('User not Authenticated.');
        }

        final currentUser = await UserService.getCurrentUser();
        final userId = currentUser.uid;
        final activeReq = await ActiveRequestProviderRepository.getByUserId(userId);
        if (activeReq == null) {
          // Start watching for available requests to pick up.
          RequestRepository
            .getWaitingForProviderRequests()
            .listen((data) => providerRequestsStream!.add(data));

          // Emit new state for any updates to requests.
          await emit.forEach(providerRequestsStream!.stream, onData: (QuerySnapshot<Object?> newRequest) {
            final requests = newRequest.docs;
            final hasNoRequestsAvailable = requests.length == 0;
            if (hasNoRequestsAvailable) {
              return SearchingWithNoneFound();
            }
            return SearchingWithRequestsFound(requests);
          }, onError: (error, stackTrace) {
            return ErrorOccurred();
          });
        } else {
          emit(ActiveRequestFound(activeReq));
        }
      } catch (e) {
        emit(ErrorOccurred());
      }
    });
  }

  @override
  Future<void> close() async {
    await _killStreams();
    await super.close();
  }

  _killStreams() async {
    await providerRequestsStream!.close();
    providerRequestsStream = null;
  }
}
