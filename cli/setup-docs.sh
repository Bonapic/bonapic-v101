#!/bin/bash

echo "📚 Starting documentation & tracking setup..."
mkdir -p docs/dev

# --- dev_environment_blueprint.md ---
BLUEPRINT_PATH="docs/dev/dev_environment_blueprint.md"
if [ ! -f "$BLUEPRINT_PATH" ]; then
  cat > "$BLUEPRINT_PATH" <<EOF
# 🧩 BonaPic Dev Setup – Environment Blueprint
**Version:** 1.0  
**Date:** July 18, 2025  
**Status:** Initial Documentation  

## Purpose
To define the full baseline structure and files required for consistent, scalable development of the BonaPic platform.

## Core Components
- Folder structure
- Environment files (.env, .gitignore, etc.)
- CLI scripts (init, check, create)
- Documentation & versioning
EOF
  echo "📄 Created: $BLUEPRINT_PATH"
fi

# --- platform_systems_principles.md ---
PRINCIPLES_PATH="docs/dev/platform_systems_principles.md"
if [ ! -f "$PRINCIPLES_PATH" ]; then
  cat > "$PRINCIPLES_PATH" <<EOF
# 🧠 BonaPic Platform – Development Principles
**Version:** 1.0  
**Date:** July 18, 2025  
**Status:** Strategic Foundation  

## Guiding Principles
- Modular by design
- Unique & traceable identifiers
- Self-documented modules
- Test-first approach
- CLI-driven creation
- Version-aware architecture
- Developer-friendly by default
EOF
  echo "📄 Created: $PRINCIPLES_PATH"
fi

# --- Module_Register.md ---
MODULE_REGISTER="docs/dev/Module_Register.md"
if [ ! -f "$MODULE_REGISTER" ]; then
  cat > "$MODULE_REGISTER" <<EOF
# 📦 BonaPic Module Register

| System Code | System Name | File Path | Owner | Status | Created |
|-------------|-------------|-----------|--------|--------|---------|
|             |             |           |        |        |         |
EOF
  echo "📄 Created: $MODULE_REGISTER"
fi

# --- versions.json ---
VERSIONS_JSON="versions.json"
if [ ! -f "$VERSIONS_JSON" ]; then
  cat > "$VERSIONS_JSON" <<EOF
{
  "version": "0.1.0",
  "generatedAt": "$(date +%Y-%m-%dT%H:%M:%S)",
  "entries": []
}
EOF
  echo "📄 Created: $VERSIONS_JSON"
fi

# --- systemIndex.json ---
SYSTEM_INDEX_JSON="systemIndex.json"
if [ ! -f "$SYSTEM_INDEX_JSON" ]; then
  cat > "$SYSTEM_INDEX_JSON" <<EOF
{
  "systems": []
}
EOF
  echo "📄 Created: $SYSTEM_INDEX_JSON"
fi

echo "✅ Documentation setup complete."
