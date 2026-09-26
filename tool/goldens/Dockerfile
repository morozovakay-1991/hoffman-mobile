# Linux image for recording golden files. Must match the CI job in
# .github/workflows/mobile.yml: ubuntu-24.04 (linux/amd64) and the same
# FLUTTER_VERSION — glyph rendering differs between OSes, so goldens recorded
# on macOS fail on CI.
FROM --platform=linux/amd64 ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git curl unzip xz-utils ca-certificates libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

ARG FLUTTER_VERSION=3.47.2
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git /opt/flutter
ENV PATH=/opt/flutter/bin:$PATH
RUN git config --global --add safe.directory '*' \
    && flutter --disable-analytics \
    && flutter precache --no-android --no-ios \
    && flutter --version
