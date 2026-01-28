# Ephemeral Test Runner - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 4-5 days | simple_docker, simple_yaml, simple_testing |
| Phase 2 | Full CLI | 3-4 days | Phase 1 complete |
| Phase 3 | Polish | 2-3 days | Phase 2 complete |

---

## Phase 1: MVP

### Objective

Demonstrate core value: provision a test environment with database, run tests, capture results, clean up automatically.

### Deliverables

1. **TESTRUN_CLI** - Basic command routing (run, clean)
2. **TESTRUN_ENVIRONMENT** - Parse testrun.yaml, track resources
3. **TESTRUN_ENGINE** - Provision, execute, cleanup orchestration
4. **TESTRUN_SERVICE** - Container management for test services
5. **TESTRUN_RESULT** - Capture pass/fail counts, test names
6. **TESTRUN_CLEANUP** - Ensure complete resource cleanup

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Set up project structure with ECF | Compiles with all dependencies |
| T1.2 | Implement TESTRUN_CLI with run command | `testrun run` parses |
| T1.3 | Implement TESTRUN_ENVIRONMENT YAML parsing | Parses sample testrun.yaml |
| T1.4 | Implement TESTRUN_SERVICE | Creates CONTAINER_SPEC from config |
| T1.5 | Implement TESTRUN_ENGINE.provision | Starts services with network |
| T1.6 | Implement health check waiting | Waits for services to be ready |
| T1.7 | Implement test command execution | Runs test command in container |
| T1.8 | Implement TESTRUN_RESULT | Captures pass/fail/skip counts |
| T1.9 | Implement simple_testing output parser | Parses simple_testing format |
| T1.10 | Implement TESTRUN_CLEANUP | Removes containers, networks |
| T1.11 | Implement text output formatter | Prints results summary |
| T1.12 | Handle provision failures | Cleanup on partial start |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Provision environment | Valid testrun.yaml | All containers running |
| Health check timeout | Unhealthy service | Timeout error, cleanup done |
| Execute tests | Simple test suite | Results captured correctly |
| Parse simple_testing | Test output | Pass/fail counts match |
| Cleanup on success | Successful run | No containers/networks remain |
| Cleanup on failure | Failed provision | Partial resources cleaned |
| No testrun.yaml | Empty directory | Helpful error message |

### MVP Commands

```bash
# Run all tests with default environment
testrun run
# Output:
# Provisioning test environment...
#   Starting db (postgres:16-alpine)... ready (2.3s)
#   Starting redis (redis:alpine)... ready (0.8s)
#   Starting api (my-app:test)... ready (1.5s)
# Environment ready in 4.6s
#
# Executing tests...
#   Running: ./EIFGENs/my_app_tests/W_code/my_app.exe
#
# Results:
#   PASS: test_user_creation
#   PASS: test_login
#   FAIL: test_password_reset
#   PASS: test_logout
#
# Summary: 3 passed, 1 failed, 0 skipped (12.4s)
#
# Cleaning up...
#   Removed container: test_api_abc123
#   Removed container: test_redis_def456
#   Removed container: test_db_ghi789
#   Removed network: testrun_net_xyz
# Cleanup complete.

# Force cleanup orphaned resources
testrun clean
```

---

## Phase 2: Full Implementation

### Objective

Complete CLI functionality with fixture loading, parallel execution, and comprehensive result handling.

### Deliverables

