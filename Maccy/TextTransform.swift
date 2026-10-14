import Foundation
import CryptoKit

/// V1 transformation seam. Returns the original text unchanged.
/// A later transform must be explicit and must not rewrite stored history.
protocol TextTransforming: Sendable {
  func transform(_ text: String) -> String
}

struct IdentityTextTransform: TextTransforming {
  func transform(_ text: String) -> String { text }
}

enum PayloadSignature {
  static func dedupKey(parts: [(type: String, bytes: Data)]) -> String {
    var hasher = SHA256()
    for part in parts.sorted(by: { $0.type < $1.type }) {
      hasher.update(data: Data(part.type.utf8))
      hasher.update(data: Data([0]))
      hasher.update(data: part.bytes)
      hasher.update(data: Data([0x1E]))
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }
}
