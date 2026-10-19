import 'dart:io';
import 'dart:vmservice_io';

import 'package:dart_console/dart_console.dart';
import 'package:secrets_keeper/src/clipboard.dart';
import 'package:secrets_keeper/src/crypto.dart';
import 'package:secrets_keeper/src/secret.dart';
import 'package:secrets_keeper/src/storage.dart';
import 'package:secrets_keeper/src/ui/app_state.dart';
import 'package:secrets_keeper/src/ui/console.dart';
import 'package:secrets_keeper/src/ui/dialogs.dart';
import 'package:secrets_keeper/src/ui/render.dart';

Future<(VaultKey, List<Secret>)?> _unlock() async {
  if (!await vaultExists()) {
    final password = _askNewPassword();
    console.writeLine('Создаю хранилище...');
    final vk = await createVaultKey(password);
    await saveSecrets([], vk);
    return (vk, []);
  }
}

String _askNewPassword() {
  while (true) {
    console.write("Придумайте мастер пароль");
    final first = console.readLine()?.trim() ?? '';
    if (first.isEmpty) {
      console.writeLine('Пароль не может быть пустым');
      continue;
    }

    console.write("Повторите пароль: ");
    final second = console.readLine()?.trim() ?? '';
    if (first == second) {
      return first;
    }
    console.writeLine('Пароли не совпадают, попробуйте еще раз');
  }
}

Future<void> deleteWithConfirm(AppState state) async {
  final current = state.current;
  if (current == null || !confirm('Удалить ${current.name}?')) {
    state.message = 'Удаление отменено';
    return;
  }
  state.deleteSelected();
  state.message = 'Удалено: ${current.name}';
  await saveSecrets(state.items);
}

Future<void> runApp() async {
  console.hideCursor();

  final state = AppState(await loadSecrets(vk));

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
            await deleteWithConfirm(state);
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
            await deleteWithConfirm(state);
          case "a":
            final secret = askNewSecret();
            if (secret == null) {
              state.message = "Добавление отменено";
            } else {
              state.items.add(secret);
              state.message = "Добавлено: ${secret.name}";
              await saveSecrets(state.items, vk);
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
