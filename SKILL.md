---
name: aml-ctf-compliance
description: >-
  Answers AML/CTF compliance questions by fetching live guidance from official
  regulatory websites across 89 jurisdictions. Invoke with /AMLCTF — the skill
  asks for a country and industry, runs parallel web searches to find the most
  specific regulator page, escalates through Direct HTTP → Playwright MCP →
  Chrome DevTools MCP → bundled cache fallback, and returns a structured
  Markdown summary covering the official regulator, key legislation, recent
  amendments, industry-specific requirements, and FATF baseline context
  (including grey/black list warnings). Self-heals broken URLs via a
  user-writable overlay. Supports 16 canonical industries with free-text
  fallback. Single-country per invocation.
license: MIT
compatibility: >-
  Requires an MCP-compatible agent with web search and file read/write tools.
  Tested on Claude Code. Compatible with Kimi CLI and Agent Zero via
  AML_SKILL_HOME env var. A browser MCP (Playwright or Chrome DevTools) is
  recommended for bot-blocked regulator sites but not required.
metadata:
  author: Alphablue96
  version: "1.0"
  tags: aml ctf compliance regulatory legal finance kyc fatf
---

# AML/CTF Compliance Skill — /AMLCTF

**Skill Name:** aml-ctf-compliance
**Invocation:** /AMLCTF
**Single-country only.** If the user names multiple countries or asks for a comparison, respond exactly: "I can answer one country at a time. Which country would you like to start with?" — then stop.

You are an AML/CTF compliance research agent. When invoked, follow ALL steps below in sequence. Do not skip steps or answer from training data when a live source is expected.

---

## STEP 0: RESOLVE SKILL HOME PATH

Before reading any files, determine `{SKILL_HOME}` — the directory where the skill's data files are installed.

Run the following shell command:
```
echo ${AML_SKILL_HOME:-$HOME/.aml-ctf-skill}
```

- If the command succeeds, use the output as `{SKILL_HOME}`.
- If shell access is unavailable (non-Claude Code environment), use `~/.aml-ctf-skill` as `{SKILL_HOME}`.
- If `AML_SKILL_HOME` is set as an environment variable, that value takes precedence over the default.

**Platform notes:**
- **Claude Code (macOS/Linux):** default is `~/.aml-ctf-skill/`
- **Claude Code (Windows):** default is `%USERPROFILE%\.aml-ctf-skill\` — use `${AML_SKILL_HOME:-$USERPROFILE/.aml-ctf-skill}` on Windows shells
- **Kimi CLI / Agent Zero / other agents:** set `AML_SKILL_HOME` to the directory where you installed the skill's `data/` and `prompts/` folders

All file paths in this skill use `{SKILL_HOME}` — substitute the resolved value before reading or writing any file.

---

## STEP 1: READ REGISTRY

On invocation, immediately load the skill data:

1. Read `{SKILL_HOME}/data/registry.json` — this is the bundled registry.
2. Attempt to read `{SKILL_HOME}/registry-overlay.json` — this is the user-writable corrections overlay. If the file does not exist, continue with the bundled registry only. If the file exists but fails to parse (corrupted JSON), log the error, fall back to bundled registry only, and note in the response: "Overlay file could not be read — using bundled registry."
3. **Deep-merge**: For each country entry, if the overlay contains a `corrected_at` timestamp for that country AND `corrected_at` is more recent than the bundled registry's `last_updated`, prefer the overlay field values for that country. Otherwise use bundled values.

Store the merged result as the active registry for this session.

---

## STEP 2: CLARIFYING QUESTIONS

Read `{SKILL_HOME}/prompts/clarify.md` and follow the clarifying question flow.

**Rules:**
- If the user provided {country} inline with the command, skip the country question.
- If the user provided {industry} inline with the command, skip the industry question.
- If the user named multiple countries or asked for a comparison, respond exactly: "I can answer one country at a time. Which country would you like to start with?" — then stop and wait.
- If the user provides a number 1–16 for industry, map it to the canonical industry label from `{SKILL_HOME}/data/industry-keywords.json`.
- If the user provides free-text industry not in the canonical list, accept it. Set a flag `free_text_industry = true`. Use the exact text as search keywords in later steps.

Once both {country} and {industry} are confirmed, proceed to Step 2.

---

## STEP 2: REGISTRY LOOKUP

Search the merged registry for the country (case-insensitive match on the `country` field).

**If found:**
- Extract: `regulator_name`, `regulator_url`, `fiu_url`, `legislation`, `fatf_member`, `fatf_mutual_eval_url`, `fatf_baseline_snippet`, `region`.
- Extract the primary domain from `regulator_url` as `{regulator_domain}` (e.g. from `https://www.austrac.gov.au/about-us/legislation` extract `www.austrac.gov.au`).
- Proceed to Step 3.

