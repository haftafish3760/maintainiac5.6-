import 'dart:io';

import 'reusable_parsing_qa_handoff_checkpoint.dart';
import 'reusable_parsing_qa_handoff_refresh.dart';

const _usage =
    'dart run tool/reusable_parsing_qa_handoff_sync.dart '
    '[--root .] '
    '[--branch <auto-from-git>] '
    '[--commit <auto-from-git>] '
    '[--commit-full <auto-from-git>] '
    '[--label <commit label>] '
    '[--updated-at "YYYY-MM-DD HH:MM EDT"]';

Future<void> main(List<String> args) async {
  final exit = runReusableParsingQaHandoffSync(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runReusableParsingQaHandoffSync(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final refreshExit = runReusableParsingQaHandoffRefresh(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (refreshExit != 0) return refreshExit;

  final checkpointExit = runReusableParsingQaHandoffCheckpoint(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (checkpointExit != 0) return checkpointExit;

  stdout.writeln(
    'QA_REUSABLE_PARSING_HANDOFF_SYNC_COMPLETE '
    'refresh_and_checkpoint_ok=true',
  );
  return 0;
}
