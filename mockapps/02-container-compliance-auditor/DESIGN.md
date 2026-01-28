# Container Compliance Auditor - Technical Design

## Architecture

### Component Overview

```
+---------------------------------------------------------------+
|                 Container Compliance Auditor                   |
+---------------------------------------------------------------+
|  CLI Interface Layer                                           |
|    - comply scan <target>     Scan image/container             |
|    - comply report <scan-id>  Generate report from scan        |
|    - comply policy            Policy management                |
|    - comply baseline          Baseline management              |
|    - comply daemon            Continuous monitoring            |
+---------------------------------------------------------------+
|  Business Logic Layer                                          |
|    - Scan Engine        Execute compliance checks              |
|    - Policy Engine      Load, validate, apply policies         |
|    - Report Generator   Generate audit-ready reports           |
|    - Baseline Manager   Track known-good configurations        |
|    - Finding Classifier Categorize and prioritize findings     |
+---------------------------------------------------------------+
|  Integration Layer                                             |
|    - simple_docker      Container/image inspection             |
|    - simple_json        Policy definitions, scan results       |
|    - simple_yaml        Policy files, configuration            |
|    - simple_file        Report output, baseline storage        |
|    - simple_cli         Argument parsing, output formatting    |
|    - simple_hash        Image fingerprinting                   |
|    - simple_template    Report template rendering              |
|    - simple_csv         Audit export format                    |
+---------------------------------------------------------------+
```

### Class Design

| Class | Responsibility | Key Features |
|-------|----------------|--------------|
| `COMPLY_CLI` | Command-line interface | parse_args, route_command, format_output |
| `COMPLY_SCANNER` | Execute compliance scans | scan_image, scan_container, scan_host |
| `COMPLY_POLICY` | Policy representation | rules, severity, remediation |
| `COMPLY_POLICY_ENGINE` | Policy loading/execution | load_policy, evaluate_rule, aggregate_results |
| `COMPLY_FINDING` | Individual compliance finding | rule_id, severity, evidence, remediation |
| `COMPLY_SCAN_RESULT` | Complete scan results | target, findings, pass_count, fail_count |
| `COMPLY_REPORT` | Report generation | to_text, to_json, to_pdf, to_csv |
| `COMPLY_BASELINE` | Known-good configuration | create_baseline, compare_baseline |
| `COMPLY_CHECK` | Individual compliance check | check_user_root, check_exposed_ports, etc. |
| `COMPLY_FRAMEWORKS` | Built-in framework policies | cis_docker, pci_dss, hipaa, soc2 |

### Command Structure

```bash
comply <command> [options] [arguments]

Commands:
  scan <target>          Scan image or container for compliance
  report <scan-id>       Generate report from previous scan
  policy                 Policy management subcommands
  baseline               Baseline management subcommands
  daemon                 Run continuous monitoring daemon
  frameworks             List available compliance frameworks

Scan Options:
  -f, --framework NAME   Compliance framework (cis, pci-dss, hipaa, soc2, custom)
  -p, --policy FILE      Custom policy file
  -o, --output FORMAT    Output format (text, json, csv, sarif)
  --severity LEVEL       Minimum severity (critical, high, medium, low, info)
  --fail-on LEVEL        Exit non-zero if findings at this level or higher
  --baseline FILE        Compare against baseline
  --evidence-dir DIR     Save evidence artifacts

Report Options:
  --format FORMAT        Report format (text, json, pdf, html)
  --template FILE        Custom report template
  --include-evidence     Include evidence artifacts in report
  --executive-summary    Generate executive summary

Examples:
  comply scan nginx:latest                    # Quick CIS benchmark scan
  comply scan nginx:latest -f pci-dss        # PCI-DSS compliance scan
  comply scan nginx:latest --fail-on high    # Fail CI if high findings
  comply scan --all-running                  # Scan all running containers
  comply report last --format pdf            # PDF report of last scan
  comply baseline create nginx:latest        # Create baseline from image
  comply baseline compare nginx:latest       # Compare against baseline
```

### Data Flow

