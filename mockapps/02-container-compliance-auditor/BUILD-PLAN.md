# Container Compliance Auditor - Build Plan

## Phase Overview

| Phase | Deliverable | Effort | Dependencies |
|-------|-------------|--------|--------------|
| Phase 1 | MVP CLI | 4-5 days | simple_docker, simple_json, simple_cli |
| Phase 2 | Full CLI | 3-4 days | Phase 1 complete |
| Phase 3 | Polish | 2-3 days | Phase 2 complete |

---

## Phase 1: MVP

### Objective

Demonstrate core value: scan a Docker image against CIS Docker Benchmark and output findings with severity levels.

### Deliverables

1. **COMPLY_CLI** - Basic command routing (scan, report)
2. **COMPLY_SCANNER** - Inspect images and containers via simple_docker
3. **COMPLY_POLICY_ENGINE** - Load and evaluate compliance rules
4. **COMPLY_FINDING** - Individual finding with severity and remediation
5. **COMPLY_SCAN_RESULT** - Aggregate findings with pass/fail counts
6. **CIS Docker Benchmark** - 15-20 core checks from CIS benchmark

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T1.1 | Set up project structure with ECF | Compiles with all dependencies |
| T1.2 | Implement COMPLY_CLI with scan command | `comply scan nginx:latest` parses |
| T1.3 | Implement COMPLY_SCANNER.scan_image | Extracts image configuration |
| T1.4 | Implement COMPLY_FINDING model | Stores rule_id, severity, evidence, remediation |
| T1.5 | Implement CIS check: root user | Detects containers running as root |
| T1.6 | Implement CIS check: privileged mode | Detects privileged containers |
| T1.7 | Implement CIS check: resource limits | Checks memory/CPU limits |
| T1.8 | Implement CIS check: network mode | Checks for host network mode |
| T1.9 | Implement COMPLY_SCAN_RESULT | Aggregates findings, calculates pass/fail |
| T1.10 | Implement text output formatter | Prints findings in readable format |
| T1.11 | Implement --fail-on flag | Exit code based on severity |
| T1.12 | Add 10 more CIS checks | Cover top 15 CIS requirements |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| Scan compliant image | Purpose-built compliant image | 0 critical/high findings |
| Scan non-compliant image | Known bad image (root user) | Critical finding for root user |
| Unknown image | Non-existent image | Clear error message |
| JSON output | `--output json` flag | Valid JSON with findings array |
| Fail-on critical | `--fail-on critical` with critical finding | Exit code 1 |
| Fail-on high | `--fail-on high` with only medium findings | Exit code 0 |

### MVP Commands

```bash
# Scan image with default CIS checks
comply scan nginx:latest
# Output:
# Scanning nginx:latest against CIS Docker Benchmark...
#
# CRITICAL (1):
#   [CIS-4.1] Container configured to run as root
#             Remediation: Add USER directive to Dockerfile
#
# HIGH (2):
#   [CIS-5.10] No memory limit set
#   [CIS-5.11] No CPU limit set
#
# Summary: 3 findings (1 critical, 2 high, 0 medium, 0 low)
# Status: NON-COMPLIANT

# CI/CD integration (fails if high or critical)
comply scan nginx:latest --fail-on high
echo $?  # Returns 1

# JSON output for automation
comply scan nginx:latest --output json > results.json
```

---

## Phase 2: Full Implementation

### Objective

Complete CLI functionality with multiple frameworks, custom policies, and professional reporting.

### Deliverables

1. **Additional frameworks** - PCI-DSS, HIPAA, SOC 2 policy sets
2. **Custom policy support** - YAML policy file loading
3. **Container scanning** - Scan running containers, not just images
4. **Baseline management** - Create and compare baselines
5. **Report generation** - HTML and JSON reports with evidence
6. **SARIF output** - Standard format for CI/CD integration

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T2.1 | Implement PCI-DSS policy set | 20+ PCI-relevant checks |
| T2.2 | Implement HIPAA policy set | 15+ HIPAA-relevant checks |
| T2.3 | Implement SOC 2 policy set | 15+ SOC 2-relevant checks |
| T2.4 | Implement YAML policy loading | Custom policies load and execute |
| T2.5 | Implement container scanning | `comply scan --container <id>` works |
| T2.6 | Implement `comply scan --all-running` | Scans all running containers |
| T2.7 | Implement baseline creation | `comply baseline create` saves baseline |
| T2.8 | Implement baseline comparison | `comply baseline compare` shows diffs |
| T2.9 | Implement HTML report generation | Professional HTML report with styling |
| T2.10 | Implement SARIF output | Compatible with GitHub Security tab |
| T2.11 | Implement evidence collection | Save evidence artifacts to directory |
| T2.12 | Add verbose mode | Shows check execution progress |

### Test Cases

