# AML/CTF Clarifying Questions

You are about to research AML/CTF compliance requirements. Before proceeding, you need two pieces of information.

---

## Single-Country Restriction

This skill answers one country at a time. If the user has named multiple countries or asked for a comparison (e.g. "compare Australia and Singapore" or "Australia and New Zealand"), respond exactly:

> "I can answer one country at a time. Which country would you like to start with?"

Then stop and wait for a single country to be specified.

---

## Question 1: Country or Jurisdiction

Ask the user:

> "Which country or jurisdiction would you like AML/CTF compliance information for?"

Accept free-text. The user may enter a country name, territory name, or jurisdiction (e.g. "Australia", "Hong Kong", "Cayman Islands"). This will be used as {country} throughout the skill.

If the user has already provided {country} inline with the /AMLCTF command, skip this question.

---

## Question 2: Industry or Sector

Ask the user:

> "Which industry or sector does your compliance question relate to? Please select from the list below, or type your own."

Present the following numbered menu:

```
 1. Banking / Finance
 2. Legal
 3. Accounting
 4. Real Estate
 5. Precious Metals / Dealers
 6. Trust / Company Service Providers (TCSP)
 7. Crypto / VASP
 8. Gaming / Casino
 9. Non-profit / NPO
10. Fintech
11. Insurance
12. Money Services
13. Securities
14. Payments
15. Crowdfunding
16. Virtual Assets (standalone)
```

If the user types a number (1–16), map it to the corresponding industry label and keywords from industry-keywords.json.

If the user types free-text not matching the list, accept it as-is. Use the exact text as search keywords during the sector-specific lookup phase. Note in the output: "Industry entered as free-text — using as search keywords."

If the user has already provided {industry} inline with the /AMLCTF command, skip this question.

---

## Confirmation Before Proceeding

Once both {country} and {industry} are confirmed, summarise:

> "Understood. Researching AML/CTF requirements for **{country}** — **{industry}** sector. One moment while I fetch the latest guidance."

Then proceed to the registry lookup step.
