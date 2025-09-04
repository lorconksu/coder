# Spring Boot + Node.js Development Template for Coder
# This template creates a comprehensive development environment for Java Spring Boot and Node.js projects

# Define required Terraform providers
terraform {
  required_providers {
    # Coder provider for workspace management and agent communication
    coder = {
      source = "coder/coder"
    }
    # Docker provider for container management
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

# Variable to configure Docker daemon connection
# Allows flexibility in Docker daemon location (local socket, remote TCP, etc.)
variable "docker_host" {
  description = "Docker host to use for workspace containers"
  type        = string
  default     = "unix:///var/run/docker.sock"  # Standard Docker socket on Linux
}

# Data source to get information about the current Coder provisioner
# Used to access provisioner architecture and other system info
data "coder_provisioner" "me" {
}

# Data source to get information about the current workspace
# Provides workspace ID, name, owner, start count, and other workspace metadata
data "coder_workspace" "me" {
}

# User parameter for CPU allocation
# Creates a dropdown/input field in Coder workspace creation UI
data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU cores"
  description  = "Number of CPU cores for the workspace"
  type         = "number"
  default      = 2                    # Default to 2 CPU cores
  validation {
    min = 1                          # Minimum 1 CPU core
    max = 8                          # Maximum 8 CPU cores
  }
  mutable = true                     # Allow changing after workspace creation
}

# User parameter for memory allocation
# Allows users to customize memory based on their development needs
data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory (GB)"
  description  = "Amount of memory in GB for the workspace"
  type         = "number"
  default      = 4                   # Default to 4GB RAM
  validation {
    min = 2                          # Minimum 2GB for Java development
    max = 16                         # Maximum 16GB to prevent resource abuse
  }
  mutable = true                     # Allow scaling memory up/down
}

# User parameter for persistent disk size
# Storage for user projects, dependencies, and development artifacts
data "coder_parameter" "disk_size" {
  name         = "disk_size"
  display_name = "Disk Size (GB)"
  description  = "Size of the workspace disk in GB"
  type         = "number"
  default      = 20                  # Default 20GB should handle most projects
  validation {
    min = 10                         # Minimum 10GB for basic development
    max = 100                        # Maximum 100GB to control storage costs
  }
  mutable = false                    # Cannot change after creation (disk resize complexity)
}

# Configure the Docker provider with the specified host
provider "docker" {
  host = var.docker_host             # Use the docker_host variable
}

# Persistent Docker volume for workspace files
# Stores user projects, configuration files, and development work
resource "docker_volume" "workspace" {
  name = "coder-${data.coder_workspace.me.id}-workspace"  # Unique name per workspace
  # Lifecycle management to persist data across workspace restarts
  lifecycle {
    ignore_changes = all             # Don't destroy volume when template changes
  }
}

# Persistent Docker volume for Maven repository cache
# Significantly speeds up Java builds by caching downloaded dependencies
resource "docker_volume" "maven_cache" {
  name = "coder-${data.coder_workspace.me.id}-maven"     # Unique Maven cache per workspace
  lifecycle {
    ignore_changes = all             # Preserve cached dependencies
  }
}

# Persistent Docker volume for npm cache
# Speeds up Node.js package installation by caching downloaded packages
resource "docker_volume" "npm_cache" {
  name = "coder-${data.coder_workspace.me.id}-npm"       # Unique npm cache per workspace
  lifecycle {
    ignore_changes = all             # Preserve cached Node.js packages
  }
}

# Build custom Docker image from Dockerfile
# Contains all development tools: Java 21, Maven, Node.js, security scanners, etc.
resource "docker_image" "main" {
  name = "coder-spring-node-${data.coder_workspace.me.id}"  # Unique image name per workspace
  build {
    context = "."                    # Build from current directory (contains Dockerfile)
    build_args = {
      USER = "coder"                 # Pass build argument for non-root user creation
    }
  }
  # Trigger image rebuild when Dockerfile changes
  triggers = {
    dir_sha1 = sha1(join("", [filesha1("./Dockerfile")]))  # Hash of Dockerfile content
  }
}

# Main workspace container that runs the development environment
resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count              # Only create when workspace should be running
  image = docker_image.main.name                           # Use our custom built image
  name  = "coder-${data.coder_workspace.me.name}"         # Container name based on workspace name
  
  # Set container hostname to workspace name for easy identification
  hostname = data.coder_workspace.me.name

  # Resource constraints for the container
  # Note: CPU constraint removed due to Docker provider v3.6.2 type conversion bug
  memory = parseint(data.coder_parameter.memory.value, 10) * 1073741824  # Convert GB to bytes

  # Environment variables passed to the container
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",         # Token for Coder agent authentication
    "WORKSPACE_NAME=${data.coder_workspace.me.name}"       # Pass workspace name to container
  ]

  # Mount persistent workspace volume
  # This is where user projects and work are stored
  volumes {
    container_path = "/home/coder/workspace"               # Mount point inside container
    volume_name    = docker_volume.workspace.name         # Reference to workspace volume
    read_only      = false                                 # Allow read/write access
  }

  # Mount Maven cache volume for faster Java builds
  # Maven downloads and caches dependencies in ~/.m2/repository
  volumes {
    container_path = "/home/coder/.m2"                     # Maven home directory
    volume_name    = docker_volume.maven_cache.name       # Reference to Maven cache volume
    read_only      = false                                 # Allow Maven to write cache
  }

  # Mount npm cache volume for faster Node.js package installs
  # npm caches packages to speed up subsequent installations
  volumes {
    container_path = "/home/coder/.npm"                    # npm cache directory
    volume_name    = docker_volume.npm_cache.name         # Reference to npm cache volume
    read_only      = false                                 # Allow npm to write cache
  }

  # Mount Docker socket for Docker-in-Docker functionality
  # Allows running Docker commands inside the development container
  volumes {
    container_path = "/var/run/docker.sock"               # Docker socket inside container
    host_path      = "/var/run/docker.sock"               # Docker socket on host
    read_only      = false                                 # Allow Docker commands
  }

  # Command to keep container running and execute Coder agent startup script
  command = ["sh", "-c", coder_agent.main.init_script]
}

