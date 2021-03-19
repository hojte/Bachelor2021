
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CustomDrawer extends HookWidget{
  void Function(bool boolValue) setValue;
  bool debugModeValue;
  CustomDrawer(void Function(bool boolValue) this.setValue, this.debugModeValue);

  @override
  Widget build(BuildContext context) {
    final switchValue = useState(debugModeValue);
    return Drawer(
      child: ListView(
        children: [
          SwitchListTile(
            key: Key("Debug Mode"),
              activeColor: Colors.green,
              title: Text("Debug mode"),
              subtitle: Text("Do you want to display debug mode?"),
              value: switchValue.value,
              onChanged: (bool newValue){
                switchValue.value = !switchValue.value;
                newValue = switchValue.value;
                setValue(switchValue.value);
          }
          )
        ],
      ),
    );
  }
}

