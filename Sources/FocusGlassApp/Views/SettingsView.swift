import SwiftUI
import FocusGlassCore
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    var body: some View {
        FocusGlassScrollView {
            LazyVStack {
                SettingsContentView(showsHeader: true)
            }
            .padding(26)
        }
        .background(model.theme.background)
        .foregroundStyle(model.theme.text)
    }
}

struct SettingsContentView: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.focusGlassMotion) private var motion
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
                selection: $model.selectedSettingsTab,
                options: SettingsTab.allCases,
                title: { model.t($0.titleKey) },
                symbol: { $0.symbolName }
            )

            SettingsTabSummary(tab: model.selectedSettingsTab)

            Group {
                switch model.selectedSettingsTab {
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
            .id(model.selectedSettingsTab)
            .transition(motion.transition(.content))
            .animation(motion.animation(.navigation), value: model.selectedSettingsTab)
        }
    }
}

enum SettingsTab: String, CaseIterable, Identifiable {
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
                        .help(model.timerModeDescription(preset.mode))
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
    @Environment(\.focusGlassMotion) private var motion
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

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: preset.mode.symbolName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(model.theme.primary)
                    .frame(width: 28, height: 28)
                    .background(model.theme.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.timerModeTitle(preset.mode))
                        .font(.system(size: 12, weight: .bold))
                    Text(model.timerModeDescription(preset.mode))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(model.theme.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(model.theme.highlight.opacity(model.theme.borderOpacity * 0.58), lineWidth: 1)
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
                        .transition(motion.transition(.listItem))
                }
                .animation(motion.animation(.disclosure), value: preset.segments.map(\.id))
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
                    .layoutPriority(1)

                GlassSelect(
                    selection: phaseBinding,
                    options: [TimerPhase.warmUp, .focus, .shortBreak, .longBreak, .coolDown, .review],
                    title: model.phaseTitle,
                    symbol: { phaseSymbol($0) },
                    minWidth: 190
                )
                .help(model.t("presets.phase"))

                Button {
                    model.deletePresetSegment(presetID, index: index)
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
                .disabled(!canDelete)
            }

            HStack(spacing: 10) {
                Label(model.t("tasks.minutes"), systemImage: "timer")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                    .frame(minWidth: 76, alignment: .leading)

                GlassStepper(value: minutesBinding, range: 0...240, step: 5) { value in
                    "\(value) \(model.t("tasks.minutes"))"
                }
                .help(model.t("tasks.estimate"))

                GlassMinuteInputField(value: minutesBinding, range: 0...240)

                Spacer(minLength: 0)
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

                HStack(spacing: 10) {
                    Image(systemName: "cup.and.saucer")
                        .frame(width: 24)
                        .foregroundStyle(model.theme.primary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.t("strict.enforceDuringBreaks"))
                            .font(.system(size: 13, weight: .bold))
                        Text(model.t("strict.enforceDuringBreaks.detail"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(model.theme.mutedText)
                    }
                    Spacer()
                    Toggle("", isOn: $model.strictModeEnforcesDuringBreaks)
                        .toggleStyle(GlassCheckboxToggleStyle(theme: model.theme))
                        .labelsHidden()
                        .help(model.t("help.strictBreaks"))
                }
                .padding(12)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

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
    @Environment(\.focusGlassMotion) private var motion

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
                        .transition(motion.transition(.listItem))
                }
            }
        }
        .animation(motion.animation(.disclosure), value: rules.map(\.id))
    }
}

