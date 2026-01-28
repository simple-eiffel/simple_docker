# Marketplace Research: simple_docker

**Generated:** 2026-01-24
**Library:** simple_docker v1.4.0
**Status:** Production - 58 tests passing

---

## Library Profile

### Core Capabilities

| Capability | Description | Business Value |
|------------|-------------|----------------|
| Container Lifecycle | Create, start, stop, pause, restart, kill, remove containers | Automate container deployment workflows |
| Image Management | List, pull, build, inspect, remove Docker images | Standardize application packaging |
| Network Management | Create, connect, disconnect, remove networks | Isolate application environments |
| Volume Management | Create, list, remove volumes with driver config | Persist data across container restarts |
| Exec Operations | Execute commands in running containers | Remote administration and debugging |
| Dockerfile Builder | Fluent API for Dockerfile generation | Programmatic image definition |
| Zero-Config Facade | One-liner operations for common tasks | Rapid prototyping, beginner-friendly |
| Resilient IPC | Automatic retry with exponential backoff | Production-grade reliability |

### API Surface

| Feature | Type | Use Case |
|---------|------|----------|
| `DOCKER_CLIENT.ping` | Query | Health check Docker daemon |
| `DOCKER_CLIENT.run_container` | Command | Deploy containerized applications |
| `DOCKER_CLIENT.container_logs` | Query | Retrieve application output |
| `DOCKER_CLIENT.exec_in_container` | Command | Run commands in live containers |
| `DOCKER_CLIENT.build_image` | Command | Build images from Dockerfiles |
| `CONTAINER_SPEC` fluent builder | Builder | Configure containers programmatically |
| `DOCKERFILE_BUILDER` | Builder | Generate Dockerfiles with multi-stage support |
| `SIMPLE_DOCKER_QUICK.web_server` | Command | One-liner web server deployment |
| `SIMPLE_DOCKER_QUICK.postgres` | Command | One-liner database deployment |
| `SIMPLE_DOCKER_QUICK.run_script` | Command | Execute scripts in containers |

### Existing Dependencies

| simple_* Library | Purpose in simple_docker |
|------------------|------------------------|
| simple_ipc | Named pipe/Unix socket communication with Docker Engine |
| simple_json | JSON parsing for Docker API responses |
| simple_file | File operations for Dockerfile handling |
| simple_logger | Structured logging for diagnostics |

### Integration Points

- **Input formats:** CONTAINER_SPEC objects, DOCKERFILE_BUILDER, JSON configuration
- **Output formats:** DOCKER_CONTAINER, DOCKER_IMAGE, DOCKER_NETWORK, DOCKER_VOLUME objects; JSON data; log streams
- **Data flow:** Eiffel app -> simple_docker -> Docker Engine API (via named pipe) -> Container runtime

---

## Marketplace Analysis

### Industry Applications

| Industry | Application | Pain Point Solved |
|----------|-------------|-------------------|
| **Software Development** | Development environment provisioning | "Works on my machine" syndrome; onboarding time |
| **DevOps/SRE** | CI/CD pipeline automation | Consistent build/test environments |
| **Finance/Healthcare** | Compliance auditing | Container security policy enforcement |
| **QA/Testing** | Ephemeral test environments | Test isolation, parallel execution |
| **Education/Training** | Lab environment setup | Rapid classroom environment provisioning |
| **ISV/Consulting** | Client demonstration environments | Quick demo setup, teardown |

### Commercial Products (Competitors/Inspirations)

| Product | Price Point | Key Features | Gap We Could Fill |
|---------|-------------|--------------|-------------------|
| **Portainer** | $5-15/node/mo | GUI management, multi-cluster | CLI-first automation, programmable |
| **Docker Desktop** | $5-24/user/mo | Developer environment | Scriptable, no GUI dependency |
| **Docksal** | Free (OSS) | Drupal/PHP dev environments | Language-agnostic, business-tier |
| **Lando** | Free (OSS) | Local dev environments | Production deployment support |
| **Spacelift** | $99+/mo | IaC automation | Container-focused, simpler |
| **Trivy** | Free (OSS) | Security scanning | Integrated compliance reporting |
| **OX Security** | Enterprise | End-to-end container security | Lightweight, CLI-focused |

### Workflow Integration Points

| Workflow | Where simple_docker Fits | Value Added |
|----------|-------------------------|-------------|
| **Developer Onboarding** | Provision complete dev stack in one command | Hours to minutes setup time |
| **CI/CD Pipeline** | Spin up test databases, services | Isolated, reproducible tests |
| **Security Audit** | Scan containers, enforce policies | Automated compliance reporting |
| **Demo/Sales** | Quick environment setup | Professional, repeatable demos |
| **Microservices** | Container orchestration | Programmatic deployment |

### Target User Personas

