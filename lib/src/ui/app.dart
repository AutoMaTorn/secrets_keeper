import 'package:dart_console/dart_console.dart';
import 'package:secrets_keeper/src/clipboard.dart';
import 'package:secrets_keeper/src/storage.dart';
import 'package:secrets_keeper/src/ui/app_state.dart';
import 'package:secrets_keeper/src/ui/console.dart';
import 'package:secrets_keeper/src/ui/dialogs.dart';
import 'package:secrets_keeper/src/ui/render.dart';

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

  final state = AppState(await loadSecrets());

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
              final ok = await copyToClipboard(current.value);
              state.message = ok
                  ? 'Скопиравано: ${current.name}'
                  : 'Не удалось скопировать. На линух надо xclip или wl-copy';
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
              await saveSecrets(state.items);
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
