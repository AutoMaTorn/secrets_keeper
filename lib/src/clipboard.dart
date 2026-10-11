import 'dart:convert';
import 'dart:io';

enum CopyResult { copied, sentToTerminal }

List<(String, List<String>)> _clipboardCommands() {
  if (Platform.isWindows) return [('clip', [])];
  if (Platform.isMacOS) return [('pbcopy', [])];

  final env = Platform.environment;
  return [
    if (env.containsKey('WSL_DISTRO_NAME')) ('clip.exe', []),
    if (env.containsKey('WAYLAND_DISPLAY')) ('wl-copy', []),
    ('xclip', ['-selection', 'clipboard']),
    ('xsel', ['--clipboard', '--input']),
  ];
}

Future<CopyResult> copyToClipboard(String value) async {
  for (final (command, args) in _clipboardCommands()) {
    try {
      final process = await Process.start(command, args);
      process.stdin.write(value);
      await process.stdin.close();
      if (await process.exitCode == 0) return CopyResult.copied;
    } on ProcessException {
      // программы нет — пробуем следующую
    }
  }

  // ничего не сработало: просим терминал скопировать сам (OSC 52)
  final encoded = base64Encode(utf8.encode(value));
  stdout.write('\x1B]52;c;$encoded\x07');
  return CopyResult.sentToTerminal;
}
