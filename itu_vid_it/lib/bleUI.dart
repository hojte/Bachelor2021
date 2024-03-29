import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const DEVICE_NAME = "VidItESP32";
FlutterBlue fBlue = FlutterBlue.instance;
BluetoothDevice espDevice;
BluetoothCharacteristic espCharacteristic;

class FlutterBlueWidget extends HookWidget {
  final setBleCharacteristic;
  FlutterBlueWidget(this.setBleCharacteristic);

  @override
  Widget build(BuildContext context) {
    final bluetoothState = useStream(FlutterBlue.instance.state);
    if (bluetoothState?.data == BluetoothState.on) return FindESPScreen(setBleCharacteristic);
    else return BluetoothOffScreen();
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          mediaQuery.orientation == Orientation.landscape ?
          Icon(
            Icons.bluetooth_disabled,
            size: 65.0,
            color: Colors.white54,
          ):
          Icon(
            Icons.bluetooth_disabled,
            size: 200.0,
            color: Colors.white54,
          ),
          mediaQuery.orientation == Orientation.landscape ?
          Text(
            'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
            textScaleFactor: 0.8,
          ):
          Text(
            'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
            textScaleFactor: 1.0,
          ),
        ],
      ),
    );
  }
}

class FindESPScreen extends HookWidget {
  final _setBleCharacteristic;
  FindESPScreen(this._setBleCharacteristic);
  @override
  Widget build(BuildContext context) {
    final scanSnapshot = useStream(fBlue.scanResults);
    final isScanningSnapshot = useStream(fBlue.isScanning);
    final isConnecting = useState(false);
    final mountConnected = useState(false);
    final mountFound = useState(false);
    final isLoading = useState(true);
    final tryConnect = useState(true);
    final firstScan = useState(false);
    final isMounted = useIsMounted();



    isLoading.value = !isScanningSnapshot.hasData && !scanSnapshot.hasData;
    if (isLoading.value) return CircularProgressIndicator(); // wait for streams
    Future waitForConnect() async {
      isConnecting.value = true;
      try {
        await espDevice.connect(autoConnect: true);
      } catch (e) {
        if (!e.toString().contains("already_connected")) throw e; // unexpected error
      }
      mountConnected.value = true;
      var espServices = await espDevice.discoverServices();
      if (espServices != null)
        for (var service in espServices) {
          if (service.uuid.toString() == "ea411899-d14c-45d5-81f0-ce96b217c64a")
            for (BluetoothCharacteristic characteristic in service.characteristics) {
              if (characteristic.uuid.toString() == "91235981-23ee-4bca-b7b2-2aec7d075438") {
                espCharacteristic = characteristic;
                _setBleCharacteristic(characteristic);
                //var readValue = await characteristic.read();
                //print("redVal: " + utf8.decode(readValue));
                try {
                  await characteristic.write(utf8.encode("initialTestWrite"), withoutResponse: true);
                } catch (e) {
                  print("Error during BLE initialTestWrite: "+e.toString()); // fixme
                  espDevice.disconnect(); // faulty connection
                }
              }
            }
        }
      isConnecting.value = false;
      return true;
    }
    void checkConnections() {
      fBlue.connectedDevices.then((devices) {
        if (devices.any((device) => device.name == DEVICE_NAME)) {
          fBlue.stopScan();
          espDevice = devices.firstWhere((device) => device.name == DEVICE_NAME);
          if (!mountConnected.value) waitForConnect();
          mountConnected.value = true;
          mountFound.value = true;
        }
        else {
          mountConnected.value = false;
          mountFound.value = false;
          isConnecting.value = false;
          _setBleCharacteristic(null);
        }
      });
    }

    useEffect(() {
      // Check connections every 5 seconds
      Timer.periodic(Duration(seconds: 5), (Timer t) {
        if (isMounted())
          checkConnections();
        else t.cancel();
      });
      return null;
    }, [], // call once
    );
    useEffect(() { // called on new scan results
      try { // catch exception if not found
        espDevice = scanSnapshot.data
            .firstWhere((element) => element.device.name == DEVICE_NAME)
            .device;
        print("ScanFound: " + espDevice.toString());
        mountFound.value = true;
        if (!mountConnected.value || !isConnecting.value) tryConnect.value = true;
        if (isScanningSnapshot.data) fBlue.stopScan();
      } catch (e) { // when ESP is not found
        if(!isScanningSnapshot.data)
          checkConnections();
      }
      return null; // no callback
    },
      [scanSnapshot.data.length],
    );

    if (espDevice != null && tryConnect.value) { // run ONE TIME
      tryConnect.value = false;
      waitForConnect();
    }

    void onConnectPressed() {
      if (isScanningSnapshot.data) return;
      checkConnections();
      fBlue.startScan(timeout: Duration(seconds: firstScan.value ? 3 : 1))
          .then((_) => checkConnections());
      firstScan.value = true;
    }

    /// Render Section
    Widget renderIcon() {
      if (isScanningSnapshot.data || (!isScanningSnapshot.data && isConnecting.value))
        return SizedBox(
          child: CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(Colors.black),
            strokeWidth: 10,
          ),
          height: 80,
          width: 80,
        );
      return Icon(mountConnected.value ? Icons.bluetooth_connected : Icons.bluetooth,
          color: Colors.black, size: 80);
    }

    if (mountConnected.value) return TextButton(
        onPressed: () => onConnectPressed(),
        child:
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                  "Connected",
                  style: TextStyle(color: Colors.black, fontSize: 35)
              ),
              renderIcon()
            ])
    );
    if (firstScan.value && !isScanningSnapshot.data) return
      TextButton(
          onPressed: () => onConnectPressed(),
          child:
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Text(
                        "Connect",
                        style: TextStyle(color: Colors.black, fontSize: 35)
                    ),
                    Container(
                        width: 250,
                        padding: EdgeInsets.only(top: 100),
                        child: Text(
                          "No mount found, please make sure it's turned on.",
                          style: TextStyle(color: Colors.black, fontStyle: FontStyle.italic),
                        )
                    ),
                  ],
                ),
                renderIcon()
              ])
      );
    return
      TextButton(
          onPressed: () => onConnectPressed(),
          child:
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Text(
                        "Connect",
                        style: TextStyle(color: Colors.black, fontSize: 35)
                    ),
                    Container(
                      width: 250,
                    ),
                  ],
                ),
                renderIcon()
              ])
      );
  }
}