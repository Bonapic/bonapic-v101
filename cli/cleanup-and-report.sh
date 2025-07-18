#!/bin/bash

# --------------------------------------------
# cleanup-and-report.sh – BonaPic CLI Utility
# Cleans Module_Register.md and generates a "Current Status Report".
# --------------------------------------------

MODULE_REGISTER="docs/dev/Module_Register.md"
SYSTEM_INDEX_JSON="systemIndex.json"
VERSIONS_JSON="versions.json"
REPORT_FILE="docs/dev/Module_Current_Status.md"
TODAY=$(date +%Y-%m-%d)

echo "🧹 Cleaning Module_Register.md and generating summary report..."

# 1. Clean placeholder and duplicate empty rows in Module_Register.md
sed -i '/^| *| *| *| *| *| *|$/d' "$MODULE_REGISTER"

# 2. Generate Current Status Report
mkdir -p docs/dev
echo "# 📊 BonaPic Modules – Current Status" > "$REPORT_FILE"
echo "**Generated:** $TODAY" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| System | Path | Status | Version | Last Updated |" >> "$REPORT_FILE"
echo "|--------|------|--------|---------|--------------|" >> "$REPORT_FILE"

systems=$(jq -r '.systems[] | "\(.system)|\(.path)|\(.status)"' "$SYSTEM_INDEX_JSON")

while IFS='|' read -r sys path status; do
  # Get the latest version for this system
  version=$(jq -r --arg s "$sys" '.entries[] | select(.system==$s) | .version' "$VERSIONS_JSON" | tail -1)
  [ -z "$version" ] && version="N/A"

  echo "| $sys | $path | $status | $version | $TODAY |" >> "$REPORT_FILE"
done <<< "$systems"

echo "📄 Current Status Report saved to $REPORT_FILE"
echo "✅ Cleanup and summary complete."
