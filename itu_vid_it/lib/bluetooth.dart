import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FlutterBlueWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final bluetoothState = useStream(FlutterBlue.instance.state);
    if (bluetoothState?.data == BluetoothState.on) return FindESPScreen();
    else return BluetoothOffScreen();
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);

  final BluetoothState state;
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
            ),
          ],
        ),
    );
  }
}

class FindESPScreen extends HookWidget {
  static const DEVICE_NAME = "VidItESP32";
  //static const DEVICE_NAME = "PC-AdVGA6"; // Mathias test env
  @override
  Widget build(BuildContext context) {
    BluetoothDevice espDevice;
    List<BluetoothService> espServices;
    FlutterBlue fBlue = FlutterBlue.instance;
    fBlue.setLogLevel(LogLevel.notice);
    final scanSnapshot = useStream(fBlue.scanResults);
    final isScanningSnapshot = useStream(fBlue.isScanning);
    final mountConnected = useState(false);
    final mountFound = useState(false);
    final isLoading = useState(true);
    final tryConnect = useState(false);
    isLoading.value = !isScanningSnapshot.hasData && !scanSnapshot.hasData;
    if (isLoading.value) return CircularProgressIndicator(); // wait for streams

    useEffect(() { // call scan once on widget init
      fBlue.startScan(timeout: Duration(seconds: 1));
      return fBlue.stopScan;
    },
      [], // call once
    );
    useEffect(() { // check if our mount is found
      try { // catch exception if not found
        espDevice = scanSnapshot.data
            .firstWhere((element) => element.device.name == DEVICE_NAME)
            .device;
        print("ESP> " + espDevice.toString());
        mountFound.value = true;
        if (isScanningSnapshot.data) fBlue.stopScan();
      } catch (e) { // when ESP is not found
        //print(scanSnapshot.data.length.toString()+">>fault>" + e.toString());
        if(!isScanningSnapshot.data)
          mountFound.value = false;
      }
      return null; // callback
    },
      [scanSnapshot.data.length],
    );
    Future waitForConnect() async {
      if (espServices != null) return true; // already connected
      //print("ran waitForConnect()");
      try {
        await espDevice.connect(autoConnect: true);
      } catch (e) {
        if (!e.toString().contains("already_connected")) throw e; // unexpected error
      }
      mountConnected.value = true;
      espServices = await espDevice.discoverServices();
      if (espServices != null)
        for (var service in espServices) {
          if (service.uuid.toString() == "ea411899-d14c-45d5-81f0-ce96b217c64a")
            for (BluetoothCharacteristic characteristic in service.characteristics) {
              if (characteristic.uuid.toString() == "91235981-23ee-4bca-b7b2-2aec7d075438") {
                var readValue = await characteristic.read();
                print("redVal: " + readValue.toString());
                await characteristic.write([77, 97, 116, 104, 105, 97, 115], // Mathias
                    withoutResponse: true);
              }
            }
        }
      return true;
    }
    if (espDevice != null && !tryConnect.value) { // run once
      tryConnect.value = true;
      waitForConnect().then((value) => null);
    }

    /// UI rendering
    Widget renderDeviceList() {
      if (scanSnapshot.data.isEmpty)
        return Text("No devices");
      return Column(
        children: scanSnapshot.data.map(
              (r) => r.device.name.isNotEmpty ? Text(r.device.name) : Container(),
        ).toList(),
      );
    }

    final alertDismissed = useState(false);
    Widget renderAlertWidget() {
      if (isScanningSnapshot.data || mountFound.value || alertDismissed.value) return Container(); // do not display alert
      return AlertDialog(
        title: Text("Mount not found"),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('The mount \'$DEVICE_NAME\' was not found'),
              Text('Make sure it is turned on or reboot and scan again'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Rescan'),
            onPressed: () {
              fBlue.startScan(timeout: Duration(seconds: 5));
            },
          ),
          TextButton(
            child: Text('Dismiss'),
            onPressed: () {
              alertDismissed.value = true;
            },
          ),
        ],
      );
    }
    return Center(
      child: SingleChildScrollView(
        child: Column(
            children: [
              Row(children: [Text("Scan "), isScanningSnapshot.data ? CircularProgressIndicator() : Icon(Icons.check)]),
              Row(children: [Text("Mount "), mountFound.value ? Icon(Icons.check) : Icon(Icons.not_interested)]),
              Row(children: [Text("Connected           "), mountConnected.value ? Icon(Icons.check) : Icon(Icons.not_interested)]),
              renderDeviceList(),
              renderAlertWidget(),
            ]),
      ),
    );
  }
}