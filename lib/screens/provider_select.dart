import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:t2t_flutter_prototype/constants/user_type.dart';
import 'package:t2t_flutter_prototype/screens/provider_engaged.dart';
import 'package:t2t_flutter_prototype/services/mock_service.dart';
import 'package:t2t_flutter_prototype/services/user_service.dart';
import 'package:t2t_flutter_prototype/src/logic/provider_select.dart';

const tOmgYourAProvider = "OMG You're a Provider!";
const tLogOut = 'Log Out';
const tRemoveLaterNewJob = 'Remove Later: New Job';
const tGiveFeedback = 'TODO: Give Feedback';
const tSettings = 'TODO: Settings';
const tLoadingServiceRequests = 'Loading Service Requests...';
const tErrorWhileLoading = 'An error occurred while loading requests. Please log out and back in again.';
const tNoRequests = 'There are no available requests. Stay tuned!';

class ProviderSelect extends StatefulWidget {
  static const route = '/providerSelect';

  @override
  _ProviderSelectState createState() => _ProviderSelectState();
}

class _ProviderSelectState extends State<ProviderSelect> {
  List<String> _menuItems = [
    tLogOut,
    tRemoveLaterNewJob,
    tGiveFeedback,
    tSettings
  ];

  @override
  void initState() {
    super.initState();
    final bloc = BlocProvider.of<ProviderSelectBloc>(context);
    bloc.add(ProviderSelectInit());

    // TODO: Should I send back users to login screen if not authed?
  }

  _logout() => UserService.logout(context);

  _performMenuAction(String itemId) {
    switch (itemId) {
      case tLogOut:
        _logout();
        break;
      case tRemoveLaterNewJob:
        MockService.fakeConsumerSaveJob();
        break;
      case tGiveFeedback:
        // TODO
        break;
      case tSettings:
        // TODO
        break;
    }
  }

  _advanceToProviderEngaged(BuildContext context, requestId) {
    final args = ProviderEngagedArgs(requestId);
    Navigator.pushNamed(context, ProviderEngaged.route, arguments: args);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProviderSelectBloc, ProviderSelectState>(
      listener: (blocContext, state) {
        if (state is ActiveRequestFound) {
          final activeReqNotProvided = state.activeReq == null;
          if (activeReqNotProvided) {
            throw new Exception('Active request not provided while attempting to recover.');
          }
          final requestId = state.activeReq!.requestId;
          _advanceToProviderEngaged(context, requestId);
        }
      },
      builder: (context, state) {
        final loading = Center(
          child: Column(
            children: [Text(tLoadingServiceRequests), CircularProgressIndicator()],
          ),
        );
        final error = Text(tErrorWhileLoading);
        final noAvailableRequests = Center(
          child: Column(
            children: [Text(tNoRequests), CircularProgressIndicator()],
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(tOmgYourAProvider),
            actions: [
              PopupMenuButton<String>(
                itemBuilder: (context) => _menuItems
                    .map((String item) => PopupMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onSelected: _performMenuAction,
              )
            ],
          ),
          body: (() {
            if (state is SearchingWithRequestsFound) {
              final requests = state.availableRequests;
              final hasNoRequests = requests.length == 0;
              if (hasNoRequests) {
                return noAvailableRequests;
              }
              return ListView.separated(
                separatorBuilder: (context, index) => Divider(
                  height: 3,
                  color: Colors.cyan,
                ),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final thisItem = requests[index];
                  final requestId = thisItem.id;
                  final name = thisItem[UserTypes.CUSTOMER]['name'];
                  final street = thisItem['destination']['street'];
                  final number = thisItem['destination']['number'];
                  return ListTile(
                      title: Text(name),
                      subtitle: Text("Destination: $number $street $index"),
                      onTap: () {
                        _advanceToProviderEngaged(context, requestId);
                      });
                },
              );
            } else if (state is ErrorOccurred) {
              return error;
            }
            return loading;
          }())
        );
      }
    );
  }
}
