# S07: SPECIFICATION SUMMARY

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Library Summary

**Purpose:** Docker Engine API client for Eiffel with entity classes, fluent specification builder, and zero-configuration quick facade.

**Core Functionality:**
1. Docker daemon communication
2. Container lifecycle management
3. Image operations
4. Network and volume management
5. Fluent container specification
6. One-liner operations for common services

## API Surface

### DOCKER_CLIENT

| Category | Features |
|----------|----------|
| System | 3 (ping, info, version) |
| Containers | 10 |
| Images | 4 |
| Networks | 6 |
| Volumes | 4 |
| Error | 2 (has_error, last_error) |

### Entity Classes

| Class | Query Features | Mutator Features |
|-------|----------------|------------------|
| DOCKER_CONTAINER | 12 | 1 |
| DOCKER_IMAGE | 10 | 0 |
| DOCKER_NETWORK | 12 | 0 |
| DOCKER_VOLUME | 12 | 0 |

### CONTAINER_SPEC

| Category | Features |
|----------|----------|
| Fluent setters | 18 |
| Conversion | 1 (to_json) |

### SIMPLE_DOCKER_QUICK

| Category | Features |
|----------|----------|
| Web servers | 3 |
| Databases | 5 |
| Cache/MQ | 3 |
| Scripts | 3 |
| Management | 4 |

## Quality Metrics

| Metric | Value |
|--------|-------|
| Classes | 9 |
| Total Lines | ~3115 |
| Invariants | 25+ |
