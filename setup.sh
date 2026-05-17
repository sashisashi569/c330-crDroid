#!/usr/bin/env bash
# setup.sh — crDroid 11 (Android 15) for Rakuten Mini (c330ae)
# Run inside `nix develop` (FHS shell).
#
# Usage:
#   ./setup.sh            — full setup (init + sync + link manifest)
#   ./setup.sh sync       — repo sync only
#   ./setup.sh build      — source envsetup & brunch

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
ANDROID_DIR="${ANDROID_DIR:-$HOME/android/crdroid}"
MANIFEST_URL="https://github.com/crdroidandroid/android.git"
MANIFEST_BRANCH="15.0"
DEVICE="c330ae"
JOBS="$(nproc)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────
info()  { echo -e "\033[1;34m[setup]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[  ok ]\033[0m $*"; }
err()   { echo -e "\033[1;31m[error]\033[0m $*" >&2; exit 1; }

require_cmd() { command -v "$1" &>/dev/null || err "'$1' not found — run inside nix develop"; }

# ── Step 0: sanity checks ─────────────────────────────────────────────────────
require_cmd repo
require_cmd git
require_cmd java

# ── Step 1: repo init ─────────────────────────────────────────────────────────
do_init() {
  info "Creating Android source dir: $ANDROID_DIR"
  mkdir -p "$ANDROID_DIR"
  cd "$ANDROID_DIR"

  if [ ! -d ".repo" ]; then
    info "Running: repo init -u $MANIFEST_URL -b $MANIFEST_BRANCH --git-lfs"
    repo init \
      -u "$MANIFEST_URL" \
      -b "$MANIFEST_BRANCH" \
      --git-lfs \
      --depth=1
    ok "repo init done"
  else
    ok "repo already initialised — skipping init"
  fi
}

# ── Step 2: install local manifest ───────────────────────────────────────────
do_manifest() {
  cd "$ANDROID_DIR"
  mkdir -p .repo/local_manifests
  local src="$SCRIPT_DIR/local_manifests/c330ae.xml"
  local dst=".repo/local_manifests/c330ae.xml"

  if [ -f "$src" ]; then
    cp -f "$src" "$dst"
    ok "Local manifest installed: $dst"
  else
    err "Local manifest not found at: $src"
  fi
}

# ── Step 3: repo sync ─────────────────────────────────────────────────────────
do_sync() {
  cd "$ANDROID_DIR"
  info "Syncing with $JOBS parallel jobs (this takes a while on first run)…"
  repo sync \
    -c \
    -j"$JOBS" \
    --force-sync \
    --no-clone-bundle \
    --no-tags \
    --optimized-fetch
  ok "repo sync complete"
}

# ── Step 4: build ─────────────────────────────────────────────────────────────
do_build() {
  # Android 15 lunch format: <product>-<release>-<variant>
  local release
  release="$(cat "$ANDROID_DIR/vendor/lineage/vars/aosp_target_release" 2>/dev/null || echo bp1a)"
  local product="lineage_${DEVICE}-${release}-user"

  cd "$ANDROID_DIR"
  info "Setting up build environment…"
  # shellcheck disable=SC1091
  source build/envsetup.sh
  info "Running: lunch $product"
  lunch "$product"
  info "Running: make bacon"
  make -j"$JOBS" bacon
  ok "Build finished. Output: out/target/product/$DEVICE/"
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
CMD="${1:-all}"
case "$CMD" in
  all)
    do_init
    do_manifest
    do_sync
    ;;
  sync)
    do_sync
    ;;
  build)
    do_build
    ;;
  init)
    do_init
    do_manifest
    ;;
  *)
    echo "Usage: $0 [all|init|sync|build]"
    exit 1
    ;;
esac
