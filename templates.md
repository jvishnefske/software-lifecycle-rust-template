# Safe Rust Agent System - Artifact Templates

## Traceability Matrix Template

```yaml
traceability_matrix:
  component_id: "{COMP-XXX}"
  version: "{version}"
  generated: "{ISO-8601}"
  
  requirements:
    - id: "FR-XXX-001"
      type: "functional"
      text: "{requirement text}"
      parent: "{source requirement}"
      
      implementation:
        module: "{module path}"
        functions: ["{function1}", "{function2}"]
        code_review: "{approved | pending}"
        
      tests:
        - id: "test_xxx_001"
          file: "tests/{file}.rs"
          type: "unit"
          result: "PASS"
          
        - id: "test_xxx_002"
          file: "tests/integration.rs"
          type: "integration"
          result: "PASS"
          
      verification:
        static_analysis: "PASS"
        formal_verification: "VERIFIED"
        dynamic_analysis: "PASS"
        
      coverage:
        line: "100%"
        branch: "100%"
        
    - id: "SR-XXX-001"
      type: "safety"
      text: "{safety requirement text}"
      derived_from: "HAZARD-XXX"
      # ... same structure as above
```

## Unsafe Audit Template

```yaml
unsafe_audit:
  component_id: "{COMP-XXX}"
  audit_date: "{date}"
  auditor: "{name}"
  
  summary:
    total_unsafe_blocks: N
    total_unsafe_functions: N
    total_unsafe_traits: N
    total_extern_blocks: N
    
  blocks:
    - id: "UNSAFE-001"
      location:
        file: "{file path}"
        line: N
        function: "{function name}"
        
      code: |
        unsafe {
            // code
        }
        
      category: "hardware | ffi | performance | other"
      
      purpose: "{why unsafe is necessary}"
      
      safe_alternative_considered: |
        {what safe alternatives were evaluated and why rejected}
        
      safety_requirements:
        - "{invariant that must hold}"
        - "{precondition for safety}"
        
      validation:
        - method: "code_review"
          reviewer: "{name}"
          date: "{date}"
          result: "APPROVED"
          
        - method: "miri"
          result: "PASS | N/A (hardware)"
          notes: "{if N/A, explain why}"
          
        - method: "testing"
          tests: ["{test names}"]
          result: "PASS"
          
      risk_assessment:
        likelihood: "low | medium | high"
        impact: "low | medium | high"
        residual_risk: "{description}"
        
      approval:
        status: "APPROVED | PENDING | REJECTED"
        approver: "{name}"
        date: "{date}"
        conditions: ["{any conditions}"]
```

## Test Report Template

```yaml
test_report:
  component_id: "{COMP-XXX}"
  version: "{version}"
  date: "{ISO-8601}"
  environment:
    rust_version: "{version}"
    target: "{target triple}"
    os: "{operating system}"
    
  summary:
    total_tests: N
    passed: N
    failed: 0
    skipped: N
    duration: "{time}"
    
  coverage:
    tool: "cargo-llvm-cov"
    line_coverage: "X%"
    branch_coverage: "X%"
    function_coverage: "X%"
    mcdc_coverage: "X% | N/A"
    uncovered_lines:
      - file: "{file}"
        lines: [N, M]
        reason: "{why uncovered}"
        
  unit_tests:
    count: N
    modules:
      - module: "{module}"
        tests: N
        passed: N
        
  integration_tests:
    count: N
    tests:
      - name: "{test name}"
        file: "tests/{file}.rs"
        duration: "{time}"
        result: "PASS"
        
  property_tests:
    count: N
    framework: "proptest"
    tests:
      - name: "{property name}"
        cases_run: N
        shrink_attempts: N
        result: "PASS"
        
  fuzz_tests:
    targets:
      - name: "{target name}"
        iterations: N
        duration: "{time}"
        crashes: 0
        corpus_size: N
        coverage_delta: "X%"
        
  miri:
    status: "PASS | FAIL | PARTIAL"
    tests_run: N
    ub_detected: 0
    notes: "{any skipped tests and why}"
    
  timing:
    measurements:
      - function: "{function name}"
        wcet_measured: "{time}"
        wcet_budget: "{budget}"
        status: "PASS | FAIL"
        iterations: N
        conditions: "{test conditions}"
```

