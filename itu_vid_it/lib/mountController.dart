
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
      sendDataToESP(utf8.encode(cd.boundingBoxCenter));

    }
    return Container();
  }
}

class TrackingData {
  String wCoord;
  String xCoord;
  String hCoord;
  String yCoord;
  double xSpeed;
  double ySpeed;
  TrackingData(this.wCoord, this.xCoord, this.hCoord, this.yCoord, this.xSpeed,this.ySpeed);
  Map<String,dynamic> get map {
    return {
      "wCoord":wCoord,
      "xCoord":xCoord,
      "hCoord":hCoord,
      "yCoord":yCoord,
      "xSpeed":xSpeed,
      "ySpeed":ySpeed
    };
  }

}

class ComputeData {
  TrackingData trackingData;
  ComputeData(this.trackingData);


  String get boundingBoxCenter {
    if(trackingData.xCoord != null){
      String tXSpeed =  trackingData.xSpeed.toString();
      String tYSpeed =  trackingData.ySpeed.toString();


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
      String xAndYSpeed;
      if(tXSpeed == "0" && tYSpeed=="0"){
        xAndYSpeed = xSpeed.toString()+":"+ySpeed.toString();
      }
      else{
        xAndYSpeed= tXSpeed+":"+tYSpeed;
      }
      //print(xAndYSpeed);



      if(ycenter<minY && xcenter > maxX){
        return "Up & Right:"+xAndYSpeed;
      }
      else if(ycenter<minY && xcenter<minX){
        return "Up & Left:"+xAndYSpeed;
      }
      else if(ycenter > maxY && xcenter > maxX){
        return "Down & Right:"+xAndYSpeed;
      }
      else if(ycenter > maxY && xcenter<minX){
        return "Down & Left:"+xAndYSpeed;
      }
      else if(xcenter > maxX){
        return "Right:"+xAndYSpeed;
      }
      else if(xcenter<minX){
        return "Left:"+xAndYSpeed;
      }
      else if(ycenter > maxY){
        return "Down:"+xAndYSpeed;
      }
      else if(ycenter<minY){
        return "Up:"+xAndYSpeed;
      }
      else return "Hold:"+xAndYSpeed;
    }
    //Dont return anything to keep motor moving
  }

  double calculateSpeed(double position){
    double maxSpeed = 10000.0;
    double mediumMaxSpeed = 7500.0;
    double mediumMinSpeed = 5000.0;
    double minSpeed = 2500.0;
    if(position>0.0 && position<0.125 || position>0.875 && position<1.0 ) return maxSpeed;
    else if (position>0.125 && position <0.25 || position>0.75 && position<0.875) return mediumMaxSpeed;
    else if (position>0.25 && position <0.375 || position>0.625 && position<0.75) return mediumMinSpeed;
    else if (position>0.375 && position <0.5 || position>0.5 && position<0.625) return minSpeed;
    else return 0.0;
  }



  String get checkData{
    if(trackingData.xCoord == "0.0" && trackingData.wCoord =="0.0" && trackingData.yCoord=="0.0" && trackingData.hCoord=="0.0") return "No data";
    return "Data looks fine";
  }
}