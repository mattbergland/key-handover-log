import Foundation
import SwiftUI

struct Volunteer: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var initials: String
    var role: String
    var phone: String?
}

enum TagColor: String, Codable, CaseIterable, Sendable {
    case red, orange, yellow, green, teal, blue, indigo, purple

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        }
    }
}

struct LighthouseKey: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var colorName: String
    var description: String
    var holderId: UUID?
    var dueBackAt: Date?

    var isInLockbox: Bool { holderId == nil }

    func isOverdue(now: Date) -> Bool {
        holderId != nil && dueBackAt.map { $0 < now } == true
    }

    var tagColor: TagColor { TagColor(rawValue: colorName) ?? .teal }
}

enum HandoverStatus: String, Codable, CaseIterable, Sendable {
    case pending, confirmed, returnedToLockbox
}

struct Handover: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let keyId: UUID
    let fromVolunteerId: UUID?
    let toVolunteerId: UUID?
    let createdAt: Date
    var dueBackAt: Date?
    var status: HandoverStatus
    var confirmedAt: Date?
    var note: String?
}

struct KeyLogSnapshot: Codable, Equatable, Sendable {
    var volunteers: [Volunteer]
    var keys: [LighthouseKey]
    var handovers: [Handover]
    var currentUserId: UUID?
}
