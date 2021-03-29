
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
  final Function(bool boolValue) setDebugValue;
  final Function(bool boolValue) setGridViewValue;
  final bool debugModeValue;
  final bool gridViewValue;
  CustomDrawer(this.setDebugValue, this.debugModeValue, this.setGridViewValue, this.gridViewValue);

  @override
  Widget build(BuildContext context) {
    final debugValue = useState(debugModeValue);
    final gridValue = useState(gridViewValue);
    return Drawer(
      child: ListView(
        children: [
          SwitchListTile(
              activeColor: Colors.green,
              title: Text("Tracking Boxes"),
              subtitle: Text("Do you want to display the tracking boxes?"),
              value: debugValue.value,
              onChanged: (bool newValue){
                debugValue.value = !debugValue.value;
                newValue = debugValue.value;
                setDebugValue(debugValue.value);
          }
          ),
          SwitchListTile(
              activeColor: Colors.green,
              title: Text("GrivView"),
              subtitle: Text("Do you want to display the gridview?"),
              value: gridValue.value,
              onChanged: (bool newValue){
                gridValue.value = !gridValue.value;
                newValue = gridValue.value;
                setGridViewValue(gridValue.value);
              }
          ),
          renderDetectImageButton(context),
        ],
      ),
    );
  }
}

