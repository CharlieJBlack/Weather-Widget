import Foundation
import HealthKit

// MARK: - Activity Data

struct ActivityData {
    let move: RingData
    let exercise: RingData
    let stand: RingData
    let lastUpdated: Date

    struct RingData {
        let current: Double
        let goal: Double

        var progress: Double {
            guard goal > 0 else { return 0 }
            return min(current / goal, 1.0)
        }

        var percentage: Int {
            Int(progress * 100)
        }

        var isComplete: Bool {
            progress >= 1.0
        }
    }

    var allRingsComplete: Bool {
        move.isComplete && exercise.isComplete && stand.isComplete
    }
}

// MARK: - Ring Configuration

enum ActivityRing: CaseIterable {
    case move
    case exercise
    case stand

    var color: (start: String, end: String) {
        switch self {
        case .move:
            return ("#FF3B30", "#FF007A") // Red to Pink
        case .exercise:
            return ("#7AFF00", "#00FF94") // Lime to Green
        case .stand:
            return ("#00FFFF", "#0094FF") // Cyan to Blue
        }
    }

    var title: String {
        switch self {
        case .move: return "Move"
        case .exercise: return "Exercise"
        case .stand: return "Stand"
        }
    }

    var unit: String {
        switch self {
        case .move: return "CAL"
        case .exercise: return "MIN"
        case .stand: return "HRS"
        }
    }

    var icon: String {
        switch self {
        case .move: return "flame.fill"
        case .exercise: return "figure.run"
        case .stand: return "figure.stand"
        }
    }
}
