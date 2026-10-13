import 'dart:convert';

import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  final message = 'Какой то пароль';

  // инициализация алгоритма шифрования
  final algorithm = AesGcm.with256bits();

  // создание случайного секретного ключа шифрования
  final secretKey = await algorithm.newSecretKey();

  // генерируем случайный вектор инициализации / Nonce
  // AES-GCM требует уникальный IV для каждой операции шифрования
  // final nonce = algorithm.newNonce();

  // дальше само шифрование
  final clearTextBytes = utf8.encode(message);

  final secretBox = await algorithm.encrypt(
    clearTextBytes,
    secretKey: secretKey,
  );

  print(secretBox.cipherText);
  print(secretBox.mac.bytes);
  print(secretBox.nonce);

  final afterDecpypt = await algorithm.decrypt(secretBox, secretKey: secretKey);
  final withBytes = utf8.decode(afterDecpypt);
  print(withBytes);

  try {
    final list = secretBox.cipherText.toList();

    list[10] = 1;

    final broken = SecretBox(list, nonce: secretBox.nonce, mac: secretBox.mac);

    print(broken.cipherText);
    print(broken.mac.bytes);
    print(broken.nonce);

    final afterDecpyptBroken = await algorithm.decrypt(
      broken,
      secretKey: secretKey,
    );
    final withBytesBroken = utf8.decode(afterDecpyptBroken);
    print(withBytesBroken);
  } on SecretBoxAuthenticationError {
    print('Данные повреждены или неверный ключ');
  }
}
