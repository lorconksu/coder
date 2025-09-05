# Python Data Science Development Environment Dockerfile
# Based on Rocky Linux 9 with comprehensive data science and ML tools
# Includes Python 3.12, Jupyter, pandas, scikit-learn, TensorFlow, PyTorch, and more

# Use Rocky Linux 9 as the base image
FROM rockylinux:9

# Define environment variables for consistent tool configuration
ENV PYTHONUNBUFFERED=1                                # Prevent Python output buffering
ENV PYTHONDONTWRITEBYTECODE=1                         # Prevent .pyc file creation
ENV PIP_NO_CACHE_DIR=1                                # Disable pip cache for smaller image
ENV PIP_DISABLE_PIP_VERSION_CHECK=1                   # Disable pip version warnings
ENV JUPYTER_ENABLE_LAB=yes                            # Enable JupyterLab by default
ENV CUDA_VERSION=12.1                                 # CUDA version for GPU support

# Update system and install essential packages
RUN dnf update -y && \
    dnf install -y --allowerasing curl wget unzip sudo which && \
    dnf clean all

# Install development tools and system dependencies
# Required for building Python packages with native extensions
RUN dnf install -y gcc gcc-c++ make git openssl-devel libffi-devel bzip2-devel sqlite-devel && \
    dnf clean all

# Install system utilities for data science workflows
RUN dnf install -y procps-ng openssh-clients ca-certificates tzdata && \
    dnf clean all

# Install EPEL repository for additional packages
RUN dnf install -y epel-release && \
    dnf clean all

# Install Python 3.12 and development headers
RUN dnf install -y python3.12 python3.12-pip python3.12-devel && \
    dnf clean all

# Create Python symlinks for convenience
RUN ln -sf /usr/bin/python3.12 /usr/local/bin/python && \
    ln -sf /usr/bin/python3.12 /usr/local/bin/python3 && \
    ln -sf /usr/bin/pip3.12 /usr/local/bin/pip

# Upgrade pip and install essential Python tools
RUN python -m pip install --upgrade pip setuptools wheel

# Install Poetry for dependency management
RUN curl -sSL https://install.python-poetry.org | POETRY_HOME=/usr/local python3 -

# Install core data science libraries
# NumPy and SciPy ecosystem - fundamental for numerical computing
RUN pip install \
    numpy==1.24.3 \
    scipy==1.11.1 \
    pandas==2.0.3 \
    matplotlib==3.7.2 \
    seaborn==0.12.2 \
    plotly==5.15.0

# Install Jupyter ecosystem for interactive development
RUN pip install \
    jupyter==1.0.0 \
    jupyterlab==4.0.3 \
    jupyterlab-git==0.41.0 \
    notebook==7.0.0 \
    ipykernel==6.25.0 \
    ipywidgets==8.0.7

# Install machine learning libraries
RUN pip install \
    scikit-learn==1.3.0 \
    xgboost==1.7.6 \
    lightgbm==4.0.0 \
    catboost==1.2

# Install deep learning frameworks
# Install CPU versions by default (GPU versions can be added if needed)
RUN pip install \
    tensorflow==2.13.0 \
    torch==2.0.1+cpu \
    torchvision==0.15.2+cpu \
    torchaudio==2.0.2+cpu \
    -f https://download.pytorch.org/whl/torch_stable.html

# Install additional ML and data processing tools
RUN pip install \
    statsmodels==0.14.0 \
    networkx==3.1 \
    beautifulsoup4==4.12.2 \
    requests==2.31.0 \
    scrapy==2.9.0

# Install computer vision libraries
RUN pip install \
    opencv-python==4.8.0.74 \
    Pillow==10.0.0 \
    imageio==2.31.1

# Install natural language processing libraries
RUN pip install \
    nltk==3.8.1 \
    spacy==3.6.1 \
    transformers==4.32.1 \
    datasets==2.14.4

# Install development and code quality tools
RUN pip install \
    black==23.7.0 \
    flake8==6.0.0 \
    pylint==2.17.5 \
    mypy==1.5.1 \
    isort==5.12.0 \
    pytest==7.4.0 \
    pytest-cov==4.1.0

# Install security scanning tools
RUN pip install \
    bandit==1.7.5 \
    safety==2.3.5 \
    pip-audit==2.6.1

# Install database connectors
RUN pip install \
    psycopg2-binary==2.9.7 \
    pymongo==4.4.1 \
    sqlalchemy==2.0.19 \
    alembic==1.11.2

# Install PostgreSQL client
RUN dnf install -y postgresql && \
    dnf clean all

# Install Docker CLI for containerization
RUN dnf install -y dnf-plugins-core && dnf clean all
RUN dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
RUN dnf install -y docker-ce-cli docker-compose-plugin && dnf clean all

# Install security scanning tools (Trivy and Grype)
RUN curl -sfL https://github.com/aquasecurity/trivy/releases/download/v0.50.1/trivy_0.50.1_Linux-64bit.rpm -o /tmp/trivy.rpm && \
    dnf install -y /tmp/trivy.rpm && \
    rm /tmp/trivy.rpm && \
    dnf clean all

