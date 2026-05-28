import SwiftUI
import FocusGlassCore

struct SettingsView: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        ScrollView {
            SettingsContentView(showsHeader: true)
            .padding(26)
        }
        .background(model.theme.background)
        .foregroundStyle(model.theme.text)
    }
}

struct SettingsContentView: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var selectedTab: SettingsTab = .general
    var showsHeader = true

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            if showsHeader {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.t("settings.title"))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text(model.t("settings.subtitle"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(model.theme.mutedText)
                }
            }

            GlassSegmentedControl(
                selection: $selectedTab,
                options: SettingsTab.allCases,
                title: { model.t($0.titleKey) },
                symbol: { $0.symbolName }
            )

            SettingsTabSummary(tab: selectedTab)

            switch selectedTab {
            case .general:
                GeneralSettingsSection()
            case .timers:
                PresetSettingsSection()
            case .strictMode:
                StrictModeSettingsSection()
            case .permissions:
                PermissionsAutomationSettingsSection()
            case .appearance:
                ThemeStudioView()
            }
        }
    }
}

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case timers
    case strictMode
    case permissions
    case appearance

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .general: "settings.tab.general"
        case .timers: "settings.tab.timers"
        case .strictMode: "settings.tab.strict"
        case .permissions: "settings.tab.permissions"
        case .appearance: "settings.tab.appearance"
        }
    }

    var symbolName: String {
        switch self {
        case .general: "gearshape"
        case .timers: "timer"
        case .strictMode: "shield"
        case .permissions: "checkmark.seal"
        case .appearance: "paintpalette"
        }
    }

    var detailKey: String {
        switch self {
        case .general: "settings.tab.general.detail"
        case .timers: "settings.tab.timers.detail"
        case .strictMode: "settings.tab.strict.detail"
        case .permissions: "settings.tab.permissions.detail"
        case .appearance: "settings.tab.appearance.detail"
        }
    }
}

private struct SettingsTabSummary: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    let tab: SettingsTab

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: tab.symbolName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(model.theme.primary)
                .frame(width: 28, height: 28)
                .background(model.theme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(model.t(tab.titleKey))
                    .font(.system(size: 13, weight: .bold))
                Text(model.t(tab.detailKey))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(model.theme.highlight.opacity(model.theme.borderOpacity * 0.62), lineWidth: 1)
        }
    }
}

private struct GeneralSettingsSection: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 18) {
                LiquidGlassPanel(radius: 18) {
                    VStack(alignment: .leading, spacing: 16) {
                        SettingsSectionHeader(title: model.t("settings.general"), detail: model.t("settings.general.detail"))

                        SettingsPickerRow(title: model.t("settings.language"), detail: model.t("settings.language.detail")) {
                            GlassSelect(
                                selection: $model.language,
                                options: AppLanguage.allCases,
                                title: model.languageTitle,
                                symbol: languageSymbol,
                                minWidth: 210
                            )
                            .help(model.t("help.language"))
                        }

                        SettingsPickerRow(title: model.t("appearance.title"), detail: model.t("appearance.detail")) {
                            GlassSelect(
                                selection: appearanceBinding,
                                options: AppAppearanceMode.allCases,
                                title: model.appearanceModeTitle,
                                symbol: appearanceSymbol,
                                minWidth: 210
                            )
                            .help(model.t("help.appearance"))
                        }
                    }
                }

