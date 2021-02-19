import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'home.dart';

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
      title: 'RealTime Detection',
      home: HomePage(cameras),
    );
  }
}








/*







import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/customAppBarDesign.dart';
import 'package:ituvidit/customDrawer.dart';

import 'colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'home.dart';

List<CameraDescription> cameras;

Future<Null> main() async {
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  runApp(new HomeScreen());
}

//void main() => runApp(HomeScreen());


class HomeScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RealTime Detection',
      home: HomePage(cameras),
    );
  }

  /*
  @override
  Widget build(BuildContext context) {
    //Values and setter used for debugmode in the drawer
    final debugModeValue = useState(true);
    void setDebugModeValue(bool val){
      debugModeValue.value = val;
    }

    return MaterialApp(
      title: 'VidIT',
      home: Scaffold(
        appBar: AppBar(
            title: Text("VidIt"),
          flexibleSpace: CustomAppBarDesign(),
        ),
        endDrawer: CustomDrawer(setDebugModeValue, debugModeValue.value),
        body: Container(
          color: appHomeBackground,
          child:
            Center(
          child:
          //todo --> Replace the text widget to test!
            Text(debugModeValue.value.toString()),
        ),
        ),
      ),
    );
  }
 */

}

*/