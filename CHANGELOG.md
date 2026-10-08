# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.1] - 2026-10-08

### Fixed
- `DOCKER_CLIENT.stream_container_logs` no longer corrupts the client's
  shared connection. It read one buffer of the chunked log response and
  left the rest on the keep-alive pipe, so every later request read the
  previous request's response (stray 404/409 errors, a container "created"
  from an image-inspect reply, containers left behind in "created" state).
  The stream now runs on its own connection, closed on return.
- `stream_container_logs` with `follow` could block forever: the pipe read
  blocks, so `timeout_ms` never fired. It now polls for data, honors
  `timeout_ms` as an idle limit (0 = 100 s), ends at the end of the chunked
  response, decodes chunked encoding, and buffers frames split across reads.
- `SIMPLE_DOCKER_QUICK.run_script` failed with HTTP 409 (or returned empty
  output after a 404) because the container ran with AutoRemove and the
  daemon removed it before its logs were read. The container is now removed
  explicitly after the logs are read, also when an exception occurs.
- `SIMPLE_DOCKER_QUICK` container names carry a random per-facade tag, so two
  facades (or two runs) no longer both ask for `quick_redis_1` (HTTP 409).
- `SIMPLE_DOCKER_QUICK.cleanup` also removes the containers' anonymous
  volumes (new `DOCKER_CLIENT.remove_container_and_volumes`); redis and
  postgres left one volume behind per container.
- `DOCKER_CLIENT.run_container` removes the container again when it cannot
  be started, instead of leaving it in "created" state.

### Added
- `DOCKER_CLIENT.remove_container_and_volumes`, `DOCKER_CLIENT.restore_error`.

