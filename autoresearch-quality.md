# Autoresearch: Skillset Quality & Portability

## Config
- **Benchmark**: `bash autoresearch-quality.sh`
- **Target metric**: `accuracy` (higher is better, target 100)
- **Scope**: All project files (skills/, commands/, rules/, README.md)
- **Branch**: `autoresearch/quality`
- **Started**: 2026-04-14T00:00:00Z

## Goal
Ensure a new user on a different machine with any combination of plugins can install and run this project successfully. Measures portability, completeness, clarity, robustness, and consistency.

## Dimensions
- **Portability**: No hardcoded paths, no plugin-specific assumptions in rules
- **Completeness**: All phases documented, all install steps present, all files covered
- **Clarity**: Unambiguous instructions Claude can follow, explicit budgets, actionable rules
- **Robustness**: Handles 0 plugins, missing files, disabled plugins
- **Consistency**: Token claims match measurements, names match across files

## Stop Conditions
- All 5 dimensions at 100%: DONE
- 5 consecutive runs with no improvement: STOP and reassess

## Rules
1. One change per experiment
2. Run benchmark after every change
3. Keep if accuracy improves, discard if it regresses
4. Log every run to autoresearch-quality.jsonl
5. When fixing a file, re-run both benchmarks (routing + quality) to ensure no regressions
