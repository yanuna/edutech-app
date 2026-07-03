import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// AES-256 encrypted offline store for premium PDFs (PYQs, notes, etc.).
///
/// Security model:
///  • The 256-bit key is generated once and kept in the OS keystore
///    (Android Keystore / iOS Keychain) via flutter_secure_storage — never in
///    plain app storage or the code.
///  • Encrypted bytes are written into the app's PRIVATE documents sandbox with
///    a `.enc` extension. They are meaningless without the key and are not
///    visible/usable from the device file manager or external storage.
///  • Decryption happens in memory only — plaintext is never written to disk.
///  • Files are AES-256-CBC with a random 16-byte IV prepended to the ciphertext.
///
/// Usage:
///   await SecureFileStore.instance.save('pyq_2023_prelims_p1', pdfBytes);
///   final Uint8List? bytes = await SecureFileStore.instance.read('pyq_2023_prelims_p1');
///   // feed `bytes` straight into SecurePdfViewer (see shared/widgets/secure_pdf_viewer.dart)
class SecureFileStore {
  SecureFileStore._();
  static final SecureFileStore instance = SecureFileStore._();

  static const _keyName = 'content_aes_key_v1';
  static const _subDir = 'secure_content';

  // Android uses the Keystore-backed custom ciphers by default (v10+);
  // iOS keeps the key in the Keychain, only after first unlock, on-device only.
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<enc.Key> _key() async {
    var b64 = await _secure.read(key: _keyName);
    if (b64 == null) {
      final rnd = Random.secure();
      final bytes = Uint8List.fromList(List<int>.generate(32, (_) => rnd.nextInt(256)));
      b64 = base64Encode(bytes);
      await _secure.write(key: _keyName, value: b64);
    }
    return enc.Key(base64Decode(b64));
  }

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_subDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  File _fileFor(Directory dir, String id) => File('${dir.path}/$id.enc');

  /// Whether an encrypted copy is already saved offline.
  Future<bool> exists(String id) async => _fileFor(await _dir(), id).exists();

  /// Encrypt & persist PDF (or any) bytes for offline reading.
  Future<void> save(String id, Uint8List bytes) async {
    final key = await _key();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final cipher = encrypter.encryptBytes(bytes, iv: iv);
    final payload = Uint8List.fromList(iv.bytes + cipher.bytes); // [IV][ciphertext]
    await _fileFor(await _dir(), id).writeAsBytes(payload, flush: true);
  }

  /// Decrypt to memory (never written to disk). Returns null if not saved.
  Future<Uint8List?> read(String id) async {
    final file = _fileFor(await _dir(), id);
    if (!await file.exists()) return null;

    final raw = await file.readAsBytes();
    if (raw.length <= 16) return null;

    final iv = enc.IV(Uint8List.fromList(raw.sublist(0, 16)));
    final body = enc.Encrypted(Uint8List.fromList(raw.sublist(16)));
    final key = await _key();
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return Uint8List.fromList(encrypter.decryptBytes(body, iv: iv));
  }

  Future<void> delete(String id) async {
    final file = _fileFor(await _dir(), id);
    if (await file.exists()) await file.delete();
  }

  /// Remove every offline file (e.g. on logout).
  Future<void> clearAll() async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