```
Target (Image/Container) -> Scanner -> Policy Engine -> Finding Classifier
                                           |                    |
                                      Policy Rules         Findings List
                                           |                    |
                                      Evaluation           Report Generator
                                           |                    |
                                      Evidence            Output (text/json/pdf)
```

### Policy Schema (comply-policy.yaml)

```yaml
# Container Compliance Auditor Policy Definition
version: "1.0"
framework: custom-policy
name: Organization Security Policy
description: Internal container security requirements

metadata:
  author: Security Team
  version: "1.2.0"
  last_updated: "2026-01-15"
  tags: [internal, production, critical]

rules:
  - id: ORG-001
    title: Containers must not run as root
    description: All containers must run as non-root user to limit privilege escalation
    severity: critical
    category: access-control
    check:
      type: container_config
      field: User
      operator: not_equals
      value: ""
    remediation: |
      Add USER directive to Dockerfile:
        USER nonroot:nonroot
      Or set user in container spec:
        spec.set_user("nonroot")
    references:
      - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
      - CIS Docker Benchmark 4.1

  - id: ORG-002
    title: No privileged containers
    description: Containers must not run in privileged mode
    severity: critical
    category: access-control
    check:
      type: container_config
      field: HostConfig.Privileged
      operator: equals
      value: false
    remediation: Remove --privileged flag from container run command

  - id: ORG-003
    title: Resource limits required
    description: Containers must have memory and CPU limits set
    severity: high
    category: resource-management
    check:
      type: container_config
      fields:
        - path: HostConfig.Memory
          operator: greater_than
          value: 0
        - path: HostConfig.CpuShares
          operator: greater_than
          value: 0
    remediation: |
      Set resource limits in container spec:
        spec.set_memory_limit(512 * 1024 * 1024)  -- 512 MB
        spec.set_cpu_shares(1024)

  - id: ORG-004
    title: Approved base images only
    description: Images must derive from approved base images
    severity: high
    category: supply-chain
    check:
      type: image_ancestry
      allowed_bases:
        - "alpine:*"
        - "ubuntu:22.04"
        - "debian:bookworm-slim"
        - "registry.internal.com/*"
    remediation: Update Dockerfile FROM to use an approved base image

  - id: ORG-005
    title: No exposed high ports
    description: Containers should not expose ports below 1024 except 80 and 443
    severity: medium
    category: network-security
    check:
      type: container_config
      field: ExposedPorts
      operator: custom
      script: check_exposed_ports
    remediation: Use port mapping to expose services on high ports

# Compliance mappings to frameworks
mappings:
  cis_docker:
    ORG-001: "4.1"
    ORG-002: "5.4"
    ORG-003: "5.10"
  pci_dss:
    ORG-001: "7.1.1"
    ORG-002: "7.1.2"
    ORG-004: "6.3.2"
```

### Error Handling

| Error Type | Handling | User Message |
|------------|----------|--------------|
| TargetNotFound | Exit with error | "Image 'foo' not found. Pull it first or check name." |
| PolicyParseError | Show parse error | "Policy error at line {n}: {detail}" |
| DockerNotRunning | Clear instructions | "Cannot connect to Docker. Is Docker Desktop running?" |
| InsufficientPermissions | Request elevation | "Scanning host config requires admin privileges." |
| ScanTimeout | Partial results | "Scan timed out after 300s. Partial results available." |
| InvalidFramework | List available | "Unknown framework 'foo'. Available: cis, pci-dss, hipaa, soc2" |

## GUI/TUI Future Path

**CLI foundation enables:**
- CI/CD plugins (Jenkins, GitHub Actions, GitLab CI)
- IDE extensions showing findings inline
- TUI dashboard with real-time scan progress
- Web dashboard aggregating scans across teams

**What would change for TUI:**
- Add COMPLY_TUI class using simple_tui
- Real-time progress bars during scanning
- Interactive finding browser with vim-style navigation
- Drill-down from findings to evidence

**What would change for GUI/Web:**
- REST API layer exposing scan operations
- COMPLY_WEB_UI class with simple_htmx
- Historical trends and charts using simple_chart
- Team-based access control
