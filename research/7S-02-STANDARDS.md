# 7S-02: STANDARDS

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Applicable Standards

### Primary Standard

**Docker Engine API**
- URL: https://docs.docker.com/engine/api/
- Version Supported: v1.45+
- Protocol: REST over HTTP (Unix socket or TCP)

### Communication Protocol

**Unix Socket (Linux/macOS):**
- Path: `/var/run/docker.sock`
- Protocol: HTTP over Unix socket

**Named Pipe (Windows):**
- Path: `//./pipe/docker_engine`
- Protocol: HTTP over named pipe

### API Endpoints Used

| Endpoint | Purpose |
|----------|---------|
| `/_ping` | Health check |
| `/info` | System information |
| `/version` | Version information |
| `/containers/json` | List containers |
| `/containers/create` | Create container |
| `/containers/{id}/start` | Start container |
| `/containers/{id}/stop` | Stop container |
| `/containers/{id}/wait` | Wait for exit |
| `/containers/{id}/logs` | Get logs |
| `/containers/{id}` (DELETE) | Remove container |
| `/containers/{id}/exec` | Create exec |
| `/exec/{id}/start` | Start exec |
| `/images/json` | List images |
| `/images/create` | Pull image |
| `/images/{name}` (DELETE) | Remove image |
| `/networks` | List/create networks |
| `/volumes` | List/create volumes |

### JSON Schema

All API communication uses JSON format per Docker API spec.
