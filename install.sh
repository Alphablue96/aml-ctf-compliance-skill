#!/usr/bin/env bash
# AML/CTF Compliance Skill — installer
# Supports: Claude Code, Kimi CLI, and any MCP-compatible agent on macOS/Linux

set -e

SKILL_HOME="${AML_SKILL_HOME:-$HOME/.aml-ctf-skill}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing AML/CTF Compliance Skill..."
echo "  Skill data → $SKILL_HOME"

# Install data files
mkdir -p "$SKILL_HOME/data" "$SKILL_HOME/prompts" "$SKILL_HOME/logs"
cp "$SCRIPT_DIR/data/registry.json"          "$SKILL_HOME/data/registry.json"
cp "$SCRIPT_DIR/data/industry-keywords.json" "$SKILL_HOME/data/industry-keywords.json"
cp "$SCRIPT_DIR/prompts/clarify.md"          "$SKILL_HOME/prompts/clarify.md"
cp "$SCRIPT_DIR/prompts/extract.md"          "$SKILL_HOME/prompts/extract.md"
cp "$SCRIPT_DIR/prompts/fatf-context.md"     "$SKILL_HOME/prompts/fatf-context.md"

echo "  Data files installed."

# Detect agent platform and install the slash command
install_claude_code() {
    mkdir -p "$HOME/.claude/commands"
    cp "$SCRIPT_DIR/SKILL.md" "$HOME/.claude/commands/AMLCTF.md"
    echo "  Slash command installed → ~/.claude/commands/AMLCTF.md"
    echo "  Invoke with: /AMLCTF"
}

install_kimi() {
    KIMI_CMD_DIR="${KIMI_COMMANDS_DIR:-$HOME/.kimi/commands}"
    mkdir -p "$KIMI_CMD_DIR"
    cp "$SCRIPT_DIR/SKILL.md" "$KIMI_CMD_DIR/AMLCTF.md"
    echo "  Skill installed → $KIMI_CMD_DIR/AMLCTF.md"
    echo "  Invoke with: /AMLCTF"
}

if [ "$1" = "--kimi" ]; then
    install_kimi
elif [ "$1" = "--claude" ]; then
    install_claude_code
elif command -v claude &>/dev/null; then
    install_claude_code
elif command -v kimi &>/dev/null; then
    install_kimi
else
    # Default: install SKILL.md to skill home for manual wiring
    cp "$SCRIPT_DIR/SKILL.md" "$SKILL_HOME/SKILL.md"
    echo "  SKILL.md copied → $SKILL_HOME/SKILL.md"
    echo "  No agent detected. Manually add SKILL.md as a slash command in your agent."
fi

echo ""
echo "Done. To use: invoke /AMLCTF in your agent."
echo ""
echo "Optional — install a browser MCP for bot-blocked regulator sites:"
echo "  Claude Code:  claude mcp add playwright -s user -- npx -y @playwright/mcp@latest"
echo "  Kimi CLI:     kimi mcp add playwright -- npx -y @playwright/mcp@latest"
echo ""
echo "Set AML_SKILL_HOME to override the default install path (\$HOME/.aml-ctf-skill)."
