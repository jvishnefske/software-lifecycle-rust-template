# Motor Controller Example - Full 9-Layer Walkthrough

This example demonstrates the complete Safe Rust Agent System processing a motor controller component through all 9 verification layers.

## Initial Input

```yaml
component_request:
  name: "Motor Speed Controller"
  description: |
    CAN-based motor controller for industrial automation.
    Receives speed commands via CAN bus, controls motor via PWM.
    Must handle faults gracefully and enter safe state.
  safety_level: "ASIL-C"
  target: "ARM Cortex-M4 (no_std)"
  constraints:
    - "No heap allocation"
    - "No panics in production"
    - "1ms control loop"
```

---

## Layer 1: Requirements Agent

### Output

```yaml
requirements_output:
  component_id: "COMP-MOTOR-CTRL"
  version: "1.0"
  safety_level: "ASIL-C"
  
  functional_requirements:
    - id: "FR-MOTOR-001"
      title: "Speed Command Processing"
      description: |
        Motor controller shall update PWM output within 1ms of 
        receiving a valid CAN speed command.
      acceptance_criteria:
        - "Latency from CAN RX to PWM update ≤ 1ms"
        - "PWM duty cycle proportional to speed (0-5000 RPM → 0-100%)"
      testable: true
      
    - id: "FR-MOTOR-002"
      title: "Communication Timeout"
      description: |
        Motor controller shall detect CAN communication loss within 
        100ms and transition to safe state.
      acceptance_criteria:
        - "Timeout detected within 100ms of last valid message"
        - "Safe state entry within 10ms of detection"
      testable: true
      
  safety_requirements:
    - id: "SR-MOTOR-001"
      title: "Speed Limit Enforcement"
      description: |
        Motor controller shall enforce maximum speed of 5000 RPM 
        regardless of commanded value.
      derived_from: "HAZARD-001"
      verification_method: "test + proof"
      
    - id: "SR-MOTOR-002"
      title: "Safe State Entry"
      description: |
        On any fault, motor controller shall:
        1. Set PWM to 0% within 10ms
        2. Command brake engagement
        3. Verify brake engagement within 50ms
      derived_from: "HAZARD-001"
      verification_method: "test"
      
  rust_constraints:
    - id: "RC-MOTOR-001"
      type: "memory"
      description: "#![no_std], no heap allocation"
      
    - id: "RC-MOTOR-002"
      type: "panic"
      description: "No panic paths; all errors return Result"
      
  timing_requirements:
    - id: "TR-MOTOR-001"
      operation: "control_loop"
      period: "1ms"
      wcet_budget: "100µs"
      
  issues: []
```

**Gate 1→2: PASS** - All requirements formalized, testable, traced.

---

## Layer 2: Architecture Agent

### Output

```yaml
architecture_output:
  component_id: "COMP-MOTOR-CTRL"
  
  type_definitions:
    - name: "Rpm"
      kind: "newtype"
      definition: |
        /// Speed in RPM, validated to 0-5000 range
        #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
        pub struct Rpm(u16);
        
        impl Rpm {
            pub const ZERO: Self = Self(0);
            pub const MAX: Self = Self(5000);
            
            pub const fn new(value: u16) -> Option<Self> {
                if value <= 5000 { Some(Self(value)) } else { None }
            }
            
            pub const fn saturating_new(value: u16) -> Self {
                if value <= 5000 { Self(value) } else { Self::MAX }
            }
            
            pub const fn get(self) -> u16 { self.0 }
        }
      invariants:
        - "self.0 <= 5000"
        
  state_machines:
    - name: "ControllerState"
      states: ["Idle", "Running", "Fault"]
      transitions:
        - { from: "Idle", to: "Running", trigger: "start()", guard: "none" }
        - { from: "Running", to: "Idle", trigger: "stop()", guard: "none" }
        - { from: "Running", to: "Fault", trigger: "report_fault()", guard: "none" }
        - { from: "Fault", to: "Idle", trigger: "clear_fault()", guard: "fault_cleared" }
      type_state_encoding: "Runtime enum (simpler for this case)"
      
  error_types:
    - name: "MotorError"
      definition: |
        #[derive(Debug, Clone, Copy)]
        pub enum MotorError {
            SpeedExceedsLimit { commanded: Rpm, limit: Rpm },
            Timeout { elapsed_ms: u32, threshold_ms: u32 },
            HardwareFault(HardwareFaultCode),
            InvalidStateTransition { from: ControllerState, operation: &'static str },
            BrakeEngagementFailed,
        }
        
  ownership_model:
    - resource: "PWM peripheral"
      owner: "MotorController"
      access_pattern: "exclusive"
      synchronization: "none"
      
    - resource: "CAN RX buffer"
      owner: "CanDriver"
      access_pattern: "shared-mutable"
      synchronization: "critical_section"
```

