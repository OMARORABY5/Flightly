import 'dart:io';

void main() {
  final file = File('lib/features/search/presentation/screens/flight_details_screen.dart');
  final lines = file.readAsLinesSync();
  final stack = <String>[];
  final lineStack = <int>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    for (int j = 0; j < line.length; j++) {
      final c = line[j];
      if (c == '{' || c == '(' || c == '[') {
        stack.add(c);
        lineStack.add(i + 1);
      } else if (c == '}' || c == ')' || c == ']') {
        if (stack.isEmpty) {
          print('Unmatched $c at line ${i + 1}');
        } else {
          final top = stack.removeLast();
          final topLine = lineStack.removeLast();
          final expected = top == '{' ? '}' : top == '(' ? ')' : ']';
          if (c != expected) {
            print('Mismatched $c at line ${i + 1}, expected $expected to match $top at line $topLine');
          }
        }
      }
    }
  }
}
