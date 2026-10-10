import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:secrets_keeper/src/secret.dart';

const _appFolder = 'secrets_keeper';
const _vaultFileName = 'vault.json';

Future<String> _vaultPath() async {
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
  await dir.create(recursive: true);
  return p.join(dir.path, _vaultFileName);
}

Future<List<Secret>> loadSecrets() async {
  final file = File(await _vaultPath());

  if (await file.exists()) {
    final content = await file.readAsString();
    final data = jsonDecode(content) as List;
    return data.map((item) => Secret.fromJson(item)).toList();
  } else {
    return [];
  }
}

Future<void> saveSecrets(List<Secret> items) async {
  final file = File(await _vaultPath());

  final allSecrets = jsonEncode(items.map((item) => item.toJson()).toList());
  await file.writeAsString(allSecrets);
  if (!Platform.isWindows) {
    await Process.run('chmod', ['600', file.path]);
  }
}
