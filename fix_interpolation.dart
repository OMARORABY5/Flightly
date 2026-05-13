import 'dart:io';

void main() {
  final dir = Directory('mobile/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    // We accidentally wrote literal \${ instead of ${
    // The string representation in the file is \${
    if (content.contains(r'\${')) {
      content = content.replaceAll(r'\${', r'${');
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Fixed \${ in: \${file.path}');
    }
  }
}
