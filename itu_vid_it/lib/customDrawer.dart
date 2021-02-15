import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CustomDrawer extends HookWidget{

  @override
  Widget build(BuildContext context) {
    final switchValue = useState(true);
    return Drawer(
      child: ListView(
        children: [
          SwitchListTile(
              activeColor: Colors.green,
              title: Text("Debug mode"),
              subtitle: Text("Do you want to display debug mode?"),
              value: switchValue.value,
              onChanged: (bool newValue){
                switchValue.value = !switchValue.value;
                newValue = switchValue.value;
          }
          )
        ],
      ),
    );
  }
}