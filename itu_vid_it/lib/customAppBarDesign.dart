import 'package:flutter/material.dart';
import 'colors.dart';

class CustomAppBarDesign extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    appBarPrimary,
                    appBarSecondary
                  ]
              )
          ),
        );
  }
}