This is a docker image with a ton of dev tools and language toolchains pre-installed. Details in [docs](./docs)

## Usage

1. Bring up the container - mount /projects inside the container to the dev workspace

2. SSH in and initialize:

```bash
OP_ADDRESS=..
OP_EMAIL=..
OP_SECRET_KEY=..
op account add --address $OP_ADDRESS --email $OP_EMAIL --secret-key $OP_SECRET_KEY
eval $(op signin)
chezmoi init --apply # uses secrets stored in 1password, so we sign in first
source ~/.bashrc
```
