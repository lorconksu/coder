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

data "coder_provisioner" "me" {
}

data "coder_workspace" "me" {
}

# Python version parameter
data "coder_parameter" "python_version" {
  name         = "python_version"
  display_name = "Python Version"
  description  = "Python version to use"
  type         = "string"
  default      = "3.12"
  option {
    name  = "Python 3.12 (Latest)"
    value = "3.12"
  }
  option {
    name  = "Python 3.11 (LTS)"
    value = "3.11"
  }
  mutable = true
}

# Web framework parameter
data "coder_parameter" "framework" {
  name         = "framework"
  display_name = "Web Framework"
  description  = "Primary web framework for development"
  type         = "string"
  default      = "fastapi"
  option {
    name  = "FastAPI"
    value = "fastapi"
  }
  option {
    name  = "Flask"
    value = "flask"
  }
  option {
    name  = "Django"
    value = "django"
  }
  mutable = true
}

# CPU parameter
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

# Memory parameter
data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory (GB)"
  description  = "Amount of memory in GB"
  type         = "number"
  default      = 4
  validation {
    min = 2
    max = 16
  }
  mutable = true
}

# Disk size parameter
data "coder_parameter" "disk_size" {
  name         = "disk_size"
  display_name = "Disk Size (GB)"
  description  = "Size of the persistent disk in GB"
  type         = "number"
  default      = 20
  validation {
    min = 10
    max = 100
  }
  mutable = false
}

# Docker volumes for persistent storage
resource "docker_volume" "workspace" {
  name = "coder-${data.coder_workspace.me.id}-workspace"
}

resource "docker_volume" "pip_cache" {
  name = "coder-${data.coder_workspace.me.id}-pip-cache"
}

resource "docker_volume" "poetry_cache" {
  name = "coder-${data.coder_workspace.me.id}-poetry-cache"
}

