# hoffman

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Golden tests

Goldens (`test/**/goldens/*.png`) are recorded on Linux — the CI job runs on
`ubuntu-24.04` with Flutter 3.47.2, and glyphs render differently on macOS,
so goldens fail locally on a Mac. Record and check them in the matching
container (built from `tool/goldens/Dockerfile` on first use):

```sh
# record / update the goldens of the given test files
tool/goldens/run.sh --update-goldens test/features/auth/verification_goldens_test.dart
# check, as CI does
tool/goldens/run.sh test/features/auth/auth_goldens_test.dart
```