**Gate 2→3: PASS** - Types defined, state machine specified, ownership clear.

---

## Layer 3: TDD Test Author Agent

### Output (Key Tests)

```rust
// tests/controller_tests.rs - Written BEFORE implementation

#[cfg(test)]
mod speed_controller_tests {
    use super::*;
    
    // ═══════════════════════════════════════════════════════════════
    // FR-MOTOR-001: Speed Command Processing
    // ═══════════════════════════════════════════════════════════════
    
    #[test]
    fn test_set_speed_valid_command() {
        let mut controller = SpeedController::new(SpeedConfig::default());
        controller.start().unwrap();
        let speed = Rpm::new(1000).unwrap();
        
        let result = controller.set_target_speed(speed);
        
        assert!(result.is_ok());
        assert_eq!(controller.target_speed(), speed);
    }
    
    // SR-MOTOR-001: Speed limit enforced
    #[test]
    fn test_set_speed_exceeds_limit_saturates() {
        let mut controller = SpeedController::new(SpeedConfig::default());
        controller.start().unwrap();
        
        // Try to set above MAX
        let result = controller.set_target_speed(Rpm::saturating_new(6000));
        
        assert!(result.is_ok());
        assert_eq!(controller.target_speed(), Rpm::MAX);
    }
    
    // FR-MOTOR-002: Timeout detection
    #[test]
    fn test_timeout_triggers_fault() {
        let mut controller = SpeedController::new(SpeedConfig {
            timeout_ms: 100,
            ..Default::default()
        });
        controller.start().unwrap();
        
        // Advance time past timeout
        controller.tick(101);
        
        assert_eq!(controller.state(), ControllerState::Fault);
    }
    
    // SR-MOTOR-002: Safe state on fault
    #[test]
    fn test_fault_enters_safe_state() {
        let mut controller = SpeedController::new(SpeedConfig::default());
        controller.start().unwrap();
        controller.set_target_speed(Rpm::new(3000).unwrap()).unwrap();
        
        controller.report_fault(HardwareFaultCode::OverCurrent);
        
        assert_eq!(controller.state(), ControllerState::Fault);
        assert_eq!(controller.duty_cycle(), DutyCycle::ZERO);
    }
    
    // SR-MOTOR-002: Brake verification (THE KEY TEST)
    #[test]
    fn test_fault_verifies_brake_engagement() {
        let brake = MockBrake::new();
        let mut controller = SpeedController::new(SpeedConfig::default());
        controller.set_brake(brake.clone());
        controller.start().unwrap();
        
        controller.report_fault(HardwareFaultCode::OverCurrent);
        
        // Must not only command brake, but verify it
        assert!(brake.engagement_verified());
    }
}

// Kani harnesses
#[cfg(kani)]
mod verification {
    use super::*;
    
    #[kani::proof]
    fn verify_rpm_always_bounded() {
        let value: u16 = kani::any();
        let rpm = Rpm::saturating_new(value);
        assert!(rpm.get() <= 5000);
    }
    
    #[kani::proof]
    #[kani::unwind(5)]
    fn verify_rate_limiter_bounded() {
        let current: u16 = kani::any();
        let target: u16 = kani::any();
        let max_accel: u16 = kani::any();
        
        kani::assume(current <= 5000);
        kani::assume(target <= 5000);
        kani::assume(max_accel > 0 && max_accel <= 500);
        
        // ... rate limit logic ...
        // Assert delta <= max_accel
    }
}
```

**Gate 3→4: PASS** - Tests compile, ALL TESTS FAIL (no implementation).