# Coder agent handles communication between workspace and Coder server
# Provides terminal access, file operations, port forwarding, and metrics
resource "coder_agent" "main" {
  os             = "linux"                                 # Operating system type
  arch           = data.coder_provisioner.me.arch         # Architecture from provisioner
  startup_script_behavior = "non-blocking"                # Don't block workspace start on script completion

  # Metadata provides real-time metrics displayed in Coder workspace UI
  
  # CPU usage metric - updates every 10 seconds
  metadata {
    display_name = "CPU Usage"                             # Label shown in UI
    key          = "0_cpu_usage"                           # Unique identifier (0_ for sorting)
    script       = "coder stat cpu"                        # Command to get CPU usage
    interval     = 10                                      # Update every 10 seconds
    timeout      = 1                                       # Timeout after 1 second
  }

  # RAM usage metric - updates every 10 seconds
  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"                           # 1_ prefix for display order
    script       = "coder stat mem"                        # Command to get memory usage
    interval     = 10                                      # Update frequency
    timeout      = 1                                       # Command timeout
  }

  # Disk usage metric for workspace directory - updates every minute
  metadata {
    display_name = "Disk Usage"
    key          = "3_disk_usage"                          # 3_ prefix for display order
    script       = "coder stat disk --path /home/coder/workspace"  # Check workspace disk usage
    interval     = 60                                      # Update every minute (less frequent)
    timeout      = 1                                       # Command timeout
  }

  # Startup script runs when workspace starts
  # Configures the development environment and installs additional tools
  startup_script = <<-EOT
    set -e                                                 # Exit on any error
    
    # Wait for Docker socket to be available before proceeding
    echo "Waiting for Docker socket..."
    while [ ! -S /var/run/docker.sock ]; do
      sleep 1
    done
    
    # Set proper permissions for Docker socket access
    # Allows coder user to run Docker commands without sudo
    sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
    
    # Ensure workspace directory exists and has proper ownership
    mkdir -p /home/coder/workspace
    sudo chown -R coder:coder /home/coder/workspace
    
    # Initialize Git configuration if not already set
    # Provides default values for Git operations
    if ! git config --global user.name > /dev/null 2>&1; then
      echo "Setting up Git configuration..."
      git config --global user.name "Coder User"
      git config --global user.email "coder@example.com"
      git config --global init.defaultBranch main
    fi
    
    # Create useful development aliases and environment setup
    # These aliases improve developer productivity with common shortcuts
    cat >> /home/coder/.bashrc << 'EOF'
# Development aliases for common commands
alias ll='ls -la'                                          # Detailed file listing
alias la='ls -la'                                          # Alternative detailed listing
alias ..='cd ..'                                           # Go up one directory
alias ...='cd ../..'                                       # Go up two directories
alias grep='grep --color=auto'                             # Colorized grep output

# Maven aliases for Java development
alias mvnc='mvn clean'                                     # Clean Maven build
alias mvnci='mvn clean install'                            # Clean and install dependencies
alias mvncp='mvn clean package'                            # Clean and package application
alias mvnt='mvn test'                                      # Run Maven tests

# Docker aliases for container management
alias d='docker'                                           # Short docker command
alias dc='docker-compose'                                  # Docker Compose shortcut
alias dps='docker ps'                                      # List running containers
alias dpsa='docker ps -a'                                  # List all containers

# Security scanning aliases for vulnerability detection
alias scan-trivy='trivy fs --security-checks vuln,config,secret .'    # Trivy security scan
alias scan-grype='grype dir:.'                                         # Grype vulnerability scan

# SonarQube alias for code quality analysis
alias sonar='sonar-scanner'                                # SonarQube scanner

# Environment configuration
export EDITOR=vim                                          # Default text editor
export HISTSIZE=10000                                      # Bash history size
export HISTFILESIZE=20000                                  # Bash history file size
EOF

    # Install additional development utilities via npm
    # These tools enhance the development workflow
    npm install -g typescript ts-node nodemon eslint prettier
    
    # Display completion message with available tools
    echo "Workspace initialization complete!"
    echo "Available tools:"
    echo "  - Java 21 LTS with Maven"                      # Java development stack
    echo "  - Node.js LTS with npm"                        # Node.js development stack  
    echo "  - Git, Docker CLI, PostgreSQL client"          # Essential development tools
    echo "  - SonarQube Scanner"                            # Code quality analysis
    echo "  - Security scanners: Trivy, Grype"             # Vulnerability scanning
    echo "  - TypeScript development tools"                 # Modern JavaScript development
    echo ""
    echo "Run 'scan-trivy' or 'scan-grype' to scan your code for vulnerabilities"
    echo "Run 'sonar' to perform code quality analysis"
  EOT
}

# VS Code Server integration using official Coder module
# Provides browser-based VS Code IDE for development
# See https://registry.coder.com/modules/coder/code-server
module "code-server" {
  count  = data.coder_workspace.me.start_count             # Only deploy when workspace is running
  source = "registry.coder.com/coder/code-server/coder"    # Official Coder module

  # Semantic versioning to get latest stable version without breaking changes
  version = "~> 1.0"                                       # Accept 1.x versions

  agent_id = coder_agent.main.id                           # Associate with our Coder agent
  order    = 1                                             # Display order in workspace UI
}