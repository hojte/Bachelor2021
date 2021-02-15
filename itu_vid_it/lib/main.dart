
import 'package:flutter/material.dart';
import 'package:ituvidit/customAppBarDesign.dart';
import 'package:ituvidit/customDrawer.dart';

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
        drawer: CustomDrawer(),
        body: Center(
          child:
          //todo --> Replace the text widget to test!
          Text("Hello world!"),
        ),
      ),
    );
  }


}

