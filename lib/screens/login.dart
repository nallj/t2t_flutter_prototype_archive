import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:t2t_flutter_prototype/constants/user_type.dart';
import 'package:t2t_flutter_prototype/repositories/user_repository.dart';
import 'package:t2t_flutter_prototype/screens/provider_select.dart';
import 'package:t2t_flutter_prototype/screens/registration.dart';
import 'package:t2t_flutter_prototype/screens/schedule_customer.dart';
import 'package:t2t_flutter_prototype/services/user_service.dart';
import 'package:t2t_flutter_prototype/src/logic/location.dart';

final textBoxBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(8));

const logoPath = 'assets/images/lol.jpeg';

const tFillBothInputs = 'Please fill out both inputs to sign in.';
const tInvalidEmail = 'Invalid email provided.';
const tPasswordTooShort = 'The password is too short. It must be 3 or more letters.';
const tLoginFailed = 'Logging in failed.';
const tEmailHint = 'Email address';
const tPasswordHint = 'Password';
const tSignIn = 'Sign in';
const tOrRegisterNow = 'Or Register Now';

const inputBoxBackgroundColors = Colors.white;
// const buttonTextColor = Colors.white;

class Login extends StatefulWidget {
  static const route = '/';

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final _emailField = TextEditingController();
  final _passwordField = TextEditingController();
  var _errorMessage = '';
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _checkForAuthedUser();
  }

  _checkForAuthedUser() async {
    final isUserAuthed = await UserService.isAuthedUser();
    if (isUserAuthed) {
      final currentUser = await UserService.getCurrentUser();

      final userId = currentUser.uid;
      _redirectAuthedUser(userId);
    }
  }

  _onSignOnPress() {
    final email = _emailField.text;
    final password = _passwordField.text;

    // TODO: Move this validation logic to a common place so it can be used in registration.dart.
    final noEmailProvided = email.isEmpty;
    final noPasswordProvided = password.isEmpty;
    final missingUserInfo = noEmailProvided || noPasswordProvided;
    if (missingUserInfo) {
      _setError(tFillBothInputs);
      return;
    }

    final emailNotValid = !email.contains('@') || !email.contains('.');
    if (emailNotValid) {
      _setError(tInvalidEmail);
      return;
    }

    final passwordTooShort = password.length < 3;
    if (passwordTooShort) {
      _setError(tPasswordTooShort);
      return;
    }

    _setError('');
    _loginUser(email, password);
  }

  _setError(String? error) {

    setState(() {
      _errorMessage = error == null ? '' : error;
    });
  }

  _setLoading(bool loading) {
   setState(() {
     _loading = loading;
   });
  }

  _loginUser(String email, String password) {
    _setLoading(true);

    FirebaseAuth
      .instance
      .signInWithEmailAndPassword(email: email, password: password)
      .then((authedUser) {
        // TODO: Handle situation where user is null.
        final userId = authedUser.user!.uid;
        _redirectAuthedUser(userId);
      })
      .catchError((error) {
        // TODO: handle these types of errors
        // com.google.firebase.auth.FirebaseAuthInvalidUserException: There is no user record corresponding to this identifier. The user may have been deleted.
        // com.google.firebase.auth.FirebaseAuthInvalidCredentialsException: The password is invalid or the user does not have a password.
        _setError(tLoginFailed);
        _setLoading(false);
      });
  }

  _redirectAuthedUser(String userId) async {
    _setLoading(true);

    final user = await UserRepository.getUserOrThrow(userId, 'No user data found for this user ID.');

    final locationBloc = context.read<LocationBloc>();
    //! Potential DATA RACE problem - upon restarting the app already logged in, it's possible for the user to not have the first location before reaching ScheduleCustomer._setProviderNotCalledStatus. To fix, probably just put following code behind a locationBloc.state.currentLocation.first type statement.
    locationBloc.add(BeginListening());
    //! Does this work?
    await locationBloc.stream.first;

    print('>>>> Retrieved user data:');
    print(user.toString());

    print('>>>> Redirecting...');
    switch (user.type) {
      case UserType.Customer:
        print('>>>> Going to customer view!');
        Navigator.pushReplacementNamed(context, ScheduleCustomer.route);
        break;
      case UserType.Provider:
        // print('>>>> Going to provider select view!');
        // Navigator.pushReplacementNamed(context, ProviderSelect.route);

        // Sending to provider engaged because I want to test 'recover active request' functionality.
        print('>>>> Going to provider engaged view!');
        Navigator.pushReplacementNamed(context, ProviderSelect.route);
        break;
      default:
        final unknownUserType = user.type.toString();
        throw Exception("Unknown user type retrieved from user record: $unknownUserType");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xBFFF00), // 0xEEEEEE),
        ),
        padding: EdgeInsets.all(20),
        child: Center(
          // ref: https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html
          // This widget is useful when you have a single box that will normally be entirely visible, for example a clock face in a time picker, but you need to make sure it can be scrolled if the container gets too small in one axis (the scroll direction).
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Logo
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Image.asset(
                    logoPath,
                    height: 83,
                    width: 83,
                  ),
                ),

                // Email field
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    autofocus: true,
                    controller: _emailField,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      border: textBoxBorder,
                      contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      filled: true,
                      // fillColor: inputBoxBackgroundColors,
                      hintText: tEmailHint,
                    ),
                  )
                ),

                // Password field
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _passwordField,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    style: TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      border: textBoxBorder,
                      contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      filled: true,
                      // fillColor: inputBoxBackgroundColors,
                      hintText: tPasswordHint,
                    ),
                  )
                ),

                // Submit
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: ElevatedButton(
                    onPressed: _onSignOnPress, // onPressed: () { _onSignOnPress(); }
                    child: Text(
                      tSignIn,
                      // style: TextStyle(
                      //   color: buttonTextColor,
                      // ),
                    )
                  ),
                ),

                // Registration link
                Center(
                  child: GestureDetector(
                    child: Text(
                      tOrRegisterNow,
                      style: TextStyle(color: Colors.blueAccent)
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, Registration.route);
                    },
                  ),
                ),

                // Loading
                _loading
                  ? Center(
                      child: CircularProgressIndicator(backgroundColor: Colors.greenAccent)
                    )
                  : Center(),

                // Error messages
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