### Changed (tests)
- Container, network and volume names carry a random per-run tag; `on_clean`
  (also reached from the runner's rescue path) removes whatever a test
  created, including SIMPLE_DOCKER_QUICK containers.
- Tests that need the daemon are SKIPPED with the reason when it is not
  reachable; the summary reports passed, failed and skipped.
- Tests that passed whatever happened (`assert (..., True)`) now assert the
  outcome: log lines received in order, callback stop after exactly three
  lines, exec output text, `[Exit code: 42]`, not-found for a missing
  container, and that the shared connection still answers in step after a
  stream.

## [1.4.0] - 2025-12-16

### Added
- **SIMPLE_DOCKER_QUICK - Zero-Config Beginner API**
  - One-liner operations for common Docker tasks
  - Web servers: `web_server`, `web_server_nginx`, `web_server_apache`
  - Databases: `postgres`, `postgres_on_port`, `mysql`, `mysql_on_port`, `mariadb`, `mongodb`
  - Caches: `redis`, `redis_on_port`, `memcached`
  - Message queues: `rabbitmq`
  - Script execution: `run_script`, `run_script_in_image`, `run_python`
  - Container management: `stop_all`, `cleanup`, `container_count`
  - Status: `is_available`, `has_error`, `last_error_message`
  - Full access: `client` attribute for advanced operations
  - Automatic image pulling when not present
  - Docker multiplexed stream header stripping for clean output
  - Full Design by Contract

### Changed
- Test count increased from 49 to 58 tests
- README updated with two-API-level documentation
- User guide updated with comprehensive SIMPLE_DOCKER_QUICK section
- Index page updated with beginner-friendly examples

## [1.3.0] - 2025-12-16

### Added
- **Phase 3 Features: Streaming Logs**
  - `LOG_STREAM_OPTIONS` - Fluent builder for log stream configuration
    - `set_stdout`, `set_stderr`, `set_timestamps`, `set_follow`
    - `set_tail` for tail mode, `set_timeout_ms` for streaming timeout
    - `is_valid` query (requires stdout or stderr enabled)
    - `to_query_string` for HTTP query generation
  - `stream_container_logs` - Callback-based log streaming
    - Agent callback receives log chunks in real-time
    - Callback returns Boolean to continue/stop streaming
    - Proper handling of Docker multiplexed stream format
    - 8-byte frame header parsing (type, size)
  - Internal helpers: `build_streaming_request`, `process_log_stream_data`, `read_big_endian_32`

### Changed
- Test count increased from 39 to 49 tests (10 log stream tests)
- Added "What is Docker?" beginner guide to documentation

## [1.2.0] - 2025-12-16

### Added
- **Phase 3 Features: Build Support**
  - `build_image (a_context_path, a_tag)` - Build image from directory with Dockerfile
    - Creates tar archive using simple_archive
    - Sends binary POST to /build endpoint
  - `build_image_from_dockerfile (a_dockerfile, a_tag)` - Build from Dockerfile string
    - Creates temp directory with Dockerfile content
    - Useful for programmatic image generation
  - `do_binary_request` - Internal helper for binary uploads (tar archives)
  - `build_binary_request` - HTTP request builder for binary content
  - Note: Build features are experimental; streaming build output requires additional work

### Changed
- Added simple_archive and uuid library dependencies
- Test count increased from 38 to 39 tests
- Added `test_build_dockerfile_builder_generates_valid_output` test

## [1.1.0] - 2025-12-15

### Added
- **Phase 2 Features**
  - `DOCKERFILE_BUILDER` - Fluent API for Dockerfile generation
    - Single and multi-stage build support
    - All Dockerfile instructions: FROM, RUN, COPY, ADD, ENV, EXPOSE, WORKDIR, etc.
    - Labels, ARGs, and build-time variables
    - Stage naming for multi-stage builds with `from_image_as`
  - `DOCKER_NETWORK` - Network representation and operations
    - Properties: id, name, driver, scope, internal, attachable, ingress
    - Queries: `is_bridge`, `is_host`, `is_overlay`, `is_internal`, `matches`
    - Client operations: `list_networks`, `get_network`, `create_network`, `remove_network`
    - Container connection: `connect_container_to_network`, `disconnect_container_from_network`
    - Pruning: `prune_networks`
  - `DOCKER_VOLUME` - Volume representation and operations
    - Properties: name, driver, mountpoint, scope, labels, options
    - Queries: `is_local`, `is_in_use`, `is_anonymous`, `size_mb`, `size_gb`
    - Client operations: `list_volumes`, `get_volume`, `create_volume`, `create_volume_with_driver`, `remove_volume`
    - Pruning: `prune_volumes`
  - Exec operations for running commands in containers
    - `exec_in_container` - Execute command and get output
    - `create_exec`, `start_exec`, `inspect_exec` - Low-level exec API
- **Resilient IPC with rescue/retry**
  - `DOCKER_CLIENT` constructors retry up to 3 times on IPC failures
  - `execute_request` retries with 100ms delays on transient failures
  - Automatic IPC reconnection on failure
  - Configurable via `default_retry_count` and `default_retry_delay_ms`
- **Cookbook verification tests** - 10 tests that dogfood documentation examples
- **Strengthened contracts** - Postconditions on all network, volume, and exec operations

### Changed
- Test count increased from 15 to 38 tests
- Documentation updated to IUARC 5-doc standard

## [1.0.0] - 2025-12-15

### Added
- Initial release of simple_docker library
- `DOCKER_CLIENT` - Main facade for Docker operations
  - Connection: `ping`, `version`, `info`
  - Containers: `list_containers`, `get_container`, `create_container`, `start_container`, `stop_container`, `restart_container`, `pause_container`, `unpause_container`, `kill_container`, `remove_container`, `container_logs`, `wait_container`
  - Images: `list_images`, `get_image`, `image_exists`, `pull_image`, `remove_image`
  - Convenience: `run_container` (create + start)
- `DOCKER_CONTAINER` - Container representation
  - Properties: id, short_id, names, image, state, status, labels, ports, ip_address
  - State queries: `is_running`, `is_paused`, `is_exited`, `is_dead`
  - Transition queries: `can_start`, `can_stop`, `has_exited_successfully`
- `DOCKER_IMAGE` - Image representation
  - Properties: id, short_id, repo_tags, repo_digests, size, virtual_size
  - Queries: `primary_tag`, `repository`, `tag`, `has_tag`, `matches`, `size_mb`
- `CONTAINER_SPEC` - Fluent builder for container configuration
  - Basic: `set_name`, `set_hostname`, `set_working_dir`, `set_user`
  - Command: `set_cmd`, `set_entrypoint`
  - Environment: `add_env`
  - Ports: `add_port`, `add_port_udp`
  - Volumes: `add_volume`, `add_volume_readonly`
  - Labels: `add_label`
  - Resources: `set_memory_limit`, `set_cpu_shares`
  - Policies: `set_restart_policy`, `set_network_mode`, `set_auto_remove`
  - Terminal: `set_tty`, `set_stdin_open`
  - JSON export: `to_json`
- `CONTAINER_STATE` - State constants and queries
  - States: created, running, paused, restarting, removing, exited, dead
  - Queries: `is_valid_state`, `is_running_state`, `is_stopped_state`
  - Transitions: `can_start`, `can_stop`, `can_pause`, `can_remove`
- `DOCKER_ERROR` - Error handling
  - Types: connection_error, timeout_error, not_found_error, conflict_error, server_error, client_error
  - Queries: `is_connection_error`, `is_timeout_error`, `is_not_found`, `is_conflict`, `is_server_error`, `is_retryable`
- Windows named pipe support via `simple_ipc`
- HTTP/1.1 chunked transfer encoding handling
- Full Design by Contract with preconditions, postconditions, and invariants
- Comprehensive test suite (15 tests)
- Logging support via `simple_logger`

### Dependencies
- simple_ipc (v2.0.0+)
- simple_json
- simple_file
- simple_logger
