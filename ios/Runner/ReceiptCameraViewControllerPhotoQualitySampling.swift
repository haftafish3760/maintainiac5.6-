import UIKit

extension ReceiptCameraViewController {
  struct CapturedPhotoQualitySample {
    let averageLuma: Double
    let edgeScore: Double
    let topLuma: Double
    let middleLuma: Double
    let bottomLuma: Double
    let bottomEdgeScore: Double
  }

  func sampleCapturedImageQuality(_ image: UIImage) -> CapturedPhotoQualitySample {
    guard let cgImage = image.cgImage else {
      return CapturedPhotoQualitySample(
        averageLuma: -1,
        edgeScore: -1,
        topLuma: -1,
        middleLuma: -1,
        bottomLuma: -1,
        bottomEdgeScore: -1
      )
    }
    let sampleWidth = max(2, min(96, cgImage.width))
    let sampleHeight = max(2, min(128, cgImage.height))
    let bytesPerPixel = 4
    let bytesPerRow = sampleWidth * bytesPerPixel
    var pixels = [UInt8](repeating: 0, count: sampleHeight * bytesPerRow)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var rendered = false
    pixels.withUnsafeMutableBytes { buffer in
      guard let baseAddress = buffer.baseAddress,
            let context = CGContext(
              data: baseAddress,
              width: sampleWidth,
              height: sampleHeight,
              bitsPerComponent: 8,
              bytesPerRow: bytesPerRow,
              space: colorSpace,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
        return
      }
      context.interpolationQuality = .low
      context.draw(
        cgImage,
        in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight)
      )
      rendered = true
    }
    if !rendered {
      return CapturedPhotoQualitySample(
        averageLuma: -1,
        edgeScore: -1,
        topLuma: -1,
        middleLuma: -1,
        bottomLuma: -1,
        bottomEdgeScore: -1
      )
    }
    var lumaTotal = 0.0
    var edgeTotal = 0.0
    var edgeCount = 0
    var bandLumaTotals = [Double](repeating: 0, count: 3)
    var bandCounts = [Int](repeating: 0, count: 3)
    var bandEdgeTotals = [Double](repeating: 0, count: 3)
    var bandEdgeCounts = [Int](repeating: 0, count: 3)
    var previousRow = [Double](repeating: -1, count: sampleWidth)
    for y in 0..<sampleHeight {
      var previousLuma = -1.0
      let bandIndex = min(2, (y * 3) / sampleHeight)
      for x in 0..<sampleWidth {
        let index = (y * bytesPerRow) + (x * bytesPerPixel)
        let luma = (Double(pixels[index]) * 0.299) +
          (Double(pixels[index + 1]) * 0.587) +
          (Double(pixels[index + 2]) * 0.114)
        lumaTotal += luma
        bandLumaTotals[bandIndex] += luma
        bandCounts[bandIndex] += 1
        if previousLuma >= 0 {
          let delta = abs(luma - previousLuma)
          edgeTotal += delta
          bandEdgeTotals[bandIndex] += delta
          edgeCount += 1
          bandEdgeCounts[bandIndex] += 1
        }
        if previousRow[x] >= 0 {
          let delta = abs(luma - previousRow[x])
          edgeTotal += delta
          bandEdgeTotals[bandIndex] += delta
          edgeCount += 1
          bandEdgeCounts[bandIndex] += 1
        }
        previousRow[x] = luma
        previousLuma = luma
      }
    }
    let pixelCount = Double(sampleWidth * sampleHeight)
    return CapturedPhotoQualitySample(
      averageLuma: pixelCount <= 0 ? -1 : lumaTotal / pixelCount,
      edgeScore: edgeCount <= 0 ? -1 : edgeTotal / Double(edgeCount),
      topLuma: bandAverage(totals: bandLumaTotals, counts: bandCounts, index: 0),
      middleLuma: bandAverage(totals: bandLumaTotals, counts: bandCounts, index: 1),
      bottomLuma: bandAverage(totals: bandLumaTotals, counts: bandCounts, index: 2),
      bottomEdgeScore: bandAverage(totals: bandEdgeTotals, counts: bandEdgeCounts, index: 2)
    )
  }

  func bandAverage(totals: [Double], counts: [Int], index: Int) -> Double {
    if index < 0 || index >= totals.count || index >= counts.count { return -1 }
    if counts[index] <= 0 { return -1 }
    return totals[index] / Double(counts[index])
  }
}
