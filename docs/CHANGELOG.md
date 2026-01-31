# Devbox Docker Changelog

## v1.1 (2026-01-30)

Chezmoi dotfiles v2, ed25519 SSH keys, host-shared uv cache, latest dev tool versions.

### Python: host-shared uv cache (replaces baked-in ML packages)
- Added `/etc/uv/uv.toml` with system-wide config: `cache-dir = "/projects/.uv-cache"`, `link-mode = "hardlink"`, PyTorch CUDA 12.8 index
- `python-uv.sh` no longer installs torch, jax, langchain, openai, huggingface-hub, or nose
- `python-base` venv is now a lightweight scratch env (ipython, numpy, scipy, pandas, matplotlib, sympy, python-dotenv)
- Heavy CUDA packages (torch, jax) are installed per-project via `uv add` — cached on the host mount at `/projects/.uv-cache`
- Build uses a throwaway `UV_CACHE_DIR=/tmp/uv-cache-build` (host mount doesn't exist during build, so system config cache-dir would write to a shadowed image layer)
- Added `docs/uv-README.md` (copied to `~/uv-README.md` in image) with per-project usage examples
- See `docs/uv-caching.md` and `docs/shared-uv-cache.txt` for design rationale

### Chezmoi dotfiles v2
- chezmoi source dir renamed `chezmoi/` → `dotfiles/` (matches the repo name)
- Build-time config moved to standalone `chezmoi.toml` file (was inline `printf`)
- Config sets `personal = false` (skips 1Password), `internal_network = false` (uses GitHub HTTPS for externals during build)
- Cleaned up legacy non-chezmoi files from dotfiles dir (`link.sh`, `git-branch.sh`, `nvim/`, `polybar/`, `vim-plug/`, `custom.zsh-theme`) that chezmoi was deploying to `~` as-is
- Run `chezmoi init` at runtime to re-evaluate config with proper hostname detection and 1Password

### SSH keys: RSA → ed25519
- `addssh.sh` updated to copy ed25519 keys (`ssh-keys/dev.pem` → `~/.ssh/id_ed25519`)
- Removed RSA `id_rsa` / `id_rsa.pub` handling
- `authorized_keys` built from all `*.pub` files found

### Dev tools: latest versions via language package managers
- `fzf` installed via `go install` in `go.sh` (was apt 0.29, now latest)
- `ripgrep` and `fd-find` installed via `cargo install` in `rust.sh` (were apt 13.0/8.3, now latest)
- `neovim` installed from GitHub releases in `devbase.sh` (was apt 0.6, now latest 0.10+)
- Removed `fzf`, `ripgrep`, `fd-find`, `neovim` from apt install block

### Build improvements
- Removed `--no-cache` from `build.sh` — Docker layer caching now works across rebuilds
- `run_once_after_install-tmux-plugins.sh` no longer fails the build on transient plugin download errors (`|| true`)

### Node
- Added AI coding assistants: `@openai/codex`, `@google/gemini-cli`

## v1.0 (2026-01-29)

Major restructure: split-brain home directory, chezmoi dotfiles, modernized toolchain installs.

### Split-brain home directory
- `/home/ankit` is now image-owned — toolchains, dotfiles, and SSH keys survive container recreation
- `/projects` is the persistent bind mount (was `/home/ankit`)

### Dotfiles via chezmoi
- Replaced the old `git clone dotfiles` + `link.sh` symlink approach with chezmoi
- chezmoi source lives in `chezmoi/` alongside the Dockerfile
- `.bashrc` is a chezmoi template with `{{ if .is_devbox }}` conditional for toolchain PATHs
- Managed files: `.bashrc`, `.bash_profile`, `.alias.sh`, `.gitconfig`, `.gitignore_global`, `.tmux.conf`, `.sqliterc`, `.git-branch.sh`, nvim config + vim-plug
- All PATH/env setup (cargo, uv, Go, CUDA, Java, coursier) moved from Dockerfile ENV directives into the chezmoi-managed `.bashrc`
- Added `.bash_profile` that sources `.bashrc` (fixes SSH login shells not loading config)

### Python: pyenv + pip replaced by uv
- `python-uv.sh` replaces `python.sh`
- `uv` manages Python versions (replaces pyenv — no more compiling from source)
- Shared base virtualenv at `/home/ankit/python-base` (replaces `pip install --system`)
- CLI tools (pre-commit, ruff) installed via `uv tool install`
- Same packages: numpy, scipy, pandas, matplotlib, jax[cuda], torch, langchain, openai, ipython

### Node: consolidated global installs
- `node.sh` now installs pnpm, bun, and typescript globally via `npm install -g`
- Removed the separate pnpm installer block from the Dockerfile (was `wget get.pnpm.io | bash`)
- All three (node, pnpm, bun) are system-wide installs, no home directory pollution

### Dockerfile layer caching fix
- Moved all `COPY script.sh` directives to immediately before their `RUN bash script.sh`
- Previously all scripts were COPYed upfront, so changing any script busted the cache for everything including apt installs
- Separated system-wide installs (root) from user home dir installs (`USER ankit`) with the USER directive at the boundary
- Removed `--mount=type=cache` from apt commands (was preventing layer caching)

### SSH keys baked into image
- `addssh.sh` is now actually executed during build (was only COPYed, never run)
- SSH keys from `ssh-keys/` are set up in `/home/ankit/.ssh/` at build time
- Removed `postbuild.sh` — all its tasks are now handled in the Dockerfile

### Terraform install fix
- Fixed path mismatch: `wget` downloaded to working dir but `unzip` looked in `/tmp/`
- Now unzips directly to `/usr/local/bin/`

### Third-party tool installs moved to direct downloads
- `just`: direct binary install via `just.systems/install.sh` (was makedeb apt repo)
- `terraform`: direct zip download with GPG + SHA256 verification (was HashiCorp apt repo)
- `1password CLI`: direct zip download (unchanged but cleaned up)

### Other
- Go upgraded to 1.25.6

### Removed
- `postbuild.sh` — no longer needed
- `python.sh` — replaced by `python-uv.sh`
- `backup-volumes.sh` — stale
- Old `COPY dotfiles/` + `link.sh` approach
- `COPY bin/` (directory didn't exist, would have failed on build)
- `--mount=type=cache` on apt commands
- pnpm home-directory installer block
