import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as FA;
import 'package:flutter/material.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/constants/user_type.dart';
import 'package:t2t_flutter_prototype/models/user.dart';
import 'package:t2t_flutter_prototype/repositories/user_repository.dart';
import 'package:t2t_flutter_prototype/screens/provider_select.dart';
import 'package:t2t_flutter_prototype/screens/schedule_customer.dart';

const tRegistration = 'Registration';
const tRegister = 'Register';
const tFullName = 'Full name';
const tEmail = 'Email';
const tPassword = 'Password';
const tCustomer = 'Customer';
const tProvider = 'Provider';
const tFillAllInputs = 'Fill all inputs to register.';
const tInvalidEmail = 'Invalid email provided.';
const tInvalidPassword = 'Invalid password provided (must be 6 or more characters).';
const tErrorDuringRegistration = 'An unexpected error occured during registration.';

final textInputSyle = TextStyle(fontSize: 24, color: Colors.blueGrey);
final textInputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(6));

class Registration extends StatefulWidget {
  static const route = '/register';

  @override
  RegistrationState createState() => RegistrationState();
}

class RegistrationState extends State<Registration> {
  final _nameField = TextEditingController();
  final _emailField = TextEditingController();
  final _passwordField = TextEditingController();
  var _errorMessage = '';
  var _loading = false;
  var _userType = UserType.Customer;

  _createUser(String name, String email, String password, UserType userType) async {
    _setLoading(true);

    final auth = FA.FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;

    auth
      .createUserWithEmailAndPassword(email: email, password: password)
      .then((savedUser) {
        // TODO: Handle situation where user is null.
        final userId = savedUser.user!.uid;
        // user.userId = userId;

        final handleSuccessfulUserDocSave = (_) {
          print('>>>> Redirecting...');
          final returnFalseFn = (_) => false;
          switch (userType) {
            case UserType.Customer:
              print('>>>> Going to customer view!');
              Navigator.pushNamedAndRemoveUntil(context, ScheduleCustomer.route, returnFalseFn);
              break;
            case UserType.Provider:
              print('>>>> Going to provider view!');
              Navigator.pushNamedAndRemoveUntil(context, ProviderSelect.route, returnFalseFn);
              break;
          }
        };

        final user = User(userId, email, name, userType);
        UserRepository
          .upsert(user)
          .then(handleSuccessfulUserDocSave);
          // TODO: Handle errors separatey here (since auth was successful).
      })
      .catchError((err, stack) {
        _setError(tErrorDuringRegistration);
        _setLoading(false);

        print('>>>> OMG ERROR HAPPENED');
        print(err);
        print('>>>> AND ITS HAPPENING AGAINST');
        print(stack);

        // TODO: Handle these types of errors (parse from err):
        // [firebase_auth/invalid-email] The email address is badly formatted
        // [firebase_auth/email-already-in-use] The email address is already in use by another account.
        // [firebase_auth/weak-password] Password should be at least 6 characters
      });
  }

  // TODO: Move the validation logic out of login.dart and into to a common place.
  _handleRegisterPress() async {
    final name = _nameField.text;
    final email = _emailField.text.trim();
    final password = _passwordField.text;

    final noNameProvided = name.isEmpty;
    final noEmailProvided = email.isEmpty;
    final noPasswordProvided = password.isEmpty;
    final missingUserInfo = noNameProvided || noEmailProvided || noPasswordProvided;
    if (missingUserInfo) {
      _setError(tFillAllInputs);
      return;
    }

    final emailNotValid = !email.contains('@') || !email.contains('.');
    if (emailNotValid) {
      _setError(tInvalidEmail);
      return;
    }

    final passwordTooShort = password.length < 6;
    if (passwordTooShort) {
      _setError(tInvalidPassword);
      return;
    }

    await _createUser(name, email, password, _userType);
  }

  _setError(String error) {
    setState(() {
      _errorMessage = error;
    });
  }

  _setLoading(bool loading) {
   setState(() {
     _loading = loading;
   });
  }

  _setUserType(UserType userType) {
    setState(() {
      _userType = userType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tRegistration),
      ),
      body: Container(
        padding: EdgeInsets.all(32),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Name field
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    autofocus: true,
                    controller: _nameField,
                    keyboardType: TextInputType.text,
                    style: textInputSyle,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(16, 8, 8, 32),
                      hintText: tFullName,
                      filled: true,
                      // fillColor: Colors.grey,
                      border: textInputBorder,
                    ),
                  ),
                ),

                // Email field
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _emailField,
                    keyboardType: TextInputType.text,
                    style: textInputSyle,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(16, 8, 8, 32),
                      hintText: tEmail,
                      filled: true,
                      // fillColor: Colors.grey,
                      border: textInputBorder,
                    ),
                  ),
                ),

                // Password field
                Padding(
                  padding: EdgeInsets.only(bottom: 0),
                  child: TextField(
                    controller: _passwordField,
                    keyboardType: TextInputType.text,
                    style: textInputSyle,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(16, 8, 8, 32),
                      hintText: tPassword,
                      filled: true,
                      // fillColor: Colors.grey,
                      border: textInputBorder,
                    ),
                  ),
                ),

                // User type
                Padding(
                  padding: EdgeInsets.only(bottom: 0),
                  child: Row(
                    children: [
                      Text(tCustomer),
                      Switch(
                        value: _userType == UserType.Provider,
                        onChanged: (value) {
                          _setUserType(value ? UserType.Provider : UserType.Customer);
                        },
                      ),
                      Text(tProvider),
                    ],
                  ),
                ),

                // Register button
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: ElevatedButton(
                    onPressed: _handleRegisterPress, // onPressed: () { _handleRegisterPress(); }
                    child: Text(
                      tRegister,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    )
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