# Docker image
resource "docker_image" "main" {
  name = "coder-${data.coder_workspace.me.id}"
  build {
    context = "./."
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

  # Resource constraints (memory only due to Docker provider v3.6.2 cpus type bug)
  memory = parseint(data.coder_parameter.memory.value, 10) * 1073741824  # GB to bytes

  # Environment variables
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "WORKSPACE_NAME=${data.coder_workspace.me.name}",
    "PYTHON_VERSION=${data.coder_parameter.python_version.value}",
    "WEB_FRAMEWORK=${data.coder_parameter.framework.value}"
  ]

  # Mount volumes
  volumes {
    container_path = "/home/coder/workspace"
    volume_name    = docker_volume.workspace.name
    read_only      = false
  }

  volumes {
    container_path = "/home/coder/.cache/pip"
    volume_name    = docker_volume.pip_cache.name
    read_only      = false
  }

  volumes {
    container_path = "/home/coder/.cache/pypoetry"
    volume_name    = docker_volume.poetry_cache.name
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

  metadata {
    display_name = "Python Version"
    key          = "python_version"
    script       = "python --version"
    interval     = 3600
    timeout      = 1
  }

  metadata {
    display_name = "Active Framework"
    key          = "web_framework"
    script       = "echo $WEB_FRAMEWORK"
    interval     = 3600
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
    
    # Create Python-specific .gitignore if it doesn't exist
    if [ ! -f /home/coder/workspace/.gitignore ]; then
      cat > /home/coder/workspace/.gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/

# Virtual environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Django
*.log
local_settings.py
db.sqlite3

# Flask
instance/
.webassets-cache

# Poetry
poetry.lock

# Pipenv
Pipfile.lock
EOF
    fi
    
    # Set up development aliases and environment
    cat >> /home/coder/.bashrc << 'EOF'

# Python development aliases
alias py='python'
alias pip='python -m pip'
alias venv='python -m venv'
alias pytest='python -m pytest'

# Poetry aliases
alias po='poetry'
alias posh='poetry shell'
alias poin='poetry install'
alias poad='poetry add'
alias porun='poetry run'

# Flask aliases
alias flask-dev='flask --app app --debug run --host 0.0.0.0'
alias flask-shell='flask shell'

# Django aliases
alias djrun='python manage.py runserver 0.0.0.0:8000'
alias djmake='python manage.py makemigrations'
alias djmig='python manage.py migrate'
alias djshell='python manage.py shell'
alias djtest='python manage.py test'

# FastAPI aliases
alias uvrun='uvicorn main:app --host 0.0.0.0 --port 8000 --reload'

# Code quality aliases
alias lint='flake8 . && pylint src/'
alias format='black . && isort .'
alias typecheck='mypy .'
alias security='bandit -r . && safety check'
alias quality='lint && typecheck && security'

# Testing aliases
alias test='pytest -v'
alias testcov='pytest --cov=src --cov-report=html'
alias testwatch='pytest-watch'

# Security scanning aliases
alias scan-trivy='trivy fs --security-checks vuln,config,secret .'
alias scan-grype='grype dir:.'
alias scan-deps='pip-audit'

# Project setup aliases
alias setup-flask='poetry add flask flask-sqlalchemy flask-migrate flask-cors'
alias setup-fastapi='poetry add fastapi uvicorn[standard] sqlalchemy alembic'
alias setup-django='poetry add django djangorestframework django-cors-headers'

# Environment
export PYTHONPATH=/home/coder/workspace/src:$PYTHONPATH
export FLASK_ENV=development
export DJANGO_SETTINGS_MODULE=settings
export EDITOR=vim
EOF

    # Create framework-specific starter files based on selected framework
    cd /home/coder/workspace
    
    case "${data.coder_parameter.framework.value}" in
      "flask")
        echo "Setting up Flask starter project..."
        cat > app.py << 'EOF'
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello_world():
    return jsonify({"message": "Hello from Flask!", "framework": "Flask"})

@app.route('/health')
def health_check():
    return jsonify({"status": "healthy", "framework": "Flask"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
EOF
        ;;
        
      "fastapi")
        echo "Setting up FastAPI starter project..."
        cat > main.py << 'EOF'
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="FastAPI Starter", description="A simple FastAPI application")

class Message(BaseModel):
    message: str
    framework: str

@app.get("/", response_model=Message)
async def read_root():
    return Message(message="Hello from FastAPI!", framework="FastAPI")

@app.get("/health", response_model=dict)
async def health_check():
    return {"status": "healthy", "framework": "FastAPI"}
EOF
        ;;
        
      "django")
        echo "Setting up Django starter project..."
        if [ ! -f manage.py ]; then
          django-admin startproject myproject .
          python manage.py startapp api
        fi
        ;;
    esac
    
    # Create a sample test file
    mkdir -p tests
    cat > tests/test_app.py << 'EOF'
import pytest

def test_sample():
    """Sample test to verify pytest is working."""
    assert True

def test_addition():
    """Test basic math to verify environment."""
    assert 2 + 2 == 4
EOF
    
    echo "Python web development workspace initialized!"
    echo "Available tools:"
    echo "  - Python ${data.coder_parameter.python_version.value} with pip, poetry, pipenv"
    echo "  - Web frameworks: Flask, FastAPI, Django"
    echo "  - Code quality: black, flake8, pylint, mypy, isort"
    echo "  - Testing: pytest with coverage"
    echo "  - Security: bandit, safety, pip-audit"
    echo "  - Security scanners: Trivy, Grype"
    echo "  - Database: PostgreSQL client, SQLAlchemy"
    echo ""
    echo "Framework-specific commands:"
    echo "  Flask:   flask-dev (run dev server)"
    echo "  FastAPI: uvrun (run with uvicorn)"
    echo "  Django:  djrun (run dev server)"
    echo ""
    echo "Useful aliases:"
    echo "  quality - Run all code quality checks"
    echo "  testcov - Run tests with coverage"
    echo "  format  - Format code with black and isort"
  EOT
}

# VS Code Server using official Coder module
module "code-server" {
  count  = data.coder_workspace.me.start_count
  source = "registry.coder.com/coder/code-server/coder"
  version = "~> 1.0"
  agent_id = coder_agent.main.id
  order    = 1
}