---

## Layer 4: Implementation Agent

### Output (Key Implementation)

```rust
// src/lib.rs
#![no_std]
#![deny(unsafe_code)]
#![deny(clippy::unwrap_used)]
#![deny(clippy::panic)]

pub mod controller;
pub mod error;
pub mod types;

// src/controller.rs
use crate::{error::MotorError, types::{Rpm, DutyCycle}};

pub struct SpeedController {
    config: SpeedConfig,
    state: ControllerState,
    current_speed: Rpm,
    target_speed: Rpm,
    last_message_ms: u32,
    current_time_ms: u32,
    brake: Option<BrakeHandle>,
}

impl SpeedController {
    pub fn report_fault(&mut self, code: HardwareFaultCode) {
        self.state = ControllerState::Fault;
        self.target_speed = Rpm::ZERO;
        self.current_speed = Rpm::ZERO;
        
        // Command brake
        if let Some(ref mut brake) = self.brake {
            brake.engage();
            
            // CRITICAL: Verify brake engagement
            // (This was added after Layer 8 review finding)
            for _ in 0..50 {
                if brake.is_engaged() {
                    return;
                }
                // In real impl: delay 1ms
            }
            // Brake failed to engage - escalate
            // (handled by watchdog in real system)
        }
    }
    
    pub fn update_cycle(&mut self) {
        if self.state != ControllerState::Running {
            return;
        }
        
        let current = self.current_speed.get();
        let target = self.target_speed.get();
        let max_delta = self.config.max_acceleration.get();
        
        // Rate-limited update using saturating arithmetic
        let new_speed = if target > current {
            current.saturating_add(max_delta.min(target - current))
        } else {
            current.saturating_sub(max_delta.min(current - target))
        };
        
        self.current_speed = Rpm::saturating_new(new_speed);
    }
}
```

**Gate 4→5: PASS** - All tests pass, compiles with no warnings.

---

## Layer 5: Static Analysis Agent

### Output

```yaml
static_analysis_output:
  component_id: "COMP-MOTOR-CTRL"
  
  clippy_report:
    command: "cargo clippy -- -D warnings -D clippy::unwrap_used -D clippy::panic"
    errors: 0
    warnings: 0
    
  cargo_audit:
    vulnerabilities: 0
    warnings: 0
    
  cargo_deny:
    license_issues: 0
    duplicate_crates: 0
    
  unsafe_analysis:
    total_unsafe_blocks: 0  # Pure safe Rust!
    
  metrics:
    lines_of_code: 342
    cyclomatic_complexity_max: 6
    
  issues: []
```

**Gate 5→6: PASS** - No clippy errors, no unsafe code, no vulnerabilities.

---

## Layer 6: Formal Verification Agent

### Output

```yaml
formal_verification_output:
  component_id: "COMP-MOTOR-CTRL"
  
  kani_results:
    command: "cargo kani"
    harnesses:
      - name: "verify_rpm_always_bounded"
        property: "Rpm value never exceeds 5000"
        result: "VERIFIED"
        
      - name: "verify_rate_limiter_bounded"
        property: "Speed change per cycle ≤ max_acceleration"
        result: "VERIFIED"
        
      - name: "verify_no_overflow"
        property: "No integer overflow in arithmetic"
        result: "VERIFIED"
        
  verified_properties:
    - id: "VP-001"
      property: "SR-MOTOR-001: Speed limit mathematically enforced"
      tool: "Kani"
      confidence: "bounded (u16 range)"
      
    - id: "VP-002"
      property: "No panic paths in control loop"
      tool: "Kani"
      confidence: "bounded"
      
  assumptions:
    - id: "VA-001"
      assumption: "Hardware tick is called regularly"
      runtime_check: "Watchdog timer"
      
    - id: "VA-002"
      assumption: "SpeedConfig is valid (max_accel > 0)"
      runtime_check: "Validated at construction"
```

**Gate 6→7: PASS** - Key properties proven, assumptions documented.

---

## Layer 7: Integration & Dynamic Analysis Agent

### Output

