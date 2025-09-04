# Spring Boot + Node.js Development Environment Dockerfile
# Based on Rocky Linux 9 for enterprise-grade stability and security
# Includes Java 21 LTS, Maven, Node.js LTS, and comprehensive development tools

# Use Rocky Linux 9 as the base image
# Rocky Linux is an enterprise-grade Linux distribution that's binary-compatible with RHEL
FROM rockylinux:9

# Define environment variables for consistent tool configuration
# These variables ensure all tools can find their required paths
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk        # Java installation directory
ENV MAVEN_HOME=/opt/maven                          # Maven installation directory  
ENV NODE_VERSION=20                                # Node.js LTS version to install
ENV SONAR_SCANNER_VERSION=5.0.1.3006              # SonarQube Scanner version
ENV PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH      # Update PATH to include Java and Maven

# Refresh package cache to ensure we get latest package information
# Clean cache immediately after to keep image size minimal
RUN dnf makecache --refresh && dnf clean all

# Install essential system packages in separate layers for better caching
# --allowerasing flag resolves conflicts between curl and curl-minimal packages
RUN dnf install -y --allowerasing curl wget unzip sudo which && dnf clean all

# Install development tools required for building native dependencies
# gcc/gcc-c++: C/C++ compilers for native Node.js modules
# make: Build automation tool
# git: Version control system
RUN dnf install -y gcc gcc-c++ make git && dnf clean all

# Install additional system utilities for development and troubleshooting
# procps-ng: Process monitoring tools (ps, top, etc.)
# openssh-clients: SSH client for Git operations and remote access
# ca-certificates: SSL/TLS certificates for secure connections
# tzdata: Timezone data for proper time handling
RUN dnf install -y procps-ng openssh-clients ca-certificates tzdata && dnf clean all

# Install EPEL (Extra Packages for Enterprise Linux) repository
# Provides additional packages not available in base Rocky Linux repositories
RUN dnf install -y epel-release && dnf clean all

# Install Java 21 LTS (Long Term Support)
# java-21-openjdk: Java runtime environment
# java-21-openjdk-devel: Java development kit with compiler and debugging tools
RUN dnf install -y java-21-openjdk java-21-openjdk-devel && \
    dnf clean all

# Install Apache Maven 3.9.6 for Java project management and building
# Download from Apache archives, extract to /opt, and create symlink for version flexibility
RUN curl -sfL https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -o /tmp/maven.tar.gz && \
    tar -xzf /tmp/maven.tar.gz -C /opt && \
    ln -s /opt/apache-maven-3.9.6 /opt/maven && \
    rm /tmp/maven.tar.gz

# Install Node.js LTS (version 20.x) and npm for JavaScript development
# Uses NodeSource repository for latest LTS version with security updates
RUN curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - && \
    dnf install -y nodejs && \
    dnf clean all

# Install Docker CLI and Docker Compose for containerization support
# Allows developers to build, run, and manage containers from within the workspace
# dnf-plugins-core: Required for repository management
RUN dnf install -y dnf-plugins-core && dnf clean all
RUN dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN dnf install -y docker-ce-cli docker-compose-plugin && dnf clean all

# Install PostgreSQL client for database operations
# Provides psql command-line interface for PostgreSQL database management
RUN dnf install -y postgresql && dnf clean all

# Install SonarQube Scanner for code quality analysis
# Downloads and installs the scanner, creates symlink for global access
# Used for static code analysis, code coverage, and technical debt assessment
RUN curl -sfL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip -o /tmp/sonar-scanner.zip && \
    unzip /tmp/sonar-scanner.zip -d /opt && \
    ln -s /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm /tmp/sonar-scanner.zip

# Install Trivy - Container and filesystem vulnerability scanner
# Scans for CVEs in OS packages, language-specific packages, and misconfigurations
# Essential for DevSecOps practices and security compliance
RUN curl -sfL https://github.com/aquasecurity/trivy/releases/download/v0.50.1/trivy_0.50.1_Linux-64bit.rpm -o /tmp/trivy.rpm && \
    dnf install -y /tmp/trivy.rpm && \
    rm /tmp/trivy.rpm && \
    dnf clean all

# Install Grype - Vulnerability scanner for container images and filesystems
# Provides additional vulnerability detection capabilities alongside Trivy
# Focuses on language-specific package vulnerabilities
RUN curl -sfL https://github.com/anchore/grype/releases/download/v0.74.7/grype_0.74.7_linux_amd64.rpm -o /tmp/grype.rpm && \
    dnf install -y /tmp/grype.rpm && \
    rm /tmp/grype.rpm && \
    dnf clean all

# Create non-root user for security best practices
# useradd -m: Create home directory
# -s /bin/bash: Set bash as default shell
# Add to sudoers with NOPASSWD for development convenience
RUN useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/coder && \
    chmod 440 /etc/sudoers.d/coder

# Add coder user to docker group for Docker socket access
# groupadd -f: Create group if it doesn't exist (force, no error if exists)
# usermod -aG: Add user to additional group
RUN groupadd -f docker && \
    usermod -aG docker coder

# Set up workspace directory and fix permissions
# Ensure coder user owns their home directory and workspace
WORKDIR /home/coder/workspace
RUN chown -R coder:coder /home/coder && \
    mkdir -p /home/coder/.npm /home/coder/.config && \
    chown -R coder:coder /home/coder/.npm /home/coder/.config

# Switch to non-root user for security
# All subsequent commands run as coder user
USER coder

# Configure npm for local global package installation
# Prevents permission errors when installing global packages
# .npm-global: Local directory for global npm packages
# Update PATH to include local global binaries
RUN mkdir -p /home/coder/.npm-global && \
    npm config set prefix /home/coder/.npm-global && \
    npm config set cache /home/coder/.npm && \
    echo 'export PATH=/home/coder/.npm-global/bin:$PATH' >> /home/coder/.bashrc

# Verify all tool installations by checking their versions
# This ensures the image build fails if any tool installation failed
# Provides version information useful for debugging and compatibility
RUN java --version && \
    mvn --version && \
    node --version && \
    npm --version && \
    git --version && \
    docker --version && \
    psql --version && \
    sonar-scanner --version && \
    trivy --version && \
    grype version

# Set default command to bash shell
# Provides interactive shell when container starts without specific command
CMD ["/bin/bash"]