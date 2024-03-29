import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/mountController.dart';

import 'customAppBarDesign.dart';

class MountManualController extends HookWidget {
  final bleCharacteristic;
  MountManualController(this.bleCharacteristic);

  @override
  Widget build(BuildContext context) {
    var speedValue = useState(200.0);
    final mediaQuery = MediaQuery.of(context);


    Widget customSlider(var speedValue){
      return Container(
          width: 350,
          height: 50,
          child: Slider(
            min: 0.0,
            max: 750.0,
            divisions: 30,
            activeColor: Colors.white,
            inactiveColor: Colors.white,
            value: speedValue.value,
            label: speedValue.value.toString(),
            onChanged: (value){
              speedValue.value = value;
            },
          )
      );
    }

    Widget upArrow(BuildContext context){
      return IconButton(
        icon: Icon(Icons.north, color: Colors.white, size: 100),
        iconSize: 100,
        onPressed: () {
          var trackingData = TrackingData(1,0,0,0,0,speedValue.value);
          var compute = ComputeData(trackingData);
          MountController(trackingData, bleCharacteristic, null).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
        },
      );
    }

    Widget downArrow(BuildContext context){
      return IconButton(
        icon: Icon(Icons.south, color: Colors.white, size: 100),
        iconSize: 100,
        onPressed: () {
          var trackingData = TrackingData(1,0.05,1,1,0,speedValue.value);
          var compute = ComputeData(trackingData);
          MountController(trackingData, bleCharacteristic, null).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
        },
      );
    }
    Widget stop(BuildContext context){
      return IconButton(
        icon: Icon(Icons.stop_circle_outlined, color: Colors.white, size: 100),
        iconSize: 100,
        onPressed: () {
          var trackingData = TrackingData(1,0.05,1,0.05,1,1);
          var compute = ComputeData(trackingData);
          MountController(trackingData, bleCharacteristic, null).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
        },
      );
    }
    Widget leftArrow(BuildContext context){
      return IconButton(
        icon: Icon(Icons.west, color: Colors.white, size: 100),
        iconSize: 100,
        onPressed: () {
          var trackingData = TrackingData(0,0,1,0.05,speedValue.value,0);
          var compute = ComputeData(trackingData);
          MountController(trackingData, bleCharacteristic, null).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
        },
      );
    }
    Widget rightArrow(BuildContext context){
      return IconButton(
        icon: Icon(Icons.east, color: Colors.white, size: 100),
        iconSize: 100,
        onPressed: () {
          var trackingData = TrackingData(1,1,1,0.05,speedValue.value,0);
          var compute = ComputeData(trackingData);
          MountController(trackingData, bleCharacteristic, null).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
        },
      );
    }
    Widget upRightArrow(BuildContext context){
      return IconButton(
        icon: Icon(Icons.north_east, color: Colors.white, size: 100),
        iconSize: 100,
        onPressed: () {
          var trackingData = TrackingData(1,1,0,0,speedValue.value,speedValue.value);
          var compute = ComputeData(trackingData);
          MountController(trackingData, bleCharacteristic, null).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
        },
      );
    }
    Widget upLeftArrow(BuildContext context){
      return IconButton(
        icon: Icon(Icons.north_west, color: Colors.white, size: 100),
        iconSize: 100,
        onPressed: () {
          var trackingData = TrackingData(0,0,0,0,speedValue.value,speedValue.value);
          var compute = ComputeData(trackingData);
          MountController(trackingData, bleCharacteristic, null).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
        },
      );
    }
    Widget downRightArrow(BuildContext context){
      return IconButton(
        icon: Icon(Icons.south_east, color: Colors.white, size: 100),
        iconSize: 100,
        onPressed: () {
          var trackingData = TrackingData(1,1,1,1,speedValue.value,speedValue.value);
          var compute = ComputeData(trackingData);
          MountController(trackingData, bleCharacteristic, null).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
        },
      );
    }
    Widget downLeftArrow(BuildContext context){
      return IconButton(
        icon: Icon(Icons.south_west, color: Colors.white, size: 100),
        iconSize: 100,
        onPressed: () {
          var trackingData = TrackingData(0,0,1,1,speedValue.value,speedValue.value);
          var compute = ComputeData(trackingData);
          MountController(trackingData, bleCharacteristic, null).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
        },
      );
    }

    return Scaffold(
      backgroundColor: appBarPrimary,
      appBar: AppBar(
        title: Text("VidIt - Mount Remote Control"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            var trackingData = TrackingData(1,0.05,1,0.05,1,1);
            var compute = ComputeData(trackingData);
            MountController(trackingData, bleCharacteristic, null).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
            Navigator.pop(context);
          },
        ),
        flexibleSpace: CustomAppBarDesign(),
      ),
      body: mediaQuery.orientation == Orientation.landscape ?
      Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: upLeftArrow(context)),
                    Expanded(child: leftArrow(context)),
                    Expanded(child: downLeftArrow(context))
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: upArrow(context)),
                    Expanded(child: stop(context)),
                    Expanded(child: downArrow(context))
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: upRightArrow(context)),
                    Expanded(child: rightArrow(context)),
                    Expanded(child: downRightArrow(context))
                  ],
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(speedValue.value.toString(), style: TextStyle(fontSize: 40.0, fontWeight: FontWeight.w900, color: Colors.white)),
                customSlider(speedValue)
              ],
            ),
          ],
        ),
      ) :
      Container(
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    upLeftArrow(context),
                    leftArrow(context),
                    downLeftArrow(context)
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    upArrow(context),
                    stop(context),
                    downArrow(context),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    upRightArrow(context),
                    rightArrow(context),
                    downRightArrow(context),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                Text(speedValue.value.toString(), style: TextStyle(fontSize: 40.0, fontWeight: FontWeight.w900, color: Colors.white)),
                customSlider(speedValue)
              ],
            ),
          ],
        ),
      ),
    );
  }

}