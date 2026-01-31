# Devbox Architecture

A Docker-based dev environment with CUDA, language toolchains, and chezmoi-managed dotfiles. Access via SSH on port 2201.

## Image structure

Three-stage Dockerfile build:

```
devbase                    nvidia/cuda:12.8.1 + locale + user creation (base.sh)
  └─ devbase_langtoolchains  system packages + language toolchains
       └─ devbox               SSH keys + chezmoi dotfiles + sshd
```

### Stage 1: devbase
- Base image: `nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04`
- Creates user `ankit` (uid 1000) with passwordless sudo
- Locale (en_US.UTF-8), timezone (America/Vancouver), unminimize

### Stage 2: devbase_langtoolchains
System-wide installs (as root):
- **devbase.sh**: apt packages (build tools, monitoring, cli tools), neovim (GitHub release), just, cloudflared, docker-ce-cli, terraform, 1password CLI
- **cpp.sh**: clang/LLVM toolchain, cmake, ninja, meson
- **node.sh**: Node 24 via nodesource, pnpm, bun, typescript, codex, gemini-cli
- **sql.sh**: PostgreSQL client, SQLite
- **go.sh**: Go 1.25.6, fzf (via `go install`)

User home dir installs (as `ankit`):
- **python-uv.sh**: uv, Python 3.14 + 3.12, lightweight `~/python-base` venv (numpy/scipy/pandas/matplotlib/sympy/ipython), CLI tools (pre-commit, ruff)
- **rust.sh**: rustup (nightly default), wasm-pack, cargo crates: ripgrep, fd-find, fselect, flamegraph, cargo-generate, eza
- **Claude Code**: installed to `~/.local/bin`

### Stage 3: devbox
- SSH keys from `ssh-keys/` baked into `~/.ssh/` via `addssh.sh`
- chezmoi dotfiles applied from `dotfiles/` source directory
- `/projects` mount point created (persistent workspace)
- sshd hardened and set as entrypoint (port 22 internal, mapped to 2201 on host)

## Directory layout

```
images/devdocker/
  Dockerfile              # three-stage build
  build.sh                # docker build wrapper
  chezmoi.toml            # build-time chezmoi config (personal=false)
  dotfiles/               # chezmoi source directory (git submodule or inline)
  ssh-keys/               # ed25519 keypair (gitignored)
  addssh.sh               # copies ssh-keys/ into ~/.ssh/ during build
  base.sh                 # user creation, locale
  devbase.sh              # apt packages, neovim, just, terraform, 1password, cloudflared, docker
  cpp.sh                  # clang/LLVM, cmake, ninja, meson
  node.sh                 # Node.js, pnpm, bun, typescript, AI assistants
  sql.sh                  # PostgreSQL client, SQLite
  go.sh                   # Go, fzf
  uv.toml                 # system-wide uv config → /etc/uv/uv.toml
  python-uv.sh            # uv, Python, lightweight base venv
  rust.sh                 # Rust, cargo tools (rg, fd, eza, etc.)
  docs/                   # this documentation
  logs/                   # build logs (gitignored)
```

## Home directory: split-brain design

`/home/ankit` is **image-owned** — toolchains, dotfiles, and SSH keys are baked into the image and survive container recreation. This is a deliberate break from the previous design where `/home/ankit` was a bind mount that shadowed everything installed during build.

`/projects` is the **persistent bind mount** for active work. Clone repos here, do work, push to Gitea, delete when done.

The tradeoff: changes to `~` outside of `/projects` (e.g. installing a new cargo crate, changing shell config) are lost on container recreation. To persist them, either rebuild the image or commit the running container.

## Chezmoi dotfiles

