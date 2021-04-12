import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Grids extends HookWidget
{
  final screen;
  final setGridOffsets;
  Grids(this.screen, this.setGridOffsets(maxX, minX, minY, maxY));


  @override
  Widget build(BuildContext context) {
    final displaceGrid = useState(Offset.zero);
    final startOfPinchOffset = useState(Offset.zero);
    final displaceOnStartPinch = useState(Offset.zero);

    double bottomBase = (screen.height/100)*70 - displaceGrid.value.dy;
    double topBase = (screen.height/100)*50 - displaceGrid.value.dy;
    double leftBase = (screen.width/100)*40 - displaceGrid.value.dx;
    double rightBase = (screen.width/100)*60 - displaceGrid.value.dx;

    double maxX = rightBase / (screen.width/100);
    double minX = leftBase / (screen.width/100);
    double minY = topBase / (screen.height/100);
    double maxY = bottomBase / (screen.height/100);

    setGridOffsets(maxX/100, minX/100, minY/100, maxY/100);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (details) {
        if (details.pointerCount > 1) {
          startOfPinchOffset.value = details.focalPoint;
          displaceOnStartPinch.value = displaceGrid.value; // todo
        }
      },
      onScaleUpdate: (details) {
        if (details.pointerCount > 1) {
          displaceGrid.value = startOfPinchOffset.value - details.focalPoint;
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