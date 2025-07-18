#!/bin/bash

# -------------------------
# createModule.sh – BonaPic (Template-based Version)
# -------------------------

if [ -z "$1" ]; then
  echo "❗ Please provide a system code (e.g., core.folders)"
  exit 1
fi

SYSTEM_CODE="$1"
MODULE_GROUP=$(echo "$SYSTEM_CODE" | cut -d. -f1)       # e.g., 'core'
MODULE_FILENAME=$(echo "$SYSTEM_CODE" | cut -d. -f2)    # e.g., 'folders'
DATE=$(date +%Y-%m-%d)

# Paths
CODE_FILE="src/$MODULE_GROUP/${MODULE_FILENAME}.gs"
TEST_FILE="src/tests/test_${MODULE_FILENAME}.gs"
DOC_FILE="docs/modules/$SYSTEM_CODE.md"
MODULE_REGISTER="docs/dev/Module_Register.md"
VERSIONS_JSON="versions.json"
SYSTEM_INDEX_JSON="systemIndex.json"
TEMPLATE_DIR="module-templates"

# Replace placeholders in templates
replace_placeholders() {
  sed "s/{{SYSTEM_CODE}}/$SYSTEM_CODE/g; s/{{MODULE_GROUP}}/$MODULE_GROUP/g; s/{{MODULE_NAME}}/$MODULE_FILENAME/g; s/{{DATE}}/$DATE/g"
}

# --- Create module file from template ---
if [ ! -f "$CODE_FILE" ]; then
  mkdir -p "src/$MODULE_GROUP"
  replace_placeholders < "$TEMPLATE_DIR/templateModule.gs" > "$CODE_FILE"
  echo "📝 Created module file from template: $CODE_FILE"
else
  echo "⚠️ Code file already exists: $CODE_FILE"
fi

# --- Create test file from template ---
if [ ! -f "$TEST_FILE" ]; then
  replace_placeholders < "$TEMPLATE_DIR/templateTest.gs" > "$TEST_FILE"
  echo "🧪 Created test file from template: $TEST_FILE"
else
  echo "⚠️ Test file already exists: $TEST_FILE"
fi

# --- Create documentation file from template ---
if [ ! -f "$DOC_FILE" ]; then
  mkdir -p "$(dirname "$DOC_FILE")"
  replace_placeholders < "$TEMPLATE_DIR/templateDoc.md" > "$DOC_FILE"
  echo "📄 Created documentation from template: $DOC_FILE"
else
  echo "⚠️ Documentation already exists: $DOC_FILE"
fi

# --- Register module ---
if ! grep -q "$SYSTEM_CODE" "$MODULE_REGISTER"; then
  echo "| $SYSTEM_CODE | $MODULE_FILENAME | $CODE_FILE | TBD | Not Started | $DATE |" >> "$MODULE_REGISTER"
  echo "📓 Added entry to Module_Register.md"
else
  echo "ℹ️ Module already registered in Module_Register.md"
fi

# --- Update versions.json ---
if [ -f "$VERSIONS_JSON" ]; then
  TMP=$(mktemp)
  jq --arg sys "$SYSTEM_CODE" --arg date "$DATE" \
    '.entries += [{"system":$sys,"version":"0.1.0","createdAt":$date}]' \
    "$VERSIONS_JSON" > "$TMP" && mv "$TMP" "$VERSIONS_JSON"
  echo "🔖 Updated versions.json"
else
  echo "⚠️ versions.json not found"
fi

# --- Update systemIndex.json ---
if [ -f "$SYSTEM_INDEX_JSON" ]; then
  TMP=$(mktemp)
  jq --arg sys "$SYSTEM_CODE" --arg code "$CODE_FILE" \
    '.systems += [{"system":$sys,"path":$code,"status":"Not Started"}]' \
    "$SYSTEM_INDEX_JSON" > "$TMP" && mv "$TMP" "$SYSTEM_INDEX_JSON"
  echo "📂 Updated systemIndex.json"
else
  echo "⚠️ systemIndex.json not found"
fi

echo "✅ Module scaffolding (with templates) complete: $SYSTEM_CODE"
