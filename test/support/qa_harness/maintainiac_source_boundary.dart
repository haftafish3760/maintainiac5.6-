import 'dart:io';

class MaintainiacSourceBoundaryRule {
  const MaintainiacSourceBoundaryRule({
    required this.id,
    required this.description,
    required this.pattern,
    this.allowedPathFragments = const {},
  });

  final String id;
  final String description;
  final Pattern pattern;
  final Set<String> allowedPathFragments;

  bool allowsPath(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    return allowedPathFragments.any(
      (fragment) => normalized.contains(fragment.toLowerCase()),
    );
  }
}

class MaintainiacSourceBoundaryViolation {
  const MaintainiacSourceBoundaryViolation({
    required this.ruleId,
    required this.path,
    required this.line,
    required this.description,
    required this.match,
  });

  final String ruleId;
  final String path;
  final int line;
  final String description;
  final String match;

  Map<String, Object?> toJson() {
    return {
      'ruleId': ruleId,
      'path': path,
      'line': line,
      'description': description,
      'match': match,
    };
  }
}

class MaintainiacSourceBoundaryScanner {
  const MaintainiacSourceBoundaryScanner({
    required this.rules,
    this.allowedExtensions = const {'.dart', '.yaml', '.json', '.md'},
    this.excludedPathFragments = const {
      '/.dart_tool/',
      '/build/',
      '/.git/',
      '/android/.gradle/',
      '/ios/pods/',
    },
  });

  factory MaintainiacSourceBoundaryScanner.productionDefaults() {
    return const MaintainiacSourceBoundaryScanner(
      rules: [
        MaintainiacSourceBoundaryRule(
          id: 'no_live_firestore_in_qa',
          description: 'QA harness must not use live Firestore instances.',
          pattern:
              'Firebase'
              'Firestore.instance',
          allowedPathFragments: {'firebase_emulator_tests/'},
        ),
        MaintainiacSourceBoundaryRule(
          id: 'no_google_vision_in_parser_qa',
          description: 'Parser QA may not implement Google Vision OCR.',
          pattern: 'GoogleVision',
        ),
        MaintainiacSourceBoundaryRule(
          id: 'no_mlkit_in_parser_qa',
          description: 'Parser QA may not implement ML Kit OCR.',
          pattern: 'MLKit',
        ),
        MaintainiacSourceBoundaryRule(
          id: 'no_google_mlkit_package_in_parser_qa',
          description: 'Parser QA may not import Google ML Kit packages.',
          pattern: 'google_mlkit_',
        ),
        MaintainiacSourceBoundaryRule(
          id: 'no_camera_controller_in_parser_qa',
          description: 'Parser QA may not implement camera capture.',
          pattern: 'CameraController',
        ),
        MaintainiacSourceBoundaryRule(
          id: 'no_camera_package_in_parser_qa',
          description: 'Parser QA may not import camera packages.',
          pattern: 'package:camera/',
        ),
      ],
    );
  }

  final List<MaintainiacSourceBoundaryRule> rules;
  final Set<String> allowedExtensions;
  final Set<String> excludedPathFragments;

  List<MaintainiacSourceBoundaryViolation> scanPaths(Iterable<String> paths) {
    final violations = <MaintainiacSourceBoundaryViolation>[];
    for (final path in paths) {
      final entity = FileSystemEntity.typeSync(path);
      if (entity == FileSystemEntityType.directory) {
        violations.addAll(scanDirectory(Directory(path)));
      } else if (entity == FileSystemEntityType.file) {
        violations.addAll(scanFile(File(path)));
      }
    }
    return violations;
  }

  List<MaintainiacSourceBoundaryViolation> scanDirectory(Directory directory) {
    if (!directory.existsSync()) return const [];
    final violations = <MaintainiacSourceBoundaryViolation>[];
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) continue;
      violations.addAll(scanFile(entity));
    }
    return violations;
  }

  List<MaintainiacSourceBoundaryViolation> scanFile(File file) {
    final path = _normalize(file.path);
    if (!_shouldScan(path) || !file.existsSync()) return const [];
    final lines = file.readAsLinesSync();
    final violations = <MaintainiacSourceBoundaryViolation>[];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      for (final rule in rules) {
        if (rule.allowsPath(path)) continue;
        final match = _firstMatch(rule.pattern, line);
        if (match == null) continue;
        violations.add(
          MaintainiacSourceBoundaryViolation(
            ruleId: rule.id,
            path: path,
            line: index + 1,
            description: rule.description,
            match: match,
          ),
        );
      }
    }
    return violations;
  }

  bool _shouldScan(String path) {
    final lower = path.toLowerCase();
    if (excludedPathFragments.any(lower.contains)) return false;
    return allowedExtensions.any(lower.endsWith);
  }

  String? _firstMatch(Pattern pattern, String line) {
    if (pattern is RegExp) {
      return pattern.firstMatch(line)?.group(0);
    }
    final text = pattern.toString();
    return line.contains(text) ? text : null;
  }

  String _normalize(String path) => path.replaceAll('\\', '/');
}
