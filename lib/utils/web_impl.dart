import 'dart:html';

void removeSplash() {
  final loader = document.getElementById('loading');
  if (loader != null) {
    loader.remove();
  }
}
