import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'receipt_capture_models.dart';
import 'receipt_pdf_inspector.dart';
import 'receipt_proof_storage.dart';
import 'receipt_storage_guard.dart';

const int kMaxIncomingReceiptShareItems = 20;

class IncomingReceiptShare {
  const IncomingReceiptShare({
    required this.attachments,
    required this.receivedAt,
    this.messages = const [],
  });

  factory IncomingReceiptShare.fromMedia(List<SharedMediaFile> media) {
    final attachments = <ReceiptAttachmentRecord>[];
    final messages = <String>[];
    final receivedAt = DateTime.now();
    final importCount = media.length > kMaxIncomingReceiptShareItems
        ? kMaxIncomingReceiptShareItems
        : media.length;
    if (media.length > kMaxIncomingReceiptShareItems) {
      messages.add(
        'Maintainiac can review $kMaxIncomingReceiptShareItems shared receipt items at a time. ${media.length - kMaxIncomingReceiptShareItems} extra item(s) were left out so the import stays stable.',
      );
    }
    for (var index = 0; index < importCount; index += 1) {
      final attachment = _attachmentFromSharedMedia(
        media[index],
        receivedAt,
        index,
      );
      if (attachment == null) {
        messages.add(_unsupportedSharedMediaMessage(media[index]));
      } else {
        attachments.add(attachment);
      }
    }
    return IncomingReceiptShare(
      attachments: List.unmodifiable(attachments),
      receivedAt: receivedAt,
      messages: List.unmodifiable(messages),
    );
  }

  final List<ReceiptAttachmentRecord> attachments;
  final DateTime receivedAt;
  final List<String> messages;

  bool get hasContent => attachments.isNotEmpty || messages.isNotEmpty;

  String get importedText => attachments
      .where((attachment) => attachment.isImportedText)
      .map((attachment) => attachment.importedText.trim())
      .where((text) => text.isNotEmpty)
      .join('\n\n');
}

Future<void> discardIncomingReceiptShare(IncomingReceiptShare? share) async {
  if (share == null || !share.hasContent) return;
  await ReceiptProofStorage.instance.deleteStagedAttachments(share.attachments);
}

Future<IncomingReceiptShare> prepareIncomingReceiptShareForStorage(
  IncomingReceiptShare share,
) async {
  final kept = <ReceiptAttachmentRecord>[];
  final messages = <String>[...share.messages];
  for (final attachment in share.attachments) {
    if (attachment.isPdf) {
      final inspection = await ReceiptPdfInspector.inspect(attachment.path);
      final blocker = inspection.importBlocker;
      if (blocker != null) {
        messages.add(blocker);
        continue;
      }
      final warning = inspection.userWarning;
      if (warning != null) messages.add(warning);
      final readState = inspection.canUseAssistedRead
          ? attachment.readState
          : ReceiptAttachmentReadState.unreadable;
      kept.add(
        attachment.copyWith(
          byteSize: inspection.byteSize,
          pageCount: inspection.pageCount,
          pageCountStatus: inspection.pageCountStatus,
          validationStatus: inspection.validationStatus,
          riskFlags: inspection.riskFlags,
          documentSignals: inspection.documentSignals,
          readState: readState,
        ),
      );
      continue;
    }
    kept.add(attachment);
  }
  if (kept.isEmpty) {
    return IncomingReceiptShare(
      attachments: const [],
      receivedAt: share.receivedAt,
      messages: List.unmodifiable(messages),
    );
  }
  final staged = <ReceiptAttachmentRecord>[];
  final stagedHashes = <String>{};
  final stagedPaths = <String>{};
  for (final attachment in kept) {
    try {
      if (attachment.isPdf) {
        final storageCheck = await ReceiptStorageGuard.checkForBytes(
          requiredBytes:
              (attachment.byteSize ?? _fileSize(attachment.path) ?? 0) +
              (2 * 1024 * 1024),
          purpose: ReceiptStoragePurpose.importPdf,
        );
        if (!storageCheck.hasEnoughSpace) {
          messages.add(
            storageCheck.blockingMessage(ReceiptStoragePurpose.importPdf),
          );
          continue;
        }
        if (!storageCheck.canVerify) {
          messages.add(
            storageCheck.unknownMessage(ReceiptStoragePurpose.importPdf),
          );
        } else if (storageCheck.shouldWarnLowStorage) {
          messages.add(storageCheck.warningMessage());
        }
      }
      final stagedAttachment = await ReceiptProofStorage.instance
          .stageAttachment(attachment);
      if (_isDuplicateIncomingAttachment(
        stagedAttachment,
        stagedHashes,
        stagedPaths,
      )) {
        await ReceiptProofStorage.instance.deleteStagedAttachment(
          stagedAttachment,
        );
        messages.add('${stagedAttachment.label} was already included.');
        continue;
      }
      _rememberIncomingAttachment(stagedAttachment, stagedHashes, stagedPaths);
      staged.add(stagedAttachment);
    } on ReceiptProofStorageException catch (error) {
      messages.add(error.message);
    }
  }
  if (staged.isEmpty) {
    return IncomingReceiptShare(
      attachments: const [],
      receivedAt: share.receivedAt,
      messages: List.unmodifiable(messages),
    );
  }
  return IncomingReceiptShare(
    attachments: staged,
    receivedAt: share.receivedAt,
    messages: List.unmodifiable(messages),
  );
}

