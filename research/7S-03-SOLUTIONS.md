# 7S-03: SOLUTIONS


**Date**: 2026-01-23

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Existing Solutions Comparison

### Docker SDK/Libraries

| Solution | Language | Features | Complexity |
|----------|----------|----------|------------|
| docker-py | Python | Complete API | High |
| docker (Go) | Go | Official client | High |
| dockerode | JavaScript | Full async API | Medium |
| Docker.DotNet | C# | Complete API | High |
| **simple_docker** | **Eiffel** | **Core operations** | **Low** |

### Design Approaches

**1. Full SDK (Most Libraries)**
- Mirrors entire Docker API
- Complex, large codebase
- Learning curve

**2. Focused Operations (simple_docker)**
- Core container/image operations
- Simple, focused API
- Quick start facade

### Unique Features

1. **SIMPLE_DOCKER_QUICK facade:**
   - One-liner for web servers, databases, cache
   - Automatic image pulling
   - Container tracking and cleanup

2. **Fluent CONTAINER_SPEC builder:**
   ```eiffel
   create spec.make ("nginx:alpine")
   spec.set_name ("my-nginx")
       .add_port (80, 8080)
       .add_env ("DEBUG", "true")
       .add_volume ("/data", "/container/data")
   ```

3. **Design by Contract:**
   - Strong invariants on entity classes
   - Preconditions on all operations

4. **Windows Support:**
   - Named pipe communication
   - Cross-platform from single codebase
