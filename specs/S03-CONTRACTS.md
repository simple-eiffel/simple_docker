# S03: CONTRACTS

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Class Invariants

### DOCKER_CONTAINER

```eiffel
invariant
    id_exists: id /= Void
    short_id_exists: short_id /= Void
    short_id_length_valid: short_id.count <= 12
    short_id_consistency: (not id.is_empty and id.count >= short_id.count) implies id.starts_with (short_id)
    names_exists: names /= Void
    labels_exists: labels /= Void
    ports_exists: ports /= Void
```

### DOCKER_IMAGE

```eiffel
invariant
    id_exists: id /= Void
    short_id_exists: short_id /= Void
    short_id_length_valid: short_id.count <= 12
    short_id_consistency: (not id.is_empty and id.count >= short_id.count) implies id.starts_with (short_id)
    repo_tags_exists: repo_tags /= Void
    labels_exists: labels /= Void
    non_negative_containers: containers >= -1
```

### DOCKER_NETWORK

```eiffel
invariant
    id_exists: id /= Void
    name_exists: name /= Void
    driver_exists: driver /= Void
    driver_not_empty: not driver.is_empty
    containers_exist: containers /= Void
    container_count_consistent: container_count = containers.count
```

### DOCKER_VOLUME

```eiffel
invariant
    name_exists: name /= Void
    driver_exists: driver /= Void
    driver_not_empty: not driver.is_empty
    ref_count_non_negative: ref_count >= 0
    is_in_use_consistent: is_in_use = (ref_count > 0)
    is_local_consistent: is_local = driver.same_string ("local")
```

### CONTAINER_SPEC

```eiffel
invariant
    image_not_empty: not image.is_empty
    environment_exists: environment /= Void
    port_bindings_exists: port_bindings /= Void
    volume_bindings_exists: volume_bindings /= Void
```

### SIMPLE_DOCKER_QUICK

```eiffel
invariant
    client_exists: client /= Void
    containers_tracked: managed_containers /= Void
    names_tracked: managed_names /= Void
```
