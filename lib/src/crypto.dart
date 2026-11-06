import 'dart:convert';

import 'package:cryptography/cryptography.dart';

final _aes = AesGcm.with256bits();

class VaultKey {
  final SecretKey key;
  final List<int> salt;

  VaultKey(this.key, this.salt);
}

class VaultFormatException implements Exception {
  final String message;
  VaultFormatException(this.message);

  @override
  String toString() => 'VaultFormatException: $message';
}

Future<VaultKey> createVaultKey(String password) async {
  final salt = SecretKeyData.random(length: 16).bytes;
  final secretKey = await _deriveKeyFromPasswordArgon2(password, salt);
  return VaultKey(secretKey, salt);
}

Future<VaultKey> openVaultKey(String password, List<int> salt) async {
  final secretKey = await _deriveKeyFromPasswordArgon2(password, salt);
  return VaultKey(secretKey, salt);
}

Future<String> encryptVault(String plainText, VaultKey vk) async {
  final box = await _aes.encrypt(utf8.encode(plainText), secretKey: vk.key);
  final json = jsonEncode({
    'version': 1,
    'salt': base64Encode(vk.salt),
    'nonce': base64Encode(box.nonce),
    'cipherText': base64Encode(box.cipherText),
    'mac': base64Encode(box.mac.bytes),
  });
  return json;
}

Future<String> decryptVault(String fileContent, VaultKey vk) async {
  final data = jsonDecode(fileContent) as Map<String, dynamic>;

  final box = SecretBox(
    base64Decode(data['cipherText']),
    nonce: base64Decode(data['nonce']),
    mac: Mac(base64Decode(data['mac'])),
  );

  final clearBytes = await _aes.decrypt(box, secretKey: vk.key);
  return utf8.decode(clearBytes);
}

List<int> readSalt(String fileContent) {
  final data = jsonDecode(fileContent) as Map<String, dynamic>;
  return base64Decode(data['salt']);
}

Future<SecretKey> _deriveKeyFromPasswordArgon2(
  String password,
  List<int> salt,
) async {
  final algorithm = Argon2id(
    memory: 19456, // Выделяемая память в КБ (~19 МБ по OWASP)
    parallelism: 1, // Количество потоков
    iterations: 2, // Количество проходов
    hashLength: 32, // Длина ключа в байтах (32 байта = 256 бит)
  );

  final SecretKey derivedKey = await algorithm.deriveKeyFromPassword(
    password: password,
    nonce: salt,
  );

  return derivedKey;
}
