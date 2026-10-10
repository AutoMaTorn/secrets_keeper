import 'dart:io';

Future<void> main() async {
  final process = await Process.start('clip', []);
  process.stdin.write("secret");
  await process.stdin.close();
  await process.exitCode;
  print("copied");
}
