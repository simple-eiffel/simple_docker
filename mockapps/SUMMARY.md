# Mock Apps Summary: simple_docker

## Generated: 2026-01-24

---

## Library Analyzed

- **Library:** simple_docker v1.4.0
- **Core capability:** Docker container management via Engine API
- **Ecosystem position:** Infrastructure layer enabling containerized application deployment
- **Test status:** 58 tests passing (Production ready)

---

## Mock Apps Designed

### 1. DevEnv Provisioner

- **Purpose:** Declarative development environment provisioning with team sharing
- **Target:** Software development teams, consultancies, training organizations
- **Ecosystem:** 7 simple_* libraries (docker, yaml, json, cli, file, config, validation)
- **Revenue model:** Free -> $15/dev/mo Pro -> $45/dev/mo Enterprise
- **Status:** Design complete

**Key Commands:**
```bash
devenv init rails           # Initialize from template
devenv up                   # Start environment
devenv status               # Show running services
devenv down                 # Stop environment
```

---

### 2. Container Compliance Auditor

- **Purpose:** Automated container security scanning with compliance reporting
- **Target:** Enterprises in regulated industries (finance, healthcare, government)
- **Ecosystem:** 8 simple_* libraries (docker, json, yaml, cli, file, hash, template, config)
- **Revenue model:** Free Community -> $299/mo Business -> $999/mo Enterprise
- **Status:** Design complete

**Key Commands:**
```bash
comply scan nginx:latest              # CIS benchmark scan
comply scan nginx:latest -f pci-dss  # PCI-DSS compliance
comply scan --fail-on high           # CI/CD integration
comply report last --format pdf      # Audit report
```

---

### 3. Ephemeral Test Runner

- **Purpose:** Hermetic test environments with fixture management and automatic cleanup
- **Target:** QA teams, CI/CD pipelines, microservices development
- **Ecosystem:** 7 simple_* libraries (docker, json, yaml, cli, file, testing, config)
- **Revenue model:** Open source core -> $99/mo Pro -> $499/mo Enterprise
- **Status:** Design complete

**Key Commands:**
```bash
testrun run                    # Execute test suite
testrun run --parallel 4       # Parallel execution
testrun run --preserve-on-fail # Debug failures
testrun debug last             # Attach to failed env
```

---

## Ecosystem Coverage

| simple_* Library | Used In |
|------------------|---------|
| **simple_docker** | All 3 apps |
| **simple_json** | All 3 apps |
| **simple_yaml** | All 3 apps |
| **simple_cli** | All 3 apps |
| **simple_file** | All 3 apps |
| **simple_config** | All 3 apps |
| **simple_validation** | DevEnv Provisioner |
| **simple_hash** | Compliance Auditor |
| **simple_template** | Compliance Auditor, Test Runner |
| **simple_testing** | Test Runner |
| **simple_sql** | Test Runner (optional) |
| **simple_csv** | Compliance Auditor (optional) |

**Total unique libraries leveraged:** 12 simple_* libraries

---

## Implementation Comparison

| Aspect | DevEnv Provisioner | Compliance Auditor | Test Runner |
|--------|-------------------|-------------------|-------------|
| **MVP Effort** | 3-4 days | 4-5 days | 4-5 days |
| **Total Effort** | 7-10 days | 9-12 days | 9-12 days |
| **Complexity** | Medium | High | High |
| **Market Size** | Large | Medium (regulated) | Large |
| **Competition** | Moderate | High (enterprise tools) | Moderate |
| **Differentiation** | Language-agnostic, team focus | CLI-first, lightweight | Eiffel ecosystem integration |

---

## Recommended Implementation Order

1. **DevEnv Provisioner** - Fastest to MVP, broadest appeal, validates ecosystem
2. **Ephemeral Test Runner** - Natural fit with simple_testing, internal use case
3. **Container Compliance Auditor** - Higher complexity, but high-value market

---

## Next Steps

1. **Select Mock App** - Choose which app to implement first
2. **Create project structure** - Set up directory and ECF
3. **Run /eiffel.contracts** - Generate class skeletons with contracts
4. **Implement Phase 1** - Build MVP following BUILD-PLAN.md
5. **Run /eiffel.verify** - Validate contracts with tests

---

## Files Generated

```
simple_docker/mockapps/
├── 00-MARKETPLACE-RESEARCH.md
├── 01-devenv-provisioner/
│   ├── CONCEPT.md
│   ├── DESIGN.md
│   ├── ECOSYSTEM-MAP.md
│   └── BUILD-PLAN.md
├── 02-container-compliance-auditor/
│   ├── CONCEPT.md
│   ├── DESIGN.md
│   ├── ECOSYSTEM-MAP.md
│   └── BUILD-PLAN.md
├── 03-ephemeral-test-runner/
│   ├── CONCEPT.md
│   ├── DESIGN.md
│   ├── ECOSYSTEM-MAP.md
│   └── BUILD-PLAN.md
└── SUMMARY.md
```

**Total files:** 14 documentation files

---

## Quality Checklist

- [x] All apps are CLI-first, business-tier applications
- [x] All apps leverage 6+ simple_* libraries
- [x] All apps have clear revenue models
- [x] All apps have GUI/TUI upgrade paths documented
- [x] All apps solve real business problems with market evidence
- [x] All apps have phased build plans with acceptance criteria
- [x] All apps have complete ECF configurations
- [x] Marketplace research cites real competitors and market data
