FROM rockylinux:9

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Install essential system packages
RUN dnf update -y && \
    dnf install -y --allowerasing curl wget unzip sudo which && \
    dnf clean all

# Install development tools and Python dependencies
RUN dnf install -y gcc gcc-c++ make git openssl-devel libffi-devel bzip2-devel sqlite-devel && \
    dnf clean all

# Install Python 3.12 from EPEL
RUN dnf install -y epel-release && \
    dnf install -y python3.12 python3.12-pip python3.12-devel && \
    dnf clean all

# Create symlinks for python and pip
RUN ln -sf /usr/bin/python3.12 /usr/local/bin/python && \
    ln -sf /usr/bin/python3.12 /usr/local/bin/python3 && \
    ln -sf /usr/bin/pip3.12 /usr/local/bin/pip

# Upgrade pip and install essential Python tools
RUN python -m pip install --upgrade pip setuptools wheel

# Install Poetry for dependency management
# Install to /usr/local/bin directly for all users to access
RUN curl -sSL https://install.python-poetry.org | POETRY_HOME=/usr/local python3 -

# Install pipenv as alternative package manager
RUN pip install pipenv

# Install core development tools
RUN pip install \
    black \
    flake8 \
    pylint \
    mypy \
    isort \
    pytest \
    pytest-cov \
    pytest-mock \
    bandit \
    safety \
    pip-audit \
    httpx \
    requests \
    pydantic \
    python-dotenv

# Install web frameworks
RUN pip install \
    flask \
    flask-sqlalchemy \
    flask-migrate \
    flask-cors \
    fastapi \
    uvicorn[standard] \
    gunicorn \
    django \
    djangorestframework

# Install database drivers
RUN pip install \
    psycopg2-binary \
    sqlalchemy \
    alembic

# Install PostgreSQL client
RUN dnf install -y postgresql && \
    dnf clean all

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo && \
    dnf install -y docker-ce-cli && \
    dnf clean all

# Install security scanning tools
ENV TRIVY_VERSION=0.50.1
ENV GRYPE_VERSION=0.74.7

# Install Trivy
RUN curl -sfL https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.rpm -o /tmp/trivy.rpm && \
    dnf install -y /tmp/trivy.rpm && \
    rm /tmp/trivy.rpm && \
    dnf clean all

# Install Grype
RUN curl -sfL https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.rpm -o /tmp/grype.rpm && \
    dnf install -y /tmp/grype.rpm && \
    rm /tmp/grype.rpm && \
    dnf clean all

# Install SonarQube Scanner
ENV SONAR_SCANNER_VERSION=5.0.1.3006
RUN curl -sfL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip -o /tmp/sonar-scanner.zip && \
    unzip /tmp/sonar-scanner.zip -d /opt && \
    ln -s /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm /tmp/sonar-scanner.zip

# Create coder user and set up permissions
RUN useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/coder && \
    chmod 440 /etc/sudoers.d/coder

# Add coder user to docker group
RUN groupadd -f docker && \
    usermod -aG docker coder

# Set up working directory and permissions
WORKDIR /home/coder/workspace
RUN chown -R coder:coder /home/coder && \
    mkdir -p /home/coder/.cache/pip /home/coder/.local && \
    chown -R coder:coder /home/coder/.cache /home/coder/.local

# Switch to coder user
USER coder

# Configure Poetry for the coder user
RUN poetry config virtualenvs.create true && \
    poetry config virtualenvs.in-project true && \
    poetry config cache-dir /home/coder/.cache/pypoetry

# Create default Python project structure
RUN mkdir -p /home/coder/workspace/src /home/coder/workspace/tests && \
    echo "# Python Web Development Workspace" > /home/coder/workspace/README.md

# Create a sample pyproject.toml for Poetry projects
RUN cat > /home/coder/workspace/pyproject.toml << 'EOF'
[tool.poetry]
name = "web-project"
version = "0.1.0"
description = "Python web development project"
authors = ["Coder User <coder@example.com>"]

[tool.poetry.dependencies]
python = "^3.12"
flask = "^3.0.0"
fastapi = "^0.104.0"
uvicorn = {extras = ["standard"], version = "^0.24.0"}

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.0"
pytest-cov = "^4.1.0"
black = "^23.9.0"
flake8 = "^6.1.0"
mypy = "^1.6.0"
isort = "^5.12.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 88
target-version = ["py312"]

[tool.isort]
profile = "black"
line_length = 88

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
EOF

# Verify installations
RUN python --version && \
    pip --version && \
    poetry --version && \
    flask --version && \
    pytest --version && \
    black --version && \
    echo "Python web development environment ready!"

