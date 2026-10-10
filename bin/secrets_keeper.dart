import 'dart:io';
import 'dart:convert';

import 'package:dart_console/dart_console.dart';
import 'package:secrets_keeper/secret.dart';

const vaultPath = 'vault.json';
final console = Console();

void render(List<Secret> items, int selected, String message) {
  console.clearScreen();
  console.resetCursorPosition();

  console.writeLine(
    "↑/↓ - вверх/вниз  a - добавить  d - удалить  q - выйти  enter - выбор",
  );

  if (items.isEmpty) {
    console.writeLine("Пусто");
  } else {
    for (var i = 0; i < items.length; i++) {
      if (i == selected) {
        console.writeLine('> ${items[i].name}');
      } else {
        console.writeLine('  ${items[i].name}');
      }
    }
  }
  console.writeLine(message);
}

(int, Secret?) deleteSelected(List<Secret> items, int selected) {
  Secret? removed;
  if (items.isNotEmpty) {
    removed = items.removeAt(selected);
    if (selected > 0 && selected >= items.length) {
      selected--;
    }
  }
  return (selected, removed);
}

Secret? askNewSecret() {
  console.showCursor();

  console.write("Название: ");
  final name = console.readLine()?.trim();
  if (name == null || name.isEmpty) {
    console.hideCursor();
    return null;
  }

  console.write("Значение: ");
  final value = console.readLine()?.trim();
  console.hideCursor();
  if (value == null || value.isEmpty) {
    return null;
  }

  return Secret(name, value);
}

// kto suda zachol tot gay

Future<void> copyToClipboard(String value) async {
  final process = await Process.start('clip', []);
  process.stdin.write(value);
  await process.stdin.close();
  await process.exitCode;
}

Future<List<Secret>> loadSecrets() async {
  final file = File(vaultPath);
  if (await file.exists()) {
    final content = await file.readAsString();
    final data = jsonDecode(content) as List;
    return data.map((item) => Secret.fromJson(item)).toList();
  } else {
    return [];
  }
}

Future<void> saveSecrets(List<Secret> items) async {
  final file = File(vaultPath);

  final allSecrets = jsonEncode(items.map((item) => item.toJson()).toList());
  await file.writeAsString(allSecrets);
}

// ya uzhe krasnyi

bool confirm(String question) {
  console.write("$question (y/n): ");
  final key = console.readKey();
  return !key.isControl && key.char == "y";
}

Future<void> main() async {
  console.hideCursor();

  List<Secret> items = await loadSecrets();
  var selected = 0;
  var message = '';

  try {
    while (true) {
      render(items, selected, message);
      final key = console.readKey();

      if (key.isControl) {
        switch (key.controlChar) {
          case ControlCharacter.arrowUp:
            if (selected > 0) {
              selected--;
            }
          case ControlCharacter.arrowDown:
            if (selected < items.length - 1) {
              selected++;
            }
          case ControlCharacter.delete || ControlCharacter.backspace:
            if (items.isNotEmpty &&
                confirm("Удалить ${items[selected].name}?")) {
              final (newSelected, removed) = deleteSelected(items, selected);
              selected = newSelected;

              if (removed != null) {
                message = 'Удалено: ${removed.name}';
                await saveSecrets(items);
              }
            } else {
              message = "Удаление отменено";
            }
          case ControlCharacter.enter:
            if (items.isNotEmpty) {
              await copyToClipboard(items[selected].value);
              message = "Скопировано: ${items[selected].name}";
            }
          case ControlCharacter.ctrlC:
            return;
          default:
            break;
        }
      } else {
        switch (key.char) {
          case "d" || "в":
            final (newSelected, removed) = deleteSelected(items, selected);
            selected = newSelected;
            if (removed != null) {
              message = 'Удалено: ${removed.name}';
              await saveSecrets(items);
            }

          case "a" || "ф":
            final secret = askNewSecret();
            if (secret == null) {
              message = "Добавление отменено";
            } else {
              items.add(secret);
              message = "Добавлено: ${secret.name}";
              await saveSecrets(items);
            }

          case "q" || "й":
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