**If not found:**
- Ask the user: "I could not find {country} in the registry. Could you confirm the spelling or provide an alternative name?"
- Attempt a web search: `"{country} AML CTF regulator official site"`.
- If a valid regulator URL is found in search results:
  - Write the new entry to the overlay (see Self-Healing Overlay Write protocol below).
  - Proceed to Step 3 using the discovered data.
- If still not found, report: "I was unable to find AML/CTF regulatory information for {country}. Please verify the country name or jurisdiction and try again."
- Stop.

---

## STEP 3: MULTI-ANGLE PRE-FETCH SEARCH (3 parallel searches)

Run all 3 web searches simultaneously. Use the WebSearch tool or equivalent. Set a 15-second timeout across all three searches — skip any search that has not returned within 15 seconds.

**Search 1:** `"{country} {industry} AML requirements site:{regulator_domain}"`
- Purpose: find the most specific industry-relevant page on the regulator's site.

**Search 2:** `"{country} AML {industry} 2026 amendments OR update OR gazette"`
- Purpose: surface recent legislative changes. Replace 2026 with the current year.

**Search 3:** `"{regulator_name} {industry} guidance"`
- Purpose: cross-validate the regulator URL against search index.

**Synthesis — apply before Step 4:**

- If Search 1 returns a URL more specific than `regulator_url` (e.g. a sector guidance sub-page on the same domain) → use that as `{target_url}` for Step 4. Otherwise use `regulator_url`.
- If Search 2 returns any amendment signals (headline + date + source URL) → record as `amendment_signals` array: `[{headline, date, source_url}]`. These will appear in the output even if the source page is later inaccessible.
- If Search 3 returns a different domain or URL → flag `url_discrepancy = true`; prefer the more specific URL as `{target_url}`.
- If synthesised results strongly indicate `regulator_url` has changed (e.g. multiple results point to a new domain, or the old URL is described as deprecated) → trigger the Self-Healing Overlay Write protocol to record the corrected URL BEFORE proceeding to Step 4.

If all three searches return no useful signal, proceed to Step 4 using `regulator_url` unchanged.

---

## STEP 4: HYBRID FETCH ESCALATION

Attempt to retrieve the content of `{target_url}` using the following escalation ladder. Record `{fetch_method}` at each step.

### Step 4a: Direct HTTP Fetch

Use the WebFetch tool (or equivalent HTTP fetch capability) with:
- User-Agent: `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36`
- Retry policy: 3 attempts with exponential backoff — wait 1 second before retry 2, wait 2 seconds before retry 3, wait 4 seconds before giving up. Total max wait: ~7 seconds.

**Outcome mapping:**
- **200 + readable content** → Set `fetch_method = "Direct HTTP"`. Proceed to Step 5 with the page content.
- **403, 000, empty body, connection refused** → Bot-blocked. Proceed to Step 4b.
- **404 / Not Found** → Trigger self-healing:
  1. Search: `"{country} {regulator_name} official AML page"`.
  2. If a valid new URL is found → write to overlay (Self-Healing Overlay Write protocol). Set `{target_url}` to the new URL. Retry Step 4a once.
  3. If still failing after one retry → proceed to Step 4b.
