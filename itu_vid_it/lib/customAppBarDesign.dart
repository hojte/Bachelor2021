import 'package:flutter/material.dart';

class CustomAppBarDesign extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xdce35b),
                    Color(0x45b649)
                  ]
              )
          ),
        );
  }
}