## Verification Summary Template

```yaml
verification_summary:
  component_id: "{COMP-XXX}"
  version: "{version}"
  date: "{ISO-8601}"
  
  static_analysis:
    clippy:
      status: "PASS"
      deny_violations: 0
      warn_violations: N
      allowed_with_justification: N
      
    cargo_audit:
      status: "PASS"
      vulnerabilities: 0
      warnings: N
      
    cargo_deny:
      status: "PASS"
      license_issues: 0
      duplicate_crates: N
      
    unsafe_audit:
      status: "PASS"
      total_unsafe: N
      all_justified: true
      
  formal_verification:
    kani:
      status: "PASS"
      harnesses: N
      verified: N
      failed: 0
      timeout: 0
      
    prusti:
      status: "PASS | N/A"
      contracts: N
      verified: N
      
    creusot:
      status: "PASS | N/A"
      proofs: N
      proved: N
      
    verified_properties:
      - property: "Panic freedom in critical paths"
        tool: "Kani"
        status: "VERIFIED"
        
      - property: "Overflow freedom in arithmetic"
        tool: "Kani"
        status: "VERIFIED"
        
      - property: "Rate limiter correctness"
        tool: "Prusti"
        status: "VERIFIED"
        
    assumptions:
      - id: "VA-001"
        assumption: "{description}"
        runtime_validation: "{how validated}"
        
  dynamic_analysis:
    miri:
      status: "PASS"
      ub_detected: false
      
    sanitizers:
      address: "PASS"
      thread: "PASS | N/A"
      memory: "PASS | N/A"
      
    fuzzing:
      duration: "{total time}"
      iterations: N
      crashes: 0
      coverage_achieved: "X%"
      
    coverage:
      line: "X%"
      branch: "X%"
      mcdc: "X%"
      target_met: true
      
  independent_review:
    status: "COMPLETE"
    reviewer: "{reviewer ID}"
    findings:
      critical: 0
      major: N
      minor: N
    all_resolved: true
```

## Safety Case Fragment Template

```yaml
safety_case_fragment:
  component_id: "{COMP-XXX}"
  
  goal:
    id: "G-XXX"
    text: "{Safety goal statement}"
    context:
      - "C1: {contextual information}"
      - "C2: {operating environment}"
    assumptions:
      - "A1: {assumption}"
    
  strategy:
    id: "S-XXX"
    text: "Argument over {decomposition strategy}"
    
  sub_goals:
    - id: "G-XXX.1"
      text: "{Sub-goal statement}"
      
      arguments:
        - id: "ARG-XXX.1.1"
          text: "{Argument text}"
          
      evidence:
        - id: "E-XXX.1.1"
          type: "test | analysis | proof | review"
          reference: "{artifact reference}"
          confidence: "high | medium | low"
          description: "{what it demonstrates}"
          
  undeveloped:
    - id: "G-XXX.N"
      text: "{Goal not yet developed}"
      reason: "{why undeveloped}"
      plan: "{how it will be developed}"
```

## Change Impact Analysis Template

```yaml
change_impact_analysis:
  change_id: "CHG-XXX"
  date: "{date}"
  
  change_description: |
    {Description of the change}
    
  affected_files:
    - file: "{file path}"
      change_type: "modified | added | deleted"
      lines_changed: N
      
  impact_assessment:
    requirements:
      - id: "FR-XXX"
        impact: "none | modified | invalidated"
        action: "{required action}"
        
    safety_requirements:
      - id: "SR-XXX"
        impact: "none | modified | invalidated"
        action: "{required action}"
        
    tests:
      - id: "test_xxx"
        impact: "none | update | new_test_needed"
        action: "{required action}"
        
    verification:
      static_analysis: "rerun | no_change"
      formal_verification: "rerun | no_change"
      dynamic_analysis: "rerun | no_change"
      
    safety_case:
      impact: "none | update_evidence | rework_argument"
      affected_claims: ["{claim IDs}"]
      
  reverification_plan:
    - layer: N
      scope: "full | partial"
      items: ["{specific items}"]
      
  approval:
    status: "APPROVED | PENDING"
    approver: "{name}"
    date: "{date}"
```

