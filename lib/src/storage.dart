import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:secrets_keeper/src/crypto.dart';
import 'package:secrets_keeper/src/secret.dart';

const _appFolder = 'secrets_keeper';
const _vaultFileName = 'vault.json';

class Vault {
  final String path;
  Vault(this.path);

  Future<bool> exists() {
    final file = File(path);
    return file.exists();
  }

  Future<String> read() {
    final file = File(path);
    return file.readAsString();
  }

  Future<List<Secret>> load(VaultKey vk) async {
    final file = File(path);

    if (await file.exists()) {
      final content = await file.readAsString();
      final decrypted = await decryptVault(content, vk);
      final data = jsonDecode(decrypted) as List;
      return data.map((item) => Secret.fromJson(item)).toList();
    } else {
      return [];
    }
  }

  Future<void> save(List<Secret> items, VaultKey vk) async {
    Directory(p.dirname(path)).create(recursive: true);

    final file = File(path);

    final allSecrets = jsonEncode(items.map((item) => item.toJson()).toList());
    final encrypted = await encryptVault(allSecrets, vk);
    await file.writeAsString(encrypted);
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', file.path]);
    }
  }
}

String defaultVaultPath() {
  final env = Platform.environment;
  final String base;

  if (Platform.isWindows) {
    base = env['APPDATA']!;
  } else if (Platform.isMacOS) {
    base = p.join(env['HOME']!, 'Library', 'Appication Support');
  } else {
    base = env["XDG_CONFIG_HOME"] ?? p.join(env['HOME']!, '.config');
  }

  final dir = Directory(p.join(base, _appFolder));
  return p.join(dir.path, _vaultFileName);
}
