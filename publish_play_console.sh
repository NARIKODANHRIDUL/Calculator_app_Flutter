#!/usr/bin/env bash
# Exit on any error
set -e

TRACK="internal"
STATUS="completed"
KEY_FILE="android/play-service-account.json"
BUILD=true
RELEASE_NOTES=""
USER_FRACTION=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --track|-t)
      TRACK="$2"
      shift 2
      ;;
    --status|-s)
      STATUS="$2"
      shift 2
      ;;
    --key-file|-k)
      KEY_FILE="$2"
      shift 2
      ;;
    --release-notes|-n)
      RELEASE_NOTES="$2"
      shift 2
      ;;
    --user-fraction|-f)
      USER_FRACTION="$2"
      shift 2
      ;;
    --no-build)
      BUILD=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "========================================="
echo " Google Play Console App Bundle Publisher"
echo "========================================="
echo "Track:    $TRACK"
echo "Status:   $STATUS"
echo "Key file: $KEY_FILE"
echo ""

if [ ! -f "$KEY_FILE" ]; then
  echo "Error: Key file '$KEY_FILE' not found!"
  exit 1
fi

if [ "$BUILD" = true ]; then
  echo "==> Building App Bundle (flutter build appbundle --release)..."
  flutter build appbundle --release
fi

DART_ARGS=(
  run
  tool/publish_to_play_console.dart
  "--key-file=$KEY_FILE"
  "--track=$TRACK"
  "--status=$STATUS"
)

if [ -n "$USER_FRACTION" ]; then
  DART_ARGS+=("--user-fraction=$USER_FRACTION")
fi

if [ -n "$RELEASE_NOTES" ]; then
  DART_ARGS+=("--release-notes=$RELEASE_NOTES")
fi

echo "==> Publishing to Google Play Console..."
dart "${DART_ARGS[@]}"

echo "==> Done!"