1. **Fixture loading** - SQL fixture application before tests
2. **JUnit XML output** - Standard CI/CD result format
3. **Parallel execution** - Multiple test files concurrently
4. **Preserve on failure** - Keep environment for debugging
5. **Debug mode** - Attach to failed environment
6. **Retry flaky tests** - Automatic retry of failed tests

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement TESTRUN_FIXTURE.load_sql | SQL files applied to database |
| T2.2 | Implement fixture ordering | Fixtures apply in specified order |
| T2.3 | Implement JUnit XML output | Valid JUnit XML generated |
| T2.4 | Implement --parallel flag | Tests run in parallel workers |
| T2.5 | Implement --preserve-on-fail | Environment kept on failure |
| T2.6 | Implement `testrun debug` | Attaches shell to preserved env |
| T2.7 | Implement --retry flag | Failed tests retry N times |
| T2.8 | Implement fixture export | Export database to fixture file |
| T2.9 | Implement verbose mode | Shows detailed progress |
| T2.10 | Implement timing metrics | Track service start and test times |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Load fixtures | SQL files in fixtures/ | Data present in database |
| Fixture order | Ordered fixture list | Applied in correct order |
| JUnit output | `--output junit` | Valid JUnit XML file |
| Parallel 4 | `--parallel 4` | 4 workers, faster execution |
| Preserve env | `--preserve-on-fail` + failure | Containers still running |
| Debug mode | `testrun debug last` | Shell attached to environment |
| Retry tests | `--retry 2` + flaky test | Test passes on retry |

---

## Phase 3: Production Polish

### Objective

Production-ready tool with comprehensive features, documentation, and CI/CD examples.

### Deliverables

1. **HTML reports** - Professional test result reports
2. **Test analytics** - Track flaky tests, slow tests
3. **CI/CD examples** - GitHub Actions, GitLab, Jenkins
4. **Documentation** - User guide, configuration reference
5. **Performance optimization** - Container caching, parallel provision

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Implement HTML report generation | Professional HTML report |
| T3.2 | Implement flaky test detection | Identifies tests that flake |
| T3.3 | Implement slow test identification | Flags tests over threshold |
| T3.4 | Create GitHub Actions example | Working workflow file |
| T3.5 | Create GitLab CI example | Working .gitlab-ci.yml |
| T3.6 | Implement image caching | Reuse pulled images |
| T3.7 | Implement parallel provisioning | Services start concurrently |
| T3.8 | Write user documentation | Complete README |
| T3.9 | Write configuration reference | All options documented |
| T3.10 | Final testing pass | 40+ tests pass |

---

## ECF Target Structure

```xml
<!-- Library target -->
<target name="ephemeral_test_runner">
    <option>
        <assertions precondition="true" postcondition="true" check="true"
                    invariant="true" loop="true" supplier_precondition="true"/>
    </option>
    <library name="simple_docker" location="$SIMPLE_EIFFEL/simple_docker/simple_docker.ecf"/>
    <library name="simple_yaml" location="$SIMPLE_EIFFEL/simple_yaml/simple_yaml.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    <cluster name="src" location=".\src\"/>
</target>

<!-- CLI executable -->
<target name="testrun_cli" extends="ephemeral_test_runner">
    <root class="TESTRUN_CLI" feature="make"/>
    <setting name="console_application" value="true"/>
    <setting name="executable_name" value="testrun"/>
</target>

<!-- Test target -->
<target name="testrun_tests" extends="ephemeral_test_runner">
    <root class="TEST_APP" feature="make"/>
    <cluster name="testing" location=".\testing\"/>
</target>
```

## Build Commands

```bash
# Compile CLI (workbench mode)
/d/prod/ec.sh -batch -config testrun.ecf -target testrun_cli -c_compile

# Compile CLI (finalized)
/d/prod/ec.sh -batch -config testrun.ecf -target testrun_cli -finalize -c_compile

# Run tests
/d/prod/ec.sh -batch -config testrun.ecf -target testrun_tests -c_compile
./EIFGENs/testrun_tests/W_code/testrun.exe
```

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All test cases | 100% |
| Provision time | Typical 3-service stack | < 10 seconds |
| Cleanup reliability | No orphaned resources | 100% |
| JUnit compatibility | Parses in Jenkins/GitHub | Yes |
| Flaky test reduction | After adoption | 90% |
| Documentation | Complete user guide | Yes |

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Slow container pulls | Cache images, use alpine variants |
| Health check hangs | Strict timeouts, helpful error messages |
| Incomplete cleanup | Track all resources, force cleanup command |
| Fixture order issues | Explicit ordering in config |
| Parallel test conflicts | Isolated networks per test run |
| CI timeout issues | Configurable timeouts, partial result capture |
