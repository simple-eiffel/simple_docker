# S05: CONSTRAINTS

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Technical Constraints

### Network Constraints

| Constraint | Enforcement | Reason |
|------------|-------------|--------|
| Docker daemon available | Runtime check | Required for any operation |
| Socket/pipe accessible | Permission check | OS permissions |
| Valid JSON responses | Parsing | API contract |

### Container ID Constraints

| Constraint | Enforcement | Reason |
|------------|-------------|--------|
| ID not empty | Precondition | Required for operations |
| Short ID 12 chars max | Invariant | Docker standard |
| Short ID is prefix of full | Invariant | Consistency |

### Port Constraints

| Constraint | Enforcement | Reason |
|------------|-------------|--------|
| Container port 1-65535 | Precondition | Valid port range |
| Host port 0-65535 | Precondition | 0 = auto-assign |

### Restart Policy Constraints

Valid values only:
- "no" - Never restart
- "always" - Always restart
- "on-failure" - Restart on non-zero exit
- "unless-stopped" - Restart unless explicitly stopped

## State Machine Constraints

### Container States

```
[created] --> [running] --> [exited]
    |             |            |
    v             v            |
  [dead]      [paused]         |
                |              |
                +--------------+
```

### State Transitions

| Current | can_start | can_stop |
|---------|-----------|----------|
| created | Yes | No |
| running | No | Yes |
| paused | Yes | Yes |
| exited | Yes | No |
| dead | No | No |
