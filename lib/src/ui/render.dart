import 'package:secrets_keeper/src/secret.dart';
import 'package:secrets_keeper/src/ui/console.dart';

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
