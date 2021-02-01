import 'package:flutter/material.dart';

// import firebase
import 'package:firebase_core/firebase_core.dart';

// import services
import 'services/auth.dart';

// import views
import 'views/signin.dart';
import 'views/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context ) {
     var materialApp = MaterialApp(
       title: 'Flutter Demo',
       debugShowCheckedModeBanner: false,
       theme: ThemeData(
         primarySwatch: Colors.blue,
       ),
       home: FutureBuilder(
         future: AuthMethods().getCurrentUser(),
         builder: (context, AsyncSnapshot<dynamic> snapshot) {
           if (snapshot.hasData) {
             return Home();
           }
           else {
             return SignIn();
           }
         }),
      );
     return materialApp;
  }
}