class IncomingReceiptShareController extends ChangeNotifier {
  StreamSubscription<List<SharedMediaFile>>? _subscription;
  IncomingReceiptShare? _pending;

  IncomingReceiptShare? get pending => _pending;

  Future<void> start() async {
    if (!_supportsReceiveSharingIntent) return;
    try {
      _subscription ??= ReceiveSharingIntent.instance.getMediaStream().listen(
        (media) => unawaited(_acceptMedia(media)),
        onError: (_) {},
      );
      final initialMedia = await ReceiveSharingIntent.instance
          .getInitialMedia();
      await _acceptMedia(initialMedia);
      await ReceiveSharingIntent.instance.reset();
    } on MissingPluginException {
      await _subscription?.cancel();
      _subscription = null;
    }
  }

  void clearPending() {
    if (_pending == null) return;
    unawaited(discardIncomingReceiptShare(_pending));
    _pending = null;
    notifyListeners();
  }

  IncomingReceiptShare? takePending() {
    final current = _pending;
    if (current == null) return null;
    _pending = null;
    notifyListeners();
    return current;
  }

  Future<void> _acceptMedia(List<SharedMediaFile> media) async {
    var incoming = IncomingReceiptShare.fromMedia(media);
    if (!incoming.hasContent) return;
    incoming = await prepareIncomingReceiptShareForStorage(incoming);
    if (!incoming.hasContent) return;
    unawaited(discardIncomingReceiptShare(_pending));
    _pending = incoming;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    unawaited(discardIncomingReceiptShare(_pending));
    super.dispose();
  }
}

bool get _supportsReceiveSharingIntent => Platform.isAndroid || Platform.isIOS;

class IncomingReceiptShareScope
    extends InheritedNotifier<IncomingReceiptShareController> {
  const IncomingReceiptShareScope({
    super.key,
    required IncomingReceiptShareController controller,
    required super.child,
  }) : super(notifier: controller);

  static IncomingReceiptShareController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<IncomingReceiptShareScope>();
    assert(scope?.notifier != null, 'IncomingReceiptShareScope is missing.');
    return scope!.notifier!;
  }

  static IncomingReceiptShareController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<IncomingReceiptShareScope>()
        ?.notifier;
  }
}

List<ReceiptAttachmentRecord> receiptAttachmentsFromSharedMedia(
  List<SharedMediaFile> media, {
  DateTime? receivedAt,
}) {
  final now = receivedAt ?? DateTime.now();
  final attachments = <ReceiptAttachmentRecord>[];
  for (var index = 0; index < media.length; index += 1) {
    final attachment = _attachmentFromSharedMedia(media[index], now, index);
    if (attachment != null) attachments.add(attachment);
  }
  return attachments;
}

