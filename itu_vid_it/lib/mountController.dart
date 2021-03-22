
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';

class MountController extends StatelessWidget{
  TrackingData _trackingData;
  BluetoothCharacteristic bleCharacteristic;

  MountController(this._trackingData, this.bleCharacteristic);


  Future<bool> sendDataToESP(List<int> byteList) async {

    if(bleCharacteristic==null) return false;
    await bleCharacteristic.write(byteList, withoutResponse: true);
return true;
  }
  @override
  Widget build(BuildContext context) {
    ComputeData cd = ComputeData(_trackingData);

    //If no data is computed then it just keeps rotating to the direction of the previous direction
    if(cd.checkData == "Data looks fine"){
      //print(cd.boundingBoxCenter);
      sendDataToESP(utf8.encode(cd.boundingBoxCenter));
      //sendDataToESP(utf8.encode(cd.boundingBoxYCenter));

    }
    return Container();
  }
}

class TrackingData {
  String wCoord;
  String xCoord;
  String hCoord;
  String yCoord;
  double speed;
  TrackingData(this.wCoord, this.xCoord, this.hCoord, this.yCoord, this.speed);
  Map<String,dynamic> get map {
    return {
      "wCoord":wCoord,
      "xCoord":xCoord,
      "hCoord":hCoord,
      "yCoord":yCoord,
      "speed":speed,
    };
  }

}

class ComputeData {
  TrackingData trackingData;
  ComputeData(this.trackingData);


  String get boundingBoxCenter {
    if(trackingData.xCoord != null){
      String speed =  trackingData.speed.toString();

      double x = double.parse(trackingData.xCoord);
      double y = double.parse(trackingData.yCoord);
      double w = double.parse(trackingData.wCoord);
      double h = double.parse(trackingData.hCoord);

      double xcenter = x + w/2.0;
      double ycenter = y + h/2.0;
      double minX = 0.45;
      double maxX = 0.55;
      double minY = 0.55;
      double maxY = 0.65;

      double xSpeed = calculateSpeed(xcenter);
      double ySpeed = calculateSpeed(ycenter);



      if(ycenter<minY && xcenter > maxX){
        return "Up & Right:"+xSpeed.toString();
      }
      else if(ycenter<minY && xcenter<minX){
        return "Up & Left:"+xSpeed.toString();
      }
      else if(ycenter > maxY && xcenter > maxX){
        return "Down & Right:"+xSpeed.toString();
      }
      else if(ycenter > maxY && xcenter<minX){
        return "Down & Left:"+xSpeed.toString();
      }
      else if(xcenter > maxX){
        return "Right:"+xSpeed.toString();
      }
      else if(xcenter<minX){
        return "Left:"+xSpeed.toString();
      }
      else if(ycenter > maxY){
        return "Down:"+ySpeed.toString();
      }
      else if(ycenter<minY){
        return "Up:"+ySpeed.toString();
      }
      else return "Hold";
    }
    //Dont return anything to keep motor moving
  }

  double calculateSpeed(double position){
    position=position-0.5;
    if (position<0) position=position*(-1.0);
    return position*10000.0;
  }



  String get checkData{
    if(trackingData.xCoord == "0.0" && trackingData.wCoord =="0.0" && trackingData.yCoord=="0.0" && trackingData.hCoord=="0.0") return "No data";
    return "Data looks fine";
  }
}