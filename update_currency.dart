import 'dart:io';

void main() {
  final dir = Directory('mobile/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    // 1. Replace -\$${...} with -${...} EGP
    if (content.contains(r'-\$${')) {
      content = content.replaceAllMapped(RegExp(r'-\$\$\{([^}]+)\}'), (match) {
        return '-\${${match.group(1)}} EGP';
      });
      changed = true;
    }

    // 2. Replace +\$${...} with +${...} EGP
    if (content.contains(r'+\$${')) {
      content = content.replaceAllMapped(RegExp(r'\+\$\$\{([^}]+)\}'), (match) {
        return '+\${${match.group(1)}} EGP';
      });
      changed = true;
    }

    // 3. Replace \$${...} with ${...} EGP
    if (content.contains(r'\$${')) {
      content = content.replaceAllMapped(RegExp(r'\$\$\{([^}]+)\}'), (match) {
        return '\${${match.group(1)}} EGP';
      });
      changed = true;
    }

    // 4. Replace literal \$45 with 45 EGP
    if (content.contains(r'\$')) {
      final literalRegex = RegExp(r'\$(\d+(?:,\d+)?(?:\.\d+)?)');
      if (literalRegex.hasMatch(content)) {
        content = content.replaceAllMapped(literalRegex, (match) {
          return '${match.group(1)} EGP';
        });
        changed = true;
      }
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated: \${file.path}');
    }
  }
}
