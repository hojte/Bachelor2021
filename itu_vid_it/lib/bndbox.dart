import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'colors.dart';

class BndBox extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;
  final Function setTracked;

  BndBox(
      this.results,
      this.setTracked(dynamic recognition),
      this.previewH,
      this.previewW,
      this.screenH,
      this.screenW,
      );

  @override
  Widget build(BuildContext context) {
    List<Widget> _renderBox() {
      return results.map((recognition) {
        var _x = recognition["rect"]["x"];
        var _w = recognition["rect"]["w"];
        var _y = recognition["rect"]["y"];
        var _h = recognition["rect"]["h"];
        bool _track = recognition["track"] ?? false;
        bool _trackShift = recognition["trackShift"] ?? false;
        bool _flickerSmoother = recognition['flickerSmoother'] ?? false;
        var scaleW, scaleH, x, y, w, h;

        Color boxColor = Colors.grey;
        if (_trackShift) boxColor = Colors.red;
        if (_track) boxColor = appBarPrimary;
        if (_flickerSmoother) boxColor = Colors.blue[900];

        if (screenH / screenW > previewH / previewW) {
          scaleW = screenH / previewH * previewW;
          scaleH = screenH;
          var difW = (scaleW - screenW) / scaleW;
          x = (_x - difW / 2) * scaleW;
          w = _w * scaleW;
          if (_x < difW / 2) w -= (difW / 2 - _x) * scaleW;
          y = _y * scaleH;
          h = _h * scaleH;
        } else {
          scaleH = screenW / previewW * previewH;
          scaleW = screenW;
          var difH = (scaleH - screenH) / scaleH;
          x = _x * scaleW;
          w = _w * scaleW;
          y = (_y - difH / 2) * scaleH;
          h = _h * scaleH;
          if (_y < difH / 2) h -= (difH / 2 - _y) * scaleH;
        }

        return Positioned(
            left: math.max(0, x),
            top: math.max(0, y),
            width: w,
            height: h,
            child: InkWell(
              onDoubleTap: () {
                setTracked(recognition);
              },
              child: Container(
                padding: EdgeInsets.only(top: 5.0, left: 5.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: boxColor,
                    width: 3.0,
                  ),
                ),
                child: Text(
                  "${recognition["detectedClass"]} ${(recognition["confidenceInClass"] * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: boxColor,
                    fontSize: 14.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            )
        );
      }).toList();
    }

    return Stack(
      children: _renderBox(),
    );
  }
}