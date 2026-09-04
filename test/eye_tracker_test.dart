import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_launcher_2/services/eye_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EyeTrackerService.evaluateFaceFocus - Narrow Eyes ("Mata Sipit") & Inclusivity', () {
    test('Detects narrow/monolid eyes looking down at smartphone screen (probabilities 0.18 - 0.35)', () {
      // Scenario A: Typical downward gaze on monolid eyes
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 5.0,
          eulerZ: 3.0,
          leftEyeOpenProb: 0.22,
          rightEyeOpenProb: 0.24,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
        reason: 'Failed to recognize open narrow eyes with ~0.23 probability',
      );

      // Scenario B: Uneven lighting across eyes (e.g., side lamp or shadow)
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: -4.0,
          eulerZ: 2.0,
          leftEyeOpenProb: 0.32,
          rightEyeOpenProb: 0.16,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
        reason: 'Failed to recognize focus when one eye reaches 0.32 and other is shaded',
      );

      // Scenario C: Lower probability threshold confirmed by eye landmarks
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 0.0,
          eulerZ: 0.0,
          leftEyeOpenProb: 0.15,
          rightEyeOpenProb: 0.15,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
        reason: 'Failed to recognize focus when eye landmarks are detected and average is 0.15',
      );
    });

    test('Detects normal/wide open eyes reliably', () {
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 2.0,
          eulerZ: -1.0,
          leftEyeOpenProb: 0.88,
          rightEyeOpenProb: 0.92,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
      );
    });

    test('Correctly identifies closed eyes as NOT focused', () {
      // Both eyes shut / sleeping
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 0.0,
          eulerZ: 0.0,
          leftEyeOpenProb: 0.04,
          rightEyeOpenProb: 0.05,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isFalse,
        reason: 'Falsely detected closed eyes as focused',
      );

      // Prolonged blink or meditation
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 5.0,
          eulerZ: 2.0,
          leftEyeOpenProb: 0.10,
          rightEyeOpenProb: 0.08,
          hasEyeLandmarks: false,
          facePresent: true,
        ),
        isFalse,
      );
    });
  });

  group('EyeTrackerService.evaluateFaceFocus - Reading Posture & Orientation', () {
    test('Allows natural reading posture with slight yaw and head tilt', () {
      // Reading from left to right / right to left (yaw up to 25°)
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 18.0,
          eulerZ: 10.0,
          leftEyeOpenProb: 0.40,
          rightEyeOpenProb: 0.40,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
      );

      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: -22.0,
          eulerZ: -12.0,
          leftEyeOpenProb: 0.35,
          rightEyeOpenProb: 0.35,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
      );
    });

    test('Rejects when head is turned away (looking to side or talking to someone)', () {
      // Turned right
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 35.0,
          eulerZ: 0.0,
          leftEyeOpenProb: 0.80,
          rightEyeOpenProb: 0.80,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isFalse,
        reason: 'Failed to reject face looking away with yaw 35°',
      );

      // Turned left
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: -32.0,
          eulerZ: 5.0,
          leftEyeOpenProb: 0.80,
          rightEyeOpenProb: 0.80,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isFalse,
      );
    });

    test('Rejects excessive head roll/tilt', () {
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 5.0,
          eulerZ: 32.0,
          leftEyeOpenProb: 0.80,
          rightEyeOpenProb: 0.80,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isFalse,
        reason: 'Failed to reject excessive head tilt of 32°',
      );
    });

    test('Gracefully handles missing Euler angle estimations without failing', () {
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: null,
          eulerZ: null,
          leftEyeOpenProb: 0.50,
          rightEyeOpenProb: 0.50,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
      );
    });

    test('Rejects when no face is present', () {
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 0.0,
          eulerZ: 0.0,
          leftEyeOpenProb: 0.90,
          rightEyeOpenProb: 0.90,
          facePresent: false,
        ),
        isFalse,
      );
    });
  });

  group('EyeTrackerService.evaluateFaceFocus - Monocular Vision & Single-Eye Disability', () {
    test('Correctly detects focus for users with only 1 functional eye (other eye closed / 0.00)', () {
      // Left eye functional & open, right eye closed / non-functional (0.00)
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 0.0,
          eulerZ: 0.0,
          leftEyeOpenProb: 0.75,
          rightEyeOpenProb: 0.00,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
        reason: 'Failed to recognize single-eye user with open left eye (0.75)',
      );

      // Right eye functional & open, left eye closed / non-functional (0.00)
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 0.0,
          eulerZ: 0.0,
          leftEyeOpenProb: 0.00,
          rightEyeOpenProb: 0.80,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
        reason: 'Failed to recognize single-eye user with open right eye (0.80)',
      );

      // Single functional eye that is also narrow/monolid and looking down (0.16)
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 0.0,
          eulerZ: 0.0,
          leftEyeOpenProb: 0.16,
          rightEyeOpenProb: 0.00,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
        reason: 'Failed to recognize single functional eye that is narrow with landmark (0.16)',
      );
    });

    test('Correctly detects focus when one eye is covered with an eye patch (null probability)', () {
      // Left eye open, right eye covered by eye patch (ML Kit returns null for right)
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 2.0,
          eulerZ: 1.0,
          leftEyeOpenProb: 0.60,
          rightEyeOpenProb: null,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
      );

      // Right eye open, left eye covered by eye patch (ML Kit returns null for left)
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: -2.0,
          eulerZ: 0.0,
          leftEyeOpenProb: null,
          rightEyeOpenProb: 0.60,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
      );
    });

    test('Correctly identifies NOT focused when single-eye user closes their only functional eye', () {
      // Functional left eye is closed (0.03), right eye is non-functional (0.00)
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 0.0,
          eulerZ: 0.0,
          leftEyeOpenProb: 0.03,
          rightEyeOpenProb: 0.00,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isFalse,
        reason: 'Falsely detected single-eye user as focused when their only eye was closed',
      );
    });
  });

  group('EyeTrackerService.evaluateFaceFocus - Strabismus & Misaligned Eyes ("Mata Tidak Sejajar / Juling")', () {
    test('Detects focus for users with strabismus (asymmetrical eye angles, compensatory head tilt)', () {
      // Scenario A: Compensatory head tilt (ocular torticollis, e.g. 14° roll) common in strabismus
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 6.0,
          eulerZ: 14.0, // Natural compensatory tilt
          leftEyeOpenProb: 0.70,
          rightEyeOpenProb: 0.65,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
        reason: 'Failed to detect focus with compensatory head tilt for misaligned eyes',
      );

      // Scenario B: Unequal openness or visual asymmetry (e.g. one dominant eye wider than the other)
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: -5.0,
          eulerZ: 8.0,
          leftEyeOpenProb: 0.78,
          rightEyeOpenProb: 0.25, // Asymmetric opening
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
        reason: 'Failed to detect focus with asymmetric eye openness',
      );

      // Scenario C: Slight compensatory head turn (yaw 15°)
      expect(
        EyeTrackerService.evaluateFaceFocus(
          eulerY: 15.0, // Compensatory gaze turn
          eulerZ: -6.0,
          leftEyeOpenProb: 0.60,
          rightEyeOpenProb: 0.55,
          hasEyeLandmarks: true,
          facePresent: true,
        ),
        isTrue,
        reason: 'Failed to detect focus with compensatory head turn',
      );
    });
  });
}
