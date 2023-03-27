import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  String userNumber = '';
  String? receivedID;
  bool otpFieldVisibility = false;
  bool _loginSuccess = false;
  bool _isLoading = false;

  void verifyUserPhoneNumber() {
    setState(() {   
      _isLoading = true;
    });
    auth.verifyPhoneNumber(
      phoneNumber: userNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential).then(
              (value)=>print('Logged In Successfully'),
            );
      },
      verificationFailed: (FirebaseAuthException e) {
        // showDialog(
        //   context: context,
        //   builder: (ctx) => AlertDialog(
        //     title: const Text("Login Failed"),
        //     content: const Text("Please Try Again."),
        //     actions: [
        //       TextButton(
        //         onPressed: () => Navigator.of(ctx).pop(),
        //         child: const Text("Ok"),
        //       ),
        //     ],
        //   ),
        // );
        print(e.message);
      },
      codeSent: (String verificationId, int? resendToken) {
        receivedID = verificationId;
        otpFieldVisibility = true;
        _isLoading = false;
        setState(() {});
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('TimeOut');
      },
    );
  }

  Future<void> verifyOTPCode() async {
    if (receivedID == null) return;
    setState(() {
      _isLoading = true;
    });
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: receivedID!,
      smsCode: otpController.text,
    );
    await auth
        .signInWithCredential(credential)
        .then((value)  {
                setState(() {
                  _loginSuccess = true;
                });
              });
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Phone Authentication',
          ),
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: IntlPhoneField(
                controller: phoneController,
                initialCountryCode: 'MY',
                decoration: const InputDecoration(
                  hintText: 'Phone Number',
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  userNumber = val.completeNumber;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Visibility(
                visible: otpFieldVisibility,
                child: TextField(
                  controller: otpController,
                  decoration: const InputDecoration(
                    hintText: 'OTP Code',
                    labelText: 'OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            _isLoading ? const CircularProgressIndicator() : _loginSuccess ? Text("Login Success: $receivedID"):
            ElevatedButton(
              onPressed: () {
                if (otpFieldVisibility) {
                  verifyOTPCode();
                } else {
                  verifyUserPhoneNumber();
                }
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: otpFieldVisibility ? const Text('Verify'):const Text('Get OTP'),
            )
          ],
        ),
      ),
    );
  }
}
