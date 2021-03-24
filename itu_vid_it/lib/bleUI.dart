import 'dart:convert';

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
    final tryConnect = useState(false);
    final firstScan = useState(false);

    isLoading.value = !isScanningSnapshot.hasData && !scanSnapshot.hasData;
    if (isLoading.value) return CircularProgressIndicator(); // wait for streams

    useEffect(() { // call scan once on widget init
      fBlue.connectedDevices.then((devices) => {
        if (devices.any((device) => device.name == DEVICE_NAME)) {
          fBlue.stopScan(),
          mountConnected.value = true,
          mountFound.value = true,
        }
      });
      //fBlue.startScan(timeout: Duration(seconds: 1));
      return fBlue.stopScan;
    },
      [], // call once
    );
    useEffect(() { // check if our mount is found
      try { // catch exception if not found
        espDevice = scanSnapshot.data
            .firstWhere((element) => element.device.name == DEVICE_NAME)
            .device;
        print(DEVICE_NAME + " -> " + espDevice.toString());
        mountFound.value = true;
        if (isScanningSnapshot.data) fBlue.stopScan();
      } catch (e) { // when ESP is not found
        //print(scanSnapshot.data.length.toString()+">>fault>" + e.toString());
        if(!isScanningSnapshot.data)
          fBlue.connectedDevices.then((devices) => {
            if (devices.any((device) => device.name == DEVICE_NAME)) {
              fBlue.stopScan(),
              mountConnected.value = true,
              mountFound.value = true,
            }
          });
        if(!isScanningSnapshot.data)
          mountFound.value = false;
      }
      return null; // no callback
    },
      [scanSnapshot.data.length],
    );
    Future waitForConnect() async {
      isConnecting.value = true;
      //print("ran waitForConnect()");
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
                await characteristic.write(utf8.encode("initialTest"), withoutResponse: true);
              }
            }
        }
      isConnecting.value = false;
      return true;
    }
    if (espDevice != null && !tryConnect.value) { // run once
      tryConnect.value = true;
      waitForConnect().then((value) => null);
    }

    return !mountConnected.value ? Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(primary: Colors.teal[300]),
          onPressed: () {
            firstScan.value = true;
            fBlue.startScan(timeout: Duration(seconds: 1));
          },
          child: !isScanningSnapshot.data ? Text("Connect", style: TextStyle(color: Colors.black)):
          Text("Connecting", style: TextStyle(color: Colors.black)),
        ),
        isScanningSnapshot.data || (!isScanningSnapshot.data && isConnecting.value) ?
        CircularProgressIndicator() :
        mountConnected.value ?
        Text("The VidIT mount is connected, you can proceed to tracking.") :
        firstScan.value ? Column(
          children: [
            Text("The VidIT mount was not found"),
            Text("Make sure it is turned on or reboot and connect again"),
            Text("Or you can proceed to tracking without connection to the mount"),
          ],
        )
            : Container()
      ],
    ) : Text("The VidIT mount is connected, you can proceed to tracking.");
  }
}