ReceiptAttachmentRecord? _attachmentFromSharedMedia(
  SharedMediaFile media,
  DateTime receivedAt,
  int index,
) {
  final path = _normalizedSharedPath(media.path);
  final mime = media.mimeType?.toLowerCase().trim() ?? '';
  final lowerPath = path.toLowerCase();
  final displayName = _displayNameFromPath(path);
  final id = 'SHARE-${receivedAt.microsecondsSinceEpoch}-$index';

  if (media.type == SharedMediaType.url) return null;

  if (media.type == SharedMediaType.text) {
    return ReceiptAttachmentRecord(
      id: id,
      path: '',
      kind: ReceiptAttachmentKind.emailText,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: receivedAt,
      displayName: displayName.isEmpty ? 'Shared receipt text' : displayName,
      importedText: path,
      sourceLabel: 'Shared',
    );
  }

  if (media.type == SharedMediaType.image ||
      mime.startsWith('image/') ||
      _hasImageExtension(lowerPath)) {
    return ReceiptAttachmentRecord(
      id: id,
      path: path,
      kind: ReceiptAttachmentKind.photo,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: receivedAt,
      displayName: displayName.isEmpty ? 'Shared receipt image' : displayName,
      originalFileName: displayName,
      mimeType: mime.isEmpty ? 'image/*' : mime,
      byteSize: _fileSize(path),
      sourceLabel: 'Shared',
    );
  }

  if (mime == 'application/pdf' ||
      mime == 'application/x-pdf' ||
      mime == 'application/acrobat' ||
      mime == 'application/vnd.pdf' ||
      mime == 'application/octet-stream' ||
      lowerPath.endsWith('.pdf')) {
    return ReceiptAttachmentRecord(
      id: id,
      path: path,
      kind: ReceiptAttachmentKind.pdf,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: receivedAt,
      displayName: displayName.isEmpty ? 'Shared receipt PDF' : displayName,
      originalFileName: displayName,
      mimeType: mime.isEmpty ? 'application/pdf' : mime,
      byteSize: _fileSize(path),
      pageCountStatus: ReceiptPdfPageCountStatus.unknown,
      validationStatus: ReceiptPdfValidationStatus.notChecked,
      sourceLabel: 'Shared',
    );
  }

  if (mime.startsWith('text/')) {
    return ReceiptAttachmentRecord(
      id: id,
      path: '',
      kind: ReceiptAttachmentKind.emailText,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: receivedAt,
      displayName: displayName.isEmpty ? 'Shared receipt text' : displayName,
      importedText: path,
      sourceLabel: 'Shared',
    );
  }

  return null;
}

bool _hasImageExtension(String path) {
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.webp') ||
      path.endsWith('.heic') ||
      path.endsWith('.heif');
}

String _displayNameFromPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty || trimmed.contains('\n')) return '';
  final slash = trimmed.lastIndexOf('/');
  final rawName = slash == -1 ? trimmed : trimmed.substring(slash + 1);
  return _safeDecodePathComponent(rawName);
}

String _safeDecodePathComponent(String value) {
  try {
    return Uri.decodeComponent(value);
  } catch (_) {
    return value;
  }
}

String _normalizedSharedPath(String value) {
  final trimmed = value.trim();
  if (trimmed.startsWith('file://')) {
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.isScheme('file')) return uri.toFilePath();
  }
  return trimmed;
}

int? _fileSize(String path) {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.lengthSync();
  } catch (_) {
    return null;
  }
}

String _unsupportedSharedMediaMessage(SharedMediaFile media) {
  final path = _normalizedSharedPath(media.path);
  final name = _displayNameFromPath(path);
  if (media.type == SharedMediaType.url) {
    return 'Maintainiac received a link, not a receipt file. Open the link, save or share the actual PDF/photo receipt, then import it again.';
  }
  final label = name.isEmpty ? 'That shared item' : name;
  final mime = media.mimeType?.trim();
  final typeLabel = mime == null || mime.isEmpty
      ? media.type.name
      : '$mime ${media.type.name}';
  return '$label could not be imported as receipt proof. Share a PDF, receipt photo, or receipt text instead. File type: $typeLabel.';
}

bool _isDuplicateIncomingAttachment(
  ReceiptAttachmentRecord attachment,
  Set<String> hashes,
  Set<String> paths,
) {
  final hash = attachment.fileHash.trim();
  final path = attachment.path.trim();
  return (hash.isNotEmpty && hashes.contains(hash)) ||
      (path.isNotEmpty && paths.contains(path));
}

void _rememberIncomingAttachment(
  ReceiptAttachmentRecord attachment,
  Set<String> hashes,
  Set<String> paths,
) {
  final hash = attachment.fileHash.trim();
  final path = attachment.path.trim();
  if (hash.isNotEmpty) hashes.add(hash);
  if (path.isNotEmpty) paths.add(path);
}
