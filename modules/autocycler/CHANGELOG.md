# Changelog

## 2026-10-09

### Added
- New `n_concurrent_tasks` input parameter: controls the number of parallel assembly jobs within a single AUTOCYCLER process. Set to `"auto"` (default) to calculate from available CPUs with a 4-thread-per-job floor, or specify an integer to override. Capped at available CPUs with a logged warning if exceeded.
- New `genome_size` input parameter: accepts `"auto"` (estimate via Raven, previous default behavior) or a user-provided value with optional suffix (`"4m"`, `"4.5M"`, `"5000k"`, `"1g"`, `"5000000"`). Providing a known genome size skips the Raven estimation step.

### Changed
- Reduced default CPU allocation from 6 to 4, allowing more concurrent AUTOCYCLER processes at the Nextflow level on typical machines.
- Parallelism and threads-per-job are now logged to the AutoCycler log file for easier debugging.
- Pipelines calling `AUTOCYCLER` must now pass `n_concurrent_tasks` (ninth positional input) and `genome_size` (fourth positional input). Use `"auto"` for both to preserve the previous behavior.
