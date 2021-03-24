
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ituvidit/static.dart';

Widget renderDetectImageButton(BuildContext context){
  return ElevatedButton(
    child: Text("Detect in an Image"),
    onPressed: () {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => StaticImage(),
      ),
      );
    },
  );
}

class CustomDrawer extends HookWidget{
  final Function(bool boolValue) setValue;
  final bool debugModeValue;
  CustomDrawer(this.setValue, this.debugModeValue);

  @override
  Widget build(BuildContext context) {
    final switchValue = useState(debugModeValue);
    return Drawer(
      child: ListView(
        children: [
          SwitchListTile(
              activeColor: Colors.green,
              title: Text("Tracking Boxes"),
              subtitle: Text("Do you want to display the tracking boxes?"),
              value: switchValue.value,
              onChanged: (bool newValue){
                switchValue.value = !switchValue.value;
                newValue = switchValue.value;
                setValue(switchValue.value);
          }
          ),
          renderDetectImageButton(context),
        ],
      ),
    );
  }
}

