import 'package:ituvidit/trackingData.dart';

class ComputeData{
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