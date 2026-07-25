import Foundation
import AppKit
import Combine
import Testing
@testable import FocusGlassApp
import FocusGlassCore

@Suite(.serialized)
struct FocusGlassPersistenceTests {
    @Test
    @MainActor
    func migrationFromV2AssignsProjectIDAndSurvivesProjectRename() {
        let projectID = UUID()
        let taskID = UUID()
        let fileURL = temporaryStateURL()
        let store = FocusGlassStore(fileURL: fileURL)
        store.save(
            FocusGlassPersistedState(
                schemaVersion: 2,
                selectedThemeID: ThemeProfile.noirCrimsonID,
                themeProfiles: ThemeProfile.builtIn,
                language: .en,
                strictModeEnabled: false,
                intention: "",
                activeProject: "Alpha",
                projects: [
                    FocusProject(id: projectID, name: "Alpha", detail: "Client work", accentName: "aurora")
                ],
                tasks: [
                    FocusTask(
                        id: taskID,
                        title: "Draft plan",
                        projectID: nil,
                        projectName: "Alpha",
                        estimate: 25 * 60,
                        completed: 5 * 60,
                        isDone: false
                    )
                ],
                distractionRules: [],
                recentSessions: [
                    FocusSessionRecord(
                        projectID: nil,
                        projectName: "Alpha",
                        mode: .pomodoro,
                        startedAt: Date(timeIntervalSince1970: 10),
                        endedAt: Date(timeIntervalSince1970: 20),
                        plannedSeconds: 25 * 60,
                        honestFocusSeconds: 20 * 60,
                        distractionCount: 0
                    )
                ]
            )
        )

        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)

        #expect(model.tasks.first?.projectID == projectID)
        #expect(model.recentSessions.first?.projectID == projectID)

        var renamedProject = model.projects[0]
        renamedProject.name = "Beta"
        model.updateProject(renamedProject)

