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
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
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
      ),
    );
  }
}

class FindESPScreen extends HookWidget {
  //static const DEVICE_NAME = "VidItESP32";
  static const DEVICE_NAME = "PC-AdVGA6"; // Mathias test env
  @override
  Widget build(BuildContext context) {
    BluetoothDevice espDevice;
    List<BluetoothService> espServices;
    List<BluetoothDevice> bluetoothDevices;
    FlutterBlue fBlue = FlutterBlue.instance;
    fBlue.setLogLevel(LogLevel.notice);
    final scanSnapshot = useStream(fBlue.scanResults);
    AsyncSnapshot<List<BluetoothDevice>> connectedDevices = useFuture(fBlue.connectedDevices, initialData: []);
    final isScanningSnapshot = useStream(fBlue.isScanning);
    final mountConnected = useState(false);
    final mountFound = useState(false);
    final isLoading = useState(true);
    isLoading.value = !isScanningSnapshot.hasData && !scanSnapshot.hasData;
    if (isLoading.value) return CircularProgressIndicator(); // wait for streams

    useEffect(() { // call scan once on widget init
      fBlue.startScan(timeout: Duration(seconds: 1));
      return fBlue.stopScan;
    },
      [], // call once
    );
    useEffect(() { // check if out mount is found
      try { // throws exception if not found
        espDevice = scanSnapshot.data
            .firstWhere((element) => element.device.name == DEVICE_NAME)
            .device;
        mountFound.value = true;
      } catch (e) { // when ESP is not found
        print(scanSnapshot.data.length.toString()+">>fault>" + e.toString());
        if(!isScanningSnapshot.data)
          mountFound.value = false;
      }
      return null; // callback
    },
      [scanSnapshot.data.length],
    );
    try {
      useEffect(() { // call scan once on widget init
        if (espDevice == null) return null;
        if (connectedDevices.data.any((device) => device.name == DEVICE_NAME)) {
          print("preConnected");
          espDevice = connectedDevices.data.firstWhere((device) => device.name == DEVICE_NAME);
          espDevice.discoverServices().then((espServices) => {
            espServices.forEach((service) {
              for (BluetoothCharacteristic c in service.characteristics) {
                print("characteristic>>>"+c.toString());
                //c.read().then((value) => print("redVal: "+value.toString()));
                //c.write([0x4], withoutResponse: true, ).then((value) => print("wrote K to "+c.deviceId.toString()));
              }
            })
          });
          return null;
        }
        espDevice.connect(autoConnect: false).then((_) => {
          mountConnected.value = true,
          espDevice.discoverServices().then((espServices) => {
            espServices.forEach((service) {
              for(BluetoothCharacteristic c in service.characteristics) {
                print("characteristic>>>"+c.toString());
                //c.read().then((value) => print("redVal: "+value.toString()));
                //c.write([0x4], withoutResponse: true, ).then((value) => print("wrote K to "+c.deviceId.toString()));
              }
            })
          }),
        });
        return null;
      },
        [espDevice?.id], // call once
      );
    } catch (e) {
      print("CON err code="+e.toString());
    }
    /*if (espDevice == null && scanSnapshot.hasData && !mountConnected.value) {
      try {
        espDevice = scanSnapshot.data
            .firstWhere((element) => element.device.name == "PC-AdVGA6")
        //.firstWhere((element) => element.device.name == "VidItESP32")
            .device;
        mountFound.value = true;
        espDevice.connect(autoConnect: false).then((_) => {
          mountConnected.value = true,
          espDevice.discoverServices().then((espServices) => {
            espServices.forEach((service) {
              for(BluetoothCharacteristic c in service.characteristics) {
                print("characteristic>>>"+c.toString());
                c.read().then((value) => print("redVal: "+value.toString()));
                c.write([0x4], withoutResponse: true, ).then((value) => print("wrote K to "+c.deviceId.toString()));
              }
            })
          }),
        });
      } catch (e) { // when ESP is not found
        //print("fault>" + e.toString());
        if(!isScanningSnapshot.data)
          mountFound.value = false;
      }
    }

    /* if(espServices != null) {
      espServices.forEach((service) {
        for(BluetoothCharacteristic c in service.characteristics) {
          c.write([0x4], withoutResponse: true).then((value) => print("wrote K to "+c.deviceId.toString()));
        }
      });
    }*/*/

    Widget renderDeviceList() {
      if (!scanSnapshot.hasData)
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
              Text('The mount $DEVICE_NAME was not found'),
              Text('Make sure it is turned on and scan again'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Rescan'),
            onPressed: () {
              fBlue.startScan(timeout: Duration(seconds: 4));
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
              Row(children: [Text("Connected "), mountConnected.value ? Icon(Icons.check) : Icon(Icons.not_interested)]),
              renderDeviceList(),
              renderAlertWidget(),
            ]),
      ),
    );
  }
  Future bleStuff() async {
    await FlutterBlue.instance.startScan(timeout: Duration(seconds: 1));
    var connectedDevices = await FlutterBlue.instance.connectedDevices;
    print("devisces>>> "+ connectedDevices.toString());
    List<BluetoothDevice> scanResults = [];
    FlutterBlue.instance.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        scanResults.add(result.device);
      }
    });
    print("allDevisces>>> "+ scanResults.toString());
  }
}