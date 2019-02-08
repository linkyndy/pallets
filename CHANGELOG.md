# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2019-02-08
### Added
- shared contexts (#9)
- handle TERM and TTIN signals (#15, #17)
- configure how long failed jobs are kept (#21)

### Changed
- use a single Redis connection when picking up work (#11)
- improve logging (#14)
- fix handling empty workflows and contexts (#18)
- fix encoding for msgpack serializer (#19)
- malformed jobs are given up rather than discarded (#22)

### Removed
- support for Ruby 2.1 & 2.2 (#13)

## [0.2.0] - 2018-10-02
### Added
- msgpack serializer (#5)

## 0.1.0 - 2018-09-29
- Pallets' inception <3

[Unreleased]: https://github.com/linkyndy/pallets/compare/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/linkyndy/pallets/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/linkyndy/pallets/compare/v0.1.0...v0.2.0
