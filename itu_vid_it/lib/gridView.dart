import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

List<Widget> Grids(Size screen)
{
  return [
    Positioned(
        top: (screen.height/100)*65,
        child: Container(color: Colors.green,width: screen.width,height: 2.0,)
    ),
    Positioned(
        top: (screen.height/100)*55,
        child: Container(color: Colors.green,width: screen.width,height: 2.0,)
    ),
    Positioned(
        left: (screen.width/100)*45,
        child: Container(color: Colors.green,width: 2.0,height: screen.height,)
    ),
    Positioned(
        left: (screen.width/100)*55,
        child: Container(color: Colors.green,width: 2.0,height: screen.height,)
    )
  ];


}