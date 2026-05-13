import 'dart:io';

void main() {
  final dir = Directory('mobile/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    // Match 'EGP ${...}'
    final regexInterpolation = RegExp(r"EGP \$\{([^}]+)\}");
    if (regexInterpolation.hasMatch(content)) {
      content = content.replaceAllMapped(regexInterpolation, (match) {
        return '\${${match.group(1)}} EGP';
      });
      changed = true;
    }

    // Match 'EGP 500', 'EGP 100,000+', etc.
    final regexLiteral = RegExp(r"EGP (\d+(?:,\d+)*\+?)");
    if (regexLiteral.hasMatch(content)) {
      content = content.replaceAllMapped(regexLiteral, (match) {
        return '${match.group(1)} EGP';
      });
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Swapped EGP in: \${file.path}');
    }
  }
}
