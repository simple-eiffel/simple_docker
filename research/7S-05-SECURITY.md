# 7S-05: SECURITY

**Library:** simple_docker
**Date:** 2026-01-23
**Status:** BACKWASH (reverse-engineered from implementation)

## Security Considerations

### Docker Socket Access

**Risk:** Docker socket access = root access on host

**Mitigation:**
- Application must have socket permissions
- Consider rootless Docker for reduced privileges
- Don't expose socket to untrusted code

### Container Escape

**Risk:** Malicious container could escape to host

**Mitigation:**
- Don't mount host directories without need
- Use read-only volume mounts when possible
- Avoid privileged containers

### Image Security

**Risk:** Pulling untrusted images

**Mitigation:**
- Use specific image tags, not `latest`
- Verify image sources
- Scan images for vulnerabilities

### Port Binding

**Risk:** Binding to 0.0.0.0 exposes to network

**Mitigation:**
- Bind to localhost (127.0.0.1) when possible
- Use Docker networks for inter-container communication

### Credentials in Environment

**Risk:** Secrets in environment variables visible

**Mitigation:**
- Use Docker secrets when possible
- Don't log environment variables
- Use least privilege for credentials

## Security Checklist

- [ ] Validate image sources before pulling
- [ ] Avoid running containers as root
- [ ] Limit volume mounts
- [ ] Use specific image tags
- [ ] Restrict network exposure
- [ ] Don't embed secrets in code
- [ ] Clean up stopped containers
