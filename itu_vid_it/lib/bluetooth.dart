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
    List<ScanResult> scanResult;
    final scanSnapshot = useStream(fBlue.scanResults);
    final isScanningSnapshot = useStream(fBlue.isScanning);
    final mountConnected = useState(false);
    final mountFound = useState(false);
    final isScanning = useState(false);
    final firstScanInit = useState(false);

    if(isScanningSnapshot.hasData) isScanning.value = isScanningSnapshot.data;
    if(scanSnapshot.hasData) scanResult = scanSnapshot.data;

    // Bool to determine when to start scanning
    bool startScan = !isScanning.value && scanResult == null && !firstScanInit.value;

    if (startScan) {
      firstScanInit.value = true;
      fBlue.startScan(timeout: Duration(seconds: 2));
    }

    if (scanSnapshot.hasData && esp == null) {
      try {
        esp = scanSnapshot.data
            .firstWhere((element) => element.device.name == "VidItESP32")
            .device;
        mountFound.value = true;
        if (isScanning.value) fBlue.stopScan();
      } catch (e) {
        if(isScanningSnapshot.hasData && !isScanningSnapshot.data)
          mountFound.value = false;
      }
    }
    if (useStream(esp?.state).data == BluetoothDeviceState.disconnected) esp.connect().then((value) => mountConnected.value = true);
    if (useStream(esp?.state).data == BluetoothDeviceState.connected) {
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

    final deviceListUI = scanSnapshot?.data?.map(
          (r) => r.device.name.isNotEmpty ? Text(r.device.name) : Container(),
    )?.toList();

    Widget alertWidget() {
      if (!firstScanInit.value || isScanning.value || mountFound.value) return Container();
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
              print("lol trying to rescan");
            },
          ),
          TextButton(
            child: Text('Dismiss'),
            onPressed: () {

            },
          ),
        ],
      );
    }
    return Center(
      child: SingleChildScrollView(
        child: Column(
            children: [
              Card(
                child: Text(
                    "Scanning: ${isScanning.value}\n"
                        "Mount found: ${mountFound.value}\n"
                        "Connection status: ${mountConnected.value ? "Connected" : "Disconnected"}"
                ),
              ),
              Column(
                children: deviceListUI != null ? deviceListUI : [Text("No devices")],
              ),
              alertWidget(),
            ]),
      ),
    );
  }
}