                DataStorageSection()
            }

            VStack(alignment: .leading, spacing: 18) {
                LiquidGlassPanel(radius: 18) {
                    VStack(alignment: .leading, spacing: 16) {
                        SettingsSectionHeader(title: model.t("settings.general"), detail: model.t("settings.general.detail"))
                        SettingsPickerRow(title: model.t("settings.language"), detail: model.t("settings.language.detail")) {
                            GlassSelect(
                                selection: $model.language,
                                options: AppLanguage.allCases,
                                title: model.languageTitle,
                                symbol: languageSymbol,
                                minWidth: 210
                            )
                            .help(model.t("help.language"))
                        }
                        SettingsPickerRow(title: model.t("appearance.title"), detail: model.t("appearance.detail")) {
                            GlassSelect(
                                selection: appearanceBinding,
                                options: AppAppearanceMode.allCases,
                                title: model.appearanceModeTitle,
                                symbol: appearanceSymbol,
                                minWidth: 210
                            )
                            .help(model.t("help.appearance"))
                        }
                    }
                }
                DataStorageSection()
            }
        }
    }

    private var appearanceBinding: Binding<AppAppearanceMode> {
        Binding(
            get: { model.appearanceMode },
            set: { model.setAppearanceMode($0) }
        )
    }

    private func languageSymbol(_ language: AppLanguage) -> String? {
        switch language {
        case .ru: "textformat"
        case .en: "character"
        case .system: "globe"
        }
    }

    private func appearanceSymbol(_ mode: AppAppearanceMode) -> String? {
        switch mode {
        case .system: "macwindow"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
}

private struct SettingsSectionHeader: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
            Text(detail)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(model.theme.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SettingsPickerRow<Accessory: View>: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    let title: String
    let detail: String
    let accessory: Accessory

    init(title: String, detail: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.detail = detail
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
            }
            Spacer()
            accessory
        }
        .padding(12)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DataStorageSection: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        LiquidGlassPanel(radius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                SettingsSectionHeader(title: model.t("storage.title"), detail: model.t("storage.detail"))

                HStack(spacing: 10) {
                    Image(systemName: model.isPersistenceBlocked ? "externaldrive.badge.exclamationmark" : "externaldrive.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(model.isPersistenceBlocked ? model.theme.strict : model.theme.primary)
                        .frame(width: 34, height: 34)
                        .background((model.isPersistenceBlocked ? model.theme.strict : model.theme.primary).opacity(0.13), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.storageStatusTitle)
                            .font(.system(size: 13, weight: .bold))
                        Text(model.dataDirectoryPath)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(model.theme.mutedText)
                            .lineLimit(2)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("workspace.json")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Text(model.workspacePath)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(model.theme.mutedText)
                        .lineLimit(2)
                    Text("settings.json")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Text(model.settingsPath)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(model.theme.mutedText)
                        .lineLimit(2)
                }
                .padding(12)
                .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if !model.storageWarnings.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(model.storageWarnings, id: \.self) { warning in
                            Label(warning, systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(model.theme.strict)
                        }
                    }
                }

                Button {
                    model.openDataDirectory()
                } label: {
                    Label(model.t("storage.openFolder"), systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                .help(model.dataDirectoryPath)
            }
        }
    }
}

private struct PresetSettingsSection: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var editingPresetID: UUID?

    private var activePresetID: UUID {
        editingPresetID ?? model.selectedPresetID
    }

    private var activePreset: TimerPreset? {
        model.presets.first { $0.id == activePresetID }
    }

    var body: some View {
        LiquidGlassPanel(radius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.t("presets.title"))
                            .font(.system(size: 15, weight: .bold))
                        Text(model.t("presets.settings.detail"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(model.theme.mutedText)
                    }
                    Spacer()
                    if let activePreset {
                        Button {
                            model.resetPresetToDefault(activePreset.id)
                            editingPresetID = model.selectedPresetID
                        } label: {
                            Label(model.t("presets.resetCurrent"), systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                        .help(model.t("help.presetReset"))
                    }
                }

                Text(model.t("presets.resetHint"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    ForEach(model.presets) { preset in
                        ModeChip(
                            title: model.presetTitle(preset),
                            symbolName: preset.mode.symbolName,
                            isSelected: preset.id == model.selectedPreset.id,
                            accent: model.theme.primary
                        ) {
                            editingPresetID = preset.id
                            model.selectPreset(preset)
                        }
                    }
                }

                if let preset = activePreset {
                    PresetEditor(preset: preset)
                }
            }
        }
        .onAppear {
            editingPresetID = model.selectedPresetID
        }
    }
}

