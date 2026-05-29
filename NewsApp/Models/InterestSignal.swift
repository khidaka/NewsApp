import Foundation
import SwiftData

enum SignalType: String, Codable {
    case shared
    case notInterested
}

@Model
final class InterestSignal {
    var id: UUID
    var keyword: String
    var signalTypeRaw: String
    var sourceName: String
    var recordedAt: Date

    var signalType: SignalType {
        get { SignalType(rawValue: signalTypeRaw) ?? .shared }
        set { signalTypeRaw = newValue.rawValue }
    }

    var weight: Double {
        switch signalType {
        case .shared: 2.0
        case .notInterested: -3.0
        }
    }

    init(keyword: String, signalType: SignalType, sourceName: String) {
        self.id = UUID()
        self.keyword = keyword
        self.signalTypeRaw = signalType.rawValue
        self.sourceName = sourceName
        self.recordedAt = .now
    }
}
