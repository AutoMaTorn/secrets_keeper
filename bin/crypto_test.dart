import 'dart:convert';

import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  final password = "Password";
  final aes = AesGcm.with256bits();

  // сохранение
  final salt = SecretKeyData.random(length: 16).bytes;
  final secretKey = await deriveKeyFromPasswordArgon2(password, salt);

  final box = await aes.encrypt(
    utf8.encode("Секретные данные"),
    secretKey: secretKey,
  );

  final json = jsonEncode({
    'version': 1,
    'salt': base64Encode(salt),
    'nonce': base64Encode(box.nonce),
    'cipherText': base64Encode(box.cipherText),
    'mac': base64Encode(box.mac.bytes),
  });

  print('В файл пойдёт:');
  print(json);

  // загрузка
  final data = jsonDecode(json) as Map<String, dynamic>;

  final loadedSalt = base64Decode(data['salt']);
  final loadedBox = SecretBox(
    base64Decode(data['cipherText']),
    nonce: base64Decode(data['nonce']),
    mac: Mac(base64Decode(data['mac'])),
  );

  final loadedKey = await deriveKeyFromPasswordArgon2(password, loadedSalt);

  try {
    final clearBytes = await aes.decrypt(loadedBox, secretKey: loadedKey);
    print('Расшифровано: ${utf8.decode(clearBytes)}');
  } on SecretBoxAuthenticationError {
    print('Неверный пароль или файл поврежден');
  }
}

Future<SecretKey> deriveKeyFromPasswordArgon2(
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
