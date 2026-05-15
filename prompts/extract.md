# AML/CTF Extraction Prompt

You are extracting structured AML/CTF compliance information from a raw web page snapshot. The snapshot was retrieved from the official regulatory website for **{country}**. The user's industry is **{industry}**.

---

## Raw Page Snapshot

```
{page_snapshot}
```

---

## Extraction Instructions

Analyse the page snapshot above and extract the following information. Be precise — only extract what is explicitly stated on the page. Do not infer or supplement from training data.

### Fields to Extract

1. **regulator_name** — The full official name of the regulatory body or FIU as stated on this page.

2. **regulator_url** — The canonical URL for this page or the main AML/CTF landing page for this regulator.

3. **legislation** — An array of key AML/CTF legislation items mentioned. For each item include:
   - Name of the Act, Regulation, or Instrument
   - Year of enactment or most recent amendment (if stated)
   - A one-sentence description of what it covers

4. **industry_guidance** — Any sections, paragraphs, links, or guidance specifically addressing the **{industry}** sector. Include:
   - The section title or heading (if any)
   - A summary of the specific obligations mentioned
   - Any direct links to sector-specific guidance pages found on this page
   - If no industry-specific content is found, return null

5. **amendments** — Any recently announced changes, updates, consultations, or new requirements mentioned on the page. For each item include:
   - headline: a short description of the change
   - date: the date or year of the amendment (if stated, otherwise "date not stated")

6. **source_url** — The URL from which this snapshot was retrieved.

7. **retrieved_at** — The timestamp of retrieval in ISO 8601 format: {retrieved_at}

8. **confidence** — Your confidence in the extraction quality:
   - "high" — Page was clearly the official AML/CTF page with readable structured content
   - "medium" — Page contained relevant content but was partially rendered, in a foreign language, or had limited structure
   - "low" — Page content was minimal, poorly structured, or only tangentially relevant to AML/CTF

---

## Output Format

Return the extracted data as a JSON block:

```json
{
  "regulator_name": "string",
  "regulator_url": "string",
  "legislation": [
    {
      "name": "string",
      "year": "string or null",
      "description": "string"
    }
  ],
  "industry_guidance": "string or null",
  "industry_links": ["url1", "url2"],
  "amendments": [
    {
      "headline": "string",
      "date": "string"
    }
  ],
  "source_url": "string",
  "retrieved_at": "string",
  "confidence": "high | medium | low"
}
```

---

## Important Rules

- Do NOT fabricate legislation names, dates, or guidance that is not present on the page.
- If a field cannot be determined from the page content, use null.
- If the page is in a language other than English, translate key field values to English but note the original language in a comment field.
- If the page appears to require authentication or login to view full content, set confidence to "low" and note: "Page may require authentication for full content."
- If the page is an error page (404, 403, redirect loop), return: `{ "error": "Page not accessible", "source_url": "{source_url}", "retrieved_at": "{retrieved_at}" }`