        #expect(model.tasks.first?.projectID == projectID)
        #expect(model.tasks.first?.projectName == "Alpha")
        #expect(model.tasks(for: renamedProject).map(\.id) == [taskID])
        #expect(model.sessions(for: renamedProject).count == 1)
    }

    @Test
    @MainActor
    func emptyStateStaysEmptyAfterMigration() {
        let fileURL = temporaryStateURL()
        let store = FocusGlassStore(fileURL: fileURL)
        store.save(
            FocusGlassPersistedState(
                schemaVersion: 2,
                selectedThemeID: ThemeProfile.noirCrimsonID,
                themeProfiles: ThemeProfile.builtIn,
                language: .en,
                strictModeEnabled: false,
                intention: "",
                activeProject: "",
                projects: [],
                tasks: [],
                distractionRules: [],
                recentSessions: []
            )
        )

        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)

        #expect(model.projects.isEmpty)
        #expect(model.tasks.isEmpty)
        #expect(model.activeProjectID == nil)
        #expect(model.activeProjectName.isEmpty)
    }

    @Test
    @MainActor
    func orphanLegacyProjectNameBecomesUnassignedAndIsNotGroupedByName() throws {
        let project = FocusProject(name: "Alpha", detail: "Current project", accentName: "aurora")
        let fileURL = temporaryStateURL()
        let store = FocusGlassStore(fileURL: fileURL)
        store.save(
            FocusGlassPersistedState(
                schemaVersion: 2,
                selectedThemeID: ThemeProfile.noirCrimsonID,
                themeProfiles: ThemeProfile.builtIn,
                language: .en,
                strictModeEnabled: false,
                intention: "",
                activeProject: "Alpha",
                projects: [project],
                tasks: [
                    FocusTask(
                        title: "Orphan task",
                        projectID: nil,
                        projectName: "Missing",
                        estimate: 25 * 60,
                        completed: 0,
                        isDone: false
                    )
                ],
                distractionRules: [],
                recentSessions: [
                    FocusSessionRecord(
                        projectID: nil,
                        projectName: "Missing",
                        mode: .pomodoro,
                        startedAt: Date(timeIntervalSince1970: 30),
                        endedAt: Date(timeIntervalSince1970: 60),
                        plannedSeconds: 25 * 60,
                        honestFocusSeconds: 15 * 60,
                        distractionCount: 0
                    )
                ]
            )
        )

        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)

        #expect(model.tasks.first?.projectID == nil)
        #expect(model.tasks.first?.projectName == "")
        #expect(model.recentSessions.first?.projectID == nil)
        #expect(model.recentSessions.first?.projectName == "")
        #expect(model.sessions(for: project).isEmpty)
        let unassignedSession = try #require(model.unassignedSessions.first)
        #expect(unassignedSession.honestFocusSeconds == 15 * 60)
    }

    @Test
    @MainActor
    func nilProjectIDSessionIsUnassignedEvenWithReadableLegacyName() {
        let project = FocusProject(name: "Alpha", detail: "Current project", accentName: "aurora")
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        model.projects = [project]
        model.recentSessions = [
            FocusSessionRecord(
                projectID: nil,
                projectName: "Alpha",
                mode: .pomodoro,
                startedAt: Date(timeIntervalSince1970: 30),
                endedAt: Date(timeIntervalSince1970: 60),
                plannedSeconds: 25 * 60,
                honestFocusSeconds: 10 * 60,
                distractionCount: 0
            )
        ]

        #expect(model.sessions(for: project).isEmpty)
        #expect(model.unassignedSessions.count == 1)
    }

    @Test
    @MainActor
    func activeTasksAreScopedToSelectedProjectWithoutFallback() {
        let firstProject = FocusProject(name: "Alpha", detail: "", accentName: "aurora")
        let secondProject = FocusProject(name: "Beta", detail: "", accentName: "aurora")
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        model.projects = [firstProject, secondProject]
        model.activeProjectID = firstProject.id
        model.tasks = [
            FocusTask(title: "Alpha task", projectID: firstProject.id, projectName: "Alpha", estimate: 25 * 60, completed: 0, isDone: false),
            FocusTask(title: "Beta task", projectID: secondProject.id, projectName: "Beta", estimate: 25 * 60, completed: 0, isDone: false)
        ]

        #expect(model.activeTasks.map(\.title) == ["Alpha task"])

        model.activeProjectID = UUID()

        #expect(model.activeTasks.isEmpty)
    }

    @Test
    @MainActor
    func legacyProjectWithoutNotesDecodesWithEmptyNotes() throws {
        let project = FocusProject(name: "Alpha", detail: "Client work", accentName: "aurora", notes: "Context")
        let data = try JSONEncoder().encode(project)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "notes")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(FocusProject.self, from: legacyData)

        #expect(decoded.name == "Alpha")
        #expect(decoded.notes == "")
    }

    @Test
    @MainActor
    func projectNotesPersistAcrossRelaunch() throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let firstLaunch = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        var project = firstLaunch.addProject()
        project.name = "Deep Work Sprint"
        project.notes = "Keep release context and tester handoff details."
        firstLaunch.updateProject(project)

        let secondLaunch = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        let restored = try #require(secondLaunch.projects.first { $0.id == project.id })

        #expect(restored.name == "Deep Work Sprint")
        #expect(restored.notes == "Keep release context and tester handoff details.")
    }

    @Test
    @MainActor
    func legacyIntentionMigratesIntoActiveProjectNotesWhenEmpty() throws {
        let project = FocusProject(name: "Alpha", detail: "Client work", accentName: "aurora")
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        store.save(
            FocusGlassPersistedState(
                schemaVersion: 3,
                selectedThemeID: ThemeProfile.noirCrimsonID,
                themeProfiles: ThemeProfile.builtIn,
                language: .en,
                strictModeEnabled: false,
                intention: "Keep the release checklist visible.",
                activeProjectID: project.id,
                activeProject: project.name,
                projects: [project],
                tasks: [],
                distractionRules: [],
                recentSessions: []
            )
        )

        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        let restored = try #require(model.projects.first { $0.id == project.id })

        #expect(restored.notes == "Keep the release checklist visible.")
        #expect(model.intention == "")
    }

    @Test
    @MainActor
    func projectNotesUpdateDoesNotBreakActiveTaskSelectionOrProgress() throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let firstLaunch = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        let project = firstLaunch.addProject()
        var task = firstLaunch.addQuickTask()
        task.title = "Audit cockpit task layout"
        task.completed = 12 * 60
        firstLaunch.updateTask(task)
        firstLaunch.updateActiveProjectNotes("UI/UX audit notes")

        let secondLaunch = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        let restoredTask = try #require(secondLaunch.selectedActiveTask)
        let restoredProject = try #require(secondLaunch.projects.first { $0.id == project.id })

        #expect(restoredTask.id == task.id)
        #expect(restoredTask.completed == 12 * 60)
        #expect(restoredProject.notes == "UI/UX audit notes")
    }

    @Test
    @MainActor
    func presetEditChangesOnlySelectedPreset() throws {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        let countdownBefore = model.presets.first { $0.id == TimerPreset.countdown30ID }

        model.updatePreset(TimerPreset.pomodoroID) { preset in
            preset.name = "Pomodoro Custom"
            preset.segments[0].duration = 35 * 60
        }

        let pomodoro = try #require(model.presets.first { $0.id == TimerPreset.pomodoroID })
        let countdownAfter = model.presets.first { $0.id == TimerPreset.countdown30ID }
        let pomodoroSegment = try #require(pomodoro.segments.first)

        #expect(pomodoro.name == "Pomodoro Custom")
        #expect(pomodoroSegment.duration == 35 * 60)
        #expect(countdownAfter == countdownBefore)
    }

    @Test
    @MainActor
    func resetPresetRestoresOnlyThatDefault() throws {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        model.updatePreset(TimerPreset.pomodoroID) { preset in
            preset.name = "Pomodoro Custom"
            preset.segments[0].duration = 35 * 60
        }
        model.updatePreset(TimerPreset.countdown30ID) { preset in
            preset.name = "Countdown Custom"
            preset.segments[0].duration = 40 * 60
        }

        model.resetPresetToDefault(TimerPreset.pomodoroID)

        let pomodoro = model.presets.first { $0.id == TimerPreset.pomodoroID }
        let countdown = try #require(model.presets.first { $0.id == TimerPreset.countdown30ID })
        let countdownSegment = try #require(countdown.segments.first)

        #expect(pomodoro == .pomodoro)
        #expect(countdown.name == "Countdown Custom")
        #expect(countdownSegment.duration == 40 * 60)
    }

    @Test
    @MainActor
    func presetSegmentCanStoreExactManualMinutes() throws {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)

        model.updatePresetSegment(TimerPreset.deepWorkID, index: 0) { segment in
            segment.duration = 17 * 60
        }

        let deepWork = try #require(model.presets.first { $0.id == TimerPreset.deepWorkID })
        let deepWorkSegment = try #require(deepWork.segments.first)
        #expect(deepWorkSegment.duration == 17 * 60)
    }

    @Test
    func glassStepperSnapsToFiveMinuteGrid() {
        #expect(GlassStepperMath.increment(value: 1, range: 1...240, step: 5) == 5)
        #expect(GlassStepperMath.increment(value: 5, range: 1...240, step: 5) == 10)
        #expect(GlassStepperMath.increment(value: 6, range: 1...240, step: 5) == 10)
        #expect(GlassStepperMath.decrement(value: 5, range: 1...240, step: 5) == 1)
        #expect(GlassStepperMath.increment(value: 0, range: 0...240, step: 5) == 5)
        #expect(GlassStepperMath.decrement(value: 0, range: 0...240, step: 5) == 0)
    }

    @Test
    @MainActor
    func taskEstimateUpdatePersistsMinutesAndClampsProgress() throws {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        var task = model.addQuickTask()
        task.completed = 20 * 60
        model.updateTask(task)

        model.updateTaskEstimate(task, estimate: 10 * 60)

        let updatedTask = try #require(model.tasks.first { $0.id == task.id })
        #expect(updatedTask.estimate == 10 * 60)
        #expect(updatedTask.completed == 10 * 60)
    }

    @Test
    @MainActor
    func legacyTaskWithoutTimingModeDecodesAsTimed() throws {
        let task = FocusTask(
            title: "Legacy task",
            projectID: nil,
            projectName: "",
            estimate: 25 * 60,
            completed: 5 * 60,
            isDone: false
        )
        let data = try JSONEncoder().encode(task)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "timingMode")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(FocusTask.self, from: legacyData)

        #expect(decoded.timingMode == .timed)
        #expect(decoded.estimate == 25 * 60)
        #expect(decoded.completed == 5 * 60)
    }

    @Test
    @MainActor
    func checklistTaskPersistsWithoutDroppingEstimateFields() throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let firstLaunch = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        var task = firstLaunch.addQuickTask()
        task.timingMode = .checklist
        task.estimate = 30 * 60
        task.completed = 10 * 60
        firstLaunch.updateTask(task)

        let secondLaunch = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        let restored = try #require(secondLaunch.tasks.first)

        #expect(restored.timingMode == .checklist)
        #expect(restored.estimate == 30 * 60)
        #expect(restored.completed == 0)
    }

    @Test
    @MainActor
    func addQuickTaskWithoutProjectCreatesUnassignedTask() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)

        let task = model.addQuickTask()

        #expect(model.projects.isEmpty)
        #expect(task.projectID == nil)
        #expect(model.activeProjectID == nil)
        #expect(model.activeTasks.map(\.id) == [task.id])
        #expect(model.activeTaskID == task.id)
    }

    @Test
    @MainActor
    func activeTasksAreNotLimitedToThree() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        model.tasks = (1...5).map { index in
            FocusTask(
                title: "Task \(index)",
                projectID: nil,
                projectName: "",
                estimate: 25 * 60,
                completed: 0,
                isDone: false
            )
        }

        #expect(model.activeTasks.map(\.title) == ["Task 1", "Task 2", "Task 3", "Task 4", "Task 5"])
    }

    @Test
    @MainActor
    func timerTicksPublishOnlyTimerPresentationState() {
        let model = FocusGlassViewModel(
            store: FocusGlassStore(fileURL: temporaryStateURL()),
            requestPermissionsOnLaunch: false
        )
        var modelUpdates = 0
        var timerUpdates = 0
        let modelObservation = model.objectWillChange.sink {
            modelUpdates += 1
        }
        let timerObservation = model.timerPresentation.objectWillChange.sink {
            timerUpdates += 1
        }

        model.startTimerForTesting()
        model.advanceTimerForTesting(by: 1)

        #expect(modelUpdates == 0)
        #expect(timerUpdates == 2)
        #expect(model.engineSnapshot.elapsed == 1)
        withExtendedLifetime((modelObservation, timerObservation)) {}
    }

    @Test
    @MainActor
    func taskAndAnalyticsCachesStayInSyncWithPublishedCollections() {
        let model = FocusGlassViewModel(
            store: FocusGlassStore(fileURL: temporaryStateURL()),
            requestPermissionsOnLaunch: false
        )
        let project = model.addProject()
        let task = model.addQuickTask()

        #expect(model.taskCount(for: project) == 1)
        #expect(model.activeTasks.map(\.id) == [task.id])

        model.toggleTask(task)
        #expect(model.taskCount(for: project) == 1)
        #expect(model.activeTasks.isEmpty)

        model.recentSessions = [
            FocusSessionRecord(
                projectID: project.id,
                projectName: project.name,
                mode: .pomodoro,
                startedAt: Date(timeIntervalSince1970: 10),
                endedAt: Date(timeIntervalSince1970: 20),
                plannedSeconds: 20,
                honestFocusSeconds: 15,
                distractionCount: 1
            )
        ]

        #expect(model.dailySummary.sessionsCompleted == 1)
        #expect(model.dailySummary.honestFocusSeconds == 15)
        #expect(model.modeEffectivenessSummaries.first?.mode == .pomodoro)
        #expect(model.projectFocusSummaries.first?.projectID == project.id)
        #expect(model.focusHeatmapValues.count == 28)
    }

    @Test
    @MainActor
    func activeTaskIDPersistsAndClearsWhenScopeChanges() {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let firstLaunch = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        let project = firstLaunch.addProject()
        let task = firstLaunch.addQuickTask()

        let secondLaunch = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)

        #expect(secondLaunch.activeProjectID == project.id)
        #expect(secondLaunch.activeTaskID == task.id)

        secondLaunch.activeProjectID = nil
        #expect(secondLaunch.activeTaskID == nil)

        secondLaunch.selectProject(project)
        secondLaunch.selectTaskForSession(task)
        secondLaunch.deleteTask(task)

        #expect(secondLaunch.activeTaskID == nil)
    }

    @Test
    @MainActor
    func completedSessionAppliesHonestFocusTimeToCapturedTimedTask() throws {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        let project = model.addProject()
        var capturedTask = model.addQuickTask()
        capturedTask.title = "Captured"
        model.updateTask(capturedTask)
        var laterTask = model.addQuickTask()
        laterTask.title = "Later"
        model.updateTask(laterTask)
        model.selectTaskForSession(capturedTask)
        model.selectPreset(
            TimerPreset(
                name: "Two seconds",
                mode: .countdown,
                segments: [TimerSegment(title: "Focus", duration: 2, phase: .focus)]
            )
        )

        model.startTimerForTesting()
        model.selectTaskForSession(laterTask)
        model.advanceTimerForTesting(by: 2)

        let captured = try #require(model.tasks.first { $0.id == capturedTask.id })
        let later = try #require(model.tasks.first { $0.id == laterTask.id })
        let record = try #require(model.recentSessions.first)
        let outcome = try #require(model.pendingSessionOutcome)

        #expect(model.activeProjectID == project.id)
        #expect(captured.completed == 2)
        #expect(later.completed == 0)
        #expect(record.taskID == capturedTask.id)
        #expect(record.taskTitle == "Captured")
        #expect(outcome.record.id == record.id)
        #expect(outcome.task?.id == capturedTask.id)
    }

    @Test
    @MainActor
    func completingOutcomeMarksCapturedTaskDone() throws {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        let task = model.addQuickTask()
        model.selectPreset(
            TimerPreset(
                name: "Two seconds",
                mode: .countdown,
                segments: [TimerSegment(title: "Focus", duration: 2, phase: .focus)]
            )
        )

        model.startTimerForTesting()
        model.advanceTimerForTesting(by: 2)

        #expect(model.pendingSessionOutcome?.record.taskID == task.id)

        model.completeOutcomeTask()

        let completedTask = try #require(model.tasks.first { $0.id == task.id })
        #expect(completedTask.isDone)
        #expect(model.activeTaskID == nil)
        #expect(model.pendingSessionOutcome == nil)
    }

    @Test
    @MainActor
    func checklistTaskDoesNotReceiveSessionTimeProgress() throws {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        var task = model.addQuickTask()
        task.timingMode = .checklist
        model.updateTask(task)
        model.selectPreset(
            TimerPreset(
                name: "Two seconds",
                mode: .countdown,
                segments: [TimerSegment(title: "Focus", duration: 2, phase: .focus)]
            )
        )

        model.startTimerForTesting()
        model.advanceTimerForTesting(by: 2)

        let restored = try #require(model.tasks.first { $0.id == task.id })
        #expect(restored.completed == 0)
        #expect(model.recentSessions.first?.taskID == task.id)
    }

    @Test
    @MainActor
    func continuingOutcomeKeepsChecklistTaskActiveWithoutProgress() throws {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        var task = model.addQuickTask()
        task.timingMode = .checklist
        model.updateTask(task)
        model.selectPreset(
            TimerPreset(
                name: "Two seconds",
                mode: .countdown,
                segments: [TimerSegment(title: "Focus", duration: 2, phase: .focus)]
            )
        )

        model.startTimerForTesting()
        model.advanceTimerForTesting(by: 2)
        model.continueOutcomeTask()

        let restored = try #require(model.tasks.first { $0.id == task.id })
        #expect(restored.completed == 0)
        #expect(!restored.isDone)
        #expect(model.activeTaskID == task.id)
        #expect(model.pendingSessionOutcome == nil)
    }

    @Test
    @MainActor
    func startNextSessionFromOutcomeKeepsCapturedTaskAndRunsTimer() throws {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        let task = model.addQuickTask()
        model.selectPreset(
            TimerPreset(
                name: "Two seconds",
                mode: .countdown,
                segments: [TimerSegment(title: "Focus", duration: 2, phase: .focus)]
            )
        )

        model.startTimerForTesting()
        model.advanceTimerForTesting(by: 2)
        model.startNextSessionFromOutcome()

        #expect(model.pendingSessionOutcome == nil)
        #expect(model.activeTaskID == task.id)
        #expect(model.engineSnapshot.status == .running)
    }

    @Test
    @MainActor
    func strictModeBreakEvaluationFollowsBreakSetting() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        model.strictModeEnabled = true
        model.strictModeEnforcesDuringBreaks = false
        model.selectPreset(
            TimerPreset(
                name: "Focus and break",
                mode: .pomodoro,
                segments: [
                    TimerSegment(title: "Focus", duration: 1, phase: .focus),
                    TimerSegment(title: "Break", duration: 60, phase: .shortBreak)
                ]
            )
        )

        model.startTimerForTesting()
        model.advanceTimerForTesting(by: 1)

        #expect(model.engineSnapshot.activeSegment.phase == .shortBreak)
        #expect(model.strictModeCanEvaluateCurrentPhase == false)

        model.strictModeEnforcesDuringBreaks = true
        #expect(model.strictModeCanEvaluateCurrentPhase == true)
    }

    @Test
    @MainActor
    func pauseSessionDistractionActionPausesRunningTimer() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        model.startTimerForTesting()

        model.applyDistractionResponseForTesting(action: .pauseSession)

        #expect(model.engineSnapshot.status == .paused)
        #expect(model.distractionHistory.first?.action == .pauseSession)
    }

    @Test
    @MainActor
    func distractionHistoryPersistsContextAndLinksCompletedSession() throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        let project = model.addProject()
        let task = model.addQuickTask()
        model.selectPreset(
            TimerPreset(
                name: "Two seconds",
                mode: .countdown,
                segments: [TimerSegment(title: "Focus", duration: 2, phase: .focus)]
            )
        )

        model.startTimerForTesting()
        model.applyDistractionResponseForTesting(action: .warn)
        model.advanceTimerForTesting(by: 2)

        let event = try #require(model.distractionHistory.first)
        let session = try #require(model.recentSessions.first)
        #expect(event.action == .warn)
        #expect(event.sessionID == session.id)
        #expect(event.projectID == project.id)
        #expect(event.projectName == project.name)
        #expect(event.taskID == task.id)
        #expect(event.mode == .countdown)

        let reloaded = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        #expect(reloaded.distractionHistory.first?.id == event.id)
        #expect(reloaded.distractionHistory.first?.sessionID == event.sessionID)
        #expect(reloaded.distractionHistory.first?.projectID == event.projectID)
        #expect(reloaded.distractionHistory.first?.action == event.action)
    }

    @Test
    @MainActor
    func unconfirmedQuitRuleIsRecordedAsSafeHide() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        model.startTimerForTesting()

        model.applyDistractionResponseForTesting(action: .quitAfterOptIn)

        #expect(model.distractionHistory.first?.action == .hide)
    }

    @Test
    @MainActor
    func focusGuardHandlesWarnHideAndPauseRulePaths() {
        let service = FocusGuardService()
        let actions: [DistractionAction] = [.warn, .hide, .pauseSession]

        for action in actions {
            let rule = DistractionRuleSpec(
                label: "QA \(action.rawValue)",
                bundleIdentifier: "local.focusglass.tests.\(action.rawValue)",
                action: action
            )

            #expect(service.handleDistraction(rule: rule))
            #expect(service.lastDistractionMessage != nil)
        }
    }

    @Test
    @MainActor
    func appAndSiteRulesCanBeAddedAndAreSeparated() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)

        model.addAppDistractionRule(label: "Discord", bundleIdentifier: "com.hnc.Discord")
        model.addSiteDistractionRule(pattern: "https://www.youtube.com/feed")

        #expect(model.appRules.count == 1)
        #expect(model.appRules.first?.targetKind == .app)
        #expect(model.appRules.first?.action == .hide)
        #expect(model.siteRules.count == 1)
        #expect(model.siteRules.first?.matchValue == "youtube.com")
        #expect(model.siteRules.first?.matches(siteURL: "music.youtube.com") == true)
    }

    @Test
    @MainActor
    func focusModeLifecycleTracksFullscreenWindowState() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)

        #expect(!model.isFocusModeActive)
        model.enterFocusMode()
        #expect(model.isFocusModeActive)
        model.leaveFocusMode()
        #expect(!model.isFocusModeActive)
    }

    @Test
    @MainActor
    func legacyStateMigratesIntoSplitWorkspaceAndSettingsFiles() {
        let fileURL = temporaryStateURL()
        let store = FocusGlassStore(fileURL: fileURL)
        let project = FocusProject(name: "Persisted", detail: "User data", accentName: "aurora")
        store.save(
            FocusGlassPersistedState(
                schemaVersion: 3,
                selectedThemeID: ThemeProfile.noirCrimsonID,
                themeProfiles: ThemeProfile.builtIn,
                language: .ru,
                strictModeEnabled: true,
                intention: "Keep data",
                activeProjectID: project.id,
                activeProject: project.name,
                projects: [project],
                tasks: [
                    FocusTask(title: "Saved task", projectID: project.id, projectName: project.name, estimate: 25 * 60, completed: 0, isDone: false)
                ],
                distractionRules: [],
                recentSessions: []
            )
        )

        _ = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)

        #expect(FileManager.default.fileExists(atPath: store.paths.legacyStateURL.path))
        #expect(FileManager.default.fileExists(atPath: store.paths.workspaceURL.path))
        #expect(FileManager.default.fileExists(atPath: store.paths.settingsURL.path))
    }

    @Test
    func storagePathsUseCommandLineDataDirectoryOverride() {
        let overridePath = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .path

        let paths = FocusGlassStoragePaths(
            environment: [:],
            arguments: ["FocusGlass", "focusglass-data-dir=\(overridePath)"]
        )

        #expect(paths.dataDirectory.path == overridePath)
        #expect(paths.workspaceURL.path == "\(overridePath)/workspace.json")
        #expect(paths.settingsURL.path == "\(overridePath)/settings.json")
    }

    @Test
    func storagePathsEnvironmentOverrideWinsOverCommandLineOverride() {
        let environmentPath = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .path
        let argumentPath = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .path

        let paths = FocusGlassStoragePaths(
            environment: ["FOCUSGLASS_DATA_DIR": environmentPath],
            arguments: ["FocusGlass", "--focusglass-data-dir=\(argumentPath)"]
        )

        #expect(paths.dataDirectory.path == environmentPath)
    }

    @Test
    @MainActor
    func projectsAndTasksSurviveRelaunchWithSplitStorage() {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let firstLaunch = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        var project = firstLaunch.addProject()
        project.name = "Client Alpha"
        firstLaunch.updateProject(project)
        var task = firstLaunch.addQuickTask()
        task.title = "Write proposal"
        task.projectID = project.id
        firstLaunch.updateTask(task)

        let secondLaunch = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)

        #expect(secondLaunch.projects.map(\.name).contains("Client Alpha"))
        #expect(secondLaunch.tasks.map(\.title).contains("Write proposal"))
        #expect(secondLaunch.tasks.first?.projectID == project.id)
    }

    @Test
    @MainActor
    func corruptedWorkspaceBlocksAutosaveAndCreatesBackup() throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        try FileManager.default.createDirectory(at: store.paths.dataDirectory, withIntermediateDirectories: true)
        try Data("{broken workspace".utf8).write(to: store.paths.workspaceURL)
        try Data("{}".utf8).write(to: store.paths.settingsURL)

        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        model.addProject()

        let files = try FileManager.default.contentsOfDirectory(atPath: store.paths.dataDirectory.path)
        #expect(model.isPersistenceBlocked)
        #expect(files.contains { $0.hasPrefix("workspace.invalid-") })
        #expect((try? String(contentsOf: store.paths.workspaceURL, encoding: .utf8)) == "{broken workspace")
    }

    @Test
    @MainActor
    func corruptedSettingsDoesNotDropWorkspace() throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let project = FocusProject(name: "Workspace survives", detail: "", accentName: "aurora")
        store.save(
            workspace: FocusGlassWorkspaceState(projects: [project]),
            settings: FocusGlassSettingsState()
        )
        try Data("{broken settings".utf8).write(to: store.paths.settingsURL)

        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)

        #expect(!model.isPersistenceBlocked)
        #expect(model.projects.first?.name == "Workspace survives")
        #expect(model.storageWarnings.contains { $0.contains("settings.json") })
    }

    @Test
    @MainActor
    func appearanceModeSystemDoesNotForceColorSchemeAndAdaptsTheme() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        model.appearanceMode = .system

        #expect(model.preferredColorScheme == nil)
        #expect(model.effectiveTheme(for: .light).backgroundTopHex != model.effectiveTheme(for: .dark).backgroundTopHex)
    }

    @Test
    @MainActor
    func singleSegmentPresetCannotSkip() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        let countdown = model.presets.first { $0.id == TimerPreset.countdown30ID }

        if let countdown {
            model.selectPreset(countdown)
        }

        #expect(model.canSkipSegment == false)
    }

    @Test
    @MainActor
    func legacyThemeDecodeDefaultsHighlightHex() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(ThemeProfile.builtIn[0])
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "highlightHex")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(ThemeProfile.self, from: legacyData)

        #expect(decoded.highlightHex == "#FFFFFF")
    }

    @Test
    @MainActor
    func legacyThemeDecodeCreatesExplicitAppearancePalettes() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(ThemeProfile.builtIn[0])
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "lightPalette")
        object.removeValue(forKey: "darkPalette")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(ThemeProfile.self, from: legacyData)

        #expect(decoded.lightPalette != nil)
        #expect(decoded.darkPalette != nil)
        #expect(decoded.resolved(for: .light).backgroundTopHex != decoded.resolved(for: .dark).backgroundTopHex)
    }

    @Test
    @MainActor
    func editingLightPaletteDoesNotRewriteDarkPalette() {
        let model = FocusGlassViewModel(
            store: FocusGlassStore(fileURL: temporaryStateURL()),
            requestPermissionsOnLaunch: false
        )
        let originalDark = model.effectiveTheme(for: .dark).primaryHex

        model.updateActiveThemePalette(for: .light) { palette in
            palette.primaryHex = "#123456"
        }

        #expect(model.effectiveTheme(for: .light).primaryHex == "#123456")
        #expect(model.effectiveTheme(for: .dark).primaryHex == originalDark)
    }

    @Test
    @MainActor
    func invalidImportedThemeColorIsRejected() throws {
        let model = FocusGlassViewModel(
            store: FocusGlassStore(fileURL: temporaryStateURL()),
            requestPermissionsOnLaunch: false
        )
        let initialCount = model.themeProfiles.count
        var profile = ThemeProfile.builtIn[0]
        var light = profile.palette(for: .light)
        light.primaryHex = "not-a-color"
        profile.setPalette(light, for: .light)
        let data = try JSONEncoder().encode(profile)

        #expect(!model.importThemeJSON(data: data))
        #expect(model.themeProfiles.count == initialCount)
    }

    @Test
    @MainActor
    func themeEffectTokensChangeRenderedScales() {
        var low = ThemeProfile.builtIn[0]
        low.glassOpacity = 0
        low.density = 0
        low.motion = 0
        var high = low
        high.glassOpacity = 1
        high.density = 1
        high.motion = 1

        #expect(low.glassStrength < high.glassStrength)
        #expect(low.spacingScale < high.spacingScale)
        #expect(low.motionDurationScale < high.motionDurationScale)
        #expect(low.animationDuration(1) >= 0.8)
        #expect(high.animationDuration(1) <= 1.15)
    }

    @Test
    @MainActor
    func settingsPersistCurrentSchemaVersion() async throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)

        model.updateActiveTheme { profile in
            profile.motion = 0.73
        }
        await model.flushPendingThemeSideEffectsForTesting()

        let data = try Data(contentsOf: store.paths.settingsURL)
        let settings = try JSONDecoder().decode(FocusGlassSettingsState.self, from: data)
        #expect(settings.schemaVersion == 6)
    }

    @Test
    @MainActor
    func highlightHexPersistsToSettingsFileAfterDebouncedFlush() async throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)

        model.updateActiveTheme { profile in
            profile.highlightHex = "#ABCDEF"
        }
        await model.flushPendingThemeSideEffectsForTesting()

        let data = try Data(contentsOf: store.paths.settingsURL)
        let settings = try JSONDecoder().decode(FocusGlassSettingsState.self, from: data)
        let selectedProfile = settings.themeProfiles.first { $0.id == settings.selectedThemeID }

        #expect(selectedProfile?.highlightHex == "#ABCDEF")
    }

    @Test
    @MainActor
    func themeChangeDefersPersistenceAndIconSideEffects() async throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)
        let originalThemeID = model.selectedThemeID
        let nextTheme = try #require(model.themeProfiles.first { $0.id != originalThemeID })

        model.selectTheme(nextTheme)

        #expect(model.selectedThemeID == nextTheme.id)
        #expect(model.isThemeSideEffectPending)
        #expect(model.lastIconStatus == nil)

        let immediateData = try Data(contentsOf: store.paths.settingsURL)
        let immediateSettings = try JSONDecoder().decode(FocusGlassSettingsState.self, from: immediateData)
        #expect(immediateSettings.selectedThemeID == originalThemeID)

        await model.flushPendingThemeSideEffectsForTesting()

        let flushedData = try Data(contentsOf: store.paths.settingsURL)
        let flushedSettings = try JSONDecoder().decode(FocusGlassSettingsState.self, from: flushedData)
        #expect(flushedSettings.selectedThemeID == nextTheme.id)
        #expect(!model.isThemeSideEffectPending)
        #expect(model.lastThemePerformanceMessage != nil)
    }

    @Test
    @MainActor
    func userProtectedBundleLocationsSkipPersistentIconWrites() {
        let home = URL(fileURLWithPath: "/Users/focusglass", isDirectory: true)

        #expect(
            FocusGlassViewModel.isUserConsentProtectedBundleLocation(
                home.appendingPathComponent("Documents/FocusGlass/build/FocusGlass.app", isDirectory: true),
                homeDirectory: home
            )
        )
        #expect(
            FocusGlassViewModel.isUserConsentProtectedBundleLocation(
                home.appendingPathComponent("Desktop/FocusGlass.app", isDirectory: true),
                homeDirectory: home
            )
        )
        #expect(
            FocusGlassViewModel.isUserConsentProtectedBundleLocation(
                home.appendingPathComponent("Downloads/FocusGlass.app", isDirectory: true),
                homeDirectory: home
            )
        )
        #expect(
            !FocusGlassViewModel.isUserConsentProtectedBundleLocation(
                URL(fileURLWithPath: "/Applications/FocusGlass.app", isDirectory: true),
                homeDirectory: home
            )
        )
    }

    @Test
    @MainActor
    func themeSelectionAdvancesAnimatedTransitionToken() throws {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        let initialTransitionID = model.themeTransitionID
        let nextTheme = try #require(model.themeProfiles.first { $0.id != model.selectedThemeID })

        model.selectTheme(nextTheme)

        #expect(model.themeTransitionID == initialTransitionID + 1)
    }

    @Test
    @MainActor
    func editingBuiltInThemeBatchesToSingleTransition() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)
        let initialTransitionID = model.themeTransitionID

        model.updateActiveTheme { profile in
            profile.primaryHex = "#445566"
        }

        #expect(model.themeTransitionID == initialTransitionID + 1)
    }

    @Test
    @MainActor
    func rapidThemeEditsPersistOnlyFinalThemeAfterFlush() async throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        let model = FocusGlassViewModel(store: store, requestPermissionsOnLaunch: false)

        model.updateActiveTheme { profile in
            profile.primaryHex = "#101010"
        }
        let customThemeID = model.selectedThemeID
        model.updateActiveTheme { profile in
            profile.primaryHex = "#202020"
        }
        model.updateActiveTheme { profile in
            profile.primaryHex = "#303030"
        }

        let immediateData = try Data(contentsOf: store.paths.settingsURL)
        let immediateSettings = try JSONDecoder().decode(FocusGlassSettingsState.self, from: immediateData)
        #expect(immediateSettings.selectedThemeID != customThemeID)

        await model.flushPendingThemeSideEffectsForTesting()

        let flushedData = try Data(contentsOf: store.paths.settingsURL)
        let flushedSettings = try JSONDecoder().decode(FocusGlassSettingsState.self, from: flushedData)
        let selectedProfile = flushedSettings.themeProfiles.first { $0.id == flushedSettings.selectedThemeID }

        #expect(flushedSettings.selectedThemeID == customThemeID)
        #expect(selectedProfile?.primaryHex == "#303030")
    }

    @Test
    @MainActor
    func effectiveThemePreservesHighlightHex() {
        let model = FocusGlassViewModel(store: FocusGlassStore(fileURL: temporaryStateURL()), requestPermissionsOnLaunch: false)

        model.updateActiveTheme { profile in
            profile.highlightHex = "#112233"
        }

        #expect(model.effectiveTheme(for: .light).highlightHex == "#112233")
        #expect(model.effectiveTheme(for: .dark).highlightHex == "#112233")
    }

    @Test
    @MainActor
    func reusableMainWindowFindsExistingFocusGlassWindow() {
        let focusWindow = NSWindow()
        focusWindow.title = "FocusGlass"
        let identifiedWindow = NSWindow()
        identifiedWindow.identifier = FocusGlassViewModel.mainWindowIdentifier
        let otherWindow = NSWindow()
        otherWindow.title = "Other"

        #expect(FocusGlassViewModel.reusableMainWindow(in: [otherWindow, focusWindow]) === focusWindow)
        #expect(FocusGlassViewModel.reusableMainWindow(in: [focusWindow, identifiedWindow]) === identifiedWindow)
        #expect(FocusGlassViewModel.reusableMainWindow(in: [otherWindow]) == nil)
    }

    @Test
    @MainActor
    func workspaceWriteFailureUpdatesSaveStatus() throws {
        let store = FocusGlassStore(fileURL: temporaryStateURL())
        try FileManager.default.createDirectory(at: store.paths.workspaceURL, withIntermediateDirectories: true)

        store.save(workspace: FocusGlassWorkspaceState(), settings: FocusGlassSettingsState())

        #expect(store.lastSaveStatus?.isError == true)
    }

    private func temporaryStateURL() -> URL {
        FileManager.default
            .temporaryDirectory
            .appendingPathComponent("FocusGlassTests-\(UUID().uuidString)")
            .appendingPathComponent("state.json")
    }
}
