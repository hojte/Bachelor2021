// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

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

  @override
  Widget build(BuildContext context) {
    BluetoothDevice esp;
    List<BluetoothService> espServices;
    FlutterBlue fBlue = FlutterBlue.instance;
    final scanSnapshot = useStream(fBlue.scanResults);
    final isScanningSnapshot = useStream(fBlue.isScanning);
    final mountConnected = useState(false);
    final mountFound = useState(false);

    final isLoading = useState(true);
    isLoading.value = !isScanningSnapshot.hasData && !scanSnapshot.hasData;

    if (isLoading.value) return CircularProgressIndicator(); // wait for streams
    final scanInit = useState(false);
    if (!isScanningSnapshot.data && !scanInit.value) {
      scanInit.value = true;
      fBlue.startScan(timeout: Duration(seconds: 3));
    }

    if (scanSnapshot.hasData && esp == null) {
      try {
        esp = scanSnapshot.data
            .firstWhere((element) => element.device.name == "VidItESP32")
            .device;
        mountFound.value = true;
        if (isScanningSnapshot.data) fBlue.stopScan();
      } catch (e) {
        if(!isScanningSnapshot.data)
          mountFound.value = false;
      }
    }
    AsyncSnapshot<BluetoothDeviceState> espStateSnapshot; // I think this is pretty unsafe
    if (esp != null) espStateSnapshot = useStream(esp.state);
    if (esp != null && espStateSnapshot.data == BluetoothDeviceState.disconnected)
      esp.connect().then((value) => mountConnected.value = true);
    if (esp != null && espStateSnapshot.data == BluetoothDeviceState.connected) {
      mountConnected.value = true;
      if(espServices == null) esp.discoverServices().then((value) => espServices = value);
    }

    if(espServices != null) {
      espServices.forEach((service) {
        for(BluetoothCharacteristic c in service.characteristics) {
          c.write([0x4], withoutResponse: true).then((value) => print("wrote K to "+c.deviceId.toString()));
        }
      });
    }

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
              Text('The mount was not found'),
              Text('Make sure it is turned on and scan again'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Rescan'),
            onPressed: () {
              fBlue.startScan(timeout: Duration(seconds: 2));
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
              //renderDeviceList(),
              renderAlertWidget(),
            ]),
      ),
    );
  }
}