private struct StrictRuleRow: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @State private var asksQuitConfirmation = false
    let rule: DistractionRuleSpec

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                ruleIdentity
                Spacer(minLength: 12)
                actionControls
            }

            VStack(alignment: .leading, spacing: 10) {
                ruleIdentity
                HStack(spacing: 10) {
                    actionControls
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .confirmationDialog(
            model.t("strict.quit.confirm.title"),
            isPresented: $asksQuitConfirmation,
            titleVisibility: .visible
        ) {
            Button(model.t("strict.quit.confirm.action"), role: .destructive) {
                var updated = model.distractionRules.first(where: { $0.id == rule.id }) ?? rule
                updated.action = .quitAfterOptIn
                updated.allowsQuitAfterOptIn = true
                model.updateRule(updated)
            }
            Button(model.t("common.cancel"), role: .cancel) {}
        } message: {
            Text(model.t("strict.quit.confirm.detail"))
        }
    }

    private var ruleIdentity: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: enabledBinding)
                .toggleStyle(GlassCheckboxToggleStyle(theme: model.theme))
                .labelsHidden()
                .accessibilityLabel(rule.label)

            Image(systemName: rule.targetKind == .app ? "app.badge" : "globe")
                .frame(width: 22)
                .foregroundStyle(rule.isEnabled ? model.theme.primary : model.theme.mutedText)

            VStack(alignment: .leading, spacing: 3) {
                Text(rule.label)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(2)
                Text(rule.matchValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
                    .lineLimit(1)
            }
            .layoutPriority(1)
        }
    }

    private var actionControls: some View {
        HStack(spacing: 10) {
            GlassSelect(
                selection: actionBinding,
                options: DistractionAction.allCases,
                title: model.actionTitle,
                symbol: actionSymbol,
                minWidth: 210
            )
            .help(model.t("help.strictRuleAction"))

            Button {
                model.deleteRule(rule)
            } label: {
                Image(systemName: "trash")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .icon))
            .accessibilityLabel(model.t("common.delete"))
        }
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
                if newValue == .quitAfterOptIn {
                    asksQuitConfirmation = true
                    return
                }
                var updated = rule
                updated.action = newValue
                updated.allowsQuitAfterOptIn = false
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
                            .frame(minHeight: FocusGlassHitTarget.row)
                            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
    @Environment(\.focusGlassMotion) private var motion
    @State private var showsAdvanced = false
    @State private var previewSurface = ThemePreviewSurface.mainWindow
    @State private var editingAppearance = AppResolvedAppearance.dark
    @State private var showsThemeImporter = false
    @State private var showsThemeExporter = false
    @State private var exportDocument = ThemeProfileDocument()
    @State private var themeNameDraft = ""

    var body: some View {
        LiquidGlassPanel(radius: 22, padding: 18) {
            LazyVStack(alignment: .leading, spacing: 18) {
                header
                swatchGrid
                preview
                actionGrid
                statusStrip
                advancedEditor
            }
        }
        .onAppear {
            editingAppearance = model.resolvedAppearance
            themeNameDraft = model.selectedThemeProfile.name
        }
        .onChange(of: model.selectedThemeID) { _, _ in
            themeNameDraft = model.selectedThemeProfile.name
        }
        .fileExporter(
            isPresented: $showsThemeExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "\(model.selectedThemeProfile.name).focusglass-theme.json"
        ) { result in
            switch result {
            case .success:
                model.lastThemeMessage = model.t("theme.exported")
            case .failure:
                model.lastThemeMessage = model.t("theme.exportFailed")
            }
        }
        .fileImporter(isPresented: $showsThemeImporter, allowedContentTypes: [.json]) { result in
            guard case let .success(url) = result else {
                model.lastThemeMessage = model.t("theme.importFailed")
                return
            }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            guard let data = try? Data(contentsOf: url) else {
                model.lastThemeMessage = model.t("theme.importFailed")
                return
            }
            _ = model.importThemeJSON(data: data)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                Text(model.t("theme.title"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(model.t("theme.subtitle"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(model.theme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 7) {
                Text(model.t("theme.activeTheme"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(model.theme.mutedText)
                    .textCase(.uppercase)
                if model.selectedThemeProfile.isBuiltIn {
                    ThemeStatusBadge(
                        title: model.selectedThemeProfile.name,
                        detail: model.t("theme.builtIn")
                    )
                } else {
                    TextField(model.t("theme.name"), text: $themeNameDraft)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 190)
                        .onSubmit {
                            model.renameActiveTheme(themeNameDraft)
                        }
                }
            }
        }
    }

    private var swatchGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 176), spacing: 10)], spacing: 10) {
            ForEach(model.themeProfiles) { profile in
                ThemeSwatch(profile: profile, isSelected: profile.id == model.selectedThemeID) {
                    model.selectTheme(profile)
                }
            }
        }
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 10)], alignment: .leading, spacing: 10) {
            themeAction(title: model.t("theme.duplicate"), symbol: "plus.square.on.square", help: model.t("help.themeDuplicate")) {
                model.duplicateActiveTheme()
            }

            if model.selectedThemeProfile.isBuiltIn {
                themeAction(title: model.t("theme.reset"), symbol: "arrow.counterclockwise", help: model.t("help.themeReset")) {
                    model.resetActiveTheme()
                }
            } else {
                themeAction(title: model.t("theme.delete"), symbol: "trash", variant: .danger, help: model.t("help.themeDelete")) {
                    model.deleteActiveCustomTheme()
                }
            }

            themeAction(title: model.t("theme.export"), symbol: "square.and.arrow.up", help: model.t("help.themeExport")) {
                guard let data = try? model.themeExportData() else {
                    model.lastThemeMessage = model.t("theme.exportFailed")
                    return
                }
                exportDocument = ThemeProfileDocument(data: data)
                showsThemeExporter = true
            }

            themeAction(title: model.t("theme.import"), symbol: "square.and.arrow.down", help: model.t("help.themeImport")) {
                showsThemeImporter = true
            }
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 10) {
            GlassSegmentedControl(
                selection: $previewSurface,
                options: ThemePreviewSurface.allCases,
                title: { model.t($0.titleKey) },
                symbol: { $0.symbolName }
            )
            ThemePreviewCard(
                theme: model.effectiveTheme(for: editingAppearance),
                surface: previewSurface
            )
            .id(previewSurface)
            .transition(motion.transition(.emphasis))
            .animation(motion.animation(.selection), value: previewSurface)
        }
    }

    private var statusStrip: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(statusMessages, id: \.self) { message in
                Text(message)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(model.theme.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(model.theme.highlight.opacity(model.theme.highlightAlpha * 0.18), in: Capsule())
                    .help(message)
                    .transition(motion.transition(.listItem))
            }
        }
        .animation(motion.animation(.selection), value: statusMessages)
    }

    private var statusMessages: [String] {
        var messages: [String] = []
        if let message = model.lastThemeMessage {
            messages.append(message)
        }
        if let iconStatus = model.lastIconStatus {
            messages.append(iconStatus)
        }
        if model.isThemeSideEffectPending {
            messages.append(model.t("theme.saving"))
        }
        return messages
    }

    private var advancedEditor: some View {
        GlassDisclosureSection(isExpanded: $showsAdvanced) {
            Label(model.t("theme.advancedColors"), systemImage: "slider.horizontal.3")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(model.theme.text)
                .padding(.horizontal, 2)
        } content: {
            editorSections
                .padding(.top, 12)
        }
    }

    private var editorSections: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                GlassSegmentedControl(
                    selection: $editingAppearance,
                    options: [AppResolvedAppearance.light, .dark],
                    title: { appearance in
                        model.t(appearance == .light ? "appearance.light" : "appearance.dark")
                    },
                    symbol: { appearance in appearance == .light ? "sun.max" : "moon.stars" }
                )

                let ratio = model.effectiveTheme(for: editingAppearance).contrastRatio(for: editingAppearance)
                Text(String(format: model.t("theme.contrastValue"), ratio))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(ratio >= 4.5 ? model.theme.strict : model.theme.mutedText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(model.theme.surface.opacity(model.theme.resolvedSurfaceAlpha), in: Capsule())

                if ratio < 4.5 {
                    Button {
                        model.repairActiveThemeContrast(for: editingAppearance)
                    } label: {
                        Label(model.t("theme.repairContrast"), systemImage: "wand.and.stars")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: .secondary))
                }
            }

            ThemeEditorSection(
                title: model.t("theme.group.glass"),
                symbolName: "sparkles",
                initiallyExpanded: true
            ) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ThemeSliderField(title: model.t("theme.glass"), value: doubleBinding(\.glassOpacity), range: 0.2...0.9)
                    ThemeSliderField(title: model.t("theme.menuGlass"), value: doubleBinding(\.menuGlassOpacity), range: 0.2...0.95)
                    ThemeSliderField(title: model.t("theme.surfaceAlpha"), value: doubleBinding(\.surfaceAlpha), range: 0.08...0.60)
                    ThemeSliderField(title: model.t("theme.highlightAlpha"), value: doubleBinding(\.highlightAlpha), range: 0.04...0.60)
                    ThemeSliderField(title: model.t("theme.specularOpacity"), value: doubleBinding(\.specularOpacity), range: 0.04...0.70)
                    ThemeSliderField(title: model.t("theme.blurIntensity"), value: doubleBinding(\.blurIntensity), range: 0.20...1.00)
                    ThemeSliderField(title: model.t("theme.fullscreenGlow"), value: doubleBinding(\.fullscreenGlowIntensity), range: 0...1)
                    ThemeSliderField(title: model.t("theme.radius"), value: doubleBinding(\.cornerRadius), range: 8...28, step: 1, displayMode: .integer)
                    ThemeSliderField(title: model.t("theme.border"), value: doubleBinding(\.borderOpacity), range: 0...0.5)
                    ThemeSliderField(title: model.t("theme.shadow"), value: doubleBinding(\.shadowDepth), range: 0...0.65)
                    ThemeSliderField(title: model.t("theme.density"), value: doubleBinding(\.density), range: 0...1)
                    ThemeSliderField(title: model.t("theme.motion"), value: doubleBinding(\.motion), range: 0...1)
                }
            }

            ThemeEditorSection(
                title: model.t("theme.group.accent"),
                symbolName: "paintpalette",
                initiallyExpanded: false
            ) {
                colorGrid {
                    ThemeColorField(title: model.t("theme.primary"), value: stringBinding(\.primaryHex))
                    ThemeColorField(title: model.t("theme.secondary"), value: stringBinding(\.secondaryHex))
                    ThemeColorField(title: model.t("theme.glow"), value: stringBinding(\.glowHex))
                    ThemeColorField(title: model.t("theme.ringStart"), value: stringBinding(\.timerRingStartHex))
                    ThemeColorField(title: model.t("theme.ringEnd"), value: stringBinding(\.timerRingEndHex))
                    ThemeColorField(title: model.t("theme.strict"), value: stringBinding(\.strictHex))
                }
            }

            ThemeEditorSection(
                title: model.t("theme.group.foundation"),
                symbolName: "rectangle.3.group",
                initiallyExpanded: false
            ) {
                colorGrid {
                    ThemeColorField(title: model.t("theme.backgroundTop"), value: stringBinding(\.backgroundTopHex))
                    ThemeColorField(title: model.t("theme.backgroundMid"), value: stringBinding(\.backgroundMidHex))
                    ThemeColorField(title: model.t("theme.backgroundBottom"), value: stringBinding(\.backgroundBottomHex))
                    ThemeColorField(title: model.t("theme.surface"), value: stringBinding(\.surfaceHex))
                    ThemeColorField(title: model.t("theme.elevatedSurface"), value: stringBinding(\.elevatedSurfaceHex))
                    ThemeColorField(title: model.t("theme.highlightColor"), value: stringBinding(\.highlightHex))
                }
            }

            ThemeEditorSection(
                title: model.t("theme.group.readability"),
                symbolName: "textformat.size",
                initiallyExpanded: false
            ) {
                colorGrid {
                    ThemeColorField(title: model.t("theme.text"), value: stringBinding(\.textHex))
                    ThemeColorField(title: model.t("theme.muted"), value: stringBinding(\.mutedTextHex))
                    ThemeColorField(title: model.t("theme.heatmapLow"), value: stringBinding(\.heatmapLowHex))
                    ThemeColorField(title: model.t("theme.heatmapHigh"), value: stringBinding(\.heatmapHighHex))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func themeAction(
        title: String,
        symbol: String,
        variant: LiquidGlassButtonStyle.Variant = .secondary,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidGlassButtonStyle(theme: model.theme, variant: variant))
        .help(help)
    }

    private func colorGrid<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], spacing: 10) {
            content()
        }
    }

    private func stringBinding(_ keyPath: WritableKeyPath<ThemePalette, String>) -> Binding<String> {
        Binding(
            get: { model.selectedThemeProfile.palette(for: editingAppearance)[keyPath: keyPath] },
            set: { value in
                model.updateActiveThemePalette(
                    for: editingAppearance,
                    animatesTransition: false
                ) { palette in
                    palette[keyPath: keyPath] = value
                }
            }
        )
    }

    private func doubleBinding(_ keyPath: WritableKeyPath<ThemeProfile, Double>) -> Binding<Double> {
        Binding(
            get: { model.selectedThemeProfile[keyPath: keyPath] },
            set: { value in
                model.updateActiveThemeInteractively { profile in
                    profile[keyPath: keyPath] = value
                }
            }
        )
    }

}

