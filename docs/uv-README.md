# Python / uv setup

uv is the package manager. Python 3.14 and 3.12 are pre-installed.
A lightweight `~/python-base` venv (ipython, numpy, pandas) is available for quick scripting.

Package cache lives at `/projects/.uv-cache` (host-shared, persists across rebuilds).
The PyTorch CUDA 12.8 index is pre-configured system-wide in `/etc/uv/uv.toml`.

## Per-project usage

New projects need a `[tool.uv.sources]` block to route torch/jax to the right index:

```bash
uv init my-ml-project && cd my-ml-project
```

Add to `pyproject.toml`:

```toml
[tool.uv.sources]
torch = [{ index = "pytorch-cu128", marker = "sys_platform == 'linux'" }]
torchvision = [{ index = "pytorch-cu128", marker = "sys_platform == 'linux'" }]
```

Then:

```bash
uv add torch torchvision          # uses CUDA 12.8 wheels, cached on host
uv add jax[cuda12]                # CUDA via pip extra, no special index needed
uv add numpy pandas matplotlib    # cached after first install
```

First install downloads; every subsequent `uv add` across any project is near-instant (hardlinked from cache).
