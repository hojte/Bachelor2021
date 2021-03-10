// imgLib -> Image package from https://pub.dartlang.org/packages/image
//https://gist.github.com/Alby-o/fe87e35bc21d534c8220aed7df028e03
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as imglib;
import 'package:camera/camera.dart';

Future<int> convertImageToPngBytes(CameraImage image, String filePath, int index) async {
  try {
    imglib.Image img;
    if (image.format.group == ImageFormatGroup.yuv420) {
      img = await compute(_convertYUV420, image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      img = await compute(_convertBGRA8888, image);
    }

    // Convert to png/jpg
    List<int> res = await compute(imglib.encodePng, img);
    await File(filePath).writeAsBytes(res);
    return index;
  } catch (e) {
    print(">>CONVERSION ERROR:" + e.toString());
    return -1;
  }
}

// CameraImage BGRA8888 -> PNG
// Color
imglib.Image _convertBGRA8888(CameraImage image) {
  return imglib.Image.fromBytes(
    image.width,
    image.height,
    image.planes[0].bytes,
    format: imglib.Format.bgra,
  );
}

// CameraImage YUV420_888 -> PNG -> Image (compresion:0, filter: none)
// Black
imglib.Image _convertYUV420(CameraImage image) {
  var img = imglib.Image(image.width, image.height); // Create Image buffer
  Plane plane = image.planes[0];
  const int shift = (0xFF << 24);

  // Fill image buffer with plane[0] from YUV420_888
  for (int x = 0; x < image.width; x++) {
    for (int planeOffset = 0;
    planeOffset < image.height * image.width;
    planeOffset += image.width) {
      final pixelColor = plane.bytes[planeOffset + x];
      // color: 0x FF  FF  FF  FF
      //           A   B   G   R
      // Calculate pixel color
      var newVal = shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;

      img.data[planeOffset + x] = newVal;
    }
  }

  return img;
}