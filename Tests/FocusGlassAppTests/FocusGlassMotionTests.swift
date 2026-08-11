import Testing
@testable import FocusGlassApp

struct FocusGlassMotionTests {
    @Test
    func durationScaleIsClampedToThemeStudioRange() {
        let low = FocusGlassMotion(durationScale: 0.1)
        let high = FocusGlassMotion(durationScale: 4)

        #expect(low.durationScale == 0.80)
        #expect(high.durationScale == 1.15)
    }

    @Test
    func tokenDurationsUseTheConfiguredScale() {
        let motion = FocusGlassMotion(durationScale: 1.15)

        #expect(abs(motion.duration(.micro) - 0.138) < 0.000_1)
        #expect(abs(motion.duration(.navigation) - 0.322) < 0.000_1)
        #expect(abs(motion.duration(.emphasis) - 0.414) < 0.000_1)
    }

    @Test
    func reduceMotionRemovesSpatialAndProgressMotion() {
        let motion = FocusGlassMotion(durationScale: 1.15, reduceMotion: true)

        #expect(motion.allowsSpatialMotion == false)
        #expect(motion.duration(.selection) == 0.12)
        #expect(motion.duration(.progress) == 0)
        #expect(motion.animation(.progress) == nil)
    }

    @Test
    func motionHierarchyRemainsCalmAndOrdered() {
        let motion = FocusGlassMotion()

        #expect(motion.duration(.micro) < motion.duration(.selection))
        #expect(motion.duration(.selection) < motion.duration(.disclosure))
        #expect(motion.duration(.disclosure) < motion.duration(.navigation))
        #expect(motion.duration(.navigation) < motion.duration(.emphasis))
    }
}
