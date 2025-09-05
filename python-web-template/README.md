# Python Web Development Template

A comprehensive Coder template for Python web development with support for Flask, FastAPI, and Django frameworks. Built on Rocky Linux 9 with modern Python development tools and security-first practices.

## Features

### 🐍 Python Environment
- **Python 3.12** (latest stable) with Python 3.11 fallback support
- **Package Managers**: pip, Poetry, and Pipenv
- **Virtual Environment**: Built-in venv support with Poetry integration
- **Dependency Caching**: Persistent pip and Poetry cache volumes

### 🌐 Web Frameworks
- **Flask**: Lightweight WSGI web framework with SQLAlchemy
- **FastAPI**: Modern async API framework with automatic OpenAPI docs
- **Django**: Full-featured web framework with Django REST Framework
- **Framework Selection**: Choose your preferred framework during workspace creation

### 🛠️ Development Tools
- **Code Quality**: black, flake8, pylint, mypy, isort
- **Testing**: pytest with coverage reporting and mocking
- **Debugging**: Enhanced debugging capabilities
- **Documentation**: Sphinx-ready documentation setup

### 🔒 Security & DevSecOps
- **Security Scanners**: Bandit (Python security linter), Safety (dependency vulnerability scanner)
- **Container Scanning**: Trivy and Grype for comprehensive security analysis
- **Dependency Auditing**: pip-audit for Python package vulnerabilities
- **Code Quality**: SonarQube Scanner integration

### 🗄️ Database & API Support
- **Database**: PostgreSQL client, SQLAlchemy, Alembic migrations
- **HTTP Clients**: httpx, requests
- **Data Validation**: Pydantic for data validation and serialization
- **Environment Management**: python-dotenv for configuration

### 🔧 Additional Tools
- **Git**: Pre-configured with Python-specific .gitignore
- **Docker**: Docker CLI for containerization
- **VS Code**: Integrated VS Code server
- **Non-root Security**: Runs as `coder` user with sudo access

## Quick Start

### 1. Deploy the Template
1. Upload `python-web-template.tar` to your Coder instance
2. Create a new workspace from the template
3. Select your preferred web framework (Flask/FastAPI/Django)
4. Configure CPU, memory, and storage requirements

### 2. Framework-Specific Setup

#### Flask Development
```bash
# The workspace comes with a sample Flask app
flask-dev                    # Start development server
curl http://localhost:8000   # Test the application

# Or manually:
export FLASK_APP=app.py
flask --debug run --host 0.0.0.0 --port 8000
```

#### FastAPI Development
```bash
# The workspace comes with a sample FastAPI app
uvrun                       # Start with uvicorn
curl http://localhost:8000  # Test the application

# Access interactive docs at http://localhost:8000/docs

# Or manually:
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

#### Django Development
```bash
# Django project is created during setup
djrun                       # Start development server
djmake && djmig            # Make and run migrations

# Or manually:
python manage.py runserver 0.0.0.0:8000
```

## Development Workflow

### Code Quality & Formatting
```bash
# Format code
format                      # Runs black + isort
black .                     # Format with black
isort .                     # Sort imports

# Linting
lint                        # Runs flake8 + pylint
flake8 .                    # PEP8 style checking
pylint src/                 # Advanced code analysis

# Type checking
typecheck                   # Run mypy
mypy .                      # Type checking
```

### Testing
```bash
# Run tests
test                        # Basic pytest
testcov                     # With coverage report
pytest -v --cov=src --cov-report=html

# Watch mode (install pytest-watch first)
pip install pytest-watch
testwatch
```

### Security Analysis
```bash
# Python security
security                    # Runs bandit + safety
bandit -r .                 # Security linter
safety check                # Dependency vulnerabilities
scan-deps                   # pip-audit scan

# Container security
scan-trivy                  # Trivy security scan
scan-grype                  # Grype vulnerability scan

# Combined quality check
quality                     # Runs lint + typecheck + security
```

### Package Management

#### Using Poetry (Recommended)
```bash
# Project setup
poetry init                 # Initialize new project
poetry install              # Install dependencies
poetry shell               # Activate virtual environment

# Package management
poetry add flask            # Add dependency
poetry add --group dev pytest  # Add dev dependency
poetry remove package       # Remove dependency
poetry update              # Update dependencies

