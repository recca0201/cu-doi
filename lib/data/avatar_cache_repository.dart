import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'local_player_store.dart';

class LocalAvatar {
  const LocalAvatar({required this.reference, required this.custom});
  final String reference;
  final bool custom;
}

class CloudAvatarRef {
  const CloudAvatarRef({
    required this.uid,
    required this.objectPath,
    required this.contentType,
    required this.sha256Hex,
  });
  final String uid;
  final String objectPath;
  final String contentType;
  final String sha256Hex;
}

class AvatarCacheRepository {
  // Public constructor keeps the injectable parameter readable in tests.
  // ignore: prefer_initializing_formals
  AvatarCacheRepository({
    Future<Directory> Function()? root,
    this._storage,
  }) : _root = root ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _root;
  final FirebaseStorage? _storage;
  Future<String> pathFor(String ownerHash) async =>
      p.join((await _root()).path, 'avatars', ownerHash, 'avatar.jpg');
  Future<bool> isReadable(String? path) async =>
      path != null && await File(path).exists();
  Future<void> delete(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<LocalAvatar> resolvePreset(String presetId) async =>
      LocalAvatar(reference: presetId, custom: false);

  Future<LocalAvatar> downloadCustom(
    OwnerLease lease,
    CloudAvatarRef cloud,
  ) async {
    if (!lease.isCurrent() ||
        !cloud.objectPath.startsWith('avatars/${cloud.uid}/') ||
        !const {'image/jpeg', 'image/webp'}.contains(cloud.contentType)) {
      throw const FormatException('Invalid avatar reference');
    }
    final storage = _storage;
    if (storage == null) {
      throw StateError('Firebase Storage is unavailable');
    }
    final bytes = await storage
        .ref(cloud.objectPath)
        .getData(2 * 1024 * 1024 + 1);
    if (bytes == null ||
        bytes.length > 2 * 1024 * 1024 ||
        sha256.convert(bytes).toString() != cloud.sha256Hex) {
      throw const FormatException('Invalid avatar payload');
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width > 1024 || decoded.height > 1024) {
      throw const FormatException('Invalid avatar dimensions');
    }
    if (!lease.isCurrent()) throw StateError('Stale owner lease');
    final target = File(await pathFor(lease.owner.value));
    final temp = File('${target.path}.download');
    try {
      await temp.parent.create(recursive: true);
      await temp.writeAsBytes(bytes, flush: true);
      if (!lease.isCurrent()) throw StateError('Stale owner lease');
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
      return LocalAvatar(reference: target.path, custom: true);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }
}
