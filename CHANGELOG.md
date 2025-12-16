# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
