<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_docker

**[Documentation](https://simple-eiffel.github.io/simple_docker/)** | **[GitHub](https://github.com/simple-eiffel/simple_docker)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()
[![Tests](https://img.shields.io/badge/tests-15%20passing-brightgreen.svg)]()

Docker container management library for Eiffel. Build, run, and manage containers programmatically.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Production** - 15 tests passing

## Overview

SIMPLE_DOCKER provides a clean, type-safe API for Docker container management through Windows named pipes. It communicates directly with the Docker Engine API, enabling full container lifecycle control from Eiffel applications.

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

- **Container Lifecycle** - Create, start, stop, pause, restart, kill, remove containers
- **Image Management** - List, pull, inspect, and remove Docker images
- **Fluent Builder API** - Configure containers with intuitive chained method calls
- **Design by Contract** - Full preconditions, postconditions, and invariants
- **Windows Named Pipes** - Direct communication with Docker Engine via `\\.\pipe\docker_engine`
- **Chunked Transfer Handling** - Proper HTTP/1.1 chunked encoding support
- **Structured Logging** - Integration with simple_logger

## Installation

1. Clone the repository:
```bash
git clone https://github.com/simple-eiffel/simple_docker.git
```

2. Set environment variable:
```bash
# Windows
set SIMPLE_DOCKER=D:\path\to\simple_docker

# MSYS2/Git Bash
export SIMPLE_DOCKER=/d/prod/simple_docker
```

3. Add to your ECF:
```xml
<library name="simple_docker" location="$SIMPLE_DOCKER\simple_docker.ecf"/>
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
| `DOCKER_CLIENT` | Main facade for all Docker operations |
| `DOCKER_CONTAINER` | Container representation with state and metadata |
| `DOCKER_IMAGE` | Image representation with tags and size |
| `CONTAINER_SPEC` | Fluent builder for container configuration |
| `CONTAINER_STATE` | State constants and transition queries |
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

**Test Results:** 15 tests passing

## Project Structure

```
simple_docker/
├── src/                            # Eiffel source
│   ├── docker_client.e             # Main facade
│   ├── docker_container.e          # Container representation
│   ├── docker_image.e              # Image representation
│   ├── docker_error.e              # Error handling
│   ├── container_spec.e            # Fluent builder
│   └── container_state.e           # State constants
├── testing/                        # Test suite
│   ├── lib_tests.e                 # Test cases
│   └── test_app.e                  # Test runner
├── docs/                           # Documentation
│   ├── index.html                  # API docs
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
- [ ] DOCKERFILE_BUILDER - Fluent Dockerfile generation
- [ ] DOCKER_NETWORK - Network operations
- [ ] DOCKER_VOLUME - Volume operations
- [ ] COMPOSE_BUILDER - docker-compose.yaml generation
- [ ] Unix socket support (via simple_ipc)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## See Also

- [Docker Engine API Documentation](https://docs.docker.com/engine/api/)
- [simple_ipc](https://github.com/simple-eiffel/simple_ipc) - IPC library for named pipes
- [simple_json](https://github.com/simple-eiffel/simple_json) - JSON parsing library
