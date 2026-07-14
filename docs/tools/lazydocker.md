# lazydocker

Terminal UI for managing Docker containers, images, volumes, and `docker-compose` projects.

- **Repo:** https://github.com/jesseduffield/lazydocker
- **License:** MIT
- **Installed on tony-omen:** `~/.local/bin/lazydocker` (v0.25.2)

## Requirements

- Docker >= 29.0.0 (API >= 1.24)
- Docker Compose >= 1.23.2 (optional, needed for compose workflows)

## Gaussian Splatter project alias

A bash alias is set up in `~/.bashrc`:

```bash
alias lzd-gaussian='cd /home/tony/CascadeProjects/gaussian-splatting-docker && lazydocker'
```

Usage:

```bash
lzd-gaussian
```

This loads `lazydocker` in the Gaussian Splatter project directory so it picks up `docker-compose.yml` and shows the `colmap`, `3dgs`, `nerfstudio`, `variants`, and `jupyter` services.

> **Repo rename note:** the GitHub repository is now `https://github.com/tonezzz/chaba.git`. The local working directory still uses the original path `/home/tony/CascadeProjects/gaussian-splatting-docker`.

## Common keybindings

| Key | Action |
| --- | --- |
| `?` | Show all keybindings |
| `↑` / `↓` or mouse | Select container/service |
| `l` | View logs |
| `r` | Restart service/container |
| `b` | Rebuild service |
| `d` | Remove container/service |
| `a` | Attach to container/service |
| `q` | Quit |

## Multiple docker-compose projects

`lazydocker` binds to one compose context per instance (the current working directory). For multiple projects, use one terminal/tmux pane per project:

```bash
cd /path/to/project-a && lazydocker
```

Or scope by compose project name from anywhere:

```bash
lazydocker -p project-a
```

Point at a specific compose file explicitly:

```bash
lazydocker -f /path/to/project-a/docker-compose.yml
```

## Useful config notes

- Open config in-app: focus the project panel (top-left) and press `o` (or `e` for vim).
- Default log window is the last 60 minutes. Change `logs.since` or `commandTemplates.serviceLogs` to adjust.
- Text selection conflicts with mouse support; hold `Option`/Alt while dragging, or disable mouse with `gui.ignoreMouseEvents`.
- Running `lazydocker` inside a Docker container has a known bug where logs and CPU usage are not visible.
