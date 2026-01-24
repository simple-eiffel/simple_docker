# S01: PROJECT INVENTORY

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Project Structure

```
simple_docker/
├── src/
│   ├── docker_client.e        # Main Docker API client
│   ├── docker_container.e     # Container entity
│   ├── docker_image.e         # Image entity
│   ├── docker_network.e       # Network entity
│   ├── docker_volume.e        # Volume entity
│   ├── container_spec.e       # Container specification builder
│   ├── container_state.e      # State constants
│   ├── docker_error.e         # Error handling
│   └── simple_docker_quick.e  # Zero-config facade
├── testing/
│   ├── test_app.e             # Test entry point
│   ├── lib_tests.e            # Unit tests
│   └── mock_docker_client.e   # Mock for testing
├── research/                   # 7S research documents
├── specs/                      # Specification documents
├── simple_docker.ecf          # Library ECF
└── README.md                   # Documentation
```

## File Inventory

| File | Type | Lines | Purpose |
|------|------|-------|---------|
| docker_client.e | Source | ~700 | Main API client |
| docker_container.e | Source | ~355 | Container representation |
| docker_image.e | Source | ~290 | Image representation |
| docker_network.e | Source | ~350 | Network representation |
| docker_volume.e | Source | ~315 | Volume representation |
| container_spec.e | Source | ~480 | Builder for containers |
| container_state.e | Source | ~100 | State constants |
| docker_error.e | Source | ~50 | Error handling |
| simple_docker_quick.e | Source | ~475 | Quick facade |

## Dependencies

### simple_* Libraries
- simple_json - JSON parsing
- simple_http - HTTP communication

### Eiffel Base Libraries
- ARRAYED_LIST, HASH_TABLE, STRING
- PLAIN_TEXT_FILE (for named pipe)
