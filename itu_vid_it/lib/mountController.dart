
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
    print("XXXXXXXXXXXXXX: " + cd.xData);

    sendDataToESP(utf8.encode(cd.xData));
    //sendDataToESP(utf8.encode(_trackingData.xCoord));

    return Container();
  }
}

class TrackingData {
  String wCoord;
  String xCoord;
  String hCoord;
  String yCoord;
  String speed;
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

  String get xData{
    print(trackingData.xCoord);
    if(trackingData.xCoord != null){
      double xdata = double.parse(trackingData.xCoord);
      if(xdata>0.4){
        return "Right";
      }
      else if (xdata<0.3){
        return "Left";
      }
      else{
        //If x is between 0.4 and 0.3
        return "Hold";
      }
    }
    //If there is no x data given
    //return "Hold";
  }
}