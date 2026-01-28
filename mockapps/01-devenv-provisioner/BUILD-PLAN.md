# DevEnv Provisioner - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 3-4 days | simple_docker, simple_yaml, simple_cli |
| Phase 2 | Full CLI | 2-3 days | Phase 1 complete |
| Phase 3 | Polish | 2-3 days | Phase 2 complete |

---

## Phase 1: MVP

### Objective

Demonstrate core value proposition: parse a devenv.yaml file, start services in dependency order, show status.

### Deliverables

1. **DEVENV_CLI** - Basic command routing (up, down, status)
2. **DEVENV_PARSER** - Parse devenv.yaml with services, ports, volumes
3. **DEVENV_ENGINE** - Start/stop containers via simple_docker
4. **DEVENV_STATE** - Track running containers in JSON file
5. **Basic templates** - 2-3 starter templates (web+db, api+db+cache)

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Set up project structure with ECF | Compiles with all dependencies |
| T1.2 | Implement DEVENV_CLI with up/down/status | Commands parse correctly |
| T1.3 | Implement DEVENV_PARSER for YAML | Parses sample devenv.yaml |
| T1.4 | Implement DEVENV_SERVICE model | Converts to CONTAINER_SPEC |
| T1.5 | Implement DEVENV_ENGINE.up | Starts containers in order |
| T1.6 | Implement DEVENV_ENGINE.down | Stops all tracked containers |
| T1.7 | Implement DEVENV_STATE | Persists container IDs to JSON |
| T1.8 | Implement DEVENV_ENGINE.status | Shows running services |
| T1.9 | Create postgres+redis template | Template works with `devenv up` |
| T1.10 | Create nginx+api template | Template works end-to-end |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Parse valid YAML | Sample devenv.yaml | DEVENV_CONFIG with services |
| Parse invalid YAML | Malformed file | Error message, no crash |
| Start services | `devenv up` with template | Containers running, status shows UP |
| Stop services | `devenv down` | All containers stopped |
| Status running | After `devenv up` | Table showing service names, ports, status |
| Status stopped | After `devenv down` | "No services running" message |
| Dependency order | Service with depends_on | DB starts before API |

### MVP Commands

```bash
# Initialize from template
devenv init postgres-redis

# Start environment
devenv up

# Check status
devenv status
# Output:
# SERVICE   IMAGE              STATUS    PORTS
# db        postgres:16        Running   5432->5432
# redis     redis:alpine       Running   6379->6379

# Stop environment
devenv down
```

---

## Phase 2: Full Implementation

### Objective

Complete CLI functionality with all commands, health checks, and proper error handling.

### Deliverables

1. **Health monitoring** - Wait for services to be ready
2. **Service commands** - logs, exec, restart for individual services
3. **Template management** - list, apply, export templates
4. **Network/volume management** - Custom networks and named volumes
5. **Improved output** - Progress bars, colored status, verbose mode
6. **Error recovery** - Handle partial starts, cleanup on failure

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement health checks | Waits for pg_isready before dependent starts |
| T2.2 | Implement `devenv logs [service]` | Shows container logs, supports --follow |
| T2.3 | Implement `devenv exec <service> <cmd>` | Executes command in container |
| T2.4 | Implement `devenv restart [service]` | Restarts one or all services |
| T2.5 | Implement `devenv template list` | Lists available templates |
| T2.6 | Implement `devenv template apply <name>` | Creates devenv.yaml from template |
| T2.7 | Implement network configuration | Creates custom networks per environment |
| T2.8 | Implement volume configuration | Named volumes persist across restarts |
| T2.9 | Add progress indicators | Shows "Starting db... OK" style output |
| T2.10 | Implement error recovery | Cleans up on partial failure |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Health wait | Service with healthcheck | Waits until healthy before dependent |
| Logs streaming | `devenv logs -f web` | Live log output |
| Exec command | `devenv exec db psql` | Opens psql shell |
| Restart single | `devenv restart api` | Only api container restarts |
| Template list | `devenv template list` | Shows available templates |
| Network isolation | Two projects same machine | Separate networks, no conflicts |

---

## Phase 3: Production Polish

### Objective

Production-ready CLI with comprehensive error handling, documentation, and professional output.

### Deliverables

1. **Error handling hardening** - All error paths covered
2. **Help documentation** - Detailed help for all commands
3. **Configuration validation** - Catch errors before Docker calls
4. **Performance optimization** - Parallel container starts where possible
5. **Additional templates** - 5+ production-quality templates
6. **Installer/packaging** - Easy installation script

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Comprehensive error messages | All error paths have helpful messages |
| T3.2 | Help text for all commands | `--help` works on every command |
| T3.3 | Configuration validation | Invalid config fails fast with clear error |
| T3.4 | Parallel start optimization | Independent services start concurrently |
| T3.5 | Create Rails+Postgres template | Full Rails development environment |
| T3.6 | Create Node+Mongo template | Full Node.js development environment |
| T3.7 | Create Python+Postgres+Redis template | Full Django/Flask environment |
| T3.8 | Write README documentation | Clear usage instructions |
| T3.9 | Create installation script | One-line install works |
| T3.10 | Final testing pass | All 30+ tests pass |

---

## ECF Target Structure

```xml
<!-- Library target (reusable logic) -->
<target name="devenv_provisioner">
    <option>
        <assertions precondition="true" postcondition="true" check="true"
                    invariant="true" loop="true" supplier_precondition="true"/>
    </option>
    <library name="simple_docker" location="$SIMPLE_EIFFEL/simple_docker/simple_docker.ecf"/>
    <library name="simple_yaml" location="$SIMPLE_EIFFEL/simple_yaml/simple_yaml.ecf"/>
    <!-- ... other libraries ... -->
    <cluster name="src" location=".\src\"/>
</target>

<!-- CLI executable target -->
<target name="devenv_cli" extends="devenv_provisioner">
    <root class="DEVENV_CLI" feature="make"/>
    <setting name="console_application" value="true"/>
    <setting name="executable_name" value="devenv"/>
</target>

<!-- Test target -->
<target name="devenv_tests" extends="devenv_provisioner">
    <root class="TEST_APP" feature="make"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    <cluster name="testing" location=".\testing\"/>
</target>
```

## Build Commands

```bash
# Compile CLI (workbench mode for development)
/d/prod/ec.sh -batch -config devenv_provisioner.ecf -target devenv_cli -c_compile

# Compile CLI (finalized for release)
/d/prod/ec.sh -batch -config devenv_provisioner.ecf -target devenv_cli -finalize -c_compile

# Run tests
/d/prod/ec.sh -batch -config devenv_provisioner.ecf -target devenv_tests -c_compile
./EIFGENs/devenv_tests/W_code/devenv.exe

# Finalized tests with contracts
/d/prod/ec.sh -batch -config devenv_provisioner.ecf -target devenv_tests -finalize -keep -c_compile
./EIFGENs/devenv_tests/F_code/devenv.exe
```

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors, zero warnings | 100% |
| Tests pass | All test cases | 100% |
| CLI works | All commands functional | 100% |
| Documentation | README complete | Yes |
| Templates | At least 5 working templates | 5+ |
| Error handling | No unhandled exceptions | 100% |
| User feedback | Positive review from 3+ developers | Positive |

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| YAML parsing edge cases | Use simple_yaml, add fuzzing tests |
| Docker API changes | simple_docker abstracts Docker version |
| Performance on large configs | Add progress indicators, parallel starts |
| Template quality | Test templates against real projects |
| Cross-platform issues | Test on Windows (primary), document Linux/macOS |
