# Implementation Plan

- [x] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Web Marker Deprecation Warnings
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test that web platform rendering with markers generates deprecation warnings (from Bug Condition in design)
  - The test assertions should match the Expected Behavior Properties from design
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found to understand root cause
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 2.1, 2.2, 2.3_
  - **COMPLETED**: Test created and initially failed on unfixed code, confirming bug exists

- [x] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Cross-Platform Functionality
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy inputs (mobile platforms, non-marker features)
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - **COMPLETED**: Preservation tests created and passed on unfixed code, establishing baseline

- [x] 3. Fix for Google Maps marker deprecation warnings

  - [x] 3.1 Implement the marker migration fix
    - Update GoogleMap widgets to use `markerType: GoogleMapMarkerType.advancedMarker`
    - Identify all GoogleMap widget instances across the codebase
    - Apply markerType configuration consistently to eliminate deprecated API usage
    - Verify web `index.html` has correct Google Maps API configuration with marker library
    - Ensure package dependencies support advanced markers (google_maps_flutter ^2.17.0)
    - _Bug_Condition: isBugCondition(input) where input.platform == 'web' AND input.hasMarkers == true AND input.markerType == GoogleMapMarkerType.normal_
    - _Expected_Behavior: noDeprecationWarnings(result) AND markersDisplayCorrectly(result) from design_
    - _Preservation: Mobile platform functionality, marker visual appearance, marker interactions, map performance from design_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4_
    - **COMPLETED**: Fixed 14 GoogleMap widgets across FRONTEND and RIDERSIDE apps

  - [x] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Web Marker Deprecation Elimination
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1
    - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
    - _Requirements: Expected Behavior Properties from design_
    - **COMPLETED**: Test now passes, confirming fix eliminates deprecation warnings

  - [x] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Cross-Platform Functionality
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
    - Confirm all tests still pass after fix (no regressions)
    - **COMPLETED**: All preservation tests still pass, confirming no regressions

- [x] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
  - **COMPLETED**: All tests pass successfully - bug fix implementation complete!