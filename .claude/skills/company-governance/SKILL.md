---
name: company-governance
description: Research a company's governance structure (legal entities and subsidiaries, board, cap table and investor types, regulatory filings) and assess its financial-gravity risks in Eric Ries's Incorruptible terms, from the perspective of a candidate or employee. Use when preparing for a job interview, evaluating an employer, or when asked about a company's ownership, board, investors, or governance.
---

# Company governance check

Goal: put the company's *structure* on the record from primary sources, then
translate it into risks a candidate or engineer will feel day to day. Facts
first, take second, every claim sourced, every inference labelled.

## Inputs

- Company name, HQ, known office locations, founding year.
- Anything the user already has (pitch PDF, job ad, deck). Read it first: it
  names investors, offices and mission wording to check against.
- Where the user would sit (country, office, role). The employing entity and
  the local subsidiary's health matter to them directly.

## Procedure

### 1. Legal entities and subsidiaries

Use `scripts/registries.py` (stdlib Python, in this skill's folder) for the
JSON registries and WebFetch for the HTML ones. Run it as
`python3 ~/.claude/skills/company-governance/scripts/registries.py <cmd> ...`.

- **US**: `registries.py edgar "<name>" --ua "<your name> <your email>"`.
  Form D gives jurisdiction, offering size, investor count, SAFE conversions
  and the related-persons list (officers and directors) at each filing. Gaps
  matter: a company that raised after its last Form D has no public board
  record after that date. Skipping Form D is common and rarely enforced, so
  say "no public record", not "non-compliant".
- **UK**: Companies House. Fetch
  `https://find-and-update.company-information.service.gov.uk/search?q=<name>`,
  then `/company/<number>/officers`, `/persons-with-significant-control` and
  `/filing-history`. Note share capital at incorporation, model articles, the
  PSC statement, director DOBs, accounting-period changes, and whether any
  accounts have been filed and of what type.
- **Norway**: `registries.py brreg "<name>"` lists matches, then roles (CEO,
  chair, board, auditor, accountant) for the best match or `--orgnr`.
- **Denmark**: `registries.py cvr "<name or CVR number>"`. Name search is
  fuzzy, so check the name in the output. Confirm status wording such as
  "under tvangsopløsning" on proff.dk or datacvr.virk.dk via WebFetch.
- **Elsewhere**: Sweden allabolag.se, Germany northdata.com, Netherlands
  kvk.nl, France pappers.fr, Finland ytj.fi, Ireland core.cro.ie. Listed
  companies: the annual report and the exchange's filing feed.

For each subsidiary record incorporation date, share capital, directors,
owner, status and whether accounts are filed. A subsidiary in dissolution
proceedings or with overdue accounts is a signal about administrative
capacity, not necessarily solvency. Work the filing calendar backwards to the
most likely cause before saying anything about it.

### 2. Board and cap table

- Reliability order: regulatory filings, then the company's own about page
  and press releases, then Tracxn, Crunchbase, Dealroom and PitchBook via
  WebSearch snippets (their pages usually block fetches; the snippets still
  carry the facts).
- Build a round table: date, amount, the label the company used, lead, new vs
  existing investors, cumulative total. Watch for relabelling: the same round
  gets called seed, Series A and "strategic" by different sources.
- Classify every investor: financial VC, strategic corporate (whose parent,
  which business unit), thesis fund (climate, defense, health), hedge-fund
  venture arm, angel, accelerator (does it take equity?), government grant.
  Note which investors compete with each other or with the company's
  customers.
- Board: who sits, whom they represent, whether anyone is independent,
  whether the chair is separate from the CEO. Investor partners who leave
  their fund may keep their seat; say what you could and could not verify.
- Founder ages and tenure where registries publish them.

### 3. Structure signals

Check each; absence is a finding.

- Public-benefit corporation or equivalent, foundation or trust ownership,
  steward ownership, dual-class or founder super-voting shares, mission lock
  in the charter.
- Independent directors, separate chair, audit committee.
- CFO full-time, fractional or absent. General counsel.
- Secondary-market listings (EquityZen, Forge, Hiive): early liquidity and
  employee share sales.
- Filing hygiene across jurisdictions: Form D cadence, accounts on time, PSC
  statements consistent with the cap table.
- Government money and its strings: grant milestones, defense programmes,
  export control.

### 4. Narrative drift

Read the company's announcements in date order: seed release, product
launches, each round, the current deck. Write one line per year on what the
company said it was. Each narrative was aimed at an investor pool; count how
many theses the cap table now has to keep satisfied.

### 5. Map to Ries

Read `reference/ries-framework.md` in this folder. Then write down:

- **Magnetic alignment**: a real mission, customers who chose the company for
  it, talent pull, non-financial backers.
- **Financial gravity vectors**: the specific investors, structures or
  business-model tensions that pull toward extraction or exit. Name the
  mechanism (a strategic lead with a right of first refusal, a preferred
  stack, a revenue business funding a moonshot, grant deadlines).
- **Structural integrity**: what protections exist, what is absent, and
  whether it is too late to add them cheaply.

### 6. Translate to the employee's day

What will pull engineers off product work here, and how does it compare with
what the user already knows (public-market reporting, customer deliverables,
grant reporting, fundraising demos, forward-deployed work)? Which entity
employs them, how equity is granted and taxed across borders, what a change
of control does to it, whether the local office is viable.

## Output

Lead with the bottom line in two or three sentences. Then:

1. A table of public-record findings, one row per fact, source in the row.
2. Notes on reading the table, with every inference labelled as one.
3. Risks in Ries's terms, as bullets, each naming the mechanism.
4. What it means day to day, as bullets.
5. Five or six questions to ask, phrased as curiosity rather than audit.
6. Sources as a link list.

Offer to save the result where the user keeps notes. Do not create files
unprompted.

## Caveats

- Registry data lags and third-party mirrors lag more. Confirm anything
  alarming in two sources, then say what it most likely means and what would
  rule it out.
- No valuations, revenue or headcount without a source and a date.
- SEC endpoints refuse requests without a User-Agent. Tracxn and Crunchbase
  rate-limit fetches. Prefer search snippets for those.
- Keep the user's email out of anything saved or published. The `--ua`
  string is for the request only.
