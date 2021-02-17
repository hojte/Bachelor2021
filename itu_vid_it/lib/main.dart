
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/customAppBarDesign.dart';
import 'package:ituvidit/customDrawer.dart';

import 'colors.dart';

void main() => runApp(HomeScreen());


class HomeScreen extends HookWidget {
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
}