private enum ThemePreviewSurface: String, CaseIterable {
    case mainWindow
    case menuBar
    case fullscreen

    var titleKey: String {
        switch self {
        case .mainWindow: "theme.preview.main"
        case .menuBar: "theme.preview.menu"
        case .fullscreen: "theme.preview.fullscreen"
        }
    }

    var symbolName: String {
        switch self {
        case .mainWindow: "macwindow"
        case .menuBar: "menubar.rectangle"
        case .fullscreen: "arrow.up.left.and.arrow.down.right"
        }
    }
}

private struct ThemeProfileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct ThemeColorField: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    let title: String
    @Binding var value: String

    var body: some View {
        HStack(spacing: 10) {
            ColorPicker("", selection: colorBinding, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 36, height: 30)
                .controlSize(.large)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(model.theme.mutedText)
                Text(value.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(model.theme.text.opacity(0.88))
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    model.theme.highlight.opacity(model.theme.highlightAlpha * 0.18),
                    model.theme.elevatedSurface.opacity(model.theme.surfaceAlpha * 1.02),
                    model.theme.surface.opacity(model.theme.surfaceAlpha * 0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(model.theme.highlight.opacity(model.theme.borderOpacity * 0.72), lineWidth: 1)
        }
        .help("\(title): \(value)")
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: value) },
            set: { color in
                value = NSColor(color).hexString
            }
        )
    }
}