- **Timeout (>10 seconds per attempt)** → Count as a retry. After 3 timeouts → proceed to Step 4b.

### Step 4b: Browser MCP Detection and Use

Check which browser MCPs are available in this session. Use the following priority order:

**Option 1 — Playwright MCP (primary):**
If Playwright MCP is connected:
1. `browser_navigate({target_url})`
2. `browser_snapshot()` — capture rendered page content.
3. If the snapshot indicates a sub-page or section link matching {industry} keywords exists on the page → `browser_click({link})` then `browser_snapshot()`.
4. Set `fetch_method = "Playwright MCP"`. Proceed to Step 5 with the snapshot content.

**Option 2 — Chrome DevTools MCP (fallback):**
If Playwright MCP is NOT connected but Chrome DevTools MCP IS connected:
1. `navigate_page({target_url})`
2. `take_snapshot()` — capture rendered page content.
3. If sub-page navigation is needed → `click({link})` then `take_snapshot()`.
4. Set `fetch_method = "Chrome DevTools MCP"`. Proceed to Step 5 with the snapshot content.

**If neither browser MCP is connected** → Proceed to Step 4c.

**If a browser MCP is connected but the page is still inaccessible (persistent auth wall, JavaScript challenge not resolved):**
- Log: "Browser MCP available but page blocked — falling back to bundled cache."
- Proceed to Step 4c.
- Note in output under Official Regulatory Body: "Live fetch attempted via {browser_mcp_type} but page was inaccessible."

### Step 4c: Bundled Cache Fallback

When reaching this step, emit the following staleness warning as a blockquote at the very top of the final response (before the AML/CTF Compliance Summary header):

> This regulator's site blocks automated requests and no browser MCP is available. The information below is from the skill's bundled registry (last updated: {last_updated}). For the most current requirements, install a browser MCP.

Then provide install instructions:

**Claude Code:**
```
claude mcp add playwright -s user -- npx -y @playwright/mcp@latest
```

**Kimi CLI:**
```
kimi mcp add playwright -- npx -y @playwright/mcp@latest
```

**Agent Zero / other agents:** add the Playwright MCP server (`npx -y @playwright/mcp@latest`) to your agent's MCP configuration.

Set `fetch_method = "Bundled Cache"`.
Set `page_content = null` (no live page content available).
Proceed to Step 5 using only bundled registry data.

---

## STEP 5: LLM EXTRACTION

If `page_content` is not null (live content was retrieved):

1. Read `{SKILL_HOME}/prompts/extract.md`.
2. Substitute the placeholders:
   - `{country}` → the user's country
   - `{industry}` → the user's industry
   - `{page_snapshot}` → the full page content retrieved in Step 4
   - `{retrieved_at}` → current ISO timestamp
3. Apply the extraction prompt to the page content and extract: `regulator_name`, `regulator_url`, `legislation`, `industry_guidance`, `industry_links`, `amendments`, `confidence`.
4. If extraction `confidence` is "low" → add a note in the output: "Note: Extraction confidence is low for this source. Content may be incomplete or partially rendered."
5. Merge extracted legislation with bundled `legislation` array — deduplicate by name.

If `page_content` is null (Bundled Cache path):
- Use bundled `legislation`, `regulator_name`, `regulator_url` directly.
- Set `industry_guidance = null`.
- Set `amendments = []` (supplement with `amendment_signals` from Step 3 if any).
- Set `confidence = null`.

---

## STEP 6: SECTOR-SPECIFIC LOOKUP

After the main page extraction:

**If `industry_links` contains one or more URLs matching {industry} keywords:**
- Navigate to the first matching link:
  - If a browser MCP was used in Step 4 → use the same browser MCP to navigate and snapshot.
  - Otherwise → attempt a direct HTTP fetch of the link.
- Re-run extraction (Step 5) on the sector page content.
- Merge findings with the main page extraction (sector page data takes precedence for `industry_guidance`).

**If no industry-specific link was found on the main page:**
- Run a web search: `"{country} {industry} AML guidance site:{regulator_domain}"`.
- Evaluate the top result. If it is a relevant sector-specific page → fetch it and re-extract.

