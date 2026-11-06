import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:secrets_keeper/src/crypto.dart';
import 'package:secrets_keeper/src/secret.dart';
import 'package:secrets_keeper/src/storage.dart';
import 'package:test/test.dart';

/// Права файла или папки в восьмеричном виде, например '600'. Только Linux.
Future<String> permissions(String path) async {
  final result = await Process.run('stat', ['-c', '%a', path]);
  return (result.stdout as String).trim();
}

void main() {
  late VaultKey vk;
  late Directory tempDir;
  late Vault vault;

  setUpAll(() async {
    vk = await createVaultKey('test');
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vault_test_');
    vault = Vault(p.join(tempDir.path, 'vault.json'));
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('без файла', () {
    test('exists возвращает false', () async {
      expect(await vault.exists(), isFalse);
    });

    test('load возвращает пустой список', () async {
      expect(await vault.load(vk), isEmpty);
    });

    test('exists не создаёт папку', () async {
      final nested = Vault(p.join(tempDir.path, 'sub', 'vault.json'));
      await nested.exists();
      expect(await Directory(p.join(tempDir.path, 'sub')).exists(), isFalse);
    });
  });

  group('сохранение и загрузка', () {
    test('возвращают те же секреты', () async {
      await vault.save([
        Secret('git', 'token123'),
        Secret('почта', 'пароль 🔑'),
      ], vk);

      final loaded = await vault.load(vk);
      expect(loaded.length, 2);
      expect(loaded[0].name, 'git');
      expect(loaded[0].value, 'token123');
      expect(loaded[1].name, 'почта');
      expect(loaded[1].value, 'пароль 🔑');
    });

    test('пустой список сохраняется и загружается', () async {
      await vault.save([], vk);
      expect(await vault.exists(), isTrue);
      expect(await vault.load(vk), isEmpty);
    });

    test('повторное сохранение заменяет содержимое', () async {
      await vault.save([Secret('a', '1')], vk);
      await vault.save([Secret('b', '2')], vk);

      final loaded = await vault.load(vk);
      expect(loaded.length, 1);
      expect(loaded.first.name, 'b');
    });

    test('создаёт отсутствующую папку', () async {
      final nested = Vault(p.join(tempDir.path, 'a', 'b', 'vault.json'));
      await nested.save([Secret('git', 'x')], vk);
      expect(await nested.exists(), isTrue);
    });

    test('в файле нет открытого текста', () async {
      await vault.save([Secret('github', 'super-secret-token')], vk);
      final content = await vault.read();
      expect(content.contains('github'), isFalse);
      expect(content.contains('super-secret-token'), isFalse);
    });

    test('неверный пароль не загружает', () async {
      await vault.save([Secret('git', 'x')], vk);
      final content = await vault.read();
      final wrong = await openVaultKey('wrong', readSalt(content));
      await expectLater(
        vault.load(wrong),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });

  group('атомарная запись', () {
    test('после сохранения не остаётся .tmp', () async {
      await vault.save([Secret('git', 'x')], vk);
      expect(await File('${vault.path}.tmp').exists(), isFalse);
    });

    test('первое сохранение не создаёт .bak', () async {
      await vault.save([Secret('git', 'x')], vk);
      expect(await File('${vault.path}.bak').exists(), isFalse);
    });

    test('второе сохранение кладёт предыдущую версию в .bak', () async {
      await vault.save([Secret('old', '1')], vk);
      await vault.save([Secret('new', '2')], vk);

      final backup = Vault('${vault.path}.bak');
      final loaded = await backup.load(vk);
      expect(loaded.single.name, 'old');
    });
  });

  group('права доступа', () {
    final skip = Platform.isLinux ? false : 'проверка прав только на Linux';

    test('файл хранилища — 600', () async {
      await vault.save([Secret('git', 'x')], vk);
      expect(await permissions(vault.path), '600');
    }, skip: skip);

    test('резервная копия — 600', () async {
      await vault.save([Secret('a', '1')], vk);
      await vault.save([Secret('b', '2')], vk);
      expect(await permissions('${vault.path}.bak'), '600');
    }, skip: skip);

    test('папка — 700', () async {
      final nested = Vault(p.join(tempDir.path, 'secure', 'vault.json'));
      await nested.save([Secret('git', 'x')], vk);
      expect(await permissions(p.join(tempDir.path, 'secure')), '700');
    }, skip: skip);
  });
}
