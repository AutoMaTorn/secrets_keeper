import 'dart:io';

(String, List<String>) _clipboardCommand() {
  if (Platform.isWindows) return ('clip', []);
  if (Platform.isMacOS) return ('pbcopy', []);

  // линух
  if (Platform.environment.containsKey('WAYLAND_DISPLAY')) {
    return ('wl-copy', []);
  }
  return ('xclip', ['-selection', 'clipboard']);
}

Future<bool> copyToClipboard(String value) async {
  final (command, args) = _clipboardCommand();
  try {
    final process = await Process.start(command, args);
    process.stdin.write(value);
    await process.stdin.close();
    final code = await process.exitCode;
    return code == 0;
  } on ProcessException {
    return false;
  }
}
