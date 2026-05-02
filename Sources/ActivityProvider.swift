import Foundation
import HealthKit
import Combine
import os.log

private let logger = Logger(subsystem: "com.local.LockScreenWeather", category: "ActivityProvider")

class ActivityProvider: ObservableObject {
    static let shared = ActivityProvider()

    @Published var currentActivity: ActivityData?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let healthStore = HKHealthStore()
    private var updateTimer: Timer?
    private var isUpdating = false
    private var authorizationAttempted = false

    private init() {
        logger.info("Initializing ActivityProvider...")

        // Check if HealthKit is available on this Mac
        let available = HKHealthStore.isHealthDataAvailable()
        logger.info("HealthKit available: \(available)")

        if available {
            requestAuthorizationAndFetch()
        } else {
            logger.warning("HealthKit not available on this Mac")
            errorMessage = "HealthKit requires iPhone sync"
            isLoading = false
        }
    }

    // MARK: - Authorization

    private func requestAuthorizationAndFetch() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.activitySummaryType()
        ]

        logger.info("Requesting HealthKit authorization...")

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.authorizationAttempted = true

                if let error = error {
                    logger.error("Authorization error: \(error.localizedDescription)")
                }

                // Note: success just means the request completed, not that access was granted
                // We need to try fetching data to see if we actually have access
                logger.info("Authorization request completed (success=\(success)), attempting to fetch data...")
                self?.fetchActivityData()
            }
        }
    }

    // MARK: - Public Methods

    func startUpdating() {
        logger.info("startUpdating() called")
        guard !isUpdating else { return }
        isUpdating = true

        if authorizationAttempted {
            fetchActivityData()
        }

        // Update every 5 minutes
        updateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.fetchActivityData()
        }
    }

    func stopUpdating() {
        isUpdating = false
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func refresh(force: Bool = false) {
        logger.info("refresh() called")
        fetchActivityData()
    }

    // MARK: - Data Fetching

    private func fetchActivityData() {
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.warning("HealthKit not available")
            errorMessage = "HealthKit not available"
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        let calendar = Calendar.current
        let now = Date()

        // Create date components for today
        var dateComponents = DateComponents()
        dateComponents.calendar = calendar
        dateComponents.year = calendar.component(.year, from: now)
        dateComponents.month = calendar.component(.month, from: now)
        dateComponents.day = calendar.component(.day, from: now)

        let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)

        logger.info("Executing activity summary query for \(dateComponents.year!)-\(dateComponents.month!)-\(dateComponents.day!)")

        let query = HKActivitySummaryQuery(predicate: predicate) { [weak self] _, summaries, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    logger.error("Query failed: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to fetch activity data"
                    return
                }

                logger.info("Query returned \(summaries?.count ?? 0) summaries")

                guard let summary = summaries?.first else {
                    logger.info("No activity summary for today - showing zero progress")
                    // No data for today - show empty rings (this is valid - maybe no activity yet)
                    self?.currentActivity = ActivityData(
                        move: ActivityData.RingData(current: 0, goal: 500),
                        exercise: ActivityData.RingData(current: 0, goal: 30),
                        stand: ActivityData.RingData(current: 0, goal: 12),
                        lastUpdated: Date()
                    )
                    return
                }

                // Extract ring data
                let moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
                let moveCurrent = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())

                let exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
                let exerciseCurrent = summary.appleExerciseTime.doubleValue(for: .minute())

                let standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())
                let standCurrent = summary.appleStandHours.doubleValue(for: .count())

                logger.info("Activity data - Move: \(Int(moveCurrent))/\(Int(moveGoal)), Exercise: \(Int(exerciseCurrent))/\(Int(exerciseGoal)), Stand: \(Int(standCurrent))/\(Int(standGoal))")

                self?.currentActivity = ActivityData(
                    move: ActivityData.RingData(current: moveCurrent, goal: moveGoal),
                    exercise: ActivityData.RingData(current: exerciseCurrent, goal: exerciseGoal),
                    stand: ActivityData.RingData(current: standCurrent, goal: standGoal),
                    lastUpdated: Date()
                )
            }
        }

        healthStore.execute(query)
    }
}
