# FATF Baseline Context Generation Prompt

You are generating the FATF Baseline Context section for an AML/CTF compliance summary for **{country}**.

---

## Bundled FATF Data for {country}

- **FATF Member:** {fatf_member}
- **FATF Mutual Evaluation URL:** {fatf_mutual_eval_url}
- **Bundled Baseline Snippet:** {fatf_baseline_snippet}

---

## Instructions

Using the bundled data above, generate the FATF Baseline Context section as a concise list of 3–5 bullet points.

### Required Bullet Points

1. **FATF Status** — State whether the country is:
   - A full FATF Member
   - A FATF Observer
   - A member of a FATF-Style Regional Body (FSRB) — name the FSRB (e.g. MONEYVAL, APG, GAFILAT, GIABA, EAG, ESAAMLG, MENAFATF, CFATF)
   - On the FATF Grey List (Jurisdictions Under Increased Monitoring)
   - On the FATF Black List (High-Risk Jurisdictions Subject to a Call for Action)

2. **Grey List / Black List Warning** — If the country is on the FATF Grey List or Black List, include a prominent warning:
   - Grey List: "CAUTION: {country} is currently on the FATF Grey List (Jurisdictions Under Increased Monitoring). Enhanced due diligence (EDD) should be applied to transactions and business relationships involving {country}-based counterparties."
   - Black List: "HIGH RISK: {country} is on the FATF Black List (High-Risk Jurisdiction). FATF calls for enhanced countermeasures. Apply maximum EDD and consult your compliance officer before engaging with {country}-based counterparties."
   - If the country was recently removed from the Grey List, note: "NOTE: {country} was removed from the FATF Grey List in {month/year}. Normal AML/CTF obligations apply but continued vigilance is warranted."

3. **Relevant FATF Recommendations** — Always include these baseline recommendations applicable to all reporting entities in this country:
   - R.10 — Customer Due Diligence (CDD): Know Your Customer obligations, ongoing monitoring
   - R.20 — Reporting of Suspicious Transactions (STR/SAR): obligation to report suspicious activity to the FIU
   - R.16 — Wire Transfers: obligations when sending or receiving wire transfers (Originator/Beneficiary data)
   - Add any other Recommendations that are particularly relevant based on the bundled snippet or country context (e.g. R.24 Beneficial Ownership for company formation jurisdictions, R.15 New Technologies for crypto-active jurisdictions)

4. **Mutual Evaluation** — Link to the FATF country page for the latest mutual evaluation report:
   - "Latest mutual evaluation and follow-up reports: {fatf_mutual_eval_url}"

5. **Note to User** — Include: "The FATF Recommendations represent the international minimum standard. {country}'s national legislation may impose stricter obligations. Always consult the official regulator directly."

---

## Output Format

Return the FATF Baseline Context as Markdown bullet points:

```markdown
### FATF Baseline Context
- **FATF Status:** {Member / Observer / FSRB member / Grey List / Black List — with FSRB name if applicable}
{If grey/black list: include prominent warning as a blockquote}
- **Relevant Recommendations:**
  - R.10 — Customer Due Diligence (CDD): all reporting entities must identify and verify customers and monitor the relationship
  - R.20 — Suspicious Transaction Reporting (STR): mandatory reporting of suspicious activity to {country} FIU
  - R.16 — Wire Transfers: originator and beneficiary information must accompany wire transfers
  {Additional recommendations if applicable}
- **Mutual Evaluation:** [Latest report and follow-up]({fatf_mutual_eval_url})
- **Note:** The FATF Recommendations represent the international minimum standard. {country}'s national legislation may impose stricter obligations.
```

---

## Important Rules

- Always include all three baseline Recommendations (R.10, R.20, R.16) regardless of jurisdiction.
- Never omit the Grey List or Black List warning if applicable — this is safety-critical compliance information.
- Do not answer from LLM training data if the bundled snippet is available — use the bundled snippet as the authoritative source.
- Keep the section concise — maximum 5 bullet points excluding the grey/black list warning.
