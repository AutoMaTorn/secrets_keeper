import 'dart:convert';

// ai code! I hate write tests...
import 'package:cryptography/cryptography.dart';
import 'package:secrets_keeper/src/crypto.dart';
import 'package:test/test.dart';

/// Меняет первый символ base64-поля обёртки на другой допустимый символ,
/// чтобы строка осталась корректным base64, но байты изменились.
String corruptField(String fileContent, String field) {
  final data = jsonDecode(fileContent) as Map<String, dynamic>;
  final value = data[field] as String;
  final replacement = value[0] == 'A' ? 'B' : 'A';
  data[field] = replacement + value.substring(1);
  return jsonEncode(data);
}

void main() {
  // Argon2 медленный, поэтому один общий ключ для тестов,
  // где сам пароль не важен.
  late VaultKey sharedKey;

  setUpAll(() async {
    sharedKey = await createVaultKey('общий-пароль');
  });

  group('шифрование и расшифровка', () {
    test('возвращают исходный текст', () async {
      const text = 'git token123';
      final file = await encryptVault(text, sharedKey);
      expect(await decryptVault(file, sharedKey), text);
    });

    test('сохраняют кириллицу и эмодзи', () async {
      const text = 'Привет 🔑 секрет';
      final file = await encryptVault(text, sharedKey);
      expect(await decryptVault(file, sharedKey), text);
    });

    test('работают с пустой строкой', () async {
      final file = await encryptVault('', sharedKey);
      expect(await decryptVault(file, sharedKey), '');
    });

    test('работают с длинным текстом', () async {
      final text = 'x' * 100000;
      final file = await encryptVault(text, sharedKey);
      expect(await decryptVault(file, sharedKey), text);
    });
  });

  group('формат файла', () {
    test('содержит все поля обёртки', () async {
      final file = await encryptVault('данные', sharedKey);
      final data = jsonDecode(file) as Map<String, dynamic>;
      expect(data['version'], 1);
      for (final field in ['salt', 'nonce', 'cipherText', 'mac']) {
        expect(data[field], isA<String>(), reason: 'поле $field');
      }
    });

    test('не содержит открытого текста', () async {
      const text = 'super-secret-token';
      final file = await encryptVault(text, sharedKey);
      expect(file.contains(text), isFalse);
    });

    test('readSalt возвращает соль ключа', () async {
      final file = await encryptVault('данные', sharedKey);
      expect(readSalt(file), sharedKey.salt);
    });

    test('соль имеет длину 16 байт', () {
      expect(sharedKey.salt.length, 16);
    });
  });

  group('ключ из пароля', () {
    test('тот же пароль и соль дают тот же ключ', () async {
      final again = await openVaultKey('общий-пароль', sharedKey.salt);
      expect(
        await again.key.extractBytes(),
        await sharedKey.key.extractBytes(),
      );
    });

    test('ключ имеет длину 32 байта', () async {
      expect((await sharedKey.key.extractBytes()).length, 32);
    });

    test('другой пароль даёт другой ключ', () async {
      final other = await openVaultKey('Общий-пароль', sharedKey.salt);
      expect(
        await other.key.extractBytes(),
        isNot(await sharedKey.key.extractBytes()),
      );
    });

    test('тот же пароль с новой солью даёт другой ключ', () async {
      final other = await createVaultKey('общий-пароль');
      expect(other.salt, isNot(sharedKey.salt));
      expect(
        await other.key.extractBytes(),
        isNot(await sharedKey.key.extractBytes()),
      );
    });

    test('заново полученный ключ расшифровывает данные', () async {
      final file = await encryptVault('данные', sharedKey);
      final reopened = await openVaultKey('общий-пароль', readSalt(file));
      expect(await decryptVault(file, reopened), 'данные');
    });
  });

  group('nonce', () {
    test('два шифрования одного текста дают разный результат', () async {
      final a = await encryptVault('одно и то же', sharedKey);
      final b = await encryptVault('одно и то же', sharedKey);
      expect(a, isNot(b));

      final nonceA = (jsonDecode(a) as Map)['nonce'];
      final nonceB = (jsonDecode(b) as Map)['nonce'];
      expect(nonceA, isNot(nonceB));
    });
  });

  group('защита от подмены', () {
    test('неверный пароль не расшифровывает', () async {
      final file = await encryptVault('данные', sharedKey);
      final wrong = await openVaultKey('неверный', readSalt(file));
      await expectLater(
        decryptVault(file, wrong),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    for (final field in ['cipherText', 'mac', 'nonce']) {
      test('изменённое поле $field не расшифровывается', () async {
        final file = await encryptVault('данные для проверки', sharedKey);
        final broken = corruptField(file, field);
        await expectLater(
          decryptVault(broken, sharedKey),
          throwsA(isA<SecretBoxAuthenticationError>()),
        );
      });
    }
  });
}
