import AVFoundation
import CoreMedia
import CoreVideo
import UIKit

struct LiveReceiptFraming {
  var found = false
  var widthRatio = 0.0
  var heightRatio = 0.0
  var edgeCoverage = 0.0
  var confidenceBucket = "unknown"
  var touchesEdge = false
}
