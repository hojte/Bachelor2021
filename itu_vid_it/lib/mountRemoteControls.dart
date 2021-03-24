import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/colors.dart';
import 'package:ituvidit/mountController.dart';

import 'customAppBarDesign.dart';

class MountRemoteControls extends HookWidget {
  final bleCharacteristic;
  MountRemoteControls(this.bleCharacteristic);

  Widget upArrow(BuildContext context){
    return IconButton(
        icon: Icon(Icons.north, color: Colors.white, size: 100),
        iconSize: 100,
        onPressed: () {
          var trackingData = TrackingData("1","0","0","0",5000);
          var compute = ComputeData(trackingData);
          compute.boundingBoxCenter;
          MountController(trackingData, bleCharacteristic).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
        },
    );
  }

  Widget downArrow(BuildContext context){
    return IconButton(
      icon: Icon(Icons.south, color: Colors.white, size: 100),
      iconSize: 100,
      onPressed: () {
        var trackingData = TrackingData("1","0.05","1","1",5000);
        var compute = ComputeData(trackingData);
        compute.boundingBoxCenter;
        MountController(trackingData, bleCharacteristic).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
      },
    );
  }
  Widget stop(BuildContext context){
    return IconButton(
      icon: Icon(Icons.motion_photos_pause_outlined, color: Colors.white, size: 100),
      iconSize: 100,
      onPressed: () {
        var trackingData = TrackingData("1","0.05","1","0.05",5000);
        var compute = ComputeData(trackingData);
        compute.boundingBoxCenter;
        MountController(trackingData, bleCharacteristic).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
      },
    );
  }
  Widget leftArrow(BuildContext context){
    return IconButton(
      icon: Icon(Icons.west, color: Colors.white, size: 100),
      iconSize: 100,
      onPressed: () {
        var trackingData = TrackingData("0","0","1","0",5000);
        var compute = ComputeData(trackingData);
        compute.boundingBoxCenter;
        MountController(trackingData, bleCharacteristic).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
      },
    );
  }
  Widget rightArrow(BuildContext context){
    return IconButton(
      icon: Icon(Icons.east, color: Colors.white, size: 100),
      iconSize: 100,
      onPressed: () {
        var trackingData = TrackingData("1","1","1","0",5000);
        var compute = ComputeData(trackingData);
        compute.boundingBoxCenter;
        MountController(trackingData, bleCharacteristic).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
      },
    );
  }
  Widget upRightArrow(BuildContext context){
    return IconButton(
      icon: Icon(Icons.north_east, color: Colors.white, size: 100),
      iconSize: 100,
      onPressed: () {
        var trackingData = TrackingData("1","1","0","0",5000);
        var compute = ComputeData(trackingData);
        compute.boundingBoxCenter;
        MountController(trackingData, bleCharacteristic).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
      },
    );
  }
  Widget upLeftArrow(BuildContext context){
    return IconButton(
      icon: Icon(Icons.north_west, color: Colors.white, size: 100),
      iconSize: 100,
      onPressed: () {
        var trackingData = TrackingData("0","0","0","0",5000);
        var compute = ComputeData(trackingData);
        compute.boundingBoxCenter;
        MountController(trackingData, bleCharacteristic).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
      },
    );
  }
  Widget downRightArrow(BuildContext context){
    return IconButton(
      icon: Icon(Icons.south_east, color: Colors.white, size: 100),
      iconSize: 100,
      onPressed: () {
        var trackingData = TrackingData("1","1","1","1",5000);
        var compute = ComputeData(trackingData);
        compute.boundingBoxCenter;
        MountController(trackingData, bleCharacteristic).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
      },
    );
  }
  Widget downLeftArrow(BuildContext context){
    return IconButton(
      icon: Icon(Icons.south_west, color: Colors.white, size: 100),
      iconSize: 100,
      onPressed: () {
        var trackingData = TrackingData("0","0","1","1",5000);
        var compute = ComputeData(trackingData);
        compute.boundingBoxCenter;
        MountController(trackingData, bleCharacteristic).sendDataToESP(utf8.encode(compute.boundingBoxCenter));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBarPrimary,
      appBar: AppBar(
        title: Text("VidIt - Mount Remote Control"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: CustomAppBarDesign(),
      ),
      body: Container(

          child: Row(
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
                  downArrow(context)
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  upRightArrow(context),
                  rightArrow(context),
                  downRightArrow(context)
                ],
              ),
            ],
        ),
      ),
    );
  }

}