private struct PresetEditor: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    let preset: TimerPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider().opacity(0.16)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.t("presets.name"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                    TextField(model.t("presets.name"), text: nameBinding)
                        .textFieldStyle(GlassTextFieldStyle(theme: model.theme))
                        .help(model.t("presets.name"))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(model.t("presets.mode"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                    GlassSelect(
                        selection: modeBinding,
                        options: TimerMode.allCases,
                        title: model.timerModeTitle,
                        symbol: { $0.symbolName },
                        minWidth: 230
                    )
                    .help(model.t("presets.mode"))
                }
                .frame(minWidth: 230)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(model.t("presets.segments.editor"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                    Spacer()
                    Button {
                        model.addPresetSegment(to: preset.id)
                    } label: {
                        Label(model.t("presets.addSegment"), systemImage: "plus")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                }

                ForEach(Array(preset.segments.enumerated()), id: \.element.id) { index, segment in
                    PresetSegmentEditor(presetID: preset.id, index: index, segment: segment, canDelete: preset.segments.count > 1)
                }
            }
        }
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { model.presets.first { $0.id == preset.id }?.name ?? "" },
            set: { newValue in
                model.updatePreset(preset.id) { $0.name = newValue }
            }
        )
    }

    private var modeBinding: Binding<TimerMode> {
        Binding(
            get: { model.presets.first { $0.id == preset.id }?.mode ?? preset.mode },
            set: { newValue in
                model.updatePreset(preset.id) { $0.mode = newValue }
            }
        )
    }
}

private struct PresetSegmentEditor: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    let presetID: UUID
    let index: Int
    let segment: TimerSegment
    let canDelete: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TextField(model.t("presets.segmentName"), text: titleBinding)
                    .textFieldStyle(GlassTextFieldStyle(theme: model.theme))
                    .help(model.t("presets.segmentName"))

                GlassSelect(
                    selection: phaseBinding,
                    options: [TimerPhase.warmUp, .focus, .shortBreak, .longBreak, .coolDown, .review],
                    title: model.phaseTitle,
                    symbol: { phaseSymbol($0) },
                    minWidth: 190
                )
                .help(model.t("presets.phase"))

                GlassStepper(value: minutesBinding, range: 0...240, step: 5) { value in
                    "\(value) \(model.t("tasks.minutes"))"
                }
                .help(model.t("tasks.estimate"))

                Button {
                    model.deletePresetSegment(presetID, index: index)
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
                .disabled(!canDelete)
            }

            Toggle(model.t("presets.autoStartNext"), isOn: autoStartBinding)
                .toggleStyle(GlassCheckboxToggleStyle(theme: model.theme))
                .font(.system(size: 11, weight: .semibold))
                .help(model.t("presets.autoStartNext"))
        }
        .padding(12)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { segment.title },
            set: { newValue in
                model.updatePresetSegment(presetID, index: index) { $0.title = newValue }
            }
        )
    }

    private var phaseBinding: Binding<TimerPhase> {
        Binding(
            get: { segment.phase },
            set: { newValue in
                model.updatePresetSegment(presetID, index: index) { $0.phase = newValue }
            }
        )
    }

    private var minutesBinding: Binding<Int> {
        Binding(
            get: { Int((segment.duration / 60).rounded()) },
            set: { newValue in
                model.updatePresetSegment(presetID, index: index) { $0.duration = TimeInterval(max(0, newValue) * 60) }
            }
        )
    }

    private var autoStartBinding: Binding<Bool> {
        Binding(
            get: { segment.autoStartNext },
            set: { newValue in
                model.updatePresetSegment(presetID, index: index) { $0.autoStartNext = newValue }
            }
        )
    }

    private func phaseSymbol(_ phase: TimerPhase) -> String? {
        switch phase {
        case .idle: "pause.circle"
        case .warmUp: "flame"
        case .focus: "scope"
        case .shortBreak: "cup.and.saucer"
        case .longBreak: "leaf"
        case .coolDown: "snowflake"
        case .review: "checklist"
        }
    }
}