```yaml
dynamic_analysis_output:
  component_id: "COMP-MOTOR-CTRL"
  
  miri_results:
    command: "cargo +nightly miri test"
    status: "PASS"
    ub_detected: []
    notes: "No unsafe code, clean run"
    
  fuzz_results:
    targets:
      - name: "fuzz_speed_controller"
        iterations: 1_000_000
        duration: "2 hours"
        crashes: 0
        coverage: "94%"
        
  coverage_report:
    tool: "cargo-llvm-cov"
    line_coverage: "97%"
    branch_coverage: "94%"
    uncovered_paths:
      - file: "src/controller.rs"
        lines: [201, 202]
        reason: "Brake timeout path - tested in integration"
        
  timing_analysis:
    - function: "update_cycle"
      wcet_measured: "47µs"
      wcet_budget: "100µs"
      status: "PASS"
      margin: "53%"
      
    - function: "report_fault"
      wcet_measured: "23µs"
      wcet_budget: "10ms"
      status: "PASS"
      
  integration_tests:
    - name: "test_full_can_to_pwm_pipeline"
      status: "PASS"
      latency: "890µs"
      
    - name: "test_fault_injection_overcurrent"
      status: "PASS"
```

**Gate 7→8: PASS** - Miri clean, fuzzing found no crashes, timing within budget.

---

## Layer 8: Independent Review Agent

### Output

```yaml
independent_review_output:
  component_id: "COMP-MOTOR-CTRL"
  reviewer: "Independent Review Agent"
  
  cold_read_findings:
    - id: "CR-001"
      location: "src/controller.rs:report_fault()"
      observation: |
        Brake engagement is commanded but success is assumed.
        No verification that brake actually engaged.
      concern: |
        SR-MOTOR-002 requires "verify brake engagement within 50ms"
        but implementation only commands brake without checking.
      severity: "CRITICAL"
      recommendation: |
        Add brake feedback verification loop with timeout.
        
  assumption_audit:
    - id: "AA-001"
      assumption: "Brake always engages when commanded"
      source: "Implicit in report_fault()"
      validation_status: "INVALID"
      risk_if_wrong: "Motor continues spinning during fault"
      
  consistency_check:
    - id: "CC-001"
      artifact_a: "SR-MOTOR-002"
      artifact_b: "src/controller.rs:report_fault()"
      inconsistency: |
        Requirement: "Verify brake engagement within 50ms"
        Code: Only commands brake, no verification
        
  findings_summary:
    critical: 1
    major: 0
    minor: 2
    
  overall_assessment: "CONDITIONAL"
  conditions:
    - "Resolve CR-001: Add brake engagement verification"
```

### Resolution

Implementation updated (shown in Layer 4 output above). Brake verification loop added:

```rust
// After fix
pub fn report_fault(&mut self, code: HardwareFaultCode) {
    // ... set fault state ...
    
    if let Some(ref mut brake) = self.brake {
        brake.engage();
        
        // NEW: Verify brake engagement (SR-MOTOR-002)
        for _ in 0..50 {  // 50ms timeout
            if brake.is_engaged() {
                return;  // Success
            }
            delay_ms(1);
        }
        // Brake failed - watchdog will catch this
    }
}
```

**Gate 8→9: PASS** - Critical finding resolved, review complete.

---

## Layer 9: Safety Analysis Agent

### Output

