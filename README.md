# Safe Verifiable Rust Agent System

A 9-layer multi-agent system implementing the NASA Swiss Cheese Model for safety-critical Rust development. Each layer provides independent verification with deliberately misaligned "holes" to catch defects that slip through other layers.

## Design Philosophy

Rust's ownership system, type safety, and `unsafe` boundaries provide a strong foundation for safety-critical software. This agent system builds on that foundation with:

1. **Defense in Depth**: 9 independent verification layers
2. **Test-Driven Development**: Tests written BEFORE implementation
3. **Formal Verification**: Mathematical proofs via Kani, Prusti, Creusot
4. **Dynamic Verification**: Runtime checks via Miri, sanitizers, fuzzing
5. **Full Traceability**: Requirements → Tests → Code → Verification → Safety Case

## Rust Toolchain Integration

| Tool | Layer | Purpose |
|------|-------|---------|
| `clippy` | 5 | 700+ lints including `clippy::pedantic`, `clippy::restriction` |
| `miri` | 7 | Undefined behavior detection in unsafe code |
| `cargo-tarpaulin` / `llvm-cov` | 3,7 | Code coverage including MC/DC |
| `kani` | 6 | Model checking / bounded verification |
| `prusti` | 6 | Deductive verification with contracts |
| `creusot` | 6 | Formal proofs via Why3 |
| `cargo-fuzz` / `afl` | 7 | Fuzz testing |
| `cargo-audit` | 5 | Dependency vulnerability scanning |
| `cargo-deny` | 5 | License and dependency policy |
| `cargo-careful` | 7 | Extra runtime checks in std |
| `cargo-semver-checks` | 8 | API compatibility verification |

## Layer Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 9: Safety Analysis Agent                                  │
│   - FMEA/FTA correlation, safety case assembly, release gate    │
├─────────────────────────────────────────────────────────────────┤
│ Layer 8: Independent Review Agent                               │
│   - Fresh-eyes review, adversarial analysis, assumption audit   │
├─────────────────────────────────────────────────────────────────┤
│ Layer 7: Integration & Dynamic Analysis Agent                   │
│   - Miri, fuzzing, sanitizers, timing, real hardware            │
├─────────────────────────────────────────────────────────────────┤
│ Layer 6: Formal Verification Agent                              │
│   - Kani, Prusti, Creusot - mathematical proofs                 │
├─────────────────────────────────────────────────────────────────┤
│ Layer 5: Static Analysis Agent                                  │
│   - Clippy, cargo-audit, cargo-deny, unsafe audit               │
├─────────────────────────────────────────────────────────────────┤
│ Layer 4: Implementation Agent                                   │
│   - Safe Rust, minimal unsafe, #![no_std] support               │
├─────────────────────────────────────────────────────────────────┤
│ Layer 3: TDD Test Author Agent                                  │
│   - Tests FIRST, coverage targets, property-based tests         │
├─────────────────────────────────────────────────────────────────┤
│ Layer 2: Architecture Agent                                     │
│   - Type-state patterns, ownership design, error taxonomy       │
├─────────────────────────────────────────────────────────────────┤
│ Layer 1: Requirements Agent                                     │
│   - Formalization, traceability, safety derivation              │
└─────────────────────────────────────────────────────────────────┘
```

## Safety-Critical Rust Patterns

This system enforces patterns aligned with safety standards:

- **No `std` in core logic**: `#![no_std]` with `heapless` collections
- **No panics**: `#![deny(clippy::panic)]`, `#![deny(clippy::unwrap_used)]`
- **No dynamic allocation**: Static buffers, arena allocators
- **Explicit error handling**: `Result<T, E>` with domain-specific error types
- **Bounded iteration**: No unbounded loops, iterator adapters with limits
- **Type-state machines**: Compile-time state transition enforcement
- **Unsafe isolation**: Minimal `unsafe` blocks with safety invariant documentation

## Directory Structure

```
safe-rust-agent-system/
├── README.md                          # This file
├── orchestrator.md                    # Workflow coordination
├── agents/
│   ├── 01_requirements_agent.md       # Requirements formalization
│   ├── 02_architecture_agent.md       # Type design & ownership
│   ├── 03_tdd_test_author_agent.md    # Test-first development
│   ├── 04_implementation_agent.md     # Safe Rust coding
│   ├── 05_static_analysis_agent.md    # Clippy & audits
│   ├── 06_formal_verification_agent.md # Kani/Prusti/Creusot
│   ├── 07_integration_dynamic_agent.md # Miri/fuzzing/timing
│   ├── 08_independent_review_agent.md  # Fresh-eyes analysis
│   └── 09_safety_analysis_agent.md    # Safety case & release
├── artifacts/
│   └── templates.md                   # Document templates
└── examples/
    └── motor_controller_example.md    # Complete walkthrough
```

## Quick Start

1. Provide requirements to the orchestrator
2. Each layer processes sequentially with quality gates
3. Defects route back to the originating layer
4. Final safety case assembled for certification

## Standards Alignment

- **ISO 26262**: Automotive functional safety (ASIL-A to ASIL-D)
- **DO-178C**: Airborne systems (DAL-A to DAL-E)  
- **IEC 61508**: Industrial functional safety (SIL-1 to SIL-4)
- **Ferrocene**: Rust qualified for ISO 26262 / IEC 61508

## Swiss Cheese Model Metrics

The system tracks:
- Defect injection point (which layer introduced)
- Defect detection point (which layer caught)
- Layer effectiveness (catch rate)
- First-pass yield
- Rework loops
- Field escapes (target: 0)
