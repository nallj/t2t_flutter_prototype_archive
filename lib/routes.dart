import 'package:flutter/material.dart';

import 'package:t2t_flutter_prototype/screens/login.dart';
import 'package:t2t_flutter_prototype/screens/provider_engaged.dart';
import 'package:t2t_flutter_prototype/screens/provider_select.dart';
import 'package:t2t_flutter_prototype/screens/registration.dart';
import 'package:t2t_flutter_prototype/screens/schedule_customer.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name;
    switch (routeName) {
      case Login.route:
        return MaterialPageRoute(builder: (_) => Login());
      case Registration.route:
        return MaterialPageRoute(builder: (_) => Registration());
      case ScheduleCustomer.route:
        return MaterialPageRoute(builder: (_) => ScheduleCustomer());
      case ProviderSelect.route:
        return MaterialPageRoute(builder: (_) => ProviderSelect());
      case ProviderEngaged.route:
        final routeArgs = settings.arguments! as ProviderEngagedArgs;
        final page = ProviderEngaged(routeArgs);
        return MaterialPageRoute(builder: (_) => page);
      default:
        return _getMissingRoute();
    }
  }

  static Route<dynamic> _getMissingRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text("This route doesn't exist."),
        ),
        body: Center(
          child: Text("This route doesn't exist."),
        ),
      );
    });
  }
}