```yaml
safety_analysis_output:
  component_id: "COMP-MOTOR-CTRL"
  safety_level: "ASIL-C"
  
  hazard_correlation:
    - hazard_id: "HAZARD-001"
      description: "Uncommanded motor motion"
      severity: "S3"
      mitigations:
        - requirement_id: "SR-MOTOR-001"
          implementation: "Rpm::saturating_new() clamps to MAX"
          verification: "Kani proof verify_rpm_always_bounded"
          evidence:
            - "Kani verification report"
            - "Unit tests test_set_speed_*"
            
        - requirement_id: "SR-MOTOR-002"
          implementation: "report_fault() with brake verification"
          verification: "Integration test + timing measurement"
          evidence:
            - "test_fault_enters_safe_state"
            - "test_fault_verifies_brake_engagement"
            - "Timing: 23µs < 10ms budget"
            
      residual_risk: "Brake mechanical failure"
      risk_acceptable: true
      
  safety_case:
    claims:
      - id: "SC-CLAIM-001"
        claim: "Motor controller prevents uncommanded motion (HAZARD-001)"
        arguments:
          - id: "SC-ARG-001"
            argument: "Speed is mathematically bounded by type system"
            evidence:
              - { type: "proof", reference: "Kani verify_rpm_always_bounded" }
              - { type: "test", reference: "test_set_speed_exceeds_limit" }
              
          - id: "SC-ARG-002"
            argument: "Faults trigger verified safe state entry"
            evidence:
              - { type: "test", reference: "test_fault_verifies_brake_engagement" }
              - { type: "review", reference: "Layer 8 review finding CR-001 resolved" }
              
  coverage_analysis:
    requirements_coverage: "100%"
    code_coverage:
      line: "97%"
      branch: "94%"
    verification_coverage:
      static_analysis: "complete"
      formal_verification: "complete"
      dynamic_analysis: "complete"
      
  release_decision:
    decision: "RELEASE"
    rationale: |
      All 9 layers complete. All safety requirements verified.
      Critical brake verification issue found at Layer 8 and resolved.
      Safety case demonstrates ASIL-C compliance.
    conditions: []
```

---

## Swiss Cheese Model Analysis

This example demonstrates the Swiss Cheese Model in action:

```
DEFECT: Missing brake engagement verification

Layer 1 (Requirements): ✗ MISSED
  - Requirement said "verify" but review didn't catch ambiguity
  
Layer 2 (Architecture): ✗ MISSED  
  - Interface didn't require Result return from brake
  
Layer 3 (TDD): ✗ MISSED
  - Test was "test_fault_enters_safe_state" - didn't check verification
  - Later added test_fault_verifies_brake_engagement
  
Layer 4 (Implementation): ✗ INTRODUCED DEFECT
  - Implemented fire-and-forget brake command
  
Layer 5 (Static Analysis): ✗ MISSED
  - No lint can catch missing logic
  
Layer 6 (Formal Verification): ✗ MISSED
  - Proofs assumed brake works if called
  
Layer 7 (Dynamic Analysis): ✗ MISSED
  - Mock brake always succeeded
  
Layer 8 (Independent Review): ✓ CAUGHT!
  - Fresh eyes noticed gap between requirement and code
  
Layer 9 (Safety Analysis): N/A
  - Would have caught during hazard correlation
```

**Key Insight**: Layers 1-7 shared a blind spot (assumption that brake works). Layer 8's independent perspective broke the pattern. This is exactly why the Swiss Cheese Model requires diverse, independent layers.

---

## Metrics Summary

```yaml
metrics:
  total_issues_found: 4
  issues_by_severity:
    blocker: 0
    critical: 1  # Brake verification (caught at L8)
    major: 0
    minor: 3
    
  defect_injection_layer: 4  # Implementation
  defect_detection_layer: 8  # Independent Review
  layers_passed_through: 4   # L4, L5, L6, L7 missed it
  
  layer_effectiveness:
    layer_1: "0/0"  # No defects to catch at this layer
    layer_2: "0/0"
    layer_3: "0/1"  # Missed 1 (should have had better test)
    layer_4: "N/A"  # Injection point
    layer_5: "0/1"  # Can't catch logic errors
    layer_6: "0/1"  # Assumptions hid defect
    layer_7: "0/1"  # Mocks hid defect
    layer_8: "1/1"  # CAUGHT IT ✓
    layer_9: "N/A"  # Already caught
    
  first_pass_yield: "0%"  # Defect found, required rework
  rework_to_layer: 4      # Fixed in implementation
  
  final_outcome: "RELEASE"
  time_to_release: "Acceptable for ASIL-C"
```

---

## Lessons Learned

1. **Mocks can hide defects**: MockBrake always succeeded, hiding the verification gap
2. **Requirements need precision**: "Verify brake engagement" should have specified how
3. **Independent review is essential**: Fresh perspective caught what 7 layers missed
4. **Type safety is powerful but not complete**: Rpm bounds were proven, but logic gaps remained
5. **Swiss Cheese works**: Despite 7 layers missing it, the defect didn't escape
