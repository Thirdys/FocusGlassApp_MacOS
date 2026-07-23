import Foundation
import Testing
@testable import FocusGlassCore

@Suite
struct FocusGuardTypesTests {
    @Test
    func legacyAppRuleDecodesAsAppTarget() throws {
        let data = """
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "label": "Discord",
          "bundleIdentifier": "com.hnc.Discord",
          "action": "hide",
          "isEnabled": true
        }
        """.data(using: .utf8)!

        let rule = try JSONDecoder().decode(DistractionRuleSpec.self, from: data)

        #expect(rule.targetKind == .app)
        #expect(rule.matchValue == "com.hnc.Discord")
        #expect(rule.bundleIdentifier == "com.hnc.Discord")
        #expect(rule.matches(bundleIdentifier: "com.hnc.Discord"))
        #expect(rule.allowsQuitAfterOptIn == false)
    }

    @Test
    func sitePatternNormalizationRemovesSchemeAndWWW() {
        let normalized = DistractionRuleSpec.normalizedSitePattern(" https://www.YouTube.com/feed ")

        #expect(normalized == "youtube.com")
    }

    @Test
    func siteRuleMatchesDomainAndSubdomain() {
        let rule = DistractionRuleSpec(
            label: "Reddit",
            targetKind: .site,
            matchValue: "*.reddit.com",
            sitePattern: "*.reddit.com",
            action: .hide
        )

        #expect(rule.matches(siteURL: "https://www.reddit.com/r/swift"))
        #expect(rule.matches(siteURL: "old.reddit.com/r/swift"))
        #expect(!rule.matches(siteURL: "https://example.com"))
    }

    @Test
    func disabledRulesDoNotMatch() {
        let rule = DistractionRuleSpec(
            label: "Steam",
            targetKind: .app,
            matchValue: "com.valvesoftware.steam",
            bundleIdentifier: "com.valvesoftware.steam",
            action: .hide,
            isEnabled: false
        )

        #expect(!rule.matches(bundleIdentifier: "com.valvesoftware.steam"))
    }

    @Test
    func quitActionRequiresExplicitPersistedOptIn() {
        let guardedRule = DistractionRuleSpec(
            label: "TextEdit",
            bundleIdentifier: "com.apple.TextEdit",
            action: .quitAfterOptIn
        )
        let confirmedRule = DistractionRuleSpec(
            label: "TextEdit",
            bundleIdentifier: "com.apple.TextEdit",
            action: .quitAfterOptIn,
            allowsQuitAfterOptIn: true
        )

        #expect(guardedRule.effectiveAction == .hide)
        #expect(confirmedRule.effectiveAction == .quitAfterOptIn)
    }

    @Test
    func permissionStatusExposesUserActionState() {
        #expect(FocusPermissionStatus.granted.isGranted)
        #expect(FocusPermissionStatus.missing.needsUserAction)
        #expect(FocusPermissionStatus.unavailable.needsUserAction)
        #expect(!FocusPermissionStatus.unknown.needsUserAction)
    }
}