private struct ThemeSliderField: View {
    enum DisplayMode {
        case decimal
        case integer
    }

    @EnvironmentObject private var model: FocusGlassViewModel

    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0.01
    var displayMode: DisplayMode = .decimal

    @State private var draftText = ""
    @State private var sliderValue: Double
    @State private var isSliderEditing = false
    @State private var lastSliderCommitUptime = 0.0
    @State private var pendingSliderCommit: Task<Void, Never>?
    @FocusState private var isFocused: Bool

    init(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 0.01,
        displayMode: DisplayMode = .decimal
    ) {
        self.title = title
        _value = value
        self.range = range
        self.step = step
        self.displayMode = displayMode
        _sliderValue = State(initialValue: value.wrappedValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer()
                TextField("", text: $draftText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(model.theme.text)
                    .focused($isFocused)
                    .frame(width: 54)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(model.theme.highlight.opacity(model.theme.highlightAlpha * 0.16), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .onSubmit {
                        commitDraft()
                    }
                    .onChange(of: isFocused) { _, focused in
                        if focused {
                            syncDraft()
                        } else {
                            commitDraft()
                            syncDraft()
                        }
                    }
            }
            GlassSlider(
                value: $sliderValue,
                range: range,
                step: step,
                onEditingChanged: sliderEditingChanged
            )
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [
                    model.theme.highlight.opacity(model.theme.highlightAlpha * 0.16),
                    model.theme.elevatedSurface.opacity(model.theme.surfaceAlpha * 0.96),
                    model.theme.surface.opacity(model.theme.surfaceAlpha * 0.68)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(model.theme.highlight.opacity(model.theme.borderOpacity * 0.70), lineWidth: 1)
        }
        .onAppear {
            sliderValue = value
            syncDraft()
        }
        .onChange(of: value) { _, _ in
            guard !isFocused, !isSliderEditing else { return }
            sliderValue = value
            syncDraft()
        }
        .onChange(of: sliderValue) { _, _ in
            guard isSliderEditing else { return }
            syncDraft()
            commitSliderValueWhenDue()
        }
        .onDisappear {
            pendingSliderCommit?.cancel()
            if isSliderEditing {
                value = sliderValue
            }
        }
        .help("\(title): \(formattedValue)")
    }

    private var formattedValue: String {
        switch displayMode {
        case .decimal:
            return String(format: "%.2f", sliderValue)
        case .integer:
            return String(format: "%.0f", sliderValue)
        }
    }

    private func syncDraft() {
        draftText = formattedValue
    }

    private func commitDraft() {
        let normalized = draftText.replacingOccurrences(of: ",", with: ".")
        guard let parsed = Double(normalized) else { return }
        let stepped = step > 0 ? (parsed / step).rounded() * step : parsed
        let committedValue = min(range.upperBound, max(range.lowerBound, stepped))
        sliderValue = committedValue
        value = committedValue
        lastSliderCommitUptime = ProcessInfo.processInfo.systemUptime
    }

    private func sliderEditingChanged(_ isEditing: Bool) {
        isSliderEditing = isEditing
        if isEditing {
            pendingSliderCommit?.cancel()
            lastSliderCommitUptime = 0
            return
        }

        pendingSliderCommit?.cancel()
        value = sliderValue
        lastSliderCommitUptime = ProcessInfo.processInfo.systemUptime
        syncDraft()
    }

    private func commitSliderValueWhenDue() {
        let now = ProcessInfo.processInfo.systemUptime
        let minimumInterval = 1.0 / 30.0
        let elapsed = now - lastSliderCommitUptime

        if elapsed >= minimumInterval {
            pendingSliderCommit?.cancel()
            value = sliderValue
            lastSliderCommitUptime = now
            return
        }

        pendingSliderCommit?.cancel()
        let pendingValue = sliderValue
        let delay = minimumInterval - elapsed
        pendingSliderCommit = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            value = pendingValue
            lastSliderCommitUptime = ProcessInfo.processInfo.systemUptime
        }
    }
}

private struct ThemePreviewCard: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    let theme: ThemeProfile
    let surface: ThemePreviewSurface

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                .fill(theme.background)

