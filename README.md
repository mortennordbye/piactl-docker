# piactl-docker

Minimal Docker image packaging the [`piactl`](https://github.com/pia-client/piactl) CLI from Private Internet Access.

## Usage

```bash
docker run --rm \
  --cap-add=NET_ADMIN \       # if you plan to actually bring up tunnels
  ghcr.io/<your-org>/piactl:latest version
