# AML/CTF Compliance Skill

A cross-platform agent skill that answers AML/CTF compliance questions by fetching live data from official regulatory websites across 89 jurisdictions.

## Invocation

```
/AMLCTF
```

The skill asks two questions — country and industry — then fetches live guidance from the official regulator's website and returns a structured compliance summary.

## Supported Platforms

| Platform | Status |
|----------|--------|
| Claude Code (macOS/Linux/Windows) | ✅ Native slash command |
| Kimi CLI | ✅ Slash command |
| Agent Zero | ✅ Via `AML_SKILL_HOME` env var |
| Any MCP-compatible agent | ✅ Manual SKILL.md wiring |

## Quick Install

```bash
git clone https://github.com/Alphablue96/aml-ctf-compliance-skill.git
cd aml-ctf-compliance-skill
chmod +x install.sh
./install.sh
```

The installer auto-detects your agent platform. Force a specific platform:

```bash
./install.sh --claude   # Claude Code
./install.sh --kimi     # Kimi CLI
```

## Manual Install

### 1. Install data files

```bash
# Default path — override with AML_SKILL_HOME env var
mkdir -p ~/.aml-ctf-skill
cp -r data prompts ~/.aml-ctf-skill/
```

### 2. Install the slash command

**Claude Code:**
```bash
cp SKILL.md ~/.claude/commands/AMLCTF.md
```

**Kimi CLI:**
```bash
cp SKILL.md ~/.kimi/commands/AMLCTF.md
```

**Other agents:** copy `SKILL.md` into your agent's commands/skills directory and register it as `/AMLCTF`.

### 3. (Recommended) Install a browser MCP

Many official regulator sites block automated HTTP requests. A browser MCP lets the skill render pages as a real browser session.

**Claude Code:**
```bash
claude mcp add playwright -s user -- npx -y @playwright/mcp@latest
```

**Kimi CLI:**
```bash
kimi mcp add playwright -- npx -y @playwright/mcp@latest
```

**Other agents:** add `npx -y @playwright/mcp@latest` as an MCP server in your agent config.

### 4. Custom install path (optional)

Set `AML_SKILL_HOME` to install data files anywhere:

```bash
export AML_SKILL_HOME=/path/to/your/skills/aml-ctf
./install.sh
```

The skill resolves this variable at runtime — no hardcoded paths.

## How It Works

1. Resolves `$AML_SKILL_HOME` (default: `~/.aml-ctf-skill`)
2. Loads bundled `registry.json` + user overlay (if any)
3. Asks: **country** and **industry**
4. Runs 3 parallel web searches to find the most specific guidance URL and surface recent amendments
5. Fetches the regulator page: Direct HTTP → Playwright MCP → Chrome DevTools MCP → bundled cache
6. Extracts structured data via LLM from the page snapshot
7. Returns a structured Markdown compliance summary
8. Self-heals broken URLs into `$AML_SKILL_HOME/registry-overlay.json`
9. Logs the query to `$AML_SKILL_HOME/logs/YYYY-MM-DD.md`

## Features

- **89-country bundled registry** with official regulator URLs, seed legislation, and FATF baseline context
- **Hybrid fetch strategy** with automatic escalation and fallback
- **Self-healing overlay** — broken URLs auto-corrected without needing a skill update
- **16 canonical industries** with free-text fallback
- **FATF grey/black list warnings** on every response
- **Query logging** per day

## Output Format

```markdown
## AML/CTF Compliance Summary

**Jurisdiction:** {country}
**Industry:** {industry}
**Query Date:** {ISO timestamp}

### Official Regulatory Body
### Key Legislation
### Recent Amendments (if found)
### Industry-Specific Requirements
### FATF Baseline Context
### Sources
### Disclaimer
### Data Freshness
```

## Registry Coverage

| Region | Countries |
|--------|-----------|
| Europe | 38 |
| Asia | 20 |
| North America | 15 |
| Africa | 11 |
| Latin America | 3 |
| Oceania | 2 |
| **Total** | **89** |

## File Structure

```
aml-ctf-compliance-skill/
├── install.sh                      # Cross-platform installer
├── SKILL.md                        # The /AMLCTF slash command definition
├── data/
│   ├── registry.json               # 89-country bundled registry
│   └── industry-keywords.json      # 16-industry normalisation map
└── prompts/
    ├── clarify.md                  # Clarifying question flow
    ├── extract.md                  # LLM extraction prompt
    └── fatf-context.md             # FATF baseline section generator
```

Runtime files (auto-created at `$AML_SKILL_HOME`):
- `registry-overlay.json` — URL corrections written by the skill
- `logs/YYYY-MM-DD.md` — per-day query log

## Disclaimer

This skill extracts information from publicly available regulatory sources. It does not constitute legal advice. Always consult the official regulator or qualified legal counsel for compliance decisions.

## Registry Last Updated

2026-05-15
