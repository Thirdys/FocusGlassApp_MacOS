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

    @Test
    func groupsTaskSessionsByIDAndUsesLatestCapturedContext() throws {
        let firstTaskID = UUID()
        let secondTaskID = UUID()
        let projectID = UUID()
        let oldDate = Date(timeIntervalSince1970: 100)
        let latestDate = Date(timeIntervalSince1970: 300)
        let records = [
            FocusSessionRecord(
                projectID: projectID,
                projectName: "Old project",
                taskID: firstTaskID,
                taskTitle: "Old task title",
                mode: .pomodoro,
                startedAt: oldDate.addingTimeInterval(-600),
                endedAt: oldDate,
                plannedSeconds: 900,
                honestFocusSeconds: 600,
                distractionCount: 1
            ),
            FocusSessionRecord(
                projectID: projectID,
                projectName: "Current project",
                taskID: firstTaskID,
                taskTitle: "Current task title",
                mode: .flow,
                startedAt: latestDate.addingTimeInterval(-1_200),
                endedAt: latestDate,
                plannedSeconds: 1_200,
                honestFocusSeconds: 900,
                distractionCount: 2
            ),
            FocusSessionRecord(
                projectID: projectID,
                projectName: "Current project",
                taskID: secondTaskID,
                taskTitle: "Current task title",
                mode: .timebox,
                startedAt: latestDate.addingTimeInterval(-300),
                endedAt: latestDate,
                plannedSeconds: 300,
                honestFocusSeconds: 300,
                distractionCount: 0
            ),
            FocusSessionRecord(
                projectName: "",
                mode: .stopwatch,
                startedAt: latestDate,
                endedAt: latestDate,
                plannedSeconds: 0,
                honestFocusSeconds: 120,
                distractionCount: 0
            )
        ]

        let summaries = AnalyticsEngine.summarizeByTask(records)
        let first = try #require(summaries.first { $0.taskID == firstTaskID })
        let second = try #require(summaries.first { $0.taskID == secondTaskID })

        #expect(summaries.count == 2)
        #expect(first.taskTitle == "Current task title")
        #expect(first.projectName == "Current project")
        #expect(first.sessionsCompleted == 2)
        #expect(first.plannedSeconds == 2_100)
        #expect(first.honestFocusSeconds == 1_500)
        #expect(first.distractionCount == 3)
        #expect(first.lastFocusedAt == latestDate)
        #expect(first.effectiveness == 1_500.0 / 2_100.0)
        #expect(second.taskTitle == first.taskTitle)
        #expect(summaries.first?.taskID == firstTaskID)
    }

    @Test
    func sortsEqualTaskTotalsByTitle() {
        let date = Date(timeIntervalSince1970: 100)
        let records = [
            FocusSessionRecord(
                projectName: "",
                taskID: UUID(),
                taskTitle: "Zulu",
                mode: .pomodoro,
                startedAt: date,
                endedAt: date,
                plannedSeconds: 600,
                honestFocusSeconds: 300,
                distractionCount: 0
            ),
            FocusSessionRecord(
                projectName: "",
                taskID: UUID(),
                taskTitle: "Alpha",
                mode: .pomodoro,
                startedAt: date,
                endedAt: date,
                plannedSeconds: 600,
                honestFocusSeconds: 300,
                distractionCount: 0
            )
        ]

        #expect(AnalyticsEngine.summarizeByTask(records).map(\.taskTitle) == ["Alpha", "Zulu"])
    }
}
