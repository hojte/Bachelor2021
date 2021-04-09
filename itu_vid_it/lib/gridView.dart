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

    final minX = useState(40.0);
    final maxX = useState(60.0);
    final minY = useState(50.0);
    final maxY = useState(80.0);

    double leftBase = (screen.width/100)*minX.value;
    double rightBase = (screen.width/100)*maxX.value;
    double topBase = (screen.height/100)*minY.value;
    double bottomBase = (screen.height/100)*maxY.value;

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

          minX.value+= displaceGrid.value.dx/100;
          maxX.value-= displaceGrid.value.dx/100;
          minY.value+= displaceGrid.value.dy/100;
          maxY.value-= displaceGrid.value.dy/100;

        }
      },
      child: Stack(
        children: [
          Positioned( // Bottom threshold line
              top: bottomBase,
              child: Container(color: Colors.green,width: screen.width,height: 2.0,)
          ),
          Positioned( // Top threshold line
              top: topBase,
              child: Container(color: Colors.green,width: screen.width,height: 2.0,)
          ),
          Positioned( // Left threshold line
              left: leftBase,
              child: Container(color: Colors.green,width: 2.0,height: screen.height,)
          ),
          Positioned( // Right threshold line
              left: rightBase,
              child: Container(color: Colors.green,width: 2.0,height: screen.height,)
          )
        ],
      ),
    );
  }
}