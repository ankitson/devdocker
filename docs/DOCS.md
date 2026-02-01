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
- **devbase.sh**: apt packages (build tools, monitoring, cli tools), neovim (GitHub release), git-lfs (GitHub release), just, cloudflared, docker-ce-cli, terraform, 1password CLI
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
- chezmoi dotfiles cloned from `https://github.com/ankitson/dotfiles.git` and applied (two-pass)
- `/projects` mount point created (persistent workspace)
- sshd hardened and set as entrypoint (port 22 internal, mapped to 2201 on host)

## Directory layout

```
images/devdocker/
  Dockerfile              # three-stage build
  build.sh                # docker build wrapper
  chezmoi.toml            # build-time chezmoi config (personal=false)
  dotfiles/               # chezmoi source directory (git submodule, cloned from GitHub at build)
  ssh-keys/               # ed25519 keypair (gitignored)
  addssh.sh               # copies ssh-keys/ into ~/.ssh/ during build
  first-run.sh            # interactive first-run setup (1Password sign-in)
  agent-first-run.sh      # non-interactive agent setup (service account)
  base.sh                 # user creation, locale
  devbase.sh              # apt packages, neovim, git-lfs, just, terraform, 1password, cloudflared, docker
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

**Important:** dotfiles changes must be pushed to GitHub before building the Docker image (the build clones from GitHub).

### Build time
Dotfiles are cloned from `https://github.com/ankitson/dotfiles.git` into `~/.local/share/chezmoi/` (chezmoi's source dir). This gives chezmoi a real git repo with a remote, so `chezmoi update` works at runtime. (The previous `COPY dotfiles/` approach broke because the submodule `.git` pointer was invalid inside Docker.)

A static `chezmoi.toml` is copied after the clone, overriding the template with build-safe defaults:
- `personal = false` — skips 1Password secret retrieval and SSH key deployment
- `internal_network = false` — external dependencies (clankerpedia) clone from GitHub HTTPS instead of Gitea SSH (Docker build network can't reach Gitea)

`chezmoi apply` runs twice (two-pass):
1. **First pass** (`chezmoi apply --force`): creates `.bashrc` with PATH entries for dirs that already exist (`.cargo/bin`, `.local/bin` from prior installs). Aliases may be incomplete since `lookPath` can't find tools not yet on PATH.
2. **Second pass** (`bash -ic 'chezmoi apply --force'`): starts an interactive shell that sources the `.bashrc` from pass 1, giving the full PATH. Now `lookPath` succeeds for eza, cargo, uv, uvx, etc., so aliases and tool-conditional blocks render correctly.

Deployed files: `.bashrc`, `.bash_profile`, `.alias.sh`, `.gitconfig`, `.gitignore_global`, `.tmux.conf`, `.sqliterc`, `.git-branch.sh`, `.vimrc`, nvim config, Claude Code settings. Also fetches external deps (tpm, vim-plug, clankerpedia) and runs `run_once_*` scripts.

### Runtime

**`chezmoi apply --force`** (safe, no auth needed): uses the existing build-time config (`personal=false`), re-renders templates with the current PATH. Good for picking up dotfile changes without enabling personal features.

**`chezmoi update`**: pulls latest dotfiles from the GitHub remote and re-applies. No auth needed (HTTPS clone).

**`chezmoi init --apply`** (requires 1Password): re-evaluates `.chezmoi.toml.tmpl`, which detects hostname `devbox` and sets `personal=true`, `internal_network=true`. This enables SSH key templates that call `onepasswordRead`. Requires 1Password auth first:
```bash
eval $(op signin)
chezmoi init --apply
```

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
| Flag | Build | Runtime (devbox) | Runtime (homeserver) | Runtime (agent) |
|---|---|---|---|---|
| `personal` | false | true | true | true |
| `is_devbox` | true | true | false | true |
| `is_homeserver` | false | false | true | false |
| `is_agent` | false | false | false | true |
| `internal_network` | false | true | true | false |

## Agent mode

For automated agents (CI, Claude Code tasks, etc.) that need secrets but can't use interactive 1Password sign-in.

### Prerequisites
1. A 1Password **`Agents` vault** with items: `agent-ssh` (SSH keypair), `claude-code` (OAuth token)
2. A 1Password **service account** with READ access to the `Agents` vault
3. The service account token (`ops_...`) passed as `OP_SERVICE_ACCOUNT_TOKEN` at runtime

### How it works
When `OP_SERVICE_ACCOUNT_TOKEN` is set, chezmoi automatically sets `is_agent=true` and `personal=true`. The `[onepassword] mode = "service"` config tells chezmoi to use the service account token instead of `op signin` sessions. All `onepasswordRead` calls in templates use the `Agents` vault instead of the `Private` vault.

### Setup
```bash
# One-shot: run agent task and exit
docker run -e OP_SERVICE_ACCOUNT_TOKEN="$TOKEN" ankit/devbox:1.3 \
  bash -lc '~/agent-first-run.sh && claude --task "..."'

# Or in docker-compose:
services:
  devbox-agent:
    build: ./images/devdocker
    environment:
      - OP_SERVICE_ACCOUNT_TOKEN=${OP_SERVICE_ACCOUNT_TOKEN}
```

### What's different in agent mode
| | Human (interactive) | Agent |
|---|---|---|
| 1Password auth | `op signin` (interactive) | `OP_SERVICE_ACCOUNT_TOKEN` (env var) |
| SSH keys | `op://Private/dev/*` | `op://Agents/agent-ssh/*` |
| Claude Code token | `op://Private/Anthropic/...` via `op_exec_interactive` | `op://Agents/claude-code/credential` via `op read` |
| Git identity | `Ankit Soni <dev@ankitson.com>` | `Devbox Agent <agent@ankitson.com>` |
| First-run script | `~/first-run.sh` | `~/agent-first-run.sh` |

### Security
- Token passed at runtime only (never baked into image layers)
- Service account has READ-only access to `Agents` vault — no access to `Private` vault
- Dedicated SSH keypair — independently revocable
- All service account reads are logged in 1Password audit trail

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
| git-lfs | GitHub release | `/usr/local/bin/` | Rebuild image (downloads latest) |
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
