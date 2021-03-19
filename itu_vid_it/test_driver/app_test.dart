// Imports the Flutter Driver API.
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Counter App', () {
    // First, define the Finders and use them to locate widgets from the
    // test suite. Note: the Strings provided to the `byValueKey` method must
    // be the same as the Strings we used for the Keys in step 1.
    final startTrackButton = find.text('Start Tracking');
    final detectImageButton = find.text('Detect in Image');
    final backArrow = find.byValueKey("isTracking");

    FlutterDriver driver;

    // Connect to the Flutter driver before running any tests.
    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    // Close the connection to the driver after the tests have completed.
    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    test('Finds start tracking button', () async {
      expect(await driver.getText(startTrackButton), "Start Tracking");
    });

    test('tap start tracking button', () async {
      print("FUCK");
      await driver.tap(startTrackButton);
     // await driver.tap(backArrow);
      //expect(await driver.getText(cameraWidget),"");
    });

    test('Finds detect image button', () async {
      // First, tap the button.
      //await driver.tap(buttonFinder);

      expect(await driver.getText(detectImageButton), "Detect in Image");
    });

  });
}
