
import 'package:flutter_blue/flutter_blue.dart';

class MountController {
  TrackingData trackingData;
  BluetoothCharacteristic bleCharacteristic;

  MountController(this.trackingData, this.bleCharacteristic);


  Future<bool> sendDataToESP(List<int> byteList) async {
    await bleCharacteristic.write(byteList, withoutResponse: true);
    return await bleCharacteristic.read() == byteList; // If read is what we wrote return success
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
  String xCoord = "0.4";

  String get xData{
    double xdata = double.parse(xCoord);
    if(xdata>0.4){
      return "Right";
    }
    else if (xdata>0.3){
      return "Left";
    }
  }
}