### Build time
The `dotfiles/` directory is copied to `~/.local/share/chezmoi/` (chezmoi's source dir). A static `chezmoi.toml` overrides the template with build-safe defaults:
- `personal = false` — skips 1Password secret retrieval and SSH key deployment
- `internal_network = false` — external dependencies (clankerpedia) clone from GitHub HTTPS instead of Gitea SSH (Docker build network can't reach Gitea)

`chezmoi apply --force` deploys: `.bashrc`, `.bash_profile`, `.alias.sh`, `.gitconfig`, `.gitignore_global`, `.tmux.conf`, `.sqliterc`, `.git-branch.sh`, `.vimrc`, nvim config, Claude Code settings. It also fetches external deps (tpm, vim-plug, clankerpedia) and runs `run_once_*` scripts (nvim PlugInstall, tmux plugin install, clankerpedia symlink setup).

### Runtime
After booting and signing into 1Password, run `chezmoi init` to re-evaluate `.chezmoi.toml.tmpl`. The template detects hostname `devbox` and sets `personal = true`, `internal_network = true`. Then `chezmoi apply` deploys SSH keys from 1Password and switches clankerpedia source to internal Gitea.

### What chezmoi manages
| Source file | Target | Notes |
|---|---|---|
| `dot_bashrc.tmpl` | `~/.bashrc` | Consolidated PATH loop, tool-conditional blocks |
| `dot_alias.tmpl` | `~/.alias.sh` | lookPath-gated aliases (eza, bat, terraform, etc.) |
| `dot_gitconfig.tmpl` | `~/.gitconfig` | Templated email, credential helper |
| `dot_bash_profile` | `~/.bash_profile` | Sources .bashrc (fixes SSH login shells) |
| `dot_tmux.conf` | `~/.tmux.conf` | tmux config with tpm |
| `dot_vimrc` | `~/.vimrc` | vim config |
| `private_dot_config/nvim/` | `~/.config/nvim/` | neovim config |
| `private_dot_claude/` | `~/.claude/` | Claude Code settings + statusline |
| `private_dot_ssh/` | `~/.ssh/` | Only when `personal = true` (1Password) |
| `.chezmoiexternal.toml.tmpl` | (externals) | tpm, vim-plug, clankerpedia |

### Feature flags (chezmoi data)
| Flag | Build | Runtime (devbox) | Runtime (homeserver) |
|---|---|---|---|
| `personal` | false | true | true |
| `is_devbox` | true | true | false |
| `is_homeserver` | false | false | true |
| `internal_network` | false | true | true |

## Python / uv cache

Host-shared cache at `/projects/.uv-cache` — persists across container rebuilds, supports hardlinks to per-project `.venv` dirs. PyTorch CUDA 12.8 index pre-configured in `/etc/uv/uv.toml`. `~/python-base` is a lightweight scratch venv (ipython, numpy, pandas), not a cache mechanism.

See [uv-caching.md](uv-caching.md) and [uv-README.md](uv-README.md) for details and per-project usage.

## SSH keys

SSH keys in `ssh-keys/` are gitignored. `addssh.sh` copies them into `~/.ssh/` during build. Currently uses ed25519 (`dev.pem` → `id_ed25519`, `dev.pub` → `id_ed25519.pub`). `authorized_keys` is built from all `*.pub` files found.

At runtime with `personal = true`, chezmoi can deploy keys from 1Password (overwriting the build-time keys if the templates produce different keys).

## Docker Compose integration

In the homeserver `docker-compose.yaml`, the devbox service:
- Builds from `./images/devdocker` context
- Maps host port 2201 → container port 22 (SSH)
- Bind-mounts a persistent workspace to `/projects`
- Shares the Docker socket for docker-in-docker
- Connected to `mybridge` network (can reach gitea, postgres, etc. by container name)

## Dev tool versions

Tools installed from apt get the Ubuntu 22.04 repo version. Tools with significant version gaps are installed from upstream:

| Tool | Source | Location | Update method |
|---|---|---|---|
| fzf | `go install` | `/usr/local/bin/` | `go install github.com/junegunn/fzf@latest` |
| ripgrep | `cargo install` | `~/.cargo/bin/` | `cargo install ripgrep` |
| fd | `cargo install` | `~/.cargo/bin/` | `cargo install fd-find` |
| eza | `cargo install` | `~/.cargo/bin/` | `cargo install eza` |
| neovim | GitHub release | `/opt/nvim-linux-x86_64/` | Rebuild image (downloads latest) |
| just | install script | `/usr/local/bin/` | Rebuild image |
| terraform | GitHub release | `/usr/local/bin/` | Update version in `devbase.sh` |
| 1password | vendor API | `/usr/local/bin/` | Rebuild image (downloads latest) |

## Building

```bash
cd images/devdocker
./build.sh                    # builds with layer caching
# or for a clean rebuild:
sudo docker build --no-cache --rm -t ankit/devbox:1.1 .
```

Layer caching means only changed layers rebuild. The Dockerfile is structured so each install script is a separate COPY+RUN pair — changing `rust.sh` only rebuilds from that layer onward.

## Connecting

```bash
ssh -p 2201 ankit@localhost          # from the host
ssh devbox                           # if ~/.ssh/config has the devbox entry
```
