#!/usr/bin/env bash
# Runs golden tests in the Linux container CI matches (see Dockerfile).
#
#   tool/goldens/run.sh                     # check every test
#   tool/goldens/run.sh --update-goldens test/features/auth/x_test.dart
#
# The repo is copied into the container, so its `flutter pub get` does not
# touch the host's .dart_tool; only test/**/goldens/*.png are copied back.
set -euo pipefail

IMAGE="hoffman-flutter:3.47.2"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker build --platform linux/amd64 -t "$IMAGE" "$ROOT/tool/goldens"
fi

docker run --rm --platform linux/amd64 -v "$ROOT":/src "$IMAGE" bash -c '
  set -euo pipefail
  mkdir /work
  tar -C /src --exclude=./.dart_tool --exclude=./build --exclude=./ios \
    --exclude=./android --exclude="*/failures" -cf - . | tar -C /work -xf -
  cd /work
  flutter pub get >/dev/null
  status=0
  flutter test "$@" || status=$?
  find test -type d -name goldens -print0 \
    | tar --null -T - -cf - | tar -C /src -xf -
  exit $status
' bash "$@"
