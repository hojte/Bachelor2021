// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FlutterBlueWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
        stream: FlutterBlue.instance.state,
        initialData: BluetoothState.unknown,
        builder: (c, snapshot) {
          final state = snapshot.data;
          if (state == BluetoothState.on) {
            return FindESPScreen();
          }
          return BluetoothOffScreen(state: state);
        });
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
  BluetoothDevice esp;
  List<BluetoothService> espServices;
  bool mountConnected;

  @override
  Widget build(BuildContext context) {
    final scanSnapshot = useStream(FlutterBlue.instance.scanResults);
    final isScanning = useStream(FlutterBlue.instance.isScanning);
    if (isScanning.data!=null && !isScanning.data && scanSnapshot.data!=null && scanSnapshot.data.isEmpty) FlutterBlue.instance.startScan(timeout: Duration(seconds: 1));
    final deviceList = scanSnapshot?.data?.map(
          (r) => r.device.name.isNotEmpty ? Text(r.device.name) : Container(),
    );
    //FlutterBlue.instance.startScan(timeout: Duration(seconds: 4));
    final mountFound = useState(false);
    if (scanSnapshot.hasData && esp == null) {
      try {
        esp = scanSnapshot.data
            .firstWhere((element) => element.device.name == "VidItESP32")
            .device;
      } catch (e) {
        print("Mount not found (VidItESP32)");
      }
    }
    //if (esp != null) print("yoyo: "+ esp.toString());
    if (esp != null && useStream(esp.state).data == BluetoothDeviceState.disconnected) esp.connect().then((value) => print("connected to Mount"));
    if (esp != null && useStream(esp.state).data == BluetoothDeviceState.connected && espServices == null) esp.discoverServices().then((value) => espServices = value);

    if(espServices != null) {
      espServices.forEach((service) {
        // print("serviceID: "+service.deviceId.id);
        for(BluetoothCharacteristic c in service.characteristics) {
          c.write([0x4], withoutResponse: true).then((value) => print("wrote K to "+c.deviceId.toString()));
        }
      });
    }
    return Center(
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            children:
            deviceList != null ? deviceList.toList() : [],
          ),
        ),
      ),
    );
  }
}