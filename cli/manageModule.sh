#!/bin/bash

# -------------------------------------
# manageModule.sh – BonaPic CLI Manager (Full Version)
# Supports: status update, version bump, test, report, cleanup-report, delete, list (with filter)
# -------------------------------------

MODULE_REGISTER="docs/dev/Module_Register.md"
VERSIONS_JSON="versions.json"
SYSTEM_INDEX_JSON="systemIndex.json"
TODAY=$(date +%Y-%m-%d)

print_usage() {
  echo "Usage:"
  echo "  $0 <system_code> --status <New Status>"
  echo "  $0 <system_code> --bump-version"
  echo "  $0 <system_code> --test"
  echo "  $0 <system_code> --delete"
  echo "  $0 --report"
  echo "  $0 --cleanup-report"
  echo "  $0 --list [Status]"
  exit 1
}

# --- Quick List of All Active Modules (with optional status filter) ---
list_modules() {
  FILTER="$1"
  echo "📜 Active BonaPic Modules (as of $TODAY)"
  if [ -n "$FILTER" ]; then
    echo "(Filtered by status: $FILTER)"
  fi
  echo "---------------------------------------"
  printf "| %-15s | %-35s | %-12s | %-8s |\n" "System" "Path" "Status" "Version"
  echo "|-----------------|-------------------------------------|--------------|----------|"

  jq -c '.systems[]' "$SYSTEM_INDEX_JSON" | while read -r item; do
    sys=$(echo "$item" | jq -r '.system')
    path=$(echo "$item" | jq -r '.path')
    status=$(echo "$item" | jq -r '.status')
    version=$(jq -r --arg s "$sys" '.entries[] | select(.system==$s) | .version' "$VERSIONS_JSON" | tail -1)
    [ -z "$version" ] && version="N/A"

    # Show only if matches filter (or no filter given)
    if [ -z "$FILTER" ] || [ "$status" == "$FILTER" ]; then
      printf "| %-15s | %-35s | %-12s | %-8s |\n" "$sys" "$path" "$status" "$version"
    fi
  done
  echo ""
  exit 0
}

# --- Generate Status Report (Full History) ---
generate_report() {
  REPORT_FILE="docs/dev/Module_Status_Report.md"
  echo "# 📊 BonaPic Modules – Status Report" > "$REPORT_FILE"
  echo "**Generated:** $TODAY" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "| System | Path | Status | Version | Last Updated |" >> "$REPORT_FILE"
  echo "|--------|------|--------|---------|--------------|" >> "$REPORT_FILE"

  jq -c '.systems[]' "$SYSTEM_INDEX_JSON" | while read -r item; do
    sys=$(echo "$item" | jq -r '.system')
    path=$(echo "$item" | jq -r '.path')
    status=$(echo "$item" | jq -r '.status')
    version=$(jq -r --arg s "$sys" '.entries[] | select(.system==$s) | .version' "$VERSIONS_JSON" | tail -1)
    [ -z "$version" ] && version="N/A"
    echo "| $sys | $path | $status | $version | $TODAY |" >> "$REPORT_FILE"
  done

  echo "📄 Full history report generated: $REPORT_FILE"
  exit 0
}

# --- Cleanup and Generate One-Page Report ---
cleanup_report() {
  REPORT_FILE="docs/dev/Module_Current_Status.md"
  echo "🧹 Cleaning Module_Register.md and generating one-page status report..."

  sed -i '/^| *| *| *| *| *| *|$/d' "$MODULE_REGISTER"

  echo "# 📊 BonaPic Modules – Current Status" > "$REPORT_FILE"
  echo "**Generated:** $TODAY" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "| System | Path | Status | Version | Last Updated |" >> "$REPORT_FILE"
  echo "|--------|------|--------|---------|--------------|" >> "$REPORT_FILE"

  jq -c '.systems[]' "$SYSTEM_INDEX_JSON" | while read -r item; do
    sys=$(echo "$item" | jq -r '.system')
    path=$(echo "$item" | jq -r '.path')
    status=$(echo "$item" | jq -r '.status')
    version=$(jq -r --arg s "$sys" '.entries[] | select(.system==$s) | .version' "$VERSIONS_JSON" | tail -1)
    [ -z "$version" ] && version="N/A"
    echo "| $sys | $path | $status | $version | $TODAY |" >> "$REPORT_FILE"
  done

  echo "📄 One-page summary report saved to $REPORT_FILE"
  exit 0
}

# --- Validate args ---
[ $# -lt 1 ] && print_usage

case "$1" in
  --report) generate_report ;;
  --cleanup-report) cleanup_report ;;
  --list) list_modules "$2" ;;
esac

SYSTEM_CODE="$1"
ACTION="$2"
VALUE="$3"

