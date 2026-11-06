import 'dart:async';
import 'dart:io';
import 'dart:convert';

// import 'package:cryptography/cryptography.dart';
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
    final dir = await Directory(p.dirname(path)).create(recursive: true);
    await _chmod('700', dir.path);

    final allSecrets = jsonEncode(items.map((item) => item.toJson()).toList());
    final encrypted = await encryptVault(allSecrets, vk);

    final file = File(path);
    final tmp = File('$path.tmp');
    final bak = File('$path.bak');

    await tmp.writeAsString('');
    await _chmod('600', tmp.path);
    await tmp.writeAsString(encrypted, flush: true);

    if (await file.exists()) {
      await file.copy(bak.path);
      await _chmod('600', bak.path);
    }

    await tmp.rename(path);
  }
}

String defaultVaultPath() {
  final env = Platform.environment;
  final String base;

  if (Platform.isWindows) {
    base = env['APPDATA']!;
  } else if (Platform.isMacOS) {
    base = p.join(env['HOME']!, 'Library', 'Application Support');
  } else {
    base = env["XDG_CONFIG_HOME"] ?? p.join(env['HOME']!, '.config');
  }

  final dir = Directory(p.join(base, _appFolder));
  return p.join(dir.path, _vaultFileName);
}

Future<void> _chmod(String mode, String path) async {
  if (Platform.isWindows) return;
  final result = await Process.run('chmod', [mode, path]);
  if (result.exitCode != 0) {
    throw FileSystemException(
      'Не удалось изменить права: ${result.stderr}',
      path,
    );
  }
}