private struct StrictModeSettingsSection: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        LiquidGlassPanel(radius: 18) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    SettingsSectionHeader(title: model.t("strict.title"), detail: model.t("strict.fullscreenOnly"))
                    Spacer()
                    Toggle("", isOn: $model.strictModeEnabled)
                        .toggleStyle(GlassCheckboxToggleStyle(theme: model.theme))
                        .labelsHidden()
                        .help(model.t("help.strictMode"))
                }

                StrictRulesEditor()
            }
        }
    }
}

private struct PermissionsAutomationSettingsSection: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        LiquidGlassPanel(radius: 18) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeader(title: model.t("settings.permissions"), detail: model.t("settings.permissions.detail"))

                PermissionSetupSection()

                Divider().opacity(0.16)

                AutomationSetupSection()
            }
        }
        .onAppear {
            model.focusGuard.refreshPermissionStates()
        }
    }
}

private struct StrictRulesEditor: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.t("strict.rules"))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(model.theme.mutedText)

            StrictRuleGroup(
                title: model.t("strict.apps"),
                emptyTitle: model.t("strict.apps.empty.title"),
                emptyDetail: model.t("strict.apps.empty.detail"),
                rules: model.appRules
            )

            AddAppRuleControls()

            StrictRuleGroup(
                title: model.t("strict.sites"),
                emptyTitle: model.t("strict.sites.empty.title"),
                emptyDetail: model.t("strict.sites.empty.detail"),
                rules: model.siteRules
            )

            AddSiteRuleControls()
        }
    }
}

private struct StrictRuleGroup: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    let title: String
    let emptyTitle: String
    let emptyDetail: String
    let rules: [DistractionRuleSpec]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(model.theme.text)

            if rules.isEmpty {
                EmptyInlineState(symbol: "shield.slash", title: emptyTitle, detail: emptyDetail)
            } else {
                ForEach(rules) { rule in
                    StrictRuleRow(rule: rule)
                }
            }
        }
    }
}

private struct StrictRuleRow: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    let rule: DistractionRuleSpec

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: enabledBinding)
                .toggleStyle(GlassCheckboxToggleStyle(theme: model.theme))
                .labelsHidden()

            Image(systemName: rule.targetKind == .app ? "app.badge" : "globe")
                .frame(width: 22)
                .foregroundStyle(rule.isEnabled ? model.theme.primary : model.theme.mutedText)

            VStack(alignment: .leading, spacing: 3) {
                Text(rule.label)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                Text(rule.matchValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
                    .lineLimit(1)
            }

            Spacer()

            GlassSelect(
                selection: actionBinding,
                options: DistractionAction.allCases,
                title: model.actionTitle,
                symbol: actionSymbol,
                minWidth: 230
            )
            .help(model.t("help.strictRuleAction"))

            Button {
                model.deleteRule(rule)
            } label: {
                Image(systemName: "trash")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
        }
        .padding(12)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { rule.isEnabled },
            set: { newValue in
                var updated = rule
                updated.isEnabled = newValue
                model.updateRule(updated)
            }
        )
    }

    private var actionBinding: Binding<DistractionAction> {
        Binding(
            get: { rule.action },
            set: { newValue in
                var updated = rule
                updated.action = newValue
                model.updateRule(updated)
            }
        )
    }

    private func actionSymbol(_ action: DistractionAction) -> String? {
        switch action {
        case .warn: "exclamationmark.triangle"
        case .hide: "eye.slash"
        case .pauseSession: "pause.circle"
        case .quitAfterOptIn: "xmark.circle"
        }
    }
}

