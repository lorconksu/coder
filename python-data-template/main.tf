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

# ML Framework parameter
data "coder_parameter" "ml_framework" {
  name         = "ml_framework"
  display_name = "Primary ML Framework"
  description  = "Primary machine learning framework focus"
  type         = "string"
  default      = "scikit-learn"
  option {
    name  = "Scikit-learn (Traditional ML)"
    value = "scikit-learn"
  }
  option {
    name  = "TensorFlow (Deep Learning)"
    value = "tensorflow"
  }
  option {
    name  = "PyTorch (Research & Deep Learning)"
    value = "pytorch"
  }
  option {
    name  = "All Frameworks"
    value = "all"
  }
  mutable = true
}

# Include Jupyter parameter
data "coder_parameter" "include_jupyter" {
  name         = "include_jupyter"
  display_name = "Include Jupyter Lab"
  description  = "Include Jupyter Lab server for interactive development"
  type         = "bool"
  default      = true
  mutable = true
}

# CPU parameter
data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU cores"
  description  = "Number of CPU cores for the workspace"
  type         = "number"
  default      = 4
  validation {
    min = 2
    max = 16
  }
  mutable = true
}

# Memory parameter
data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory (GB)"
  description  = "Amount of memory in GB"
  type         = "number"
  default      = 8
  validation {
    min = 4
    max = 32
  }
  mutable = true
}

