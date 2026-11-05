import 'package:secrets_keeper/src/crypto.dart';
import 'package:secrets_keeper/src/secret.dart';
import 'package:secrets_keeper/src/storage.dart';

class AppState {
  final List<Secret> items;
  final VaultKey vk;
  final Vault vault;
  int selected = 0;
  String message = '';

  AppState(this.items, this.vk, this.vault);

  Secret? get current => items.isEmpty ? null : items[selected];

  Secret? deleteSelected() {
    if (items.isEmpty) return null;
    final removed = items.removeAt(selected);
    if (selected > 0 && selected >= items.length) {
      selected--;
    }
    return removed;
  }
}
