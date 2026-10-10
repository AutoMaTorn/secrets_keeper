import 'package:secrets_keeper/src/secret.dart';
import 'package:secrets_keeper/src/ui/console.dart';

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

// ya uzhe krasnyi

bool confirm(String question) {
  console.write("$question (y/n): ");
  final key = console.readKey();
  return !key.isControl && key.char == "y";
}
