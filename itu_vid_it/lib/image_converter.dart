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
      //img = await compute(_convertYUV420, image);
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

const shift = (0xFF << 24);
Future<bool> convertYUV420toImageColor(CameraImage image) async {
  try {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel;

    print("uvRowStride: " + uvRowStride.toString());
    print("uvPixelStride: " + uvPixelStride.toString());

    // imgLib -> Image package from https://pub.dartlang.org/packages/image
    var img = imglib.Image(width, height); // Create Image buffer

    // Fill image buffer with plane[0] from YUV420_888
    for(int x=0; x < width; x++) {
      for(int y=0; y < height; y++) {
        final int uvIndex = uvPixelStride * (x/2).floor() + uvRowStride*(y/2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        // Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 -vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        img.data[index] = shift | (b << 16) | (g << 8) | r;
      }
    }

    //imglib.PngEncoder pngEncoder = new imglib.PngEncoder(level: 0, filter: 0);
    //List<int> png = pngEncoder.encodeImage(img);
    //muteYUVProcessing = false;
    //return imglib.Image.memory(png);
  } catch (e) {
    print(">>>>>>>>>>>> ERROR:" + e.toString());
  }
  return null;
}