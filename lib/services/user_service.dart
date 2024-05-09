import 'package:firebase_auth/firebase_auth.dart' as FA;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:t2t_flutter_prototype/constants/user_type.dart';
import 'package:t2t_flutter_prototype/models/request_participant.dart';
import 'package:t2t_flutter_prototype/models/user.dart';
import 'package:t2t_flutter_prototype/repositories/request_repository.dart';
import 'package:t2t_flutter_prototype/repositories/user_repository.dart';
import 'package:t2t_flutter_prototype/screens/login.dart';
import 'package:t2t_flutter_prototype/services/debug_service.dart';
import 'package:t2t_flutter_prototype/src/logic/location.dart';

class UserService {
  static Future<FA.User> getCurrentUser() async {
    final currentUser = FA.FirebaseAuth
      .instance
      .currentUser;

    final noCurrentUser = currentUser == null;
    if (noCurrentUser) {
      throw Exception('No current authenticated user.');
    }
    return currentUser!;
  }

  static Future<User> getUserDataLogin() async {
    final currentUser = await getCurrentUser();
    final userId = currentUser.uid;

    final user = await UserRepository.getUserOrThrow(userId, 'No data found for the current user.');

    final recordIdDoesntMatch = user.id != userId;
    if (recordIdDoesntMatch) {
      throw Exception('Fetched user record with mismatched userId.');
    }
    return user;
  }

  static isAuthedUser() async {
    final currentUser = FA.FirebaseAuth
      .instance
      .currentUser;
    return currentUser != null;
  }

  static logout(BuildContext context) async {
    await FA.FirebaseAuth
      .instance
      .signOut();
    context.read<LocationBloc>().add(StopListening());
    await Navigator.pushReplacementNamed(context, Login.route);
  }

  static updateCurrentLocationOnRequest(
    String requestId,
    double latitude,
    double longitude,
    double heading,
    UserType userType,
    String source
  ) async {

    // TODO: This method gets called after logout somewhere. Use this log to determine source from beyond async gap.
    DebugService.pr("Called by $source", 'updateCurrentLocalstionOnRequest');

    final user = await getUserDataLogin();
    final participant = RequestParticipant.fromUser(user);

    participant.updateLocation(latitude, longitude, heading);

    final participantData = participant.toFirestoreMap(includeLocation: true);
    final isCustomer = userType == UserType.Customer;
    final updateData = isCustomer
        ? { 'customer': participantData }
        : { 'provider': participantData };

    // TODO: FirebaseException ([cloud_firestore/not-found] Some requested document was not found.)
    await RequestRepository.update(
      requestId,
      updateData
    );
  }


  static UserType getUserTypeFromDbString(String dbString) {
    final isCustomer = dbString == UserTypes.CUSTOMER;
    return isCustomer ? UserType.Customer : UserType.Provider;
  }

  static String getDbStringFromUserType(UserType userType) {
    return userType == UserType.Customer ? UserTypes.CUSTOMER : UserTypes.PROVIDER;
  }
}
