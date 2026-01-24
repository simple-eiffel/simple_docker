# 7S-01: SCOPE

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Problem Domain

Docker has become the standard for containerization, enabling consistent development and deployment environments. Developers need programmatic access to Docker functionality for:
- Automating container deployment
- Building CI/CD pipelines
- Managing development environments
- Creating container-based services

## Target Users

1. **DevOps Engineers** - Automating container workflows
2. **Eiffel Application Developers** - Using Docker in applications
3. **Testing Engineers** - Spinning up test databases/services
4. **Tool Builders** - Creating Docker management utilities

## Boundaries

### In Scope
- Docker Engine API communication (REST over Unix socket/named pipe)
- Container lifecycle management (create, start, stop, remove)
- Image management (list, pull, remove)
- Network management (list, create, connect, disconnect)
- Volume management (list, create, remove)
- Container logs retrieval
- Container execution (exec)
- System information and ping
- Fluent container specification builder
- Zero-configuration quick facade

### Out of Scope
- Docker Compose file parsing
- Docker Swarm orchestration
- Container image building (Dockerfile)
- Docker registry authentication
- Container stats streaming
- Live container events

## Key Capabilities

1. **Multiple API levels:**
   - DOCKER_CLIENT - Full Docker API
   - SIMPLE_DOCKER_QUICK - One-liner operations

2. **Entity classes:**
   - DOCKER_CONTAINER, DOCKER_IMAGE, DOCKER_NETWORK, DOCKER_VOLUME

3. **Builder pattern:**
   - CONTAINER_SPEC for fluent container configuration