# Disk size parameter
data "coder_parameter" "disk_size" {
  name         = "disk_size"
  display_name = "Disk Size (GB)"
  description  = "Size of the persistent disk in GB"
  type         = "number"
  default      = 50
  validation {
    min = 20
    max = 200
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

resource "docker_volume" "jupyter_config" {
  name = "coder-${data.coder_workspace.me.id}-jupyter"
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

  # Resource constraints
  memory = parseint(data.coder_parameter.memory.value, 10) * 1073741824  # GB to bytes

  # Environment variables
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "WORKSPACE_NAME=${data.coder_workspace.me.name}",
    "PYTHON_VERSION=${data.coder_parameter.python_version.value}",
    "ML_FRAMEWORK=${data.coder_parameter.ml_framework.value}",
    "INCLUDE_JUPYTER=${data.coder_parameter.include_jupyter.value}"
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

  volumes {
    container_path = "/home/coder/.jupyter"
    volume_name    = docker_volume.jupyter_config.name
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
    display_name = "ML Framework"
    key          = "ml_framework"
    script       = "echo $ML_FRAMEWORK"
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
    
    # Create data science specific .gitignore if it doesn't exist
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

# Virtual environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Jupyter Notebook
.ipynb_checkpoints
*/.ipynb_checkpoints/*

# IPython
profile_default/
ipython_config.py

# Data Science
*.csv
*.tsv
*.parquet
*.h5
*.hdf5
*.pickle
*.pkl
*.joblib
*.npy
*.npz

# Machine Learning Models
*.model
*.weights
*.ckpt
checkpoint
*.pb
*.pth
*.safetensors

# Datasets (large files)
data/raw/
data/processed/
*.zip
*.tar.gz

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Poetry
poetry.lock
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

# Jupyter aliases
alias jlab='jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root'
alias jnb='jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root'
alias jlist='jupyter server list'
alias jstop='jupyter server stop'

# Data science aliases
alias pandas='python -c "import pandas as pd; print(pd.__version__)"'
alias numpy='python -c "import numpy as np; print(np.__version__)"'
alias sklearn='python -c "import sklearn; print(sklearn.__version__)"'
alias torch='python -c "import torch; print(torch.__version__)"'
alias tf='python -c "import tensorflow as tf; print(tf.__version__)"'

# Code quality aliases
alias lint='flake8 . && pylint src/ notebooks/'
alias format='black . && isort .'
alias typecheck='mypy .'
alias security='bandit -r . && safety check'
alias quality='lint && typecheck && security'

# Testing aliases
alias test='pytest -v'
alias testcov='pytest --cov=src --cov-report=html'

# Security scanning aliases
alias scan-trivy='trivy fs --security-checks vuln,config,secret .'
alias scan-grype='grype dir:.'
alias scan-deps='pip-audit'

# ML workflow aliases
alias mlflow='python -m mlflow'
alias tensorboard='python -m tensorboard.main'

# Environment
export PYTHONPATH=/home/coder/workspace/src:$PYTHONPATH
export JUPYTER_CONFIG_DIR=/home/coder/.jupyter
export EDITOR=vim
EOF

    # Set up Jupyter Lab if enabled
    if [ "${data.coder_parameter.include_jupyter.value}" = "true" ]; then
      echo "Configuring Jupyter Lab..."
      
      # Ensure Jupyter config directory exists
      mkdir -p /home/coder/.jupyter
      
      # Generate Jupyter config if it doesn't exist
      if [ ! -f /home/coder/.jupyter/jupyter_lab_config.py ]; then
        jupyter lab --generate-config
      fi
      
      # Configure Jupyter for Coder environment
      cat >> /home/coder/.jupyter/jupyter_lab_config.py << 'EOF'

# Coder-specific Jupyter configuration
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_root = False
c.ServerApp.base_url = '/'
c.ServerApp.token = ''
c.ServerApp.password = ''
c.LabApp.default_url = '/lab'
EOF
    fi
    
    # Install additional ML framework specific packages based on selection
    case "${data.coder_parameter.ml_framework.value}" in
      "tensorflow")
        echo "Setting up TensorFlow-focused environment..."
        pip install --quiet tensorboard keras-tuner tensorflow-datasets
        ;;
        
      "pytorch")
        echo "Setting up PyTorch-focused environment..."
        pip install --quiet tensorboard wandb torchmetrics pytorch-lightning
        ;;
        
      "scikit-learn")
        echo "Setting up scikit-learn focused environment..."
        pip install --quiet yellowbrick shap lime
        ;;
        
      "all")
        echo "Setting up comprehensive ML environment..."
        pip install --quiet tensorboard keras-tuner tensorflow-datasets wandb torchmetrics pytorch-lightning yellowbrick shap lime
        ;;
    esac
    
    # Create sample project structure if workspace is empty
    cd /home/coder/workspace
    
    # Create directory structure if it doesn't exist
    mkdir -p {data/{raw,processed,external},notebooks,src,tests,models,reports,config}
    
    # Create sample files if they don't exist
    if [ ! -f requirements.txt ]; then
      cat > requirements.txt << 'EOF'
# Core Data Science
pandas>=2.0.0
numpy>=1.24.0
matplotlib>=3.7.0
seaborn>=0.12.0
scipy>=1.11.0

# Machine Learning
scikit-learn>=1.3.0
xgboost>=1.7.0
lightgbm>=4.0.0

# Deep Learning
tensorflow>=2.13.0
torch>=2.0.0
torchvision>=0.15.0

# Jupyter
jupyter>=1.0.0
jupyterlab>=4.0.0
ipykernel>=6.25.0

# Development
pytest>=7.4.0
black>=23.7.0
flake8>=6.0.0
mypy>=1.5.0
EOF
    fi
    
    # Create sample Python script
    if [ ! -f src/utils.py ]; then
      mkdir -p src
      cat > src/utils.py << 'EOF'
"""
Utility functions for data science projects.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from typing import Tuple, List, Optional


def load_and_explore_data(filepath: str) -> pd.DataFrame:
    """
    Load data from file and display basic information.
    
    Args:
        filepath: Path to the data file
        
    Returns:
        Loaded DataFrame
    """
    df = pd.read_csv(filepath)
    
    print(f"Dataset shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    print(f"Data types:\n{df.dtypes}")
    print(f"Missing values:\n{df.isnull().sum()}")
    
    return df


def plot_correlation_matrix(df: pd.DataFrame, figsize: Tuple[int, int] = (10, 8)) -> None:
    """
    Plot correlation matrix for numerical columns.
    
    Args:
        df: DataFrame to analyze
        figsize: Figure size tuple
    """
    numeric_columns = df.select_dtypes(include=[np.number]).columns
    
    if len(numeric_columns) > 1:
        plt.figure(figsize=figsize)
        sns.heatmap(df[numeric_columns].corr(), annot=True, cmap='coolwarm', center=0)
        plt.title('Correlation Matrix')
        plt.tight_layout()
        plt.show()
    else:
        print("Not enough numeric columns for correlation matrix")


def basic_statistics(df: pd.DataFrame) -> pd.DataFrame:
    """
    Generate basic statistics for the dataset.
    
    Args:
        df: DataFrame to analyze
        
    Returns:
        DataFrame with basic statistics
    """
    return df.describe(include='all')
EOF
    fi
    
    echo "Data science workspace initialization complete!"
    echo "Available tools:"
    echo "  - Python ${data.coder_parameter.python_version.value} with comprehensive data science stack"
    echo "  - Jupyter Lab (if enabled): http://localhost:8888"
    echo "  - ML Framework: ${data.coder_parameter.ml_framework.value}"
    echo "  - Libraries: pandas, numpy, scikit-learn, tensorflow, pytorch"
    echo "  - Development: black, pytest, mypy, flake8"
    echo "  - Security: bandit, safety, Trivy, Grype"
    echo ""
    echo "Useful commands:"
    echo "  jlab - Start Jupyter Lab"
    echo "  quality - Run all code quality checks"
    echo "  testcov - Run tests with coverage"
    echo "  format - Format code with black and isort"
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

# Jupyter Lab app (if enabled)
resource "coder_app" "jupyter" {
  count        = data.coder_parameter.include_jupyter.value ? data.coder_workspace.me.start_count : 0
  agent_id     = coder_agent.main.id
  slug         = "jupyter"
  display_name = "Jupyter Lab"
  url          = "http://localhost:8888"
  icon         = "https://raw.githubusercontent.com/jupyter/design/master/logos/Square%20Logo/squarelogo-greytext-orangebody-greymoons/squarelogo-greytext-orangebody-greymoons.png"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:8888/api"
    interval  = 10
    threshold = 60
  }
}