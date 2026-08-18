# NEWS

- v0.1.8
  - Add coordinateorder() so location data declares whether its coordinate
    columns are x then y or y then x, rather than the order being assumed
  - coordinates() and indices() now take the order wanted and return their
    columns in it, so callers need not know the native order or slice the
    result to find out
- v0.1.7
  - Add in metadata
- v0.1.6
  - Bugfixes
- v0.1.5
  - Bugfixes
- v0.1.4
  - Improve printing
  - Update GitHub workflows
  - Add Zenodo metadata
  - Fix testing and coverage checking to use GitHub workflows
- v0.1.3
  - CompatHelper fixes
- v0.1.2
  - CompatHelper fixes
  - Add TagBot
- v0.1.1
  - Bugfix for asindices()
- v0.1.0
  - Add CompatHelper
  - Move to Project.toml
