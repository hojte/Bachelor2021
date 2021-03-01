import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'homeHook.dart';
import 'trackingData.dart';

List<CameraDescription> cameras;

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VidIT',
      home: HomeHooks(cameras),

      //todo -> slet dette er brugt til test
     /* home: Scaffold(
        body: Center(
          child:
          Text(TrackingData("freder").name.toString()),)
      ),

      */
    );

  }
}