[ ! -f "$VERSIONS_JSON" ] && echo "❌ versions.json not found" && exit 1
[ ! -f "$SYSTEM_INDEX_JSON" ] && echo "❌ systemIndex.json not found" && exit 1

MODULE_NAME="${SYSTEM_CODE#*.}"
MODULE_PATH="src/${SYSTEM_CODE/\./\/}.gs"
TEST_PATH="src/tests/test_${MODULE_NAME}.gs"
DOC_PATH="docs/modules/${SYSTEM_CODE}.md"

# --- Delete Module ---
if [ "$ACTION" == "--delete" ]; then
  echo "🗑 Deleting module: $SYSTEM_CODE"

  [ -f "$MODULE_PATH" ] && rm "$MODULE_PATH" && echo "🗑 Removed $MODULE_PATH"
  [ -f "$TEST_PATH" ] && rm "$TEST_PATH" && echo "🗑 Removed $TEST_PATH"
  [ -f "$DOC_PATH" ] && rm "$DOC_PATH" && echo "🗑 Removed $DOC_PATH"

  TMP=$(mktemp)
  jq --arg sys "$SYSTEM_CODE" 'del(.systems[] | select(.system==$sys))' "$SYSTEM_INDEX_JSON" > "$TMP" && mv "$TMP" "$SYSTEM_INDEX_JSON"
  echo "📂 Removed $SYSTEM_CODE from systemIndex.json"

  sed -i "/| $SYSTEM_CODE |/d" "$MODULE_REGISTER"
  echo "📓 Removed all entries for $SYSTEM_CODE from Module_Register.md"

  $0 --cleanup-report
  echo "✅ Module $SYSTEM_CODE deleted and all records cleaned."
  exit 0
fi

# --- Status Update ---
if [ "$ACTION" == "--status" ]; then
  [ -z "$VALUE" ] && print_usage
  TMP=$(mktemp)
  jq --arg sys "$SYSTEM_CODE" --arg st "$VALUE" \
    '(.systems[] | select(.system==$sys) | .status) |= $st' \
    "$SYSTEM_INDEX_JSON" > "$TMP" && mv "$TMP" "$SYSTEM_INDEX_JSON"
  echo "🔄 Updated status for $SYSTEM_CODE to '$VALUE'"

  echo "| $SYSTEM_CODE | $MODULE_NAME | src/${SYSTEM_CODE/\./\/}.gs | TBD | $VALUE | $TODAY |" >> "$MODULE_REGISTER"
  echo "📝 Logged status change in Module_Register.md"
  exit 0
fi

# --- Version Bump ---
if [ "$ACTION" == "--bump-version" ]; then
  TMP=$(mktemp)
  jq --arg sys "$SYSTEM_CODE" '
    (.entries | map(select(.system==$sys))[-1].version) as $ver |
    if $ver then
      (.entries += [{
        "system": $sys,
        "version": (
          ($ver | split(".") | .[2] |= (tonumber + 1)) | join(".")
        ),
        "createdAt": "'"$TODAY"'"
      }])
    else
      (.entries += [{
        "system": $sys,
        "version": "0.1.0",
        "createdAt": "'"$TODAY"'"
      }])
    end
  ' "$VERSIONS_JSON" > "$TMP" && mv "$TMP" "$VERSIONS_JSON"

  VERSION=$(jq -r --arg sys "$SYSTEM_CODE" '.entries[] | select(.system==$sys) | .version' "$VERSIONS_JSON" | tail -1)
  echo "| $SYSTEM_CODE | $MODULE_NAME | src/${SYSTEM_CODE/\./\/}.gs | TBD | Version $VERSION | $TODAY |" >> "$MODULE_REGISTER"
  echo "⬆️ Version bumped for $SYSTEM_CODE to $VERSION"
  exit 0
fi

# --- Run Tests for a Module ---
if [ "$ACTION" == "--test" ]; then
  echo "🧪 Running tests for $SYSTEM_CODE..."
  ./cli/test_all.sh > /dev/null
  TEST_RESULT=$?

  if [ $TEST_RESULT -eq 0 ]; then
    STATUS="Tested"
    echo "✅ All tests passed for $SYSTEM_CODE"
  else
    STATUS="Needs Fix"
    echo "❌ Tests failed for $SYSTEM_CODE"
  fi

  TMP=$(mktemp)
  jq --arg sys "$SYSTEM_CODE" --arg st "$STATUS" \
    '(.systems[] | select(.system==$sys) | .status) |= $st' \
    "$SYSTEM_INDEX_JSON" > "$TMP" && mv "$TMP" "$SYSTEM_INDEX_JSON"

  echo "| $SYSTEM_CODE | $MODULE_NAME | src/${SYSTEM_CODE/\./\/}.gs | TBD | $STATUS | $TODAY |" >> "$MODULE_REGISTER"
  echo "📓 Module status updated to '$STATUS' and logged in Module_Register.md"
  exit 0
fi

print_usage
