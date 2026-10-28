// Checks that the version sent in the User-Agent header matches the
// version in pubspec.yaml, so a release cannot forget to bump it.
@TestOn('vm')
library;

import 'dart:io';

import 'package:ahasend/src/version.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('packageVersion matches pubspec.yaml', () {
    final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as Map;
    expect(packageVersion, pubspec['version']);
  });

  test('CHANGELOG.md has an entry for the current version', () {
    final changelog = File('CHANGELOG.md').readAsStringSync();
    expect(changelog, contains('## $packageVersion\n'));
  });
}
