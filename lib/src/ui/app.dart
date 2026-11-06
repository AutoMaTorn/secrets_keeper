import 'package:cryptography/cryptography.dart';
import 'package:dart_console/dart_console.dart';
import 'package:secrets_keeper/src/clipboard.dart';
import 'package:secrets_keeper/src/crypto.dart';
import 'package:secrets_keeper/src/secret.dart';
import 'package:secrets_keeper/src/storage.dart';
import 'package:secrets_keeper/src/ui/app_state.dart';
import 'package:secrets_keeper/src/ui/console.dart';
import 'package:secrets_keeper/src/ui/dialogs.dart';
import 'package:secrets_keeper/src/ui/render.dart';

Future<(VaultKey, List<Secret>)?> _unlock(Vault vault) async {
  if (!await vault.exists()) {
    final password = _askNewPassword();
    console.writeLine('Создаю хранилище...');
    final vk = await createVaultKey(password);
    await vault.save([], vk);
    return (vk, <Secret>[]);
  } else {
    final content = await vault.read();
    final salt = readSalt(content);

    for (var attempt = 1; attempt <= 3; attempt++) {
      final password = _askPassword();
      console.writeLine("Открываю хранилище");
      final vk = await openVaultKey(password, salt);

      try {
        final items = await vault.load(vk);
        return (vk, items);
      } on SecretBoxAuthenticationError {
        console.writeLine("Неверный пароль. Осталось попыток ${3 - attempt}");
      }
    }

    return null;
  }
}

String _askNewPassword() {
  while (true) {
    console.write("Придумайте мастер пароль: ");
    final first = console.readLine()?.trim() ?? '';
    if (first.isEmpty) {
      console.writeLine("Пароль не может быть пустым");
      continue;
    }

    console.write("Повторите пароль: ");
    final second = console.readLine()?.trim() ?? '';
    if (first == second) {
      return first;
    }
    console.writeLine("Пароли не совпадают, попробуйте еще раз");
  }
}

String _askPassword() {
  while (true) {
    console.write("Введите мастер пароль: ");
    final master = console.readLine()?.trim() ?? '';
    if (master.isEmpty) {
      console.writeLine("Пароль не может быть пустым");
      continue;
    }
    return master;
  }
}

Future<void> deleteWithConfirm(AppState state, Vault vault) async {
  final current = state.current;
  if (current == null || !confirm('Удалить ${current.name}?')) {
    state.message = 'Удаление отменено';
    return;
  }
  state.deleteSelected();
  state.message = 'Удалено: ${current.name}';
  await state.vault.save(state.items, state.vk);
}

Future<void> runApp() async {
  final vault = Vault(defaultVaultPath());
  final unlocked = await _unlock(vault);

  if (unlocked == null) {
    console.writeLine("Не удалось открыть хранилище");
    return;
  }
  final (vk, items) = unlocked;

  console.hideCursor();

  final state = AppState(items, vk, vault);

  try {
    while (true) {
      render(state.items, state.selected, state.message);
      final key = console.readKey();

      if (key.isControl) {
        switch (key.controlChar) {
          case ControlCharacter.arrowUp:
            if (state.selected > 0) {
              state.selected--;
            }
          case ControlCharacter.arrowDown:
            if (state.selected < state.items.length - 1) {
              state.selected++;
            }
          case ControlCharacter.delete || ControlCharacter.backspace:
            await deleteWithConfirm(state, vault);
          case ControlCharacter.enter:
            final current = state.current;
            if (current != null) {
              final result = await copyToClipboard(current.value);
              state.message = switch (result) {
                CopyResult.copied => 'Скопировано: ${current.name}',
                CopyResult.sentToTerminal => 'Отправлено в терминал. Если не вставляется — установите xclip или wl-copy',
              };
            }
          case ControlCharacter.ctrlC:
            return;
          default:
            break;
        }
      } else {
        switch (key.char) {
          case "d":
            await deleteWithConfirm(state, vault);
          case "a":
            final secret = askNewSecret();
            if (secret == null) {
              state.message = "Добавление отменено";
            } else {
              state.items.add(secret);
              state.message = "Добавлено: ${secret.name}";
              await state.vault.save(state.items, state.vk);
            }

          case "q":
            return;
          default:
            break;
        }
      }
    }
  } finally {
    console.showCursor();
  }
}
