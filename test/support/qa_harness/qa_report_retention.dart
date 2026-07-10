import 'dart:io';

class QaReportRetentionSummary {
  const QaReportRetentionSummary({
    required this.domain,
    required this.keptTimestampedReports,
    required this.deletedTimestampedReports,
    required this.keptPackHealthReports,
    required this.deletedPackHealthReports,
    required this.preservedAliases,
  });

  final String domain;
  final List<String> keptTimestampedReports;
  final List<String> deletedTimestampedReports;
  final List<String> keptPackHealthReports;
  final List<String> deletedPackHealthReports;
  final List<String> preservedAliases;

  int get deletedCount =>
      deletedTimestampedReports.length + deletedPackHealthReports.length;
}

QaReportRetentionSummary pruneQaReportArtifacts({
  required String domain,
  String outputDirectory = 'build/parser_qa_reports',
  int keepLatestTimestamped = 20,
  bool dryRun = false,
}) {
  if (keepLatestTimestamped < 1) {
    throw ArgumentError.value(
      keepLatestTimestamped,
      'keepLatestTimestamped',
      'Must keep at least one timestamped artifact.',
    );
  }

  final directory = Directory(outputDirectory);
  if (!directory.existsSync()) {
    return QaReportRetentionSummary(
      domain: domain,
      keptTimestampedReports: const [],
      deletedTimestampedReports: const [],
      keptPackHealthReports: const [],
      deletedPackHealthReports: const [],
      preservedAliases: const [],
    );
  }

  final latestAliases = {
    'latest_$domain.json',
    'latest_$domain.txt',
    'latest_${domain}_pack_health.json',
  };
  final preservedAliases = <String>[];
  for (final alias in latestAliases) {
    final path = _join(directory.path, alias);
    if (File(path).existsSync()) preservedAliases.add(path);
  }

  final reports = _matchingFiles(
    directory,
    RegExp('^${RegExp.escape(domain)}_(?!pack_health_).+\\.json\$'),
  );
  final packHealth = _matchingFiles(
    directory,
    RegExp('^${RegExp.escape(domain)}_pack_health_.+\\.json\$'),
  );

  final keptReports = _keepNewest(reports, keepLatestTimestamped);
  final keptPackHealth = _keepNewest(packHealth, keepLatestTimestamped);
  final deletedReports = _deleteExcept(reports, keptReports, dryRun: dryRun);
  final deletedPackHealth = _deleteExcept(
    packHealth,
    keptPackHealth,
    dryRun: dryRun,
  );

  return QaReportRetentionSummary(
    domain: domain,
    keptTimestampedReports: keptReports.map((file) => file.path).toList(),
    deletedTimestampedReports: deletedReports.map((file) => file.path).toList(),
    keptPackHealthReports: keptPackHealth.map((file) => file.path).toList(),
    deletedPackHealthReports: deletedPackHealth
        .map((file) => file.path)
        .toList(),
    preservedAliases: preservedAliases..sort(),
  );
}

List<File> _matchingFiles(Directory directory, RegExp pattern) {
  final files = <File>[];
  for (final entity in directory.listSync()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (pattern.hasMatch(name)) files.add(entity);
  }
  files.sort((a, b) {
    final modified = b.lastModifiedSync().compareTo(a.lastModifiedSync());
    if (modified != 0) return modified;
    return b.path.compareTo(a.path);
  });
  return files;
}

List<File> _keepNewest(List<File> files, int count) {
  return files.take(count).toList(growable: false);
}

List<File> _deleteExcept(
  List<File> files,
  List<File> keep, {
  required bool dryRun,
}) {
  final keepPaths = keep.map((file) => file.path).toSet();
  final deleted = <File>[];
  for (final file in files) {
    if (keepPaths.contains(file.path)) continue;
    deleted.add(file);
    if (!dryRun && file.existsSync()) {
      file.deleteSync();
    }
  }
  return deleted;
}

String _join(String directory, String fileName) {
  return directory.endsWith(Platform.pathSeparator)
      ? '$directory$fileName'
      : '$directory${Platform.pathSeparator}$fileName';
}
