FROM alpine:latest

# Install git, openssh-server, and rsync with security updates
RUN apk add --no-cache git openssh-server rsync && \
    apk upgrade --no-cache

# Create git user with home directory /home/git and shell /usr/bin/git-shell
RUN adduser -D -h /home/git -s /usr/bin/git-shell git && \
    passwd -u git

# Create SSH directory for git user
RUN mkdir -p /home/git/.ssh && \
    chmod 700 /home/git/.ssh && \
    touch /home/git/.ssh/authorized_keys && \
    chmod 600 /home/git/.ssh/authorized_keys && \
    chown -R git:git /home/git/.ssh

# SSH configuration
RUN mkdir -p /etc/ssh && \
    # Disable password authentication
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    # Enable public key authentication
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    # Disable root login
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    # Disable empty passwords
    sed -i 's/#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config && \
    # Disable X11 forwarding
    sed -i 's/#X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config && \
    sed -i 's/X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config && \
    # Additional security settings
    echo "" >> /etc/ssh/sshd_config && \
    echo "# Security hardening" >> /etc/ssh/sshd_config && \
    echo "MaxAuthTries 3" >> /etc/ssh/sshd_config && \
    echo "MaxSessions 2" >> /etc/ssh/sshd_config && \
    echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config && \
    echo "AllowAgentForwarding no" >> /etc/ssh/sshd_config && \
    echo "AllowStreamLocalForwarding no" >> /etc/ssh/sshd_config && \
    echo "GatewayPorts no" >> /etc/ssh/sshd_config && \
    echo "PermitTunnel no" >> /etc/ssh/sshd_config && \
    echo "AllowUsers git" >> /etc/ssh/sshd_config && \
    echo "LoginGraceTime 30" >> /etc/ssh/sshd_config && \
    echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config && \
    echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config && \
    echo "PrintMotd no" >> /etc/ssh/sshd_config && \
    sed -i '/^#\?HostKey /d' /etc/ssh/sshd_config && \
    echo "HostKey /etc/ssh/host-keys/ssh_host_ed25519_key" >> /etc/ssh/sshd_config && \
    echo "HostKey /etc/ssh/host-keys/ssh_host_rsa_key" >> /etc/ssh/sshd_config

# Create mount point for host-supplied SSH host keys
RUN mkdir -p /etc/ssh/host-keys

# Create git-shell-commands directory in permanent location (outside volume)
RUN mkdir -p /usr/local/share/git-shell-commands

# Copy git-shell commands to permanent location
COPY scripts/list /usr/local/share/git-shell-commands/list
COPY scripts/create /usr/local/share/git-shell-commands/create
COPY scripts/help /usr/local/share/git-shell-commands/help

# Set permissions and ownership
# Scripts are read-only (555) to prevent tampering
RUN chmod 555 /usr/local/share/git-shell-commands/* && \
    chown root:root /usr/local/share/git-shell-commands/*

# Copy run script
COPY scripts/run /usr/local/bin/run
RUN chmod 555 /usr/local/bin/run && \
    chown root:root /usr/local/bin/run

# Volume for persistent storage
VOLUME /home/git

# Expose SSH port
EXPOSE 22

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD pgrep sshd || exit 1

# Run script syncs git-shell commands and starts SSH daemon
CMD ["/usr/local/bin/run"]
