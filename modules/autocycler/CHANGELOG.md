# Changelog

## 2026-10-09

### Added
- New `genome_size` input parameter: accepts `"auto"` (estimate via Raven, previous default behavior) or a user-provided value with optional suffix (`"4m"`, `"4.5M"`, `"5000k"`, `"1g"`, `"5000000"`). Providing a known genome size skips the Raven estimation step.

### Changed
- Pipelines calling `AUTOCYCLER` must now pass a `genome_size` argument (third positional input after `read_type` and `assemblers`). Use `"auto"` to preserve the previous behavior.
