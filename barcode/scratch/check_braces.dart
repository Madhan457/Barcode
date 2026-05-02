
import 'dart:io';

void main() {
  Directory('lib').listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      final openBraces = '{'.allMatches(content).length;
      final closeBraces = '}'.allMatches(content).length;
      if (openBraces != closeBraces) {
        print('Brace mismatch in ${entity.path}: {: $openBraces, }: $closeBraces');
      }
      final openParens = '('.allMatches(content).length;
      final closeParens = ')'.allMatches(content).length;
      if (openParens != closeParens) {
        print('Paren mismatch in ${entity.path}: (: $openParens, ): $closeParens');
      }
    }
  });
}
