# Devbox Docker Notes

## 2026-02-01: Fix chezmoi dotfiles in Docker

### Problem
Four issues with chezmoi dotfiles in Docker build:
1. **Broken `.git`**: `dotfiles/` is a git submodule. `COPY` preserves the `.git` file with a broken `gitdir:` pointer → chezmoi git operations fail
2. **`~/bin` not in PATH**: `stat` in `dot_bashrc.tmpl` fails for `~/bin` because it's created by chezmoi itself during apply
3. **Missing aliases**: Docker build PATH doesn't include `~/.cargo/bin` or `~/.local/bin`, so `lookPath` fails for eza, cargo, uv, uvx
4. **1Password prompts**: SSH templates call `onepasswordRead` when `personal=true`; runtime `chezmoi init` sets `personal=true` for hostname "devbox"

### Solution
- Replace `COPY dotfiles/` with `git clone` from GitHub HTTPS (real repo, working remote)
- Move `bin/vendor/` → `dot_local/bin/vendor/` so it deploys to `~/.local/bin/vendor/` (already on PATH)
- Two-pass `chezmoi apply`: first pass creates `.bashrc` with PATH, second pass in interactive bash gets full PATH for `lookPath`
- Documented that `chezmoi init --apply` at runtime requires `eval $(op signin)` first

### Additional fixes
- **Terraform**: GPG signature verification removed from `devbase.sh` — HashiCorp key import fails in Docker. SHA256 checksum still verified.
- **first-run.sh**: script for first SSH login — 1Password sign-in, `chezmoi init --apply` (personal=true), switch dotfiles remote to SSH URL
- **Login message**: `/etc/profile.d/first-run-notice.sh` shows reminder until `~/.first-run-done` marker exists
- **Wezterm SSHMUX**: binaries in `~/.local/bin/vendor/` are not found by SSHMUX — symlinked to `/usr/local/bin/` in Dockerfile

### Files changed
- `Dockerfile` — git clone + two-pass apply, first-run.sh COPY, login message
- `devbase.sh` — terraform GPG skip
- `first-run.sh` — new, first-run setup script
- `dotfiles/bin/` → `dotfiles/dot_local/bin/` (git mv)
- `dotfiles/.gitattributes` — updated LFS paths
- `dotfiles/dot_bashrc.tmpl` — updated PATH list
- `docs/DOCS.md` — updated chezmoi section
- `docs/CHANGELOG.md` — v1.2 entry

### Next steps
- Build and verify with `./build.sh`
- SSH in and verify PATH, aliases, vendored binaries
- Test `chezmoi apply`, `chezmoi update`, `chezmoi doctor` at runtime
- Test first-run.sh flow

## 2026-02-01: Agent mode — service account support

### Problem
1Password service accounts cannot access Personal or Private vaults. The current `onepasswordRead "op://Private/..."` calls in chezmoi templates fail when running with a service account token. Automated agents need a non-interactive setup path.

### Solution
- New chezmoi flag `is_agent`: auto-detected from `OP_SERVICE_ACCOUNT_TOKEN` env var
- Dedicated `Agents` vault in 1Password with copies of secrets agents need (`agent-ssh`, `claude-code`)
- Vault-aware templates: agents read from `op://Agents/...`, humans from `op://Private/...`
- `agent-first-run.sh`: non-interactive setup script (no `op signin`, no prompts)
- Agent git identity: `Devbox Agent <agent@ankitson.com>` for clear commit attribution
- `claudep` function: agents use direct `op read` instead of `op_exec_interactive`

### 1Password setup (manual, one-time)
1. Create vault `Agents` in 1Password
2. Generate dedicated agent SSH keypair (ed25519)
3. Add items: `agent-ssh` (private key, public key), `claude-code` (credential)
4. Add public key to GitHub and Gitea
5. Create service account with READ access to `Agents` vault only
6. Save the `ops_...` token

### Files changed
- `dotfiles/.chezmoi.toml.tmpl` — `is_agent` detection, `[onepassword] mode = "service"`
- `dotfiles/private_dot_ssh/private_id_rsa.tmpl` — vault-aware
- `dotfiles/private_dot_ssh/id_rsa.pub.tmpl` — vault-aware
- `dotfiles/private_dot_ssh/authorized_keys.tmpl` — vault-aware
- `dotfiles/dot_alias.sh.tmpl` — agent-safe `claudep`
- `dotfiles/dot_gitconfig.tmpl` — agent git identity
- `chezmoi.toml` — added `is_agent = false` build-time default
- `agent-first-run.sh` — new, non-interactive setup script
- `Dockerfile` — COPY agent-first-run.sh, updated login message

### Next steps
- Create `Agents` vault and service account in 1Password
- Generate and add agent SSH keypair
- Build image and test with `OP_SERVICE_ACCOUNT_TOKEN`
- Verify: SSH keys deployed, `claudep` works, git push works, Private vault inaccessible

## 2026-02-02: Simplify git clone with BuildKit SSH mount

### Problem
The Dockerfile used HTTPS to clone the dotfiles repo during build because SSH keys aren't available inside the build context. This worked but required the repo to be public and added unnecessary complexity to the documentation.

### Solution
Use Docker BuildKit's `--mount=type=ssh` feature to forward the host's SSH agent into the build. This allows direct SSH git clone without baking secrets into the build.

### Changes
- `Dockerfile`: Changed `RUN git lfs install && git clone https://...` to `RUN --mount=type=ssh git lfs install && git clone git@github.com:...`
- `build.sh`: Added `--ssh default` flag to forward SSH agent

### Requirements
- SSH agent must be running on host with GitHub key loaded (`ssh-add`)
- Build command forwards agent: `docker build --ssh default ...`

### Next steps
- Ensure `ssh-agent` is running and key is loaded before build
- Test with `./build.sh`
