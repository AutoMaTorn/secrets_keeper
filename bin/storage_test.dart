import 'package:cryptography/cryptography.dart';
import 'package:secrets_keeper/src/crypto.dart';
import 'package:secrets_keeper/src/secret.dart';
import 'package:secrets_keeper/src/storage.dart';

Future<void> main() async {
  // первый запуск: новый ключ и сохранение
  final vk = await createVaultKey('test');
  await saveSecrets([Secret('git', 'token123')], vk);
  print('Файл есть: ${await vaultExists()}');

  // «перезапуск»: верный пароль
  final content = await readVaultFile();
  final vk2 = await openVaultKey('test', readSalt(content));
  final items = await loadSecrets(vk2);
  print('Загружено: ${items.first.name} = ${items.first.value}');

  // неверный пароль
  final vk3 = await openVaultKey('wrong', readSalt(content));
  try {
    await loadSecrets(vk3);
    print('Ошибка: неверный пароль подошёл');
  } on SecretBoxAuthenticationError {
    print('Неверный пароль отклонён');
  }
}
