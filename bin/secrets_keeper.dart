import 'package:dart_console/dart_console.dart';
import 'package:secrets_keeper/secret.dart';

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
  console.hideCursor();
  if (name == null || name.isEmpty) {
    return null;
  }

  console.write("Значение: ");
  final value = console.readLine()?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }

  return Secret(name, value);
}

void main() {
  console.hideCursor();
  List<Secret> items = [];
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
            final (newSelected, removed) = deleteSelected(items, selected);
            selected = newSelected;
            if (removed != null) {
              message = 'Удалено: $removed';
            }
          case ControlCharacter.enter:
            if (items.isNotEmpty) {
              console.hideCursor();
              message = "Выбрано: ${items[selected].name}";
            }
          case ControlCharacter.escape:
            return;
          default:
            message = 'Управляющая: ${key.controlChar}';
        }
      } else {
        switch (key.char) {
          case "d" || "в":
            final (newSelected, removed) = deleteSelected(items, selected);
            selected = newSelected;
            if (removed != null) {
              message = 'Удалено: ${removed.name}';
            }

          case "a" || "ф":
            final secret = askNewSecret();
            if (secret == null) {
              message = "Добавление отменено";
            } else {
              items.add(secret);
              print("Добавлено: ${secret.name}");
            }

          case "q" || "й":
            return;
          default:
            message = 'Символ: "${key.char}" коды: ${key.char.codeUnits}';
        }
      }
    }
  } finally {
    console.showCursor();
  }
}
