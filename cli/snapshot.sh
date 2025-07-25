#!/bin/bash
# BonaPic Project Snapshot Script
# Saves project folder structure, git status, and clasp status to text and JSON.

OUTPUT_DIR="./snapshots"
DATESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
TEXT_FILE="$OUTPUT_DIR/project_snapshot_$DATESTAMP.txt"
JSON_FILE="$OUTPUT_DIR/project_snapshot_$DATESTAMP.json"

mkdir -p "$OUTPUT_DIR"

echo "=== BonaPic Project Snapshot ===" > "$TEXT_FILE"
echo "Date: $(date)" >> "$TEXT_FILE"
echo "---------------------------------" >> "$TEXT_FILE"

# 1. Folder structure (excluding common ignores)
echo -e "\n[FOLDER STRUCTURE]" >> "$TEXT_FILE"
tree -a -I "node_modules|.git|snapshots" >> "$TEXT_FILE"

# 2. Git status
echo -e "\n[GIT STATUS]" >> "$TEXT_FILE"
git status >> "$TEXT_FILE" 2>/dev/null || echo "Git not initialized." >> "$TEXT_FILE"

# 3. Clasp status (Google Apps Script)
echo -e "\n[CLASP STATUS]" >> "$TEXT_FILE"
clasp status >> "$TEXT_FILE" 2>/dev/null || echo "Clasp not configured." >> "$TEXT_FILE"

# 4. Build JSON (basic keys for later parsing)
{
  echo "{"
  echo "  \"timestamp\": \"$(date)\","
  echo "  \"folder_structure\": \"$(tree -a -I "node_modules|.git|snapshots" | sed 's/\"/\\"/g')\","
  echo "  \"git_status\": \"$(git status 2>/dev/null | sed 's/\"/\\"/g')\","
  echo "  \"clasp_status\": \"$(clasp status 2>/dev/null | sed 's/\"/\\"/g')\""
  echo "}"
} > "$JSON_FILE"

echo "Snapshot created:"
echo "Text report: $TEXT_FILE"
echo "JSON report: $JSON_FILE"