## Pipeline Report Template

```yaml
pipeline_report:
  pipeline_id: "{unique ID}"
  component_id: "{COMP-XXX}"
  timestamp: "{ISO-8601}"
  trigger: "commit | PR | manual"
  commit_hash: "{hash}"
  
  environment:
    rust_version: "{version}"
    target: "{triple}"
    runner: "{CI runner}"
    
  layer_results:
    - layer: 1
      name: "Requirements"
      status: "PASS | FAIL | SKIP"
      duration: "{time}"
      issues: N
      artifacts:
        - name: "requirements.yaml"
          path: "{path}"
          
    - layer: 2
      name: "Architecture"
      status: "PASS | FAIL | SKIP"
      # ...
      
    # ... layers 3-9 ...
    
  gates:
    - gate: "1→2"
      status: "PASS | FAIL"
      blocking_issues: []
      
    # ... remaining gates ...
    
  metrics:
    total_duration: "{time}"
    issues_found: N
    issues_by_severity:
      blocker: 0
      critical: 0
      major: N
      minor: N
    coverage:
      line: "X%"
      branch: "X%"
    verification:
      kani_harnesses: N
      tests_passed: N
      
  outcome:
    status: "SUCCESS | FAILURE"
    blocking_issues: []
    next_steps: ["{action items}"]
```

## Defect Report Template

```yaml
defect_report:
  defect_id: "DEF-XXX"
  component_id: "{COMP-XXX}"
  
  detection:
    layer: N
    tool: "{tool name}"
    date: "{date}"
    detected_by: "{agent/person}"
    
  classification:
    severity: "BLOCKER | CRITICAL | MAJOR | MINOR"
    type: "logic | safety | performance | usability"
    
  description:
    summary: "{one line summary}"
    details: |
      {detailed description}
    reproduction: |
      {steps to reproduce}
    evidence:
      - type: "{type}"
        reference: "{reference}"
        
  root_cause:
    injection_layer: N
    analysis: |
      {why the defect was introduced}
    contributing_factors:
      - "{factor 1}"
      
  resolution:
    fix_description: |
      {how it was fixed}
    fix_commit: "{hash}"
    verification:
      - method: "{method}"
        result: "PASS"
        
  prevention:
    lessons_learned: |
      {what can prevent similar defects}
    process_improvements:
      - "{improvement}"
      
  metrics:
    time_to_detect: "{duration}"
    time_to_fix: "{duration}"
    layers_passed_through: N  # How many layers missed it
```

## Release Checklist Template

```yaml
release_checklist:
  component_id: "{COMP-XXX}"
  version: "{version}"
  target_date: "{date}"
  
  pre_release:
    requirements:
      - item: "All requirements traced"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
    implementation:
      - item: "All code reviewed"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
      - item: "No TODO/FIXME in code"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
    verification:
      - item: "All tests pass"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
      - item: "Coverage targets met"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
      - item: "Static analysis clean"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
      - item: "Miri passes"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
      - item: "Formal verification complete"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
    safety:
      - item: "All hazards mitigated"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
      - item: "Safety case complete"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
      - item: "Independent review complete"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
    documentation:
      - item: "API documentation complete"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
      - item: "User documentation complete"
        status: "DONE | PENDING"
        evidence: "{reference}"
        
  approvals:
    - role: "Development Lead"
      name: "{name}"
      date: "{date}"
      signature: "APPROVED | PENDING"
      
    - role: "Safety Engineer"
      name: "{name}"
      date: "{date}"
      signature: "APPROVED | PENDING"
      
    - role: "Quality Assurance"
      name: "{name}"
      date: "{date}"
      signature: "APPROVED | PENDING"
```