| Test | Input | Expected Output |
|------|-------|-----------------|
| PCI-DSS scan | `-f pci-dss` | PCI-DSS specific findings |
| Custom policy | `-p custom.yaml` | Custom rule evaluated |
| Container scan | Running container ID | Runtime-specific findings |
| Baseline create | Compliant image | Baseline JSON created |
| Baseline drift | Modified image | Drift findings reported |
| HTML report | `report --format html` | Valid HTML file generated |
| SARIF output | `--output sarif` | Valid SARIF JSON |

---

## Phase 3: Production Polish

### Objective

Production-ready CLI with comprehensive coverage, performance optimization, and professional documentation.

### Deliverables

1. **Complete CIS coverage** - All 100+ CIS Docker Benchmark checks
2. **Performance optimization** - Parallel check execution
3. **Error handling hardening** - All edge cases covered
4. **Documentation** - User guide, policy writing guide
5. **CI/CD examples** - GitHub Actions, GitLab CI, Jenkins examples
6. **Installer** - Easy installation across platforms

### Tasks

| Task | Description | Acceptance Criteria |
|------|-------------|---------------------|
| T3.1 | Complete CIS Docker Benchmark coverage | 100+ checks implemented |
| T3.2 | Add check parallelization | 2x faster scans |
| T3.3 | Add scan caching | Skip unchanged layers |
| T3.4 | Comprehensive error messages | All error paths covered |
| T3.5 | Write user documentation | README with full usage |
| T3.6 | Write policy authoring guide | Custom policy tutorial |
| T3.7 | Create GitHub Actions example | Working action file |
| T3.8 | Create GitLab CI example | Working .gitlab-ci.yml |
| T3.9 | Create Jenkins example | Working Jenkinsfile |
| T3.10 | Final testing pass | 50+ tests pass |

---

## ECF Target Structure

```xml
<!-- Library target -->
<target name="container_compliance_auditor">
    <option>
        <assertions precondition="true" postcondition="true" check="true"
                    invariant="true" loop="true" supplier_precondition="true"/>
    </option>
    <library name="simple_docker" location="$SIMPLE_EIFFEL/simple_docker/simple_docker.ecf"/>
    <library name="simple_json" location="$SIMPLE_EIFFEL/simple_json/simple_json.ecf"/>
    <library name="simple_yaml" location="$SIMPLE_EIFFEL/simple_yaml/simple_yaml.ecf"/>
    <library name="simple_cli" location="$SIMPLE_EIFFEL/simple_cli/simple_cli.ecf"/>
    <library name="simple_hash" location="$SIMPLE_EIFFEL/simple_hash/simple_hash.ecf"/>
    <library name="simple_template" location="$SIMPLE_EIFFEL/simple_template/simple_template.ecf"/>
    <cluster name="src" location=".\src\"/>
    <cluster name="policies" location=".\policies\"/>
</target>

<!-- CLI executable -->
<target name="comply_cli" extends="container_compliance_auditor">
    <root class="COMPLY_CLI" feature="make"/>
    <setting name="console_application" value="true"/>
    <setting name="executable_name" value="comply"/>
</target>

<!-- Test target -->
<target name="comply_tests" extends="container_compliance_auditor">
    <root class="TEST_APP" feature="make"/>
    <library name="simple_testing" location="$SIMPLE_EIFFEL/simple_testing/simple_testing.ecf"/>
    <cluster name="testing" location=".\testing\"/>
</target>
```

## Build Commands

```bash
# Compile CLI (workbench mode)
/d/prod/ec.sh -batch -config comply.ecf -target comply_cli -c_compile

# Compile CLI (finalized)
/d/prod/ec.sh -batch -config comply.ecf -target comply_cli -finalize -c_compile

# Run tests
/d/prod/ec.sh -batch -config comply.ecf -target comply_tests -c_compile
./EIFGENs/comply_tests/W_code/comply.exe

# Finalized tests
/d/prod/ec.sh -batch -config comply.ecf -target comply_tests -finalize -keep -c_compile
./EIFGENs/comply_tests/F_code/comply.exe
```

## Success Criteria

| Criterion | Measure | Target |
|-----------|---------|--------|
| Compiles | Zero errors | 100% |
| Tests pass | All test cases | 100% |
| CIS coverage | Checks implemented | 100+ |
| Scan time | Average image scan | < 30 seconds |
| False positive rate | Manual review | < 5% |
| CI/CD integration | Works with major CI systems | 3+ |
| Documentation | Complete user guide | Yes |

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Docker API rate limits | Cache image inspection results |
| Large image scan time | Parallel check execution |
| Policy false positives | Allow severity overrides, baseline exclusions |
| Framework updates | Version policies, provide update mechanism |
| Cross-platform compat | Focus Windows first, test Linux in CI |
