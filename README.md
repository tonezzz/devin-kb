# Personal Knowledge Base

A GitHub-backed knowledge base that stays in sync across every PC and is readable by Devin, Windsurf, Claude Code, and other AI coding tools.

## Repo structure

```
.
├── .windsurf/rules/devin-kb.md   # Windsurf/Cascade workspace rules
├── AGENTS.md                            # Generic agent instructions (Claude Code, Codex, Devin, etc.)
├── docs/                                # Your actual knowledge articles
│   ├── general.md
│   ├── preferences.md
│   └── tech-stack.md
└── README.md                            # This file
```

## 1. Create the GitHub repo

1. Go to https://github.com/new and create a private repo named `devin-kb` (or `kb`).
2. Replace `YOUR_USERNAME` and `YOUR_REPO` in the commands below, then run them inside this folder:

```bash
git init
git add .
git commit -m "Initial knowledge base"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

On every other machine, clone it under `~/CascadeProjects` and add the `~/devin-kb` symlink so rules can find it at either path:

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git ~/CascadeProjects/devin-kb
ln -sfn ~/CascadeProjects/devin-kb ~/devin-kb
```

> Keeping the `~/devin-kb` path consistent (even as a symlink) makes global AI rules reliable across machines.

## 2. Make Windsurf/Cascade aware of it

### Option A — Always available (recommended)

Open this repo as a workspace (or add it to a multi-root workspace) in Windsurf. Cascade automatically reads `.windsurf/rules/*.md` when the repo is open.

### Option B — Global rule for every workspace

In Windsurf, open **Customizations → Rules → + Global** and paste the content from `.windsurf/rules/devin-kb.md`. This gives every workspace a summary of your KB, but it is limited to ~6,000 characters.

For larger KBs, keep Option A open in a multi-root workspace.

## 3. Make Devin aware of it

1. Connect the GitHub repo to your Devin account.
2. Devin will automatically ingest knowledge from `AGENTS.md`, `.windsurf/rules/`, and other supported files.
3. For facts that must be recalled in **every** session, go to **Settings & Library → Knowledge** and create an entry pinned to **All repositories**, or set a macro like `!kb`.

## 4. Daily usage

- Edit files in `docs/` or update the rule files.
- Commit and push whenever you make meaningful changes:

```bash
git add -A
git commit -m "Update KB"
git push
```

- On another PC, pull before starting:

```bash
git pull
```

## Tips

- Keep one idea per file in `docs/` so AI tools can retrieve focused context.
- Use `AGENTS.md` for tool-agnostic instructions that apply to any AI agent.
- Use `.windsurf/rules/` for Windsurf-specific behavior (triggers, globs, etc.).
