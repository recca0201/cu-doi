import 'dart:io';
import 'package:ban_bua_tuong/data/avatar_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('crops to square, bounds output and commits atomically', () async {
    final root = await Directory.systemTemp.createTemp('cu-doi-avatar-');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/source.jpg');
    await source.writeAsBytes(
      img.encodeJpg(img.Image(width: 1600, height: 1200)),
    );
    final result = await const AvatarRepository().process(
      inputPath: source.path,
      outputPath: '${root.path}/cache/avatar.jpg',
    );
    final decoded = img.decodeImage(await result.readAsBytes())!;
    expect(decoded.width, decoded.height);
    expect(decoded.width, lessThanOrEqualTo(1024));
    expect(
      await result.length(),
      lessThanOrEqualTo(AvatarRepository.maxOutputBytes),
    );
    expect(File('${result.path}.tmp').existsSync(), isFalse);
  });
  test(
    'invalid file keeps target absent and cleans temporary output',
    () async {
      final root = await Directory.systemTemp.createTemp('cu-doi-avatar-bad-');
      addTearDown(() => root.delete(recursive: true));
      final input = File('${root.path}/bad.bin')
        ..writeAsStringSync('not an image');
      final output = '${root.path}/avatar.jpg';
      await expectLater(
        const AvatarRepository().process(
          inputPath: input.path,
          outputPath: output,
        ),
        throwsA(isA<AvatarProcessingException>()),
      );
      expect(File(output).existsSync(), isFalse);
      expect(File('$output.tmp').existsSync(), isFalse);
    },
  );
}
