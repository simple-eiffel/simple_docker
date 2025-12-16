# simple_docker

Docker container management library for Eiffel. Build, run, and manage containers programmatically.

## Features

- **Container Lifecycle**: Create, start, stop, pause, restart, remove containers
- **Image Management**: List, pull, inspect, and remove images
- **Fluent API**: Builder pattern for container specifications
- **Design by Contract**: Full preconditions, postconditions, and invariants
- **Windows Named Pipes**: Direct communication with Docker Engine via `\\.\pipe\docker_engine`
- **Chunked Transfer Handling**: Proper HTTP chunked encoding support

## Requirements

- EiffelStudio 25.02 or later
- Docker Desktop running on Windows
- Dependencies: simple_ipc, simple_json, simple_file, simple_logger

## Installation

1. Clone the repository:
```bash
git clone https://github.com/simple-eiffel/simple_docker.git
```

2. Set environment variable:
```bash
export SIMPLE_DOCKER=/path/to/simple_docker
```

3. Add to your ECF:
```xml
<library name="simple_docker" location="$SIMPLE_DOCKER\simple_docker.ecf"/>
```

## Quick Start

```eiffel
local
    client: DOCKER_CLIENT
    spec: CONTAINER_SPEC
    container: detachable DOCKER_CONTAINER
do
    -- Create client (connects to Docker daemon)
    create client.make

    -- Check connection
    if client.ping then
        print ("Docker is running%N")
    end

    -- List running containers
    across client.list_containers (False) as c loop
        print (c.out + "%N")
    end

    -- Create and run a container
    create spec.make ("alpine:latest")
    spec.set_name ("my-alpine")
        .set_cmd (<<"echo", "Hello from Eiffel!">>)
        .add_env ("FOO", "bar").do_nothing

    container := client.run_container (spec)

    if attached container as c then
        print ("Created container: " + c.short_id + "%N")
    end
end
```

## Container Specification

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

## Container Operations

```eiffel
-- Create container
container := client.create_container (spec)

-- Start container
if client.start_container (container.id) then
    print ("Started%N")
end

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

## Image Operations

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

## Error Handling

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

## Container State

Check container state using the helper methods:

```eiffel
if container.is_running then
    print ("Container is running%N")
elseif container.is_paused then
    print ("Container is paused%N")
elseif container.is_exited then
    if container.has_exited_successfully then
        print ("Exited with code 0%N")
    else
        print ("Exited with code: " + container.exit_code.out + "%N")
    end
end

-- Check what operations are allowed
if container.can_start then
    client.start_container (container.id).do_nothing
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

## Testing

```bash
cd /d/prod/simple_docker

# Compile tests
/d/prod/ec.sh -batch -config simple_docker.ecf -target simple_docker_tests -finalize -keep -c_compile

# Run tests (Docker Desktop must be running)
./EIFGENs/simple_docker_tests/F_code/simple_docker.exe
```

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Submit a pull request

## See Also

- [Docker Engine API Documentation](https://docs.docker.com/engine/api/)
- [simple_ipc](https://github.com/simple-eiffel/simple_ipc) - IPC library used for named pipes
- [simple_json](https://github.com/simple-eiffel/simple_json) - JSON parsing library
