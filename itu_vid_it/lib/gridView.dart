import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Grids extends HookWidget
{
  final screen;
  Grids(this.screen);


  @override
  Widget build(BuildContext context) {
    final displaceGrid = useState(Offset.zero);
    final scaleGrid = useState(1.0);
    final startOfPinch = useState(Offset.zero);
    //final initialScale = useState(0.0);

    double bottomBase = (screen.height/100)*65;
    double topBase = (screen.height/100)*55;
    double leftBase = (screen.width/100)*45;
    double rightBase = (screen.width/100)*55;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (details) {
        if (details.pointerCount > 1) {
          startOfPinch.value = details.focalPoint;
          //initialScale.value = scaleGrid.value;
        }
      },
      onScaleUpdate: (details) {
        if (details.pointerCount > 1) {
          displaceGrid.value = startOfPinch.value - details.focalPoint;
          if (topBase * details.scale - displaceGrid.value.dy > bottomBase / details.scale - displaceGrid.value.dy)
            return;
          if (leftBase * details.scale - displaceGrid.value.dx > rightBase / details.scale - displaceGrid.value.dx)
            return;
          scaleGrid.value = /*initialScale.value * */details.scale;
          print('scaleUpdate ${scaleGrid.value}');
        }
      },
      child: Stack(
        children: [
          Positioned( // Bottom threshold line
              top: bottomBase / scaleGrid.value - displaceGrid.value.dy,
              child: Container(color: Colors.green,width: screen.width,height: 2.0,)
          ),
          Positioned( // Top threshold line
              top: topBase * scaleGrid.value - displaceGrid.value.dy,
              child: Container(color: Colors.green,width: screen.width,height: 2.0,)
          ),
          Positioned( // Left threshold line
              left: leftBase * scaleGrid.value - displaceGrid.value.dx,
              child: Container(color: Colors.green,width: 2.0,height: screen.height,)
          ),
          Positioned( // Right threshold line
              left: rightBase / scaleGrid.value - displaceGrid.value.dx,
              child: Container(color: Colors.green,width: 2.0,height: screen.height,)
          )
        ],
      ),
    );
  }


}