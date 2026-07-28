// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool modified = false;

      String newContent = content;

      // 1. withOpacity -> withValues
      if (newContent.contains('.withOpacity(')) {
        newContent = newContent.replaceAllMapped(
          RegExp(r'\.withOpacity\((.*?)\)'),
          (match) => '.withValues(alpha: ${match.group(1)})',
        );
        modified = true;
      }

      // 2. desiredAccuracy + timeLimit -> locationSettings
      if (newContent.contains('desiredAccuracy: LocationAccuracy.')) {
        newContent = newContent.replaceAllMapped(
          RegExp(r'desiredAccuracy:\s*LocationAccuracy\.(\w+),\s*timeLimit:\s*(.*?)(?=\n|,)'),
          (match) => 'locationSettings: const LocationSettings(accuracy: LocationAccuracy.${match.group(1)}, timeLimit: ${match.group(2)})'
        );
        newContent = newContent.replaceAllMapped(
          RegExp(r'desiredAccuracy:\s*LocationAccuracy\.(\w+),?'),
          (match) => 'locationSettings: const LocationSettings(accuracy: LocationAccuracy.${match.group(1)}),'
        );
        modified = true;
      }

      // 3. empty catch blocks -> catch (e) { /* ignore */ }
      if (newContent.contains('catch (e) {}')) {
        newContent = newContent.replaceAll('catch (e) {}', 'catch (e) { /* ignore */ }');
        modified = true;
      }
      
      if (modified && content != newContent) {
        entity.writeAsStringSync(newContent);
        print('Updated ${entity.path}');
      }
    }
  }
}
