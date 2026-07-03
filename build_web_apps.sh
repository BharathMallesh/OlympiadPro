#!/usr/bin/env bash
# Build the three Vidyora web apps as SEPARATE bundles, each locked to one role
# (student / educator / admin) so they can be hosted at separate URLs.
#
# Output:
#   build/web_student   -> host at e.g. https://app.vidyora.com       (students)
#   build/web_educator  -> host at e.g. https://educator.vidyora.com  (teachers)
#   build/web_admin     -> host at e.g. https://admin.vidyora.com     (founders)
#
# Usage:
#   ./build_web_apps.sh                         # same-origin API (backend serves the bundle)
#   ./build_web_apps.sh https://api.vidyora.com # bake in a cross-origin API base
#
# Hosting at PATHS instead of subdomains? add --base-href, e.g. for /educator/:
#   flutter build web --release -t lib/main_teacher.dart --base-href /educator/
# Note: no `set -u` — macOS bash 3.2 treats an empty array expansion as an
# unbound variable, which would kill the build when no API URL is passed.
set -eo pipefail
cd "$(dirname "$0")"

API="${1:-}"
DEF=""
[ -n "$API" ] && DEF="--dart-define=API_BASE_URL=$API"

# name:entrypoint pairs (bash 3.2 compatible — no associative arrays).
for pair in "student:main_student" "educator:main_teacher" "admin:main_admin"; do
  name="${pair%%:*}"
  entry="${pair##*:}"
  echo "== building web: $name =="
  flutter build web --release -t "lib/${entry}.dart" $DEF
  rm -rf "build/web_${name}"
  mv build/web "build/web_${name}"
  echo "   -> build/web_${name}"
done
echo "done: build/web_student, build/web_educator, build/web_admin"
