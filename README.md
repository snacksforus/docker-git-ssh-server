# docker-git-ssh-server

Git server Docker container using Alpine Linux with SSH access, persistent storage, and built-in repository management commands.

## Features

- **SSH-based Git repository hosting** with public key authentication only
- **Persistent volume** for repositories
- **Built-in commands** for listing and creating repositories
- **Health monitoring** with Docker health checks
- **Resource limits** support for production deployments

## Quick Start

### Build

```bash
docker build -t git-server .
```

### Run

```bash
./run
```

### Add SSH Key

```bash
./scripts/add-key ~/.ssh/id_rsa.pub
```

See [SSH Key Management](#ssh-key-management) for more options.

### View Available Commands

```bash
ssh -p 2222 git@localhost help
```

### Create Repository

```bash
ssh -p 2222 git@localhost create myproject
```

### Clone Repository

```bash
git clone ssh://git@localhost:2222/home/git/myproject.git
```

## SSH Key Management

```bash
# Add your SSH public key
./scripts/add-key ~/.ssh/id_rsa.pub
```

### Remove SSH Key

```bash
# Remove key by comment (e.g., user@hostname)
./scripts/remove-key 'user@hostname'

# Remove key by fingerprint
./scripts/remove-key 'SHA256:AbC123...'

# Remove specific user's key
./scripts/remove-key 'john@laptop'
```

### List SSH Keys

```bash
# List all authorized keys with details
./scripts/list-keys
```

## Monitoring

### View Logs

```bash
# Real-time logs
docker logs -f git-server

# Last 100 lines
docker logs --tail 100 git-server

# Logs with timestamps
docker logs -t git-server
```

### Monitor Failed Login Attempts

```bash
# Watch for authentication failures
docker logs git-server 2>&1 | grep -i "failed\|invalid\|authentication"
```

### Health Check

```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' git-server

# Health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' git-server
```

### External Logging

```bash
# Send logs to syslog server
docker run -d \
  --log-driver=syslog \
  --log-opt syslog-address=udp://logserver:514 \
  --log-opt tag="git-server" \
  git-server

# Or use JSON file with rotation
docker run -d \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  git-server
```

## Backup and Disaster Recovery

### Backup Repositories

```bash
# Backup volume to tar
docker run --rm \
  -v git-repos:/backup-source:ro \
  -v $(pwd):/backup-dest \
  alpine tar czf /backup-dest/$(date +%Y%m%d)-git-repos.tar.gz -C /backup-source .

# Or use docker cp
docker cp git-server:/home/git ./$(date +%Y%m%d)-git-backup
```

### Restore from Backup

```bash
# Restore from tar
docker run --rm \
  -v git-repos:/restore-dest \
  -v $(pwd):/backup-source \
  alpine tar xzf /backup-source/YYYYMMDD-git-repos.tar.gz -C /restore-dest
```

## Maintenance

### Update Packages

```bash
# Rebuild with latest packages
docker build --no-cache -t git-server .

# Restart with new image
docker stop git-server
docker rm git-server
docker run -d [... your run command ...]
```

### Audit Repositories

```bash
# List all repositories
docker exec git-server ls -lah /home/git/*.git

# Check repository sizes
docker exec git-server du -sh /home/git/*.git
```

### Prune Old Data

```bash
# Enter container
docker exec -it git-server sh

# Run git gc on all repos
for repo in /home/git/*.git; do
  git -C "$repo" gc --aggressive
done
```

## AI-Assisted Development

This project was created using [Claude Code](https://claude.com/claude-code), Anthropic's official CLI for Claude. Claude Code was guided through the development process to:

- Design and implement the Dockerfile
- Create the git-shell command scripts with input validation
- Develop comprehensive security documentation and best practices
- Troubleshoot SSH authentication issues
- Implement defense-in-depth security measures

The project demonstrates how AI can assist in creating production-ready infrastructure with security best practices built in from the start.

## License

BSD 3-Clause License - See [LICENSE](LICENSE) file for details.

## ToDo

- [ ] git shell command to show info about repositories
- [ ] validate that the maintenance and audit command work correctly with the container

## Change History

- 20260110: Initial implementation

## Commit Signature Verification

All commits from 2026-05-25 onward are signed using SSH keys backed by a YubiKey
FIDO2 hardware security key. Each signing operation requires physical presence
on the hardware device. Commits predating this policy are unsigned.

### Verifying commits locally

Configure Git to use the included trust files:

```bash
git config gpg.ssh.allowedSignersFile .allowed_signers
git config gpg.ssh.revocationFile .revoked_signers
```

Verify a specific commit:

```bash
git verify-commit <hash>
```

Verify the full log:

```bash
git log --show-signature
```

### Key rotation and revocation

The `.allowed_signers` file lists all currently trusted public keys. The
`.revoked_signers` file lists keys that must never be trusted, regardless of the
date of the commit they signed. Both files are updated and committed when keys
are added, rotated, or revoked.

In the event of a key compromise, the affected key will be removed from GitHub
and added to `.revoked_signers`. A signed notice commit will be pushed to this
repository identifying the old and new key fingerprints and the date from which
the old key must be considered untrusted.

Public keys for this account are discoverable at:
`https://github.com/snacksforus.keys`
