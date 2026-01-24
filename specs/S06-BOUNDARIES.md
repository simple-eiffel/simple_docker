# S06: BOUNDARIES

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## System Boundaries

### Class Architecture

```
SIMPLE_DOCKER_QUICK (facade)
         |
         v
   DOCKER_CLIENT (API)
         |
    +----+----+----+----+
    |    |    |    |    |
    v    v    v    v    v
CONTAINER IMAGE NETWORK VOLUME SPEC
```

### External Dependencies

```
simple_docker
    |
    +-- simple_json (SIMPLE_JSON_OBJECT, SIMPLE_JSON_ARRAY)
    |
    +-- simple_http (HTTP client for API calls)
    |
    +-- Docker Engine (external service)
```

## Class Responsibilities

### DOCKER_CLIENT
- HTTP communication with Docker daemon
- JSON request construction
- Response parsing
- Error handling

### Entity Classes (CONTAINER, IMAGE, NETWORK, VOLUME)
- Data storage from JSON responses
- Status queries
- Output formatting

### CONTAINER_SPEC
- Fluent builder pattern
- Configuration validation
- JSON serialization for API

### SIMPLE_DOCKER_QUICK
- Simplified one-liner API
- Automatic image pulling
- Container tracking and cleanup
- Preconfigured services (postgres, redis, etc.)

## Integration Points

| Integration | Direction | Data |
|-------------|-----------|------|
| Docker daemon | REST API | JSON |
| simple_json | Internal | Parse/generate |
| simple_http | Internal | HTTP transport |
| Application | Entities | Container, Image, etc. |

## Not Responsible For

- Docker daemon installation
- Container image building
- Docker Compose parsing
- Swarm orchestration
- Registry authentication
