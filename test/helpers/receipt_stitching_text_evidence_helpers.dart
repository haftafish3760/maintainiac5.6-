import 'dart:io';

import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

List<ReceiptStitchTextEvidence> darkSurfaceReceiptTextEvidence(
  List<File> files,
) {
  const lines = [
    ['ITEM A 1.00', 'ITEM B 2.00', 'ITEM C 3.00', 'ITEM D 4.00'],
    ['ITEM C 3.00', 'ITEM D 4.00', 'ITEM E 5.00', 'ITEM F 6.00'],
    ['ITEM E 5.00', 'ITEM F 6.00', 'ITEM G 7.00', 'TOTAL 28.00'],
  ];
  const frameTops = [54.0, 62.0, 58.0];
  const frameHeights = [1622.0, 1642.0, 1630.0];
  const frameLefts = [84.0, 70.0, 104.0];
  const frameWidths = [1078.0, 1082.0, 1082.0];
  const centers = [.07, .15, .82, .90];
  const angles = [0.0, .7, -.7];
  return [
    for (var index = 0; index < files.length; index++)
      ReceiptStitchTextEvidence(
        path: files[index].path,
        lines: lines[index],
        positionedLines: [
          for (var lineIndex = 0; lineIndex < lines[index].length; lineIndex++)
            ReceiptStitchTextLineEvidence(
              text: lines[index][lineIndex],
              left: (frameLefts[index] + 110) / frameWidths[index],
              top:
                  (frameTops[index] + 1500 * (centers[lineIndex] - .018)) /
                  frameHeights[index],
              right: (frameLefts[index] + 790) / frameWidths[index],
              bottom:
                  (frameTops[index] + 1500 * (centers[lineIndex] + .018)) /
                  frameHeights[index],
              angleDegrees: angles[index],
            ),
        ],
      ),
  ];
}

List<ReceiptStitchTextEvidence> orderedReceiptSequenceTextEvidence(
  List<File> files,
) {
  return List.generate(files.length, (index) {
    final incoming = index == 0
        ? ['RECEIPT HEADER', 'PURCHASE DATE']
        : ['JOIN $index ITEM A', 'JOIN $index ITEM B'];
    final outgoing = index + 1 >= files.length
        ? ['RECEIPT TOTAL', 'PAYMENT METHOD']
        : ['JOIN ${index + 1} ITEM A', 'JOIN ${index + 1} ITEM B'];
    final lines = [...incoming, ...outgoing];
    const centers = [.10, .19, .81, .90];
    return ReceiptStitchTextEvidence(
      path: files[index].path,
      lines: lines,
      positionedLines: [
        for (var lineIndex = 0; lineIndex < lines.length; lineIndex++)
          ReceiptStitchTextLineEvidence(
            text: lines[lineIndex],
            left: .14,
            top: centers[lineIndex] - .018,
            right: .86,
            bottom: centers[lineIndex] + .018,
          ),
      ],
    );
  }, growable: false);
}
