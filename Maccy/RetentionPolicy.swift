import Foundation

struct RetentionCandidate: Equatable {
  var id: UUID
  var pinned: Bool
  var lastCopiedAt: Date
  var bytes: Int
}

struct RetentionPlan: Equatable {
  var deleteIDs: [UUID]
  var rejectIncoming: Bool
}

enum RetentionPolicy {
  static func plan(
    existing: [RetentionCandidate],
    incomingBytes: Int,
    incomingWouldPin: Bool,
    reservingSlot: Bool = false,
    now: Date,
    maxUnpinned: Int,
    maxPins: Int,
    maxAgeDays: Int,
    maxBytes: Int
  ) -> RetentionPlan {
    var pinned = existing.filter(\.pinned)
    var unpinned = existing.filter { !$0.pinned }

    if incomingWouldPin && pinned.count >= maxPins {
      return RetentionPlan(deleteIDs: [], rejectIncoming: true)
    }

    let pinnedBytes = pinned.reduce(0) { $0 + max(0, $1.bytes) }
    if pinnedBytes > maxBytes {
      return RetentionPlan(deleteIDs: [], rejectIncoming: true)
    }
    if incomingWouldPin && pinnedBytes + incomingBytes > maxBytes {
      return RetentionPlan(deleteIDs: [], rejectIncoming: true)
    }

    let cutoff = Calendar.current.date(byAdding: .day, value: -maxAgeDays, to: now) ?? now
    var delete: [UUID] = []
    let expired = unpinned.filter { $0.lastCopiedAt < cutoff }.sorted { $0.lastCopiedAt < $1.lastCopiedAt }
    delete.append(contentsOf: expired.map(\.id))
    unpinned.removeAll { candidate in expired.contains(where: { $0.id == candidate.id }) }

    unpinned.sort { $0.lastCopiedAt < $1.lastCopiedAt }
    let room = (reservingSlot && !incomingWouldPin) ? max(0, maxUnpinned - 1) : maxUnpinned
    if unpinned.count > room {
      let overflow = unpinned.prefix(unpinned.count - room)
      delete.append(contentsOf: overflow.map(\.id))
      unpinned.removeFirst(unpinned.count - room)
    }

    var accounted = pinnedBytes + unpinned.reduce(0) { $0 + max(0, $1.bytes) } + incomingBytes
    while accounted > maxBytes, !unpinned.isEmpty {
      let oldest = unpinned.removeFirst()
      delete.append(oldest.id)
      accounted -= max(0, oldest.bytes)
    }

    if accounted > maxBytes {
      return RetentionPlan(deleteIDs: delete, rejectIncoming: true)
    }
    return RetentionPlan(deleteIDs: delete, rejectIncoming: false)
  }
}