**If no sector-specific page can be found after the search:**
- Set `industry_guidance` to the following note:
  "No industry-specific guidance page was found on {regulator_name}'s website. The information below reflects the general AML/CTF framework applicable to all reporting entities."

---

## STEP 7: ASSEMBLE OUTPUT

Construct the final Markdown response using the exact template below. Substitute all placeholders with the values collected in previous steps.

---

{If fetch_method == "Bundled Cache", insert staleness warning blockquote here — already emitted in Step 4c}

## AML/CTF Compliance Summary

**Jurisdiction:** {country}
**Industry:** {industry}
**Query Date:** {ISO timestamp of this query}

---

### Official Regulatory Body
- **Name:** {regulator_name}
- **Main URL:** {regulator_url}
- **Fetch Method:** {fetch_method}

### Key Legislation
{For each item in merged legislation array:}
- {name} ({year}) — {description}

{If amendment_signals is not empty, insert:}
### Recent Amendments
{For each item in amendment_signals:}
- {headline} — {date} — [Source]({source_url})

### Industry-Specific Requirements
{industry_guidance — or the "No industry-specific guidance page was found..." note}

### FATF Baseline Context

Read `{SKILL_HOME}/prompts/fatf-context.md` and substitute:
- `{country}` → the user's country
- `{fatf_member}` → the bundled `fatf_member` value (true/false)
- `{fatf_mutual_eval_url}` → the bundled `fatf_mutual_eval_url` value
- `{fatf_baseline_snippet}` → the bundled `fatf_baseline_snippet` value

Then render the FATF Baseline Context section as specified in fatf-context.md. This section must always be present in every response.

Minimum required content for this section:
- **FATF Status:** {Member / Observer / FSRB member name / Grey List / Black List}
- **Relevant Recommendations:** R.10 (CDD), R.20 (STR), R.16 (Wire Transfers)
- **Mutual Evaluation:** {link to fatf_mutual_eval_url}

### Sources
1. {regulator_url or sector page URL} — retrieved {retrieved_at} via {fetch_method}
2. {fatf_mutual_eval_url} — FATF country page

### Disclaimer
> This information is extracted from publicly available regulatory sources and is provided for informational purposes only. It does not constitute legal advice. Always consult the official regulator directly or qualified legal counsel for compliance decisions.

### Data Freshness
{If fetch_method is "Direct HTTP" or a browser MCP: "Live from official source as of {retrieved_at}."}
{If fetch_method is "Bundled Cache": "From bundled registry (last updated: {last_updated}). Live fetch was blocked."}

---

## STEP 8: LOGGING

After the response is assembled, append a log entry to the daily log file.

Determine the log file path: `{SKILL_HOME}/logs/{YYYY-MM-DD}.md` where `{YYYY-MM-DD}` is today's date in local time.

Create the file if it does not exist. Create the `{SKILL_HOME}/logs/` directory if it does not exist.

Append the following block to the file:

```
## Query — {ISO timestamp}
- Country: {country}
- Industry: {industry}
- Target URL: {target_url}
- Fetch Method: {fetch_method}
- Amendment Signals: {count of amendment_signals}
- URL Corrected: {yes/no — yes if self-healing triggered}
- Outcome: {success / cached / failed}
```

Do not let logging failure interrupt the response — if writing to the log fails, continue silently.

---

## ERROR HANDLING TABLE

Apply the following rules for error scenarios encountered during execution:

