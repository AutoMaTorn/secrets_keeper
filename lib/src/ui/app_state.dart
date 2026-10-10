import 'package:secrets_keeper/src/secret.dart';

class AppState {
  final List<Secret> items;
  int selected = 0;
  String message = '';

  AppState(this.items);

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
