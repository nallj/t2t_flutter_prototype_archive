import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:t2t_flutter_prototype/screens/login.dart';
import 'package:t2t_flutter_prototype/src/logic/provider_engaged.dart';
import 'package:t2t_flutter_prototype/src/logic/location.dart';
import 'package:t2t_flutter_prototype/src/logic/provider_select.dart';
import 'package:t2t_flutter_prototype/src/logic/schedule_customer.dart';

import 'routes.dart';

final theme = ThemeData(
  // This is the theme of your application.
  //
  // Try running your application with "flutter run". You'll see the
  // application has a blue toolbar. Then, without quitting the app, try
  // changing the primarySwatch below to Colors.green and then invoke
  // "hot reload" (press "r" in the console where you ran "flutter run",
  // or simply save your changes to "hot reload" in a Flutter IDE).
  // Notice that the counter didn't reset back to zero; the application
  // is not restarted.
  primarySwatch: Colors.blue,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(TheApp());
}

class TheApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'Tow-2-Tow',
      theme: theme,
      home: Login(),
      initialRoute: Login.route,
      onGenerateRoute: Routes.generateRoute,
      // debugShowCheckedModeBanner: false,
    );
    final wrappedApp = MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LocationBloc()),
        BlocProvider(create: (_) => ProviderSelectBloc()),
        BlocProvider(create: (providerEngagedBlocContext) {
          final locationBloc = providerEngagedBlocContext.read<LocationBloc>();
          return ProviderEngagedBloc(locationBloc: locationBloc);
        }),
        BlocProvider(create: (scheduleCustomerBlocContext) {
          final locationBloc = scheduleCustomerBlocContext.read<LocationBloc>();
          return ScheduleCustomerBloc(locationBloc: locationBloc);
        })
      ],
      child: app,
    );
    return wrappedApp;
  }
}

// References
// https://medium.com/flutter-community/flutter-scalable-folder-files-structure-8f860faafebd
