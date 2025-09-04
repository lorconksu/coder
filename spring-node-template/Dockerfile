FROM rockylinux:9

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV MAVEN_HOME=/opt/maven
ENV NODE_VERSION=20
ENV SONAR_SCANNER_VERSION=5.0.1.3006
ENV PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH

# Install packages one group at a time to avoid transaction conflicts
RUN dnf makecache --refresh && dnf clean all

# Install essential system packages (use --allowerasing to handle curl conflicts)
RUN dnf install -y --allowerasing curl wget unzip sudo which && dnf clean all

# Install development tools
RUN dnf install -y gcc gcc-c++ make git && dnf clean all

# Install additional utilities
RUN dnf install -y procps-ng openssh-clients ca-certificates tzdata && dnf clean all

# Install EPEL repository
RUN dnf install -y epel-release && dnf clean all

# Install Java 21 LTS
RUN dnf install -y java-21-openjdk java-21-openjdk-devel && \
    dnf clean all

# Install Maven
RUN curl -sfL https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -o /tmp/maven.tar.gz && \
    tar -xzf /tmp/maven.tar.gz -C /opt && \
    ln -s /opt/apache-maven-3.9.6 /opt/maven && \
    rm /tmp/maven.tar.gz

# Install Node.js LTS (20.x) and npm
RUN curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - && \
    dnf install -y nodejs && \
    dnf clean all

# Git is already installed above

# Install Docker CLI (simplified approach)
RUN dnf install -y dnf-plugins-core && dnf clean all
RUN dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN dnf install -y docker-ce-cli docker-compose-plugin && dnf clean all

# Install PostgreSQL client
RUN dnf install -y postgresql && dnf clean all

# Install SonarQube Scanner
RUN curl -sfL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip -o /tmp/sonar-scanner.zip && \
    unzip /tmp/sonar-scanner.zip -d /opt && \
    ln -s /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm /tmp/sonar-scanner.zip

# Install Trivy
RUN curl -sfL https://github.com/aquasecurity/trivy/releases/download/v0.50.1/trivy_0.50.1_Linux-64bit.rpm -o /tmp/trivy.rpm && \
    dnf install -y /tmp/trivy.rpm && \
    rm /tmp/trivy.rpm && \
    dnf clean all

# Install Grype
RUN curl -sfL https://github.com/anchore/grype/releases/download/v0.74.7/grype_0.74.7_linux_amd64.rpm -o /tmp/grype.rpm && \
    dnf install -y /tmp/grype.rpm && \
    rm /tmp/grype.rpm && \
    dnf clean all

# Create coder user and set up sudo permissions
RUN useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/coder && \
    chmod 440 /etc/sudoers.d/coder

# Add coder user to docker group (if docker daemon is available)
RUN groupadd -f docker && \
    usermod -aG docker coder

# Fix npm cache permissions and set up working directory
WORKDIR /home/coder/workspace
RUN chown -R coder:coder /home/coder && \
    mkdir -p /home/coder/.npm /home/coder/.config && \
    chown -R coder:coder /home/coder/.npm /home/coder/.config

# Switch to coder user
USER coder

# Configure npm for the coder user (local global installs)
RUN mkdir -p /home/coder/.npm-global && \
    npm config set prefix /home/coder/.npm-global && \
    npm config set cache /home/coder/.npm && \
    echo 'export PATH=/home/coder/.npm-global/bin:$PATH' >> /home/coder/.bashrc

# Verify installations
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

# Set default command
CMD ["/bin/bash"]