| Persona | Role | Need | Willingness to Pay |
|---------|------|------|-------------------|
| **DevOps Engineer** | Platform/Infrastructure | Automate container workflows | HIGH |
| **Software Developer** | Application Developer | Consistent dev environments | MEDIUM |
| **QA Engineer** | Test Automation | Isolated test environments | MEDIUM |
| **Security Analyst** | Compliance/Security | Container audit and scanning | HIGH |
| **Tech Lead** | Team Lead | Standardize team tooling | HIGH |
| **Consultant** | External Services | Quick client environment setup | MEDIUM |

---

## Mock App Candidates

### Candidate 1: DevEnv Provisioner

**One-liner:** Declarative development environment provisioning with dependency management and team sharing.

**Target market:** Software development teams, consultancies, training organizations

**Revenue model:**
- Free tier: Personal use, 3 environment templates
- Pro tier: $15/dev/month - Team sharing, unlimited templates, cloud sync
- Enterprise tier: $45/dev/month - SSO, audit logs, private registry integration

**Ecosystem leverage:**
- simple_docker (core container management)
- simple_json (configuration files)
- simple_yaml (environment definition files)
- simple_file (template management)
- simple_config (settings persistence)
- simple_cli (command-line interface)
- simple_validation (configuration validation)

**CLI-first value:** Scriptable provisioning integrates with shell workflows, IDE plugins, CI/CD

**GUI/TUI potential:** Environment browser, template editor, status dashboard

**Viability:** HIGH - Addresses universal developer pain point with clear monetization path

---

### Candidate 2: Container Compliance Auditor

**One-liner:** Automated container security scanning with compliance report generation and policy enforcement.

**Target market:** Enterprises in regulated industries (finance, healthcare, government)

**Revenue model:**
- Community tier: Free - Basic scanning, CIS benchmarks
- Business tier: $299/month - PCI-DSS, HIPAA templates, scheduled scans
- Enterprise tier: $999/month - Custom policies, API access, SIEM integration

**Ecosystem leverage:**
- simple_docker (container inspection, image analysis)
- simple_json (scan results, policy definitions)
- simple_file (report generation)
- simple_template (report templates)
- simple_cli (scanning commands)
- simple_csv (audit export)
- simple_config (policy storage)
- simple_hash (image verification)

**CLI-first value:** Integrates into CI/CD pipelines, cron jobs, automation scripts

**GUI/TUI potential:** Compliance dashboard, policy editor, historical trend graphs

**Viability:** HIGH - Regulatory compliance is mandatory spend; clear ROI

---

### Candidate 3: Ephemeral Test Runner

**One-liner:** Spin up isolated test environments with database fixtures, run tests, capture results, tear down.

**Target market:** QA teams, CI/CD pipelines, microservices development teams

**Revenue model:**
- Open source core: Free - Basic test isolation
- Pro tier: $99/month - Parallel execution, cloud runners, test analytics
- Enterprise tier: $499/month - Self-hosted, priority support, custom integrations

**Ecosystem leverage:**
- simple_docker (container lifecycle, networking)
- simple_json (test configuration, results)
- simple_testing (test framework integration)
- simple_cli (test commands)
- simple_file (fixture management)
- simple_config (runner configuration)
- simple_template (result reporting)
- simple_sql (fixture loading - if database tests)

**CLI-first value:** Direct integration with test frameworks, CI systems, developer workflows

**GUI/TUI potential:** Test run dashboard, environment status, result visualization

**Viability:** MEDIUM-HIGH - Competitive space but clear differentiation through Eiffel ecosystem

---

## Selection Rationale

These three candidates were selected based on:

1. **Market Demand:** All address documented pain points with existing commercial solutions proving market viability

2. **Ecosystem Fit:** Each leverages 6+ simple_* libraries, demonstrating the ecosystem's value

3. **Revenue Clarity:** Clear monetization paths from free tier to enterprise

4. **CLI-First Alignment:** All work naturally as command-line tools with obvious GUI/TUI upgrade paths

5. **Differentiation:** Each offers something competitors lack:
   - DevEnv Provisioner: Programmable, language-agnostic, team-focused
   - Compliance Auditor: Lightweight CLI vs heavyweight enterprise tools
   - Test Runner: Deep integration with Eiffel testing ecosystem

6. **Implementation Feasibility:** All can be built incrementally using existing simple_docker capabilities

---

## Market Research Sources

- [Portainer Container Management](https://www.portainer.io)
- [Docker Pricing](https://www.docker.com/pricing/)
- [Container Management Tools 2026](https://northflank.com/blog/container-management-tools)
- [Docker for DevOps](https://www.docker.com/blog/docker-for-devops/)
- [Top Container Security Tools 2026](https://www.aikido.dev/blog/top-container-scanning-tools)
- [CI/CD with Docker](https://octopus.com/devops/ci-cd/ci-cd-with-docker/)
- [DevOps Automation Tools](https://www.cortex.io/post/best-devops-automation-tools)
