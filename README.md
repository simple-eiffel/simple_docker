<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/.github/main/profile/assets/logo.svg" alt="simple_ library logo" width="400">
</p>

# simple_docker

**[Documentation](https://simple-eiffel.github.io/simple_docker/)** | **[GitHub](https://github.com/simple-eiffel/simple_docker)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()
[![Tests](https://img.shields.io/badge/tests-58%20passing-brightgreen.svg)]()

Docker container management library for Eiffel. Build, run, and manage containers programmatically.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Production** - 58 tests passing (v1.4.0)

## Overview

SIMPLE_DOCKER provides two API levels:

- **SIMPLE_DOCKER_QUICK** - Zero-configuration facade for beginners (one-liners!)
- **DOCKER_CLIENT** - Full-control API for advanced users

Both communicate with the Docker Engine via Windows named pipes.

### Beginner API (SIMPLE_DOCKER_QUICK)

Don't know Docker? No problem! One-liner operations:

```eiffel
local
    docker: SIMPLE_DOCKER_QUICK
do
    create docker.make

    -- Run a web server serving files from a folder
    docker.web_server ("C:\my_website", 8080)

    -- Run a database
    docker.postgres ("mypassword")

    -- Run a cache
    docker.redis

    -- Run a shell script and get output
    print (docker.run_script ("echo hello && date"))

    -- Clean up when done
    docker.cleanup
end
```

That's it. No configuration, no specs, no ports to remember.

### Full API (DOCKER_CLIENT)

Need full control? Use the advanced API:

```eiffel
local
    client: DOCKER_CLIENT
    spec: CONTAINER_SPEC
do
    create client.make

    if client.ping then
        create spec.make ("alpine:latest")
        spec.set_name ("my-container")
            .set_cmd (<<"echo", "Hello from Eiffel!">>)
            .add_env ("FOO", "bar").do_nothing

        if attached client.run_container (spec) as c then
            print ("Created: " + c.short_id + "%N")
        end
    end
end
```

## Features

- **Zero-Config Beginner API** - One-liners for web servers, databases, caches, scripts
- **Container Lifecycle** - Create, start, stop, pause, restart, kill, remove containers
- **Image Management** - List, pull, inspect, and remove Docker images
- **Network Management** - Create, list, connect, disconnect, and remove networks
- **Volume Management** - Create, list, and remove volumes with driver configuration
- **Exec Operations** - Execute commands in running containers
- **Dockerfile Builder** - Fluent API for generating Dockerfiles with multi-stage support
- **Fluent Builder API** - Configure containers with intuitive chained method calls
- **Design by Contract** - Full preconditions, postconditions, and invariants
- **Resilient IPC** - Automatic retry with exponential backoff on transient failures
- **Windows Named Pipes** - Direct communication with Docker Engine via `\\.\pipe\docker_engine`
- **Chunked Transfer Handling** - Proper HTTP/1.1 chunked encoding support
- **Structured Logging** - Integration with simple_logger

## Installation

1. Clone the repository:
```bash
git clone https://github.com/simple-eiffel/simple_docker.git
```

2. Set environment variable (one-time setup for all simple_* libraries):
```bash
# Windows
set SIMPLE_EIFFEL=D:\prod

# MSYS2/Git Bash
export SIMPLE_EIFFEL=/d/prod
```

3. Add to your ECF:
```xml
<library name="simple_docker" location="$SIMPLE_EIFFEL/simple_docker/simple_docker.ecf"/>
```

## Dependencies

- **simple_ipc** (v2.0.0+) - Named pipe communication
- **simple_json** - JSON parsing and building
- **simple_file** - File operations
- **simple_logger** - Logging support

## Quick Start

### Check Docker Connection

```eiffel
create client.make

if client.ping then
    print ("Docker daemon is responsive%N")

    if attached client.version as v then
        print ("Docker version: " + v.to_json + "%N")
    end
end
```

### Container Specification

Use the fluent builder API to configure containers:

```eiffel
create spec.make ("nginx:alpine")
spec.set_name ("web-server")
    .set_hostname ("myhost")
    .add_port (80, 8080)           -- Map container:80 to host:8080
    .add_port_udp (53, 5353)       -- UDP port mapping
    .add_env ("DEBUG", "true")
    .add_volume ("/data", "/container/data")
    .add_volume_readonly ("/config", "/etc/config")
    .set_memory_limit (512 * 1024 * 1024)  -- 512 MB
    .set_cpu_shares (1024)
    .set_restart_policy ("unless-stopped")
    .set_network_mode ("bridge")
    .set_auto_remove (True)
    .set_tty (True).do_nothing
```

### Container Operations

```eiffel
-- Create and start
container := client.run_container (spec)

-- Or create then start separately
container := client.create_container (spec)
client.start_container (container.id).do_nothing

-- Stop with timeout
client.stop_container (container.id, 10).do_nothing

-- Pause/unpause
client.pause_container (container.id).do_nothing
client.unpause_container (container.id).do_nothing

-- Get logs
if attached client.container_logs (container.id, True, True, 100) as logs then
    print (logs)
end

-- Wait for exit
exit_code := client.wait_container (container.id)

-- Remove (force if running)
client.remove_container (container.id, True).do_nothing
```

### Image Operations

```eiffel
-- List all images
across client.list_images as img loop
    print (img.out + "%N")
end

-- Check if image exists
if client.image_exists ("alpine:latest") then
    print ("Alpine is available%N")
end

-- Pull image
if client.pull_image ("nginx:alpine") then
    print ("Image pulled%N")
end

-- Remove image
client.remove_image ("old-image:v1", False).do_nothing
```

### Error Handling

```eiffel
container := client.create_container (spec)

if client.has_error then
    if attached client.last_error as err then
        print ("Error: " + err.out + "%N")

        if err.is_not_found then
            -- Image doesn't exist, pull it
            client.pull_image (spec.image).do_nothing
        elseif err.is_conflict then
            -- Container name already exists
        elseif err.is_retryable then
            -- Connection or timeout error, can retry
        end
    end
end
```

## API Classes

| Class | Description |
|-------|-------------|
| `SIMPLE_DOCKER_QUICK` | Zero-config beginner API - one-liners for common tasks |
| `DOCKER_CLIENT` | Main facade for all Docker operations |
| `DOCKER_CONTAINER` | Container representation with state and metadata |
| `DOCKER_IMAGE` | Image representation with tags and size |
| `DOCKER_NETWORK` | Network representation with driver and scope |
| `DOCKER_VOLUME` | Volume representation with mount information |
| `CONTAINER_SPEC` | Fluent builder for container configuration |
| `CONTAINER_STATE` | State constants and transition queries |
| `DOCKERFILE_BUILDER` | Fluent API for Dockerfile generation |
| `DOCKER_ERROR` | Error classification and handling |

## Building & Testing

### Compile Library

```bash
cd /d/prod/simple_docker
/d/prod/ec.sh -batch -config simple_docker.ecf -target simple_docker -c_compile
```

### Compile Tests

```bash
/d/prod/ec.sh -batch -config simple_docker.ecf -target simple_docker_tests -c_compile
```

### Run Tests

```bash
# Docker Desktop must be running
./EIFGENs/simple_docker_tests/W_code/simple_docker.exe
```

### Finalize with Contracts

```bash
/d/prod/ec.sh -batch -config simple_docker.ecf -target simple_docker_tests -finalize -keep -c_compile
./EIFGENs/simple_docker_tests/F_code/simple_docker.exe
```

**Test Results:** 58 tests passing

## Project Structure

```
simple_docker/
├── src/                            # Eiffel source
│   ├── simple_docker_quick.e       # Zero-config beginner API
│   ├── docker_client.e             # Full-control facade (with retry logic)
│   ├── docker_container.e          # Container representation
│   ├── docker_image.e              # Image representation
│   ├── docker_network.e            # Network representation
│   ├── docker_volume.e             # Volume representation
│   ├── docker_error.e              # Error handling
│   ├── container_spec.e            # Fluent builder
│   ├── container_state.e           # State constants
│   ├── dockerfile_builder.e        # Dockerfile generation
│   └── log_stream_options.e        # Log streaming configuration
├── testing/                        # Test suite
│   ├── lib_tests.e                 # Test cases (58 tests)
│   └── test_app.e                  # Test runner
├── docs/                           # IUARC 5-doc standard
│   ├── index.html                  # Overview
│   ├── user-guide.html             # User guide
│   ├── api-reference.html          # API reference
│   ├── architecture.html           # Architecture
│   ├── cookbook.html               # Cookbook
│   └── css/style.css               # Styling
├── simple_docker.ecf               # Library configuration
├── README.md                       # This file
├── CHANGELOG.md                    # Version history
├── package.json                    # Package metadata
└── LICENSE                         # MIT License
```

## Roadmap

- [x] Core container operations (v1.0)
- [x] Image management (v1.0)
- [x] Fluent builder API (v1.0)
- [x] DOCKERFILE_BUILDER - Fluent Dockerfile generation (v1.1)
- [x] DOCKER_NETWORK - Network operations (v1.1)
- [x] DOCKER_VOLUME - Volume operations (v1.1)
- [x] Exec operations in containers (v1.1)
- [x] Resilient IPC with retry logic (v1.1)
- [x] Streaming logs with callback support (v1.3)
- [x] SIMPLE_DOCKER_QUICK - Zero-config beginner API (v1.4)
- [ ] COMPOSE_BUILDER - docker-compose.yaml generation
- [ ] Unix socket support (via simple_ipc)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## See Also

- [Docker Engine API Documentation](https://docs.docker.com/engine/api/)
- [simple_ipc](https://github.com/simple-eiffel/simple_ipc) - IPC library for named pipes
- [simple_json](https://github.com/simple-eiffel/simple_json) - JSON parsing library
