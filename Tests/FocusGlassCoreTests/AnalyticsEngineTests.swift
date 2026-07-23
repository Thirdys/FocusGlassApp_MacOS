import Foundation
import Testing
@testable import FocusGlassCore

@Suite
struct AnalyticsEngineTests {
    @Test
    func groupsSessionsByModeAndProject() {
        let projectID = UUID()
        let records = [
            FocusSessionRecord(
                projectID: projectID,
                projectName: "Release",
                mode: .pomodoro,
                startedAt: .now.addingTimeInterval(-1_800),
                endedAt: .now,
                plannedSeconds: 1_500,
                honestFocusSeconds: 1_200,
                distractionCount: 2
            ),
            FocusSessionRecord(
                projectID: projectID,
                projectName: "Release",
                mode: .pomodoro,
                startedAt: .now.addingTimeInterval(-900),
                endedAt: .now,
                plannedSeconds: 600,
                honestFocusSeconds: 600,
                distractionCount: 0
            ),
            FocusSessionRecord(
                projectName: "",
                mode: .flow,
                startedAt: .now.addingTimeInterval(-300),
                endedAt: .now,
                plannedSeconds: 300,
                honestFocusSeconds: 150,
                distractionCount: 1
            )
        ]

        let modes = AnalyticsEngine.summarizeByMode(records)
        let projects = AnalyticsEngine.summarizeByProject(records)

        #expect(modes.first { $0.mode == .pomodoro }?.sessionsCompleted == 2)
        #expect(modes.first { $0.mode == .pomodoro }?.honestFocusSeconds == 1_800)
        #expect(modes.first { $0.mode == .flow }?.effectiveness == 0.5)
        #expect(projects.first { $0.projectID == projectID }?.plannedSeconds == 2_100)
        #expect(projects.first { $0.projectID == nil }?.distractionCount == 1)
    }
}