RUN curl -sfL https://github.com/anchore/grype/releases/download/v0.74.7/grype_0.74.7_linux_amd64.rpm -o /tmp/grype.rpm && \
    dnf install -y /tmp/grype.rpm && \
    rm /tmp/grype.rpm && \
    dnf clean all

# Install SonarQube Scanner for code quality
ENV SONAR_SCANNER_VERSION=5.0.1.3006
RUN curl -sfL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip -o /tmp/sonar-scanner.zip && \
    unzip /tmp/sonar-scanner.zip -d /opt && \
    ln -s /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm /tmp/sonar-scanner.zip

# Create non-root user for security
RUN useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/coder && \
    chmod 440 /etc/sudoers.d/coder

# Add coder user to docker group
RUN groupadd -f docker && \
    usermod -aG docker coder

# Set up workspace directory and permissions
WORKDIR /home/coder/workspace
RUN chown -R coder:coder /home/coder && \
    mkdir -p /home/coder/.cache/pip /home/coder/.local /home/coder/.jupyter && \
    chown -R coder:coder /home/coder/.cache /home/coder/.local /home/coder/.jupyter

# Switch to non-root user
USER coder

# Configure Poetry for the coder user
RUN poetry config virtualenvs.create true && \
    poetry config virtualenvs.in-project true && \
    poetry config cache-dir /home/coder/.cache/pypoetry

# Configure Jupyter for better data science workflow
RUN jupyter lab --generate-config
RUN echo "c.ServerApp.ip = '0.0.0.0'" >> /home/coder/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.port = 8888" >> /home/coder/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.open_browser = False" >> /home/coder/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_root = False" >> /home/coder/.jupyter/jupyter_lab_config.py

# Download common NLTK data
RUN python -c "import nltk; nltk.download('punkt'); nltk.download('stopwords'); nltk.download('wordnet')"

# Create default data science project structure
RUN mkdir -p /home/coder/workspace/{data,notebooks,src,tests,models,reports,config} && \
    echo "# Data Science Workspace" > /home/coder/workspace/README.md

# Create sample pyproject.toml for Poetry projects
RUN cat > /home/coder/workspace/pyproject.toml << 'EOF'
[tool.poetry]
name = "data-science-project"
version = "0.1.0"
description = "Python data science and machine learning project"
authors = ["Coder User <coder@example.com>"]

[tool.poetry.dependencies]
python = "^3.12"
pandas = "^2.0.0"
numpy = "^1.24.0"
matplotlib = "^3.7.0"
seaborn = "^0.12.0"
scikit-learn = "^1.3.0"
jupyter = "^1.0.0"
jupyterlab = "^4.0.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.0"
pytest-cov = "^4.1.0"
black = "^23.7.0"
flake8 = "^6.0.0"
mypy = "^1.5.0"
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

# Create sample Jupyter notebook
RUN cat > /home/coder/workspace/notebooks/getting_started.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Data Science Getting Started\n",
    "\n",
    "Welcome to your data science workspace! This notebook demonstrates the available tools and libraries."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Import essential data science libraries\n",
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "from sklearn.datasets import load_iris\n",
    "from sklearn.model_selection import train_test_split\n",
    "from sklearn.ensemble import RandomForestClassifier\n",
    "from sklearn.metrics import accuracy_score\n",
    "\n",
    "print(\"All libraries imported successfully!\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Load and explore the Iris dataset\n",
    "iris = load_iris()\n",
    "df = pd.DataFrame(iris.data, columns=iris.feature_names)\n",
    "df['target'] = iris.target\n",
    "df['species'] = df['target'].map({0: 'setosa', 1: 'versicolor', 2: 'virginica'})\n",
    "\n",
    "print(\"Dataset shape:\", df.shape)\n",
    "print(\"\\nFirst 5 rows:\")\n",
    "df.head()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Create a simple visualization\n",
    "plt.figure(figsize=(10, 6))\n",
    "sns.scatterplot(data=df, x='sepal length (cm)', y='sepal width (cm)', hue='species')\n",
    "plt.title('Iris Dataset - Sepal Dimensions')\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Simple machine learning example\n",
    "X = df.drop(['target', 'species'], axis=1)\n",
    "y = df['target']\n",
    "\n",
    "X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)\n",
    "\n",
    "# Train a Random Forest classifier\n",
    "rf = RandomForestClassifier(n_estimators=100, random_state=42)\n",
    "rf.fit(X_train, y_train)\n",
    "\n",
    "# Make predictions and calculate accuracy\n",
    "y_pred = rf.predict(X_test)\n",
    "accuracy = accuracy_score(y_test, y_pred)\n",
    "\n",
    "print(f\"Random Forest Accuracy: {accuracy:.2f}\")\n",
    "print(f\"Feature Importance: {dict(zip(iris.feature_names, rf.feature_importances_))}\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "version": "3.12.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

# Verify installations
RUN python --version && \
    pip --version && \
    poetry --version && \
    jupyter --version && \
    python -c "import pandas, numpy, sklearn, torch, tensorflow; print('Core libraries verified!')"

# Set default command
CMD ["/bin/bash"]