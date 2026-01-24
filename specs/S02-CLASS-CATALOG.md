# S02: CLASS CATALOG

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Class Overview

| Class | Purpose | LOC |
|-------|---------|-----|
| DOCKER_CLIENT | Docker Engine API client | ~700 |
| DOCKER_CONTAINER | Container entity representation | ~355 |
| DOCKER_IMAGE | Image entity representation | ~290 |
| DOCKER_NETWORK | Network entity representation | ~350 |
| DOCKER_VOLUME | Volume entity representation | ~315 |
| CONTAINER_SPEC | Fluent container specification | ~480 |
| CONTAINER_STATE | State string constants | ~100 |
| DOCKER_ERROR | Error details | ~50 |
| SIMPLE_DOCKER_QUICK | Zero-config facade | ~475 |

## DOCKER_CLIENT

### Features
**System:** ping, info, version
**Containers:** list_containers, get_container, create_container, start_container, stop_container, remove_container, wait_container, container_logs, run_container
**Images:** list_images, image_exists, pull_image, remove_image
**Networks:** list_networks, get_network, create_network, remove_network, connect_container, disconnect_container
**Volumes:** list_volumes, get_volume, create_volume, remove_volume

## DOCKER_CONTAINER

### Creation: make, make_from_json
### Attributes: id, short_id, names, image, state, status, ports, labels, ip_address
### Queries: name, is_running, is_paused, is_exited, is_dead, can_start, can_stop

## CONTAINER_SPEC

### Fluent Setters
set_name, set_hostname, set_working_dir, set_user, add_env, add_port, add_port_udp, add_volume, add_volume_readonly, add_label, set_cmd, set_entrypoint, set_memory_limit, set_cpu_shares, set_restart_policy, set_network_mode, set_auto_remove, set_tty, set_stdin_open

## SIMPLE_DOCKER_QUICK

### One-liners
web_server, web_server_nginx, web_server_apache
postgres, mysql, mariadb, mongodb
redis, memcached, rabbitmq
run_script, run_python
stop_all, cleanup
