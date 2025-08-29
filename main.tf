terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

# Variables
variable "docker_host" {
  description = "Docker host to use for workspace containers"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

# Data sources
data "coder_provisioner" "me" {
}

data "coder_workspace" "me" {
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU cores"
  description  = "Number of CPU cores for the workspace"
  type         = "number"
  default      = 2
  validation {
    min = 1
    max = 8
  }
  mutable = true
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory (GB)"
  description  = "Amount of memory in GB for the workspace"
  type         = "number"
  default      = 4
  validation {
    min = 2
    max = 16
  }
  mutable = true
}

data "coder_parameter" "disk_size" {
  name         = "disk_size"
  display_name = "Disk Size (GB)"
  description  = "Size of the workspace disk in GB"
  type         = "number"
  default      = 20
  validation {
    min = 10
    max = 100
  }
  mutable = false
}

# Docker provider
provider "docker" {
  host = var.docker_host
}

# Docker volume for persistent storage
resource "docker_volume" "workspace" {
  name = "coder-${data.coder_workspace.me.id}-workspace"
  # Persist volume when workspace is deleted
  lifecycle {
    ignore_changes = all
  }
}

# Docker volume for Maven repository cache
resource "docker_volume" "maven_cache" {
  name = "coder-${data.coder_workspace.me.id}-maven"
  lifecycle {
    ignore_changes = all
  }
}

# Docker volume for npm cache
resource "docker_volume" "npm_cache" {
  name = "coder-${data.coder_workspace.me.id}-npm"
  lifecycle {
    ignore_changes = all
  }
}

# Build the Docker image
resource "docker_image" "main" {
  name = "coder-spring-node-${data.coder_workspace.me.id}"
  build {
    context = "."
    build_args = {
      USER = "coder"
    }
  }
  triggers = {
    dir_sha1 = sha1(join("", [filesha1("./Dockerfile")]))
  }
}

# Main workspace container
resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.main.name
  name  = "coder-${data.coder_workspace.me.name}"
  
  # Hostname
  hostname = data.coder_workspace.me.name

  # Resource constraints
  memory  = data.coder_parameter.memory.value * 1024
  cpus    = data.coder_parameter.cpu.value

  # Environment variables
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "WORKSPACE_NAME=${data.coder_workspace.me.name}"
  ]

  # Mount volumes
  volumes {
    container_path = "/home/coder/workspace"
    volume_name    = docker_volume.workspace.name
    read_only      = false
  }

  volumes {
    container_path = "/home/coder/.m2"
    volume_name    = docker_volume.maven_cache.name
    read_only      = false
  }

  volumes {
    container_path = "/home/coder/.npm"
    volume_name    = docker_volume.npm_cache.name
    read_only      = false
  }

  # Mount Docker socket for Docker-in-Docker
  volumes {
    container_path = "/var/run/docker.sock"
    host_path      = "/var/run/docker.sock"
    read_only      = false
  }

  # Keep container running
  command = ["sh", "-c", coder_agent.main.init_script]
}

# Coder agent
resource "coder_agent" "main" {
  os             = "linux"
  arch           = data.coder_provisioner.me.arch
  startup_script_behavior = "non-blocking"

  # Metadata for workspace insights
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"  
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Disk Usage"
    key          = "3_disk_usage"
    script       = "coder stat disk --path /home/coder/workspace"
    interval     = 60
    timeout      = 1
  }

  startup_script = <<-EOT
    set -e
    
    # Wait for Docker socket to be available
    echo "Waiting for Docker socket..."
    while [ ! -S /var/run/docker.sock ]; do
      sleep 1
    done
    
    # Set proper permissions for Docker socket access
    sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
    
    # Ensure workspace directory exists and has proper permissions
    mkdir -p /home/coder/workspace
    sudo chown -R coder:coder /home/coder/workspace
    
    # Initialize git config if not already set
    if ! git config --global user.name > /dev/null 2>&1; then
      echo "Setting up Git configuration..."
      git config --global user.name "Coder User"
      git config --global user.email "coder@example.com"
      git config --global init.defaultBranch main
    fi
    
    # Create useful aliases and environment setup
    cat >> /home/coder/.bashrc << 'EOF'
# Development aliases
alias ll='ls -la'
alias la='ls -la'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'

# Maven aliases
alias mvnc='mvn clean'
alias mvnci='mvn clean install'
alias mvncp='mvn clean package'
alias mvnt='mvn test'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'

# Security scanning aliases
alias scan-trivy='trivy fs --security-checks vuln,config,secret .'
alias scan-grype='grype dir:.'

# Sonar aliases
alias sonar='sonar-scanner'

# Environment
export EDITOR=vim
export HISTSIZE=10000
export HISTFILESIZE=20000
EOF

    # Install additional development utilities via npm
    npm install -g typescript ts-node nodemon eslint prettier
    
    echo "Workspace initialization complete!"
    echo "Available tools:"
    echo "  - Java 21 LTS with Maven"
    echo "  - Node.js LTS with npm"
    echo "  - Git, Docker CLI, PostgreSQL client"
    echo "  - SonarQube Scanner"
    echo "  - Security scanners: Trivy, Grype"
    echo "  - TypeScript development tools"
    echo ""
    echo "Run 'scan-trivy' or 'scan-grype' to scan your code for vulnerabilities"
    echo "Run 'sonar' to perform code quality analysis"
  EOT
}

# App for accessing the workspace via web terminal
resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code"
  url          = "http://localhost:8080/?folder=/home/coder/workspace"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:8080/healthz"
    interval  = 3
    threshold = 10
  }
}

# App for web-based terminal
resource "coder_app" "terminal" {
  agent_id     = coder_agent.main.id
  slug         = "terminal"
  display_name = "Terminal"
  command      = "bash"
  icon         = "/icon/terminal.svg"
  share        = "owner"
}