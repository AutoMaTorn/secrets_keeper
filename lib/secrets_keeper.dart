import 'package:dart_console/dart_console.dart';

void main() {
  final console = Console();
  console.writeLine('Нажимай клавиши, q — выход');

  while (true) {
    final key = console.readKey();
    if (key.isControl) {
      console.writeLine('Управляющая: ${key.controlChar}');
    } else {
      console.writeLine('Символ: ${key.char}');
      if (key.char == 'q') break;
    }
  }
}