private struct AddAppRuleControls: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var customLabel = ""
    @State private var customBundleID = ""
    @State private var showsRunningApps = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showsRunningApps.toggle()
            } label: {
                Label(model.t("strict.addRunningApp"), systemImage: "plus")
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
            .help(model.t("help.strictApps"))
            .popover(isPresented: $showsRunningApps, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(model.availableDistractionApps) { app in
                        Button {
                            model.addAppDistractionRule(label: app.label, bundleIdentifier: app.bundleIdentifier)
                            showsRunningApps = false
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(app.label)
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(1)
                                Text(app.bundleIdentifier)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(model.theme.mutedText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 9)
                            .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .glassHover(theme: model.theme, radius: 10)
                    }
                }
                .padding(8)
                .frame(width: 330)
                .background(model.theme.background)
                .foregroundStyle(model.theme.text)
            }

            HStack(spacing: 8) {
                TextField(model.t("strict.appName.placeholder"), text: $customLabel)
                    .textFieldStyle(GlassTextFieldStyle(theme: model.theme))
                TextField(model.t("strict.bundle.placeholder"), text: $customBundleID)
                    .textFieldStyle(GlassTextFieldStyle(theme: model.theme))
                Button(model.t("strict.addApp")) {
                    model.addAppDistractionRule(label: customLabel, bundleIdentifier: customBundleID)
                    customLabel = ""
                    customBundleID = ""
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                .help(model.t("help.strictApps"))
            }
        }
    }
}

private struct AddSiteRuleControls: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var sitePattern = ""

    var body: some View {
        HStack(spacing: 8) {
            TextField(model.t("strict.site.placeholder"), text: $sitePattern)
                .textFieldStyle(GlassTextFieldStyle(theme: model.theme))
            Button {
                model.addSiteDistractionRule(pattern: sitePattern)
                sitePattern = ""
            } label: {
                Label(model.t("strict.addSite"), systemImage: "plus")
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
            .help(model.t("help.strictSites"))
        }
    }
}

private struct PermissionSetupSection: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.t("settings.permissions"))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(model.theme.mutedText)

            if let message = model.focusGuard.lastPermissionMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(model.theme.strict)
                    Text(message)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(model.theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(11)
                .background(model.theme.strict.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(model.theme.strict.opacity(0.22), lineWidth: 1)
                }
            }

            ForEach(FocusPermission.allCases) { permission in
                PermissionSetupRow(permission: permission)
            }
        }
    }
}

