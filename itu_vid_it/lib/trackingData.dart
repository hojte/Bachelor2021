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