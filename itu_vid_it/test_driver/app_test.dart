// Imports the Flutter Driver API.
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('VidIT App', () {
    // First, define the Finders and use them to locate widgets from the
    // test suite. Note: the Strings provided to the `byValueKey` method must
    // be the same as the Strings we used for the Keys in step 1.
    final startTrackButton = find.text('Start Tracking');
    final detectImageButton = find.text('Detect in Image');
    final disMissButton = find.byValueKey("Dismiss");
    final customDrawer = find.byTooltip("Open navigation menu");
    final debugMode = find.byValueKey("Debug Mode");

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
    test('Finds detect image button', () async {
      // First, tap the button.
      //await driver.tap(buttonFinder);
      expect(await driver.getText(detectImageButton), "Detect in Image");
    });
    test('Tap dismiss button', () async {
      await driver.tap(disMissButton);
    });
    test('Tap custom drawer', () async {
      await driver.waitFor(customDrawer);
      await driver.tap(customDrawer);


    });
    test('Tap debug mode ', () async {
      await driver.waitFor(debugMode);
      await driver.tap(debugMode);

    });

    test('Tap start tracking button ', () async {
      //todo -> virker ikke endnu. Skal finde en møde at lukke custom drawer på igen
     // await driver.waitFor(startTrackButton);
      //await driver.tap(startTrackButton);
    });



  });
}