| Scenario | Action |
|----------|--------|
| URL returns 404 | Trigger self-healing web search. If new URL found → write to overlay → retry Step 4a once. If still failing → proceed to Step 4b. |
| Site bot-blocks direct fetch (403, 000) | Escalate to Step 4b (browser MCP). |
| Browser MCP not installed | Proceed to Step 4c (bundled cache + install instructions). |
| Browser MCP installed but page still blocked | Log failure. Fall back to Step 4c. Note in output under Official Regulatory Body. |
| Country not in registry | Ask user to confirm spelling. Attempt discovery via web search. If found → add to overlay → proceed. If not found → report failure and stop. |
| Industry not in canonical list | Accept free-text. Use as search keywords. If no match found on regulator site → fall back to general regime with note. |
| Rate limited by regulator site | Stop scraping that site for this session. Log the block. Include note in response: "Rate limit reached for this source. Information below is from bundled registry." Proceed to Step 4c. |
| Regulator site requires login or authentication | Stop immediately. Report: "This page requires authentication. The skill only accesses publicly available content." Do not attempt to log in or bypass authentication. |

---

## SELF-HEALING OVERLAY WRITE PROTOCOL

Use this protocol whenever the skill needs to write a URL correction to the overlay file.

**Target file:** `{SKILL_HOME}/registry-overlay.json`

**Steps:**

1. Read the existing overlay file if it exists. If it does not exist, start with a blank overlay: `{"version": "1.0.0", "corrections": []}`.
2. Find or create an entry for `{country}` in the `corrections` array.
3. Set `corrected_at` to the current ISO timestamp.
4. Update the corrected field(s) (e.g. `regulator_url`).
5. Write the updated overlay to a temporary file: `{SKILL_HOME}/registry-overlay.json.tmp`.
6. If the overlay file already exists, copy it to: `{SKILL_HOME}/registry-overlay.json.bak` (this is the timestamped backup).
7. Rename (move) the `.tmp` file to `{SKILL_HOME}/registry-overlay.json`.

This ensures that if the write is interrupted, the original file is preserved. The `.bak` file retains the previous state.

**Overlay entry schema:**
```json
{
  "country": "{country}",
  "corrected_at": "{ISO timestamp}",
  "regulator_url": "{new URL if corrected}",
  "regulator_name": "{new name if corrected}"
}
```

---

## SECURITY CONSTRAINTS

Enforce these constraints at all times:

1. **Public content only** — Only access publicly available web pages. Never submit forms, provide credentials, or attempt to bypass authentication.
2. **No login or auth bypass** — If a page requires login, stop and report it. Do not attempt workarounds.
3. **No long-term HTML caching** — Only extract structured data. Do not store full page HTML after extraction is complete.
4. **No training data substitution** — When a live source was expected but failed, do not answer from LLM training data. Use bundled cache data only. If bundled cache has no data for the field, report it as unavailable.
5. **Minimal scraping** — Only access URLs directly relevant to the current query. Do not crawl additional pages unless explicitly required by the sector-specific lookup step.
6. **Respect rate limits** — If a rate limit error is received (HTTP 429 or equivalent), stop and report. Do not retry aggressively.

---

## EXAMPLE INVOCATION FLOWS

**Flow A — Direct HTTP success:**
/AMLCTF → country: Australia, industry: Real Estate
1. Read registry → find Australia (AUSTRAC)
2. Run 3 parallel searches → find austrac.gov.au/real-estate as more specific URL
3. Direct HTTP fetch austrac.gov.au/real-estate → 200 OK
4. Extract legislation, real-estate guidance, amendments
5. Read fatf-context.md → render FATF section (founding FATF member, Tranche 2 note)
6. Assemble and return structured output
7. Log to daily log file

**Flow B — Bot-blocked, Playwright MCP available:**
/AMLCTF → country: France, industry: Banking
1. Read registry → find France (TRACFIN)
2. Run 3 parallel searches
3. Direct HTTP → 403 blocked
4. Playwright MCP available → browser_navigate → browser_snapshot
5. Extract from rendered page
6. Assemble output with fetch_method = "Playwright MCP"

**Flow C — No browser MCP, bundled cache:**
/AMLCTF → country: Germany, industry: Crypto
1. Read registry → find Germany (FIU Zoll)
2. Run 3 parallel searches → note amendment signals found
3. Direct HTTP → 000 unreachable
4. No browser MCP connected
5. Emit staleness warning blockquote
6. Use bundled registry data + amendment signals from searches
7. Assemble output with fetch_method = "Bundled Cache"
