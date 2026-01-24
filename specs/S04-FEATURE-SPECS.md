# S04: FEATURE SPECIFICATIONS

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## DOCKER_CLIENT Features

### System Operations

#### ping
**Signature:** `ping: BOOLEAN`
**Purpose:** Check if Docker daemon is accessible

#### info
**Signature:** `info: detachable SIMPLE_JSON_OBJECT`
**Purpose:** Get system information

### Container Operations

#### create_container
**Signature:** `create_container (spec: CONTAINER_SPEC): detachable DOCKER_CONTAINER`
**Purpose:** Create container from specification

#### start_container
**Signature:** `start_container (id: STRING): BOOLEAN`
**Purpose:** Start a stopped container

#### stop_container
**Signature:** `stop_container (id: STRING; timeout: INTEGER): BOOLEAN`
**Purpose:** Stop running container with timeout

#### run_container
**Signature:** `run_container (spec: CONTAINER_SPEC): detachable DOCKER_CONTAINER`
**Purpose:** Create and start container in one call

#### wait_container
**Signature:** `wait_container (id: STRING): INTEGER`
**Purpose:** Block until container exits, return exit code

#### container_logs
**Signature:** `container_logs (id: STRING; stdout, stderr: BOOLEAN; tail: INTEGER): detachable STRING`
**Purpose:** Get container logs

## CONTAINER_SPEC Features

### Fluent Configuration

All setters return `like Current` for chaining:

#### set_name
**Signature:** `set_name (name: STRING): like Current`
**Precondition:** name_not_empty: not name.is_empty

#### add_port
**Signature:** `add_port (container_port, host_port: INTEGER): like Current`
**Precondition:** valid_container_port: 1 <= container_port <= 65535
**Precondition:** valid_host_port: 0 <= host_port <= 65535

#### add_volume
**Signature:** `add_volume (host_path, container_path: STRING): like Current`
**Purpose:** Add read-write volume mount

#### set_restart_policy
**Signature:** `set_restart_policy (policy: STRING): like Current`
**Valid policies:** "no", "always", "on-failure", "unless-stopped"

### Conversion

#### to_json
**Signature:** `to_json: STRING`
**Purpose:** Convert spec to Docker API JSON format
