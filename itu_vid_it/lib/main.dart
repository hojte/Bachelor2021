
import 'package:flutter/material.dart';
import 'package:ituvidit/customAppBarDesign.dart';
import 'package:ituvidit/customDrawer.dart';

import 'colors.dart';

void main() => runApp(HomeScreen());


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VidIT',
      home: Scaffold(
        appBar: AppBar(
            title: Text("VidIt"),
          flexibleSpace: CustomAppBarDesign(),
        ),
        endDrawer: CustomDrawer(),
        body: Container(
          color: appHomeBackground,
          child:
            Center(
          child:
          //todo --> Replace the text widget to test!
          Text("Hello world!"),
        ),
        ),
      ),
    );
  }


}

