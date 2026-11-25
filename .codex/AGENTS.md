## About me

I'm Rikard Eide, a software engineer at Solvera in Oslo since 26 October 2026 (MSc in informatics,
NTNU). I care about design and UX, and value pragmatic solutions a small team can build on over
time. At Solvera I mostly build the elektro app, the tools our RIE draws and calculates in.

Before Solvera I spent ten years at Otovo (2016 – October 2026), from employee #3 to its stock
listing: developer, product lead, engineering manager and finally Lead UX Engineer. I helped launch
Otovo's first AI features in 2023.

### Solvera

Solvera is an AI-native consulting engineering firm (rådgivende ingeniørselskap). We design the
technical systems in buildings (ventilation, heating, plumbing and electrical, i.e. VVS and elektro),
take the professional liability (ansvarsrett) ourselves, and do a growing share of the work with
our own AI tools. Founded in 2026 by Arif Mirza (CEO), Thorvald Thorsnes and Pål Eskild Rasmussen
(backgrounds from Spacemaker, Autodesk and Enode). Pre-seed of NOK 60 million led by Seedcamp in
October 2026. Betonmast is among the customers.

The code is one pnpm monorepo, `solveraeng/os`: TypeScript on Cloudflare Workers, every app under
`os.solvera.ai`, and a wiki that holds the company's knowledge. Text people read is Norwegian;
code identifiers are English.

## Meldinger til venner, bekjente og tidligere kolleger

Når du skriver en uformell melding på mine vegne, skriv på muntlig norsk. Bruk gjerne «Hei [fornavn]!» på egen linje og en kort, varm åpning. Bruk ord jeg ville sagt høyt, som «skikkelig dyktige», «supertett», «ta en kaffe» og «hadde det vært topp». En parentes eller en emoji på slutten passer når det føles naturlig for forholdet.

Gi nok kontekst til at mottakeren skjønner hvorfor jeg tar kontakt. Når vi deler en referanse, bruk den til å forklare en konkret likhet. Til en tidligere Otovo-kollega kan «rigget som et produktselskap (ikke helt ulikt Otovo)» forklare hvordan Solvera jobber. Si hva vi prøver å få til og hvordan det merkes i praksis.

Vær presis om hvor godt vi kjenner hverandre. «Selv om vi ikke jobbet supertett, satte jeg stor pris på å sparre med deg når jeg fikk sjansen» passer når det stemmer. Knytt så henvendelsen til noe konkret ved mottakerens erfaring eller rolle.

Når jeg ber om tips, spør hvem mottakeren selv gjerne skulle jobbet med og beskriv hva personen bør gjøre i dag. «Om du har et navn eller to jeg burde ta en kaffe med, hadde det vært topp! 🙌» gjør det lett å svare. Bruk disse formuleringene som eksempler på tone og presisjon, og tilpass dem til personen.

## How I work

These hold in every repo. A repo's own AGENTS.md wins where they disagree.
The same rules, worded for Claude Code, are in `~/.claude/CLAUDE.md`. Change both together.

### Git

- **Worktrees:** take them from the treehouse pool, never `git worktree add`:

      treehouse get --lease --lease-holder "codex:<topic>" -b <branch>

  It prints the worktree's path (under `~/.treehouse`) and nothing else on stdout; work in that
  directory. When the work is merged or abandoned, release it with `treehouse return <path>`. It
  refuses while the worktree has uncommitted changes, so commit them or ask first.
  `treehouse status` lists the repo's pool.
- **Commits:** always `git commit --no-gpg-sign` (or `git -c commit.gpgsign=false commit`). Agents have no GPG passphrase, and a signed
  commit hangs or fails. `config.toml` also sets `commit.gpgsign=false` in the shell
  environment, but pass the flag anyway.
- **Cleanup:** "clean up branches/worktrees" means only what this session created or worked on:
  its worktree, its local and remote branches. List anything else that looks stale and ask.
  Other worktrees may belong to sessions that are still running.

### Checking UI

- Use my real Chrome, not headless Chrome. Serve the app on localhost rather than opening a
  `file://` build. My window is very wide, so screenshots come back small: read state from the
  DOM and zoom in to look.
- For look-and-feel, animation and interaction-feel tweaks, skip the browser. Typecheck, commit,
  and tell me what to look for; I judge it faster. Use the browser for correctness bugs, where the
  DOM or the data answers the question.
- Several variants of an app side by side get consecutive dev server ports (4000, 4001, 4002):
  the base branch first, then the variants in order. Check the ports are free first.

### Sessions that run while I'm away

A session blocked on an approval prompt runs no code, so "tell me if you get stuck" in its
brief can never fire. When you start or brief one:

- Ban tools that can open an approval prompt. A check that needs one is skipped and listed in the
  final report.
- Whoever started it checks every 30–45 minutes: read the worktree's commits and file times, and
  if nothing moved, tell me it has stalled. Never tell me "it will notify you"; say when the next
  check runs.
- It commits WIP at least once per increment and pushes the branch, so nothing lives only on disk.
- The plan and the status live in a GitHub issue: the body is the plan as a checklist, comments
  are the status log. A brief names the issue number instead of pasting the plan. Every session
  ends with a status comment and ticks what landed.
- Work that needs my decisions or my logins goes first, while I'm here.
