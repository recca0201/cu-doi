import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;

class AvatarProcessingException implements Exception {
  const AvatarProcessingException(this.message);
  final String message;
}

class AvatarRepository {
  const AvatarRepository();
  static const maxInputBytes = 20 * 1024 * 1024;
  static const maxPixels = 40000000;
  static const maxOutputBytes = 2 * 1024 * 1024;

  Future<File> process({
    required String inputPath,
    required String outputPath,
  }) async {
    final input = File(inputPath);
    if (!await input.exists() || await input.length() > maxInputBytes) {
      throw const AvatarProcessingException('invalidInput');
    }
    final bytes = await input.readAsBytes();
    final encoded = await Isolate.run(() {
      var image = img.decodeImage(bytes);
      if (image == null || image.width * image.height > maxPixels) {
        throw const AvatarProcessingException('invalidImage');
      }
      image = img.bakeOrientation(image);
      final side = image.width < image.height ? image.width : image.height;
      image = img.copyCrop(
        image,
        x: (image.width - side) ~/ 2,
        y: (image.height - side) ~/ 2,
        width: side,
        height: side,
      );
      if (side > 1024) {
        image = img.copyResize(
          image,
          width: 1024,
          height: 1024,
          interpolation: img.Interpolation.average,
        );
      }
      for (final quality in <int>[88, 80, 70, 60, 50]) {
        final out = img.encodeJpg(image, quality: quality);
        if (out.length <= maxOutputBytes) return out;
      }
      throw const AvatarProcessingException('tooLarge');
    });
    final target = File(outputPath);
    final temp = File('$outputPath.tmp');
    try {
      await temp.parent.create(recursive: true);
      await temp.writeAsBytes(encoded, flush: true);
      if (await target.exists()) await target.delete();
      return temp.rename(target.path);
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
  }
}
