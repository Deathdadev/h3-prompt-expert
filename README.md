# h3-prompt-expert — mirror of an official MiniMax skill

[![skills.sh](https://skills.sh/b/deathdadev/h3-prompt-expert)](https://skills.sh/deathdadev/h3-prompt-expert)

**Unofficial mirror.** The skill is authored and published by MiniMax; this repo only
re-hosts it so the [skills CLI](https://github.com/vercel-labs/skills) can track it as
an installable, updateable source. Nothing here rewrites or reauthors the payload.

- Official app: [MiniMax Design](https://design.minimax.io)
- Official market catalog: `https://design.minimax.io/api/v1/skills/market`
- Official download endpoint:
  `https://design.minimax.io/api/v1/skills/market/download?name=h3-prompt-expert&source=sync`
- Official open-source H3 repo and its portable sibling skill:
  [MiniMax-AI/MiniMax-H3](https://github.com/MiniMax-AI/MiniMax-H3) →
  [h3-prompt-writing](https://github.com/MiniMax-AI/MiniMax-H3/tree/main/skills/h3-prompt-writing)

## Why this repo exists

The endpoint above carries a query string. The skills CLI refuses to record
query-string URLs in `skills-lock.json`, so installing straight from it is one-shot:
`skills check` and `skills update` then report "No project skills to update" and never
notice a new MiniMax version. A public GitHub repo gives the same payload a query-free
address that the CLI does record, which is the whole point of this repo.

## Install

```bash
npx skills add Deathdadev/h3-prompt-expert --skill h3-prompt-expert
```

## Pull a new upstream version

```bash
npx skills check -g          # ↑ h3-prompt-expert has an update
npx skills update -g         # advances the lock to the newest commit
```

## Keeping the mirror current

`.github/workflows/upstream-sync.yml` runs `scripts/upstream-sync.sh` once a day and
commits, pushes, and tags `v<version>` only when the upstream content hash changes, so
the repo does not churn. Run it sooner with "Run workflow manually" in the Actions tab
right after MiniMax ships a version.

The script compares content, not the endpoint's `X-Skill-Hash` header — that header and
the raw zip bytes differ on every request for identical content, so a raw copy would
produce a new blob each poll. `upstream/h3-prompt-expert.zip` is a deterministic
re-zip (sorted paths, fixed timestamp, DEFLATE) of the mirrored tree.

## Contents

- `skills/h3-prompt-expert/` — the payload as the market endpoint serves it
- `upstream/h3-prompt-expert.zip` — deterministic re-zip of the same tree
- `upstream.sha256` — SHA-256 of that zip, for change detection
- `scripts/upstream-sync.sh` — fetch → extract → rebuild zip → status line

Clean-URL download sources (public repo only; the git source above is enough):
`https://cdn.jsdelivr.net/gh/Deathdadev/h3-prompt-expert@main/upstream/h3-prompt-expert.zip`