# Shortcuts
po                         # poetry
poin                       # poetry install
poad flask                 # poetry add flask
porun python script.py    # poetry run python script.py
```

#### Using pip + venv
```bash
# Virtual environment
python -m venv venv
source venv/bin/activate   # Linux/Mac
pip install -r requirements.txt
```

### Framework-Specific Commands

#### Flask Shortcuts
```bash
flask-dev                  # Development server
flask-shell                # Interactive shell
setup-flask               # Add Flask dependencies via Poetry
```

#### FastAPI Shortcuts  
```bash
uvrun                      # Uvicorn development server
setup-fastapi             # Add FastAPI dependencies via Poetry
```

#### Django Shortcuts
```bash
djrun                      # Development server
djmake                     # Make migrations
djmig                      # Run migrations  
djshell                    # Django shell
djtest                     # Run tests
setup-django              # Add Django dependencies via Poetry
```

## Project Structure

```
/home/coder/workspace/
├── src/                    # Source code directory
├── tests/                  # Test files
├── pyproject.toml         # Poetry configuration
├── requirements.txt       # pip requirements (if needed)
├── .gitignore            # Python-specific gitignore
├── README.md             # Project documentation
└── [framework files]      # Flask app.py, FastAPI main.py, or Django project
```

## Environment Variables

The template sets up several useful environment variables:

```bash
PYTHON_VERSION            # Selected Python version
WEB_FRAMEWORK            # Selected web framework
PYTHONPATH               # Includes src/ directory
FLASK_ENV=development    # Flask development mode
DJANGO_SETTINGS_MODULE   # Django settings
```

## Persistent Storage

The template includes persistent volumes for:
- `/home/coder/workspace` - Your project files
- `/home/coder/.cache/pip` - Pip package cache
- `/home/coder/.cache/pypoetry` - Poetry cache

## Ports

Common development server ports:
- **8000**: Flask, FastAPI, Django development servers
- **5000**: Flask alternative port
- **8080**: VS Code Server (automatically configured)

## Tips & Best Practices

### 1. Virtual Environments
Always use virtual environments for project isolation:
```bash
# With Poetry (recommended)
poetry shell

# With venv
python -m venv project_env
source project_env/bin/activate
```

### 2. Code Quality
Run quality checks before committing:
```bash
quality                    # Full quality check
format && test            # Format and test
```

### 3. Security First
Regular security scanning:
```bash
security                   # Python security check
scan-trivy                # Container vulnerability scan
scan-deps                 # Dependency audit
```

### 4. Testing Strategy
Write tests early and often:
```bash
mkdir tests
touch tests/__init__.py
# Write tests in tests/test_*.py
testcov                   # Run with coverage
```

### 5. Framework Selection
- **Flask**: Best for simple APIs, microservices, and learning
- **FastAPI**: Ideal for modern APIs, async operations, automatic docs
- **Django**: Perfect for full web applications, admin interfaces, complex projects

## Troubleshooting

### Common Issues

#### Permission Errors
```bash
sudo chown -R coder:coder /home/coder/workspace
sudo chmod 666 /var/run/docker.sock
```

#### Package Installation Issues
```bash
pip install --upgrade pip
poetry self update
```

#### Import Errors
```bash
export PYTHONPATH=/home/coder/workspace/src:$PYTHONPATH
```

#### Port Already in Use
```bash
# Kill process using port 8000
sudo lsof -ti:8000 | xargs kill -9
```

## Template Parameters

| Parameter | Description | Default | Options |
|-----------|-------------|---------|---------|
| `python_version` | Python version | 3.12 | 3.11, 3.12 |
| `framework` | Web framework | fastapi | fastapi, flask, django |
| `cpu` | CPU cores | 2 | 1-8 |
| `memory` | Memory in GB | 4 | 2-16 |
| `disk_size` | Disk size in GB | 20 | 10-100 |

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the framework-specific documentation
3. Use the built-in help commands: `flask --help`, `uvicorn --help`, `django-admin help`

## Version Information

- **Base OS**: Rocky Linux 9
- **Python**: 3.12.x (with 3.11 support)
- **Poetry**: Latest stable
- **Flask**: 3.0.x
- **FastAPI**: 0.104.x
- **Django**: 4.2.x LTS

---

**Happy Python web development! 🚀**