# AML/CTF Compliance Skill

A Claude Code agent skill that answers AML/CTF compliance questions by fetching live data from official regulatory websites across 89 jurisdictions.

## Invocation

```
/AMLCTF
```

The skill asks you two questions — country and industry — then fetches live guidance from the official regulator's website and returns a structured compliance summary.

## Features

- **89-country bundled registry** with official regulator URLs, legislation seed data, and FATF baseline context
- **Hybrid fetch strategy**: direct HTTP → Playwright MCP → Chrome DevTools MCP → bundled cache fallback
- **3 parallel pre-fetch searches** to find the most specific industry guidance page and surface recent amendments
- **Self-healing overlay**: broken URLs are auto-corrected and written to `~/.aml-ctf-skill/registry-overlay.json`
- **16 canonical industries** with free-text fallback
- **FATF Baseline Context** section on every response (grey/black list warnings included)
- **Query logging** to `~/.aml-ctf-skill/logs/YYYY-MM-DD.md`

## Installation

### 1. Install the slash command

Copy `SKILL.md` to your Claude Code commands directory:

```bash
cp SKILL.md ~/.claude/commands/AMLCTF.md
```

### 2. Install the data files

```bash
mkdir -p ~/.aml-ctf-skill
cp -r data prompts ~/.aml-ctf-skill/
```

### 3. (Recommended) Install a browser MCP

Many official regulator sites block automated HTTP requests. A browser MCP lets the skill render pages as a real browser session.

**Playwright MCP (recommended):**
```bash
claude mcp add playwright -s user -- npx -y @playwright/mcp@latest
```

**Chrome DevTools MCP (fallback):**
```bash
claude mcp add chrome-devtools -s user -- npx -y chrome-devtools-mcp@latest
```

### 4. Test it

Open Claude Code and run:
```
/AMLCTF
```

## File Structure

```
aml-ctf-compliance-skill/
├── SKILL.md                        # The /AMLCTF slash command definition
├── data/
│   ├── registry.json               # 89-country bundled registry
│   └── industry-keywords.json      # 16-industry normalisation map
└── prompts/
    ├── clarify.md                  # Clarifying question flow
    ├── extract.md                  # LLM extraction prompt for page snapshots
    └── fatf-context.md             # FATF baseline section generator
```

At runtime, the skill also uses:
- `~/.aml-ctf-skill/registry-overlay.json` — user-writable URL corrections (auto-created)
- `~/.aml-ctf-skill/logs/YYYY-MM-DD.md` — per-day query log (auto-created)

## Output Format

Every response follows this structure:

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

## Known Issues / Roadmap

- **Multi-regulator support for UAE crypto**: VARA (Dubai), ADGM/FSRA (Abu Dhabi), and DFSA (DIFC) are not yet dynamically queried alongside CBUAE — noted in the FATF snippet
- **Multi-country comparison**: single-country only by design; comparison mode planned for a future major version
- **Legislation seed data**: most countries have empty legislation arrays — populated on first live query and written to overlay

## Disclaimer

This skill extracts information from publicly available regulatory sources. It does not constitute legal advice. Always consult the official regulator or qualified legal counsel for compliance decisions.

## Registry Last Updated

2026-05-15