            switch surface {
            case .mainWindow:
                mainPreview
            case .menuBar:
                menuPreview
            case .fullscreen:
                fullscreenPreview
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CGFloat(theme.cornerRadius), style: .continuous)
                .stroke(theme.highlight.opacity(theme.borderOpacity), lineWidth: 1)
        }
    }

    private var mainPreview: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 13) {
                Label(model.t("focus.today"), systemImage: "scope")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)
                Text(previewTaskTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.mutedText)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    ThemePreviewDot(color: theme.primary)
                    ThemePreviewDot(color: theme.secondary)
                    ThemePreviewDot(color: theme.strict)
                    ThemePreviewDot(color: theme.glow)
                }
            }
            Spacer(minLength: 0)
            previewTimer(size: 122)
        }
        .padding(theme.spacing(16))
    }

    private var menuPreview: some View {
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("FocusGlass", systemImage: "timer")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Text("25:00")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                Divider().overlay(theme.highlight.opacity(0.20))
                Text(previewTaskTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                ProgressView(value: 0.68)
                    .tint(theme.primary)
            }
            .foregroundStyle(theme.text)
            .padding(theme.spacing(16))
            .frame(width: 310)
            .background(theme.surface.opacity(theme.resolvedSurfaceAlpha), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.highlight.opacity(theme.borderOpacity), lineWidth: 1)
            }
            Spacer()
        }
    }

    private var fullscreenPreview: some View {
        HStack(spacing: 18) {
            previewTimer(size: 132)
            VStack(alignment: .leading, spacing: 8) {
                Text(model.t("tasks.activeForSession"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.primary)
                    .textCase(.uppercase)
                Text(previewTaskTitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)
                    .lineLimit(3)
                Text(model.t("timer.status.running"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.mutedText)
            }
            .frame(maxWidth: 250, alignment: .leading)
        }
        .padding(theme.spacing(16))
    }

    private func previewTimer(size: CGFloat) -> some View {
        CircularTimerView(
            clockText: "25:00",
            phase: model.t("timer.phase.focus"),
            progress: 0.68,
            theme: theme,
            statusText: model.t("timer.status.running"),
            size: size,
            clockSize: size * 0.20
        )
        .frame(width: size + 12, height: size + 12)
    }

    private var previewTaskTitle: String {
        model.activeTasks.first(where: { $0.id == model.activeTaskID })?.title
            ?? model.t("theme.preview.noTask")
    }
}

private struct ThemeEditorSection<Content: View>: View {
    @EnvironmentObject private var model: FocusGlassViewModel
    @Environment(\.focusGlassMotion) private var motion
    @State private var isExpanded: Bool

    let title: String
    let symbolName: String
    let content: Content

    init(
        title: String,
        symbolName: String,
        initiallyExpanded: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbolName = symbolName
        _isExpanded = State(initialValue: initiallyExpanded)
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(motion.animation(.disclosure)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: symbolName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(model.theme.primary)
                        .frame(width: 28, height: 28)
                        .background(model.theme.primary.opacity(0.13), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text(title)
                        .font(.system(size: 14, weight: .bold))

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(model.theme.mutedText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: FocusGlassHitTarget.row, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .glassHover(theme: model.theme, radius: 11, isActive: isExpanded)

            if isExpanded {
                content
                    .transition(motion.transition(.disclosure))
            }
        }
        .padding(14)
        .background(model.theme.highlight.opacity(model.theme.highlightAlpha * 0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(model.theme.highlight.opacity(model.theme.borderOpacity * 0.66), lineWidth: 1)
        }
    }
}

private struct ThemeStatusBadge: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 9) {
            ThemePreviewDot(color: model.theme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(detail)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(model.theme.mutedText)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(model.theme.highlight.opacity(model.theme.highlightAlpha * 0.18), in: Capsule())
        .overlay {
            Capsule()
                .stroke(model.theme.highlight.opacity(model.theme.borderOpacity * 0.72), lineWidth: 1)
        }
    }
}

private struct ThemePreviewDot: View {
    let color: Color
    var size: CGFloat = 20

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
    }
}

private struct ThemeScopeRow: View {
    @EnvironmentObject private var model: FocusGlassViewModel

    let title: String
    let symbolName: String

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(model.theme.text)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
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
