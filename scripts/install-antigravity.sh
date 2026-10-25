#!/usr/bin/env bash
# Installs or updates Superpowers as a global Antigravity plugin and workflow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG_DIR="${HOME}/.gemini/config"
TARGET_PLUGIN_DIR="${CONFIG_DIR}/plugins/superpowers"
TARGET_WORKFLOW_DIR="${CONFIG_DIR}/global_workflows"

echo "=== Installing Superpowers for Antigravity IDE ==="

mkdir -p "$TARGET_PLUGIN_DIR"
cp -f "$REPO_ROOT/.antigravity-plugin/plugin.json" "$TARGET_PLUGIN_DIR/plugin.json"
echo "[OK] Plugin manifest installed"

rm -rf "$TARGET_PLUGIN_DIR/skills"
cp -r "$REPO_ROOT/skills" "$TARGET_PLUGIN_DIR/skills"
echo "[OK] Skills synchronized"

if [ -d "$REPO_ROOT/.agents/rules" ]; then
  rm -rf "$TARGET_PLUGIN_DIR/rules"
  cp -r "$REPO_ROOT/.agents/rules" "$TARGET_PLUGIN_DIR/rules"
  echo "[OK] Rules synchronized"
fi

if [ -f "$REPO_ROOT/.agents/workflows/superpowers.md" ]; then
  mkdir -p "$TARGET_WORKFLOW_DIR"
  cp -f "$REPO_ROOT/.agents/workflows/superpowers.md" "$TARGET_WORKFLOW_DIR/superpowers.md"
  echo "[OK] Global slash command registered -> /superpowers"
fi

echo ""
echo "Superpowers is now globally active in Antigravity IDE!"
