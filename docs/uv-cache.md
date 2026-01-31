# Reusing Heavy ML Python Packages with `uv` in Docker

## Problem

This dev Docker image is used for Python ML work (PyTorch, JAX, CUDA wheels, etc.).
Naively creating a new project with:

```bash
uv init .
uv add torch
```

causes ~2GB of NVIDIA / PyTorch wheels to be **re-downloaded every time**, even though:

* The image already installed these packages during build
* `uv` has a global cache mechanism
* Projects are correctly isolated using per-project `.venv` environments

### Why this happens

1. **Project isolation is intentional**
   `uv addalways creates or uses a project-local `.venv`.
   Activated `VIRTUAL_ENV` (e.g. a `python-base` venv) is ignored for project commands.

2. **Index mismatch**
   The image installs PyTorch from the CUDA index:

   ```
   https://download.pytorch.org/whl/cu128
   ```

   But `uv add torch` defaults to PyPI, so it resolves *different wheels*.

3. **Cache location matters**
   Even if wheels exist in the cache, `uv` can only hardlink them into a project venv if:

   * the cache directory and project directory are on the **same filesystem**

---

## Chosen Solution: Host-Shared `uv` Cache (Option B)

We use a **single `uv` cache directory on the host**, mounted into all dev containers.
This allows:

* Heavy ML wheels to be downloaded **once**
* All projects and containers to reuse them
* Fast installs via hardlinks (no copying, no re-downloads)
* Small Docker images (cache is not baked into the image)

### High-level layout

```
Host
└── /projects
    ├── my-project/
    │   └── .venv/
    └── .uv-cache/        ← shared uv cache

Container
└── /projects
    ├── my-project/
    │   └── .venv/
    └── .uv-cache/        ← same directory (bind mount)
```

Because the cache and project venvs live on the same filesystem, `uv` can hardlink wheels efficiently.

---

## Configuration

### 1. Mount the cache into the container

Mount the host cache directory into the container at the same path:

```text
Host:      /projects/.uv-cache
Container: /projects/.uv-cache
```

(Exact syntax depends on Docker / devcontainer / compose.)

---

### 2. Global `uv` configuration

Create `/etc/uv/uv.toml` inside the image:

```toml
# Use the shared cache
cache-dir = "/projects/.uv-cache"

# Prefer hardlinks when possible
link-mode = "hardlink"

# PyTorch CUDA index (used explicitly)
[[index]]
name = "pytorch-cu128"
url = "https://download.pytorch.org/whl/cu128"
explicit = true
```

This ensures:

* All `uv` commands use the shared cache
* PyTorch CUDA wheels are available as a named index

---

### 3. Per-project PyTorch source mapping

Each ML project must explicitly tell `uv` to resolve PyTorch from the CUDA index.

Add this to `pyproject.toml`:

```toml
[tool.uv.sources]
torch = [{ index = "pytorch-cu128", marker = "sys_platform == 'linux'" }]
torchvision = [{ index = "pytorch-cu128", marker = "sys_platform == 'linux'" }]
```

Now:

```bash
uv add torch torchvision
```

will:

* Resolve from `download.pytorch.org`
* Reuse cached CUDA wheels
* Avoid re-downloading ~2GB of data

---

## Result

* ✅ Per-project `.venv` isolation is preserved
* ✅ PyTorch/JAX/NVIDIA wheels are downloaded once
* ✅ New projects install instantly after the cache is warm
* ✅ Docker image stays small
* ✅ Works across multiple containers and images

This setup treats the `uv` cache as **shared infrastructure**, not part of a specific virtual environment — which is exactly how `uv` is designed to scale.
