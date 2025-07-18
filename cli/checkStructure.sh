#!/bin/bash

echo "🔍 Checking BonaPic project structure..."
echo "-----------------------------------------"

# --- FOLDERS TO VERIFY ---
FOLDERS=(
  "cli"
  "data"
  "docs"
  "lib"
  "src/core"
  "src/modules"
  "src/services"
  "src/orphanage"
  "src/sync"
  "src/templates"
  "src/tests"
  "src/utils"
)

# --- FILES TO VERIFY ---
FILES=(
  ".env"
  ".env.template"
  ".gitignore"
  ".eslintrc.json"
  "README.md"
  "src/core/envConfig.gs"
)

# --- Counters ---
missing_folders=0
missing_files=0

# --- Check folders ---
echo "📁 Folder Check:"
for folder in "${FOLDERS[@]}"; do
  if [ -d "$folder" ]; then
    echo "✅ $folder"
  else
    echo "❌ MISSING: $folder"
    missing_folders=$((missing_folders + 1))
  fi
done

echo ""
# --- Check files ---
echo "📄 File Check:"
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file"
  else
    echo "❌ MISSING: $file"
    missing_files=$((missing_files + 1))
  fi
done

# --- Summary ---
echo ""
echo "📊 Summary:"
echo "Missing folders: $missing_folders"
echo "Missing files: $missing_files"

if [ $missing_folders -eq 0 ] && [ $missing_files -eq 0 ]; then
  echo "✅ Project structure is COMPLETE."
else
  echo "⚠️  Project structure is INCOMPLETE."
fi