private struct PermissionSetupRow: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    let permission: FocusPermission

    private var status: FocusPermissionStatus {
        model.focusGuard.status(for: permission)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusSymbol)
                .foregroundStyle(statusColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(model.permissionTitle(permission))
                    .font(.system(size: 13, weight: .semibold))
                Text(model.permissionStatusTitle(status))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
            }
            Spacer()
            permissionButton
        }
        .padding(11)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private var statusSymbol: String {
        switch status {
        case .granted: "checkmark.circle.fill"
        case .missing: "exclamationmark.circle.fill"
        case .unavailable: "xmark.circle"
        case .unknown: "clock"
        }
    }

    private var statusColor: Color {
        switch status {
        case .granted, .missing: model.theme.primary
        case .unavailable, .unknown: model.theme.mutedText
        }
    }

    @ViewBuilder
    private var permissionButton: some View {
        switch permission {
        case .notifications:
            Button(model.t("settings.requestNotifications")) {
                model.focusGuard.requestNotifications()
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
            .disabled(status == .granted || status == .unavailable)
            .help(model.t("help.notifications"))
        case .accessibility:
            Button(model.t("settings.requestAccessibility")) {
                model.requestAccessibilityPermission()
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
            .disabled(status == .granted)
            .help(model.t("help.accessibility"))
        case .automation:
            Button(model.t("settings.requestAutomation")) {
                model.requestAutomationPermission()
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
            .disabled(status == .granted || status == .unavailable)
            .help(model.t("help.automation"))
        case .launchAtLogin:
            Button(status == .granted ? model.t("settings.disableLaunchAtLogin") : model.t("settings.enableLaunchAtLogin")) {
                model.toggleLaunchAtLogin()
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
            .help(model.t("help.launchAtLogin"))
        }
    }
}

struct ThemeStudioView: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var showsAdvanced = false

    var body: some View {
        LiquidGlassPanel(radius: 22, padding: 18) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.t("theme.title"))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(model.t("theme.subtitle"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(model.theme.mutedText)
                    }
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                    ForEach(model.themeProfiles) { profile in
                        ThemeSwatch(profile: profile, isSelected: profile.id == model.selectedThemeID) {
                            model.selectTheme(profile)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        model.duplicateActiveTheme()
                    } label: {
                        Label(model.t("theme.duplicate"), systemImage: "plus.square.on.square")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                    .help(model.t("help.themeDuplicate"))

                    Button {
                        model.resetActiveTheme()
                    } label: {
                        Label(model.t("theme.reset"), systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                    .help(model.t("help.themeReset"))

                    Button {
                        model.exportActiveThemeJSON()
                    } label: {
                        Label(model.t("theme.export"), systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                    .help(model.t("help.themeExport"))

                    Button {
                        model.importThemeJSONFromClipboard()
                    } label: {
                        Label(model.t("theme.import"), systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                    .help(model.t("help.themeImport"))

                    if let message = model.lastThemeMessage {
                        Text(message)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(model.theme.mutedText)
                    }

                    if let iconStatus = model.lastIconStatus {
                        Text(iconStatus)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(model.theme.mutedText)
                    }

                    if model.isThemeSideEffectPending {
                        Text(model.t("theme.saving"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(model.theme.mutedText)
                    } else if let performance = model.lastThemePerformanceMessage {
                        Text(performance)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(model.theme.mutedText)
                            .help(model.t("help.themePerformance"))
                    }
                }

                DisclosureGroup(model.t("theme.advancedColors"), isExpanded: $showsAdvanced) {
                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 13) {
                            Text(model.t("theme.editor"))
                                .font(.system(size: 15, weight: .bold))

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)], spacing: 10) {
                                ThemeHexField(title: model.t("theme.primary"), value: hexBinding(\.primaryHex), swatch: model.theme.primary)
                                ThemeHexField(title: model.t("theme.secondary"), value: hexBinding(\.secondaryHex), swatch: model.theme.secondary)
                                ThemeHexField(title: model.t("theme.glow"), value: hexBinding(\.glowHex), swatch: model.theme.glow)
                                ThemeHexField(title: model.t("theme.backgroundTop"), value: hexBinding(\.backgroundTopHex), swatch: Color(hex: model.selectedThemeProfile.backgroundTopHex))
                                ThemeHexField(title: model.t("theme.backgroundMid"), value: hexBinding(\.backgroundMidHex), swatch: Color(hex: model.selectedThemeProfile.backgroundMidHex))
                                ThemeHexField(title: model.t("theme.backgroundBottom"), value: hexBinding(\.backgroundBottomHex), swatch: Color(hex: model.selectedThemeProfile.backgroundBottomHex))
                                ThemeHexField(title: model.t("theme.surface"), value: hexBinding(\.surfaceHex), swatch: Color(hex: model.selectedThemeProfile.surfaceHex))
                                ThemeHexField(title: model.t("theme.elevatedSurface"), value: hexBinding(\.elevatedSurfaceHex), swatch: Color(hex: model.selectedThemeProfile.elevatedSurfaceHex))
                                ThemeHexField(title: model.t("theme.text"), value: hexBinding(\.textHex), swatch: Color(hex: model.selectedThemeProfile.textHex))
                                ThemeHexField(title: model.t("theme.muted"), value: hexBinding(\.mutedTextHex), swatch: Color(hex: model.selectedThemeProfile.mutedTextHex))
                                ThemeHexField(title: model.t("theme.ringStart"), value: hexBinding(\.timerRingStartHex), swatch: Color(hex: model.selectedThemeProfile.timerRingStartHex))
                                ThemeHexField(title: model.t("theme.ringEnd"), value: hexBinding(\.timerRingEndHex), swatch: Color(hex: model.selectedThemeProfile.timerRingEndHex))
                                ThemeHexField(title: model.t("theme.heatmapLow"), value: hexBinding(\.heatmapLowHex), swatch: Color(hex: model.selectedThemeProfile.heatmapLowHex))
                                ThemeHexField(title: model.t("theme.heatmapHigh"), value: hexBinding(\.heatmapHighHex), swatch: Color(hex: model.selectedThemeProfile.heatmapHighHex))
                                ThemeHexField(title: model.t("theme.strict"), value: hexBinding(\.strictHex), swatch: Color(hex: model.selectedThemeProfile.strictHex))
                                ThemeHexField(title: model.t("theme.highlightColor"), value: hexBinding(\.highlightHex), swatch: Color(hex: model.selectedThemeProfile.highlightHex))
                            }

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
                                ThemeSliderField(title: model.t("theme.glass"), value: doubleBinding(\.glassOpacity), range: 0.2...0.9)
                                ThemeSliderField(title: model.t("theme.menuGlass"), value: doubleBinding(\.menuGlassOpacity), range: 0.2...0.95)
                                ThemeSliderField(title: model.t("theme.surfaceAlpha"), value: doubleBinding(\.surfaceAlpha), range: 0.08...0.60)
                                ThemeSliderField(title: model.t("theme.highlightAlpha"), value: doubleBinding(\.highlightAlpha), range: 0.04...0.60)
                                ThemeSliderField(title: model.t("theme.specularOpacity"), value: doubleBinding(\.specularOpacity), range: 0.04...0.70)
                                ThemeSliderField(title: model.t("theme.blurIntensity"), value: doubleBinding(\.blurIntensity), range: 0.20...1.00)
                                ThemeSliderField(title: model.t("theme.fullscreenGlow"), value: doubleBinding(\.fullscreenGlowIntensity), range: 0...1)
                                ThemeSliderField(title: model.t("theme.radius"), value: doubleBinding(\.cornerRadius), range: 8...28)
                                ThemeSliderField(title: model.t("theme.border"), value: doubleBinding(\.borderOpacity), range: 0...0.5)
                                ThemeSliderField(title: model.t("theme.shadow"), value: doubleBinding(\.shadowDepth), range: 0...0.65)
                                ThemeSliderField(title: model.t("theme.density"), value: doubleBinding(\.density), range: 0...1)
                                ThemeSliderField(title: model.t("theme.motion"), value: doubleBinding(\.motion), range: 0...1)
                            }
                        }

                        ThemePreviewCard()
                            .frame(width: 260)
                    }
                }
                .font(.system(size: 13, weight: .bold))
            }
        }
    }

    private func hexBinding(_ keyPath: WritableKeyPath<ThemeProfile, String>) -> Binding<String> {
        Binding(
            get: { model.selectedThemeProfile[keyPath: keyPath] },
            set: { value in
                model.updateActiveTheme { profile in
                    profile[keyPath: keyPath] = normalizeHex(value)
                }
            }
        )
    }

    private func doubleBinding(_ keyPath: WritableKeyPath<ThemeProfile, Double>) -> Binding<Double> {
        Binding(
            get: { model.selectedThemeProfile[keyPath: keyPath] },
            set: { value in
                model.updateActiveTheme { profile in
                    profile[keyPath: keyPath] = value
                }
            }
        )
    }

    private func normalizeHex(_ value: String) -> String {
        let cleaned = value.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard !cleaned.isEmpty else { return "#" }
        return "#\(cleaned.prefix(6))"
    }
}

private struct ThemeHexField: View {
    let title: String
    @Binding var value: String
    let swatch: Color

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(swatch)
                .frame(width: 24, height: 24)
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                TextField("#FFFFFF", text: $value)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
            }
        }
        .padding(9)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ThemeSliderField: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
        }
        .padding(10)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ThemePreviewCard: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.t("theme.preview"))
                .font(.system(size: 14, weight: .bold))

            RoundedRectangle(cornerRadius: CGFloat(model.theme.cornerRadius), style: .continuous)
                .fill(model.theme.background)
                .frame(height: 120)
                .overlay {
                    VStack(spacing: 10) {
                        CircularTimerView(
                            clockText: "25:00",
                            phase: model.t("timer.phase.focus"),
                            progress: 0.68,
                            theme: model.theme,
                            statusText: model.t("timer.status.running"),
                            size: 86,
                            clockSize: 18
                        )
                        Text(model.theme.name)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: CGFloat(model.theme.cornerRadius), style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(model.t("theme.appliesTo"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                Label(model.t("theme.surface.mainWindow"), systemImage: "macwindow")
                Label(model.t("theme.surface.menuBar"), systemImage: "menubar.rectangle")
                Label(model.t("theme.surface.fullscreen"), systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .font(.system(size: 11, weight: .semibold))
        }
        .padding(14)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AutomationSetupSection: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    private var status: FocusPermissionStatus {
        model.focusGuard.status(for: .automation)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.t("settings.automation"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                    Text(model.t("permissions.automationHint"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(model.theme.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Label(model.permissionStatusTitle(status), systemImage: statusSymbol)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.12), in: Capsule())

                    Button {
                        model.requestAutomationPermission()
                    } label: {
                        Label(model.t("automation.checkAccess"), systemImage: "bolt.badge.checkmark")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                    .disabled(status == .unavailable)
                    .help(model.t("help.automation"))
                }
            }

            Text(model.t("automation.shortcuts.detail"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(model.theme.mutedText)
                .fixedSize(horizontal: false, vertical: true)

            if let message = model.focusGuard.lastAutomationMessage {
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(model.theme.primary)
                    Text(message)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(model.theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(model.theme.primary.opacity(0.11), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(model.theme.primary.opacity(0.20), lineWidth: 1)
                }
            }

            Text(model.t("settings.shortcuts"))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(model.theme.mutedText)

            AutomationHookRow(event: "onStart", title: model.t("hooks.start"), shortcut: "FocusGlass Start")
            AutomationHookRow(event: "onPause", title: model.t("hooks.pause"), shortcut: "FocusGlass Pause")
            AutomationHookRow(event: "onResume", title: model.t("hooks.resume"), shortcut: "FocusGlass Resume")
            AutomationHookRow(event: "onEnd", title: model.t("hooks.end"), shortcut: "FocusGlass End")
        }
    }

    private var statusSymbol: String {
        switch status {
        case .granted: "checkmark.circle.fill"
        case .missing: "exclamationmark.circle.fill"
        case .unknown: "clock"
        case .unavailable: "xmark.circle"
        }
    }

    private var statusColor: Color {
        switch status {
        case .granted: model.theme.primary
        case .missing: model.theme.strict
        case .unknown, .unavailable: model.theme.mutedText
        }
    }
}

private struct AutomationHookRow: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    let event: String
    let title: String
    let shortcut: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                HStack(spacing: 7) {
                    Text(event)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(model.theme.mutedText)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(model.theme.surface.opacity(0.36), in: Capsule())
                    Text(shortcut)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(model.theme.mutedText)
                }
            }
            Spacer()
            Button {
                model.focusGuard.runShortcut(named: shortcut)
            } label: {
                Label(model.t("automation.runShortcut"), systemImage: "play.fill")
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
            .help(shortcut)
        }
        .padding(11)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
