import 'dart:convert';

class AppPdfSecurityPolicy {
  const AppPdfSecurityPolicy._();

  static const activeJavaScript = 'active_javascript';
  static const activeLaunchAction = 'active_launch_action';
  static const automaticAction = 'automatic_action';
  static const autoOpenAction = 'auto_open_action';
  static const dynamicFormContent = 'dynamic_form_content';
  static const embeddedFile = 'embedded_file';
  static const embeddedMedia = 'embedded_media';
  static const externalLinks = 'external_links';
  static const formSubmissionAction = 'form_submission_action';

  static List<String> activeContentIssueCodesForBytes(List<int> bytes) {
    if (bytes.isEmpty) return const [];
    final text = _removeStreamBodies(
      latin1.decode(bytes, allowInvalid: true).toLowerCase(),
    );
    final issues = <String>[];
    if (_containsPdfName(text, 'javascript') || _containsPdfName(text, 'js')) {
      issues.add(activeJavaScript);
    }
    if (_containsPdfName(text, 'openaction')) issues.add(autoOpenAction);
    if (_containsPdfName(text, 'launch')) issues.add(activeLaunchAction);
    if (_containsPdfName(text, 'aa')) issues.add(automaticAction);
    if (_containsPdfName(text, 'embeddedfile') ||
        _containsPdfName(text, 'filespec')) {
      issues.add(embeddedFile);
    }
    if (_containsPdfName(text, 'richmedia')) issues.add(embeddedMedia);
    if (_containsPdfName(text, 'submitform')) {
      issues.add(formSubmissionAction);
    }
    if (_containsPdfName(text, 'acroform') || _containsPdfName(text, 'xfa')) {
      issues.add(dynamicFormContent);
    }
    if (_containsPdfName(text, 'uri')) {
      issues.add(externalLinks);
    }
    return issues.toSet().toList(growable: false);
  }

  static bool containsPdfName(String text, String name) {
    return _containsPdfName(text.toLowerCase(), name.toLowerCase());
  }

  static bool _containsPdfName(String text, String name) {
    final escaped = RegExp.escape(name);
    return RegExp('/$escaped(?![a-z0-9])').hasMatch(text);
  }

  // Content streams are compressed or arbitrary application data. Active PDF
  // features are declared in dictionaries, so scanning stream bodies creates
  // false positives for ordinary generated documents.
  static String _removeStreamBodies(String text) {
    return text.replaceAll(
      RegExp(r'stream(?:\r\n|\r|\n).*?endstream', dotAll: true),
      'stream endstream',
    );
  }
}
