# Python Data Science Template

A comprehensive Coder template for data science, machine learning, and AI development. Built on Rocky Linux 9 with Python 3.12 and a complete data science ecosystem including Jupyter Lab, pandas, scikit-learn, TensorFlow, PyTorch, and advanced analytics tools.

## Features

### 🐍 Python Environment
- **Python 3.12** (latest stable) with Python 3.11 fallback option
- **Package Managers**: pip and Poetry for dependency management
- **Virtual Environment**: Built-in venv support with Poetry integration
- **Persistent Caching**: pip and Poetry cache volumes for faster installs

### 📊 Data Science Stack
- **Core Libraries**: pandas, numpy, scipy for data manipulation
- **Visualization**: matplotlib, seaborn, plotly for data visualization
- **Analysis**: statsmodels, networkx for statistical and network analysis
- **Data Processing**: Beautiful Soup, requests, scrapy for data collection

### 🤖 Machine Learning & AI
- **Traditional ML**: scikit-learn, XGBoost, LightGBM, CatBoost
- **Deep Learning**: TensorFlow, PyTorch (CPU versions by default)
- **Computer Vision**: OpenCV, Pillow, imageio
- **NLP**: NLTK, spaCy, transformers, datasets
- **Model Utilities**: joblib, pickle for model persistence

### 📓 Interactive Development
- **Jupyter Lab**: Full-featured web-based development environment
- **Jupyter Notebook**: Traditional notebook interface
- **Extensions**: JupyterLab Git integration
- **Kernels**: Python 3.12 kernel with all libraries pre-installed

### 🛠️ Development Tools
- **Code Quality**: black, flake8, pylint, mypy, isort
- **Testing**: pytest with coverage reporting
- **Debugging**: Enhanced debugging capabilities
- **Version Control**: Git with data science .gitignore template

### 🔒 Security & DevSecOps
- **Python Security**: bandit, safety, pip-audit
- **Container Security**: Trivy and Grype for vulnerability scanning
- **Code Analysis**: SonarQube Scanner integration
- **Best Practices**: Non-root user, secure configurations

### 🗄️ Data Storage & Connectivity
- **Database**: PostgreSQL client, SQLAlchemy, Alembic
- **NoSQL**: pymongo for MongoDB connectivity
- **File Formats**: Support for CSV, Parquet, HDF5, JSON
- **Cloud Ready**: Extensible for cloud storage integrations

## Quick Start

### 1. Deploy the Template
1. Upload `python-data-template.tar` to your Coder instance
2. Create a new workspace from the template
3. Select your preferred ML framework and configuration
4. Configure resources (CPU, memory, storage)

### 2. Framework Selection Options

#### Traditional ML (scikit-learn)
- Focus on classical machine learning algorithms
- Includes additional tools: yellowbrick, SHAP, LIME
- Best for: Classification, regression, clustering tasks

#### TensorFlow (Deep Learning)
- Google's deep learning framework
- Includes: TensorBoard, Keras Tuner, TensorFlow Datasets  
- Best for: Neural networks, computer vision, production deployment

#### PyTorch (Research & Deep Learning)
- Facebook's research-focused deep learning framework
- Includes: PyTorch Lightning, torchmetrics, Weights & Biases
- Best for: Research, experimentation, custom architectures

#### All Frameworks
- Complete installation of all ML frameworks
- Maximum flexibility for diverse projects
- Higher resource usage and longer build times

### 3. Jupyter Lab Access
If enabled during workspace creation:
- Access via the "Jupyter Lab" app in your Coder workspace
- Direct URL: `http://localhost:8888` (if port forwarding enabled)
- Pre-configured with data science extensions

## Project Structure

The template creates a standard data science project structure:

```
/home/coder/workspace/
├── data/
│   ├── raw/              # Raw, immutable data dump
│   ├── processed/        # Cleaned and processed datasets
│   └── external/         # Data from third party sources
├── notebooks/            # Jupyter notebooks for exploration
│   └── getting_started.ipynb  # Sample notebook
├── src/                  # Source code for use in this project
│   └── utils.py         # Utility functions
├── tests/                # Test files
├── models/               # Trained and serialized models
├── reports/              # Generated analysis reports
├── config/               # Configuration files
├── requirements.txt      # Python dependencies
├── pyproject.toml       # Poetry configuration
└── README.md            # Project documentation
```

## Development Workflow

### Environment Setup
```bash
# Using Poetry (recommended)
poetry install              # Install dependencies
poetry shell               # Activate virtual environment

# Using pip
pip install -r requirements.txt
python -m venv venv && source venv/bin/activate
```

### Jupyter Lab Usage
```bash
# Start Jupyter Lab
jlab                       # Alias for jupyter lab with proper config

# Alternative commands
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
jlist                      # List running servers
jstop                      # Stop Jupyter server
```

### Code Quality & Testing
```bash
# Format code
format                     # Runs black + isort
black .                    # Format with black
isort .                    # Sort imports

# Quality checks
lint                       # Runs flake8 + pylint
quality                    # Complete quality check (lint + typecheck + security)
typecheck                  # Type checking with mypy

# Testing
test                       # Run pytest
testcov                    # Run tests with coverage report
```

### Security Analysis
```bash
# Python-specific security
security                   # Runs bandit + safety
bandit -r .               # Security linting
safety check              # Check dependencies for vulnerabilities
scan-deps                 # pip-audit scan

# Container security  
scan-trivy                # Container vulnerability scan
scan-grype                # Package vulnerability scan
```

### Machine Learning Workflow
```bash
# Framework version checks
pandas                     # Check pandas version
numpy                     # Check numpy version  
sklearn                   # Check scikit-learn version
torch                     # Check PyTorch version
tf                        # Check TensorFlow version

# ML tools
mlflow                    # MLflow tracking server
tensorboard              # TensorBoard visualization
```

## Sample Code

### Quick Data Analysis
```python
# Load the utility functions
from src.utils import load_and_explore_data, plot_correlation_matrix

# Load and explore your dataset
df = load_and_explore_data('data/raw/dataset.csv')

# Visualize correlations
plot_correlation_matrix(df)
```

### Machine Learning Pipeline
```python
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report

# Load data
df = pd.read_csv('data/processed/clean_data.csv')
X = df.drop('target', axis=1)
y = df['target']

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Evaluate
y_pred = model.predict(X_test)
print(classification_report(y_test, y_pred))
```

### Deep Learning with TensorFlow
```python
import tensorflow as tf
from tensorflow import keras

# Build model
model = keras.Sequential([
    keras.layers.Dense(128, activation='relu', input_shape=(784,)),
    keras.layers.Dropout(0.2),
    keras.layers.Dense(10, activation='softmax')
])

# Compile and train
model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

model.fit(X_train, y_train, epochs=10, validation_split=0.2)
```

### PyTorch Example
```python
import torch
import torch.nn as nn
import torch.optim as optim

# Define model
class SimpleNet(nn.Module):
    def __init__(self):
        super(SimpleNet, self).__init__()
        self.fc1 = nn.Linear(784, 128)
        self.fc2 = nn.Linear(128, 10)
        self.dropout = nn.Dropout(0.2)
        
    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = self.dropout(x)
        x = self.fc2(x)
        return x

# Initialize and train
model = SimpleNet()
optimizer = optim.Adam(model.parameters())
criterion = nn.CrossEntropyLoss()
```

## Environment Variables

The template sets up several useful environment variables:

```bash
PYTHON_VERSION           # Selected Python version
ML_FRAMEWORK            # Selected ML framework
INCLUDE_JUPYTER         # Whether Jupyter is enabled
PYTHONPATH              # Includes src/ directory
JUPYTER_CONFIG_DIR      # Jupyter configuration directory
```

## Persistent Storage

The template includes persistent volumes for:
- `/home/coder/workspace` - Your projects and data
- `/home/coder/.cache/pip` - Pip package cache
- `/home/coder/.cache/pypoetry` - Poetry cache
- `/home/coder/.jupyter` - Jupyter configuration and extensions

## Ports

Common service ports:
- **8888**: Jupyter Lab server
- **6006**: TensorBoard (if using TensorFlow)
- **8080**: VS Code Server (automatically configured)
- **5000**: Flask development server (if building web apps)

## Common Data Science Tasks

### Data Loading & Exploration
```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Load data
df = pd.read_csv('data/raw/dataset.csv')

# Basic exploration
print(df.info())
print(df.describe())
print(df.head())

# Visualization
plt.figure(figsize=(10, 6))
df.hist(bins=30)
plt.tight_layout()
plt.show()
```

### Feature Engineering
```python
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.feature_selection import SelectKBest, f_classif

# Scale features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Feature selection
selector = SelectKBest(score_func=f_classif, k=10)
X_selected = selector.fit_transform(X_scaled, y)
```

### Model Evaluation
```python
from sklearn.metrics import accuracy_score, precision_recall_fscore_support
from sklearn.model_selection import cross_val_score

# Cross-validation
cv_scores = cross_val_score(model, X, y, cv=5)
print(f"CV Accuracy: {cv_scores.mean():.3f} (+/- {cv_scores.std() * 2:.3f})")

# Detailed metrics
precision, recall, f1, _ = precision_recall_fscore_support(y_test, y_pred, average='weighted')
print(f"Precision: {precision:.3f}, Recall: {recall:.3f}, F1: {f1:.3f}")
```

## Tips & Best Practices

### 1. Data Organization
- Keep raw data immutable in `data/raw/`
- Store processed data in `data/processed/`
- Use clear, descriptive filenames with timestamps

### 2. Notebook Management
- Keep notebooks focused on specific tasks
- Export important functions to `src/` modules
- Use meaningful notebook names and clear markdown

### 3. Version Control
- Git ignore large data files and model artifacts
- Use DVC (Data Version Control) for dataset versioning
- Commit frequently with descriptive messages

### 4. Performance
- Use vectorized operations with pandas/numpy
- Profile code with `%timeit` in notebooks
- Consider Dask for larger-than-memory datasets

### 5. Reproducibility
- Set random seeds for reproducible results
- Document environment and dependencies
- Use configuration files for hyperparameters

## Troubleshooting

### Common Issues

#### Memory Errors
```bash
# Check memory usage
free -h
# Increase workspace memory allocation
# Use data sampling for exploration: df.sample(n=10000)
```

#### Package Installation Issues
```bash
# Clear pip cache
pip cache purge
# Reinstall with verbose output
pip install --verbose package_name
```

#### Jupyter Issues
```bash
# Restart Jupyter
jstop && jlab
# Reset Jupyter config
rm -rf ~/.jupyter && jupyter lab --generate-config
```

#### GPU Support (if needed)
```bash
# Check GPU availability
python -c "import torch; print(torch.cuda.is_available())"
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

## Template Parameters

| Parameter | Description | Default | Options |
|-----------|-------------|---------|---------|
| `python_version` | Python version | 3.12 | 3.11, 3.12 |
| `ml_framework` | Primary ML framework | scikit-learn | scikit-learn, tensorflow, pytorch, all |
| `include_jupyter` | Include Jupyter Lab | true | true, false |
| `cpu` | CPU cores | 4 | 2-16 |
| `memory` | Memory in GB | 8 | 4-32 |
| `disk_size` | Disk size in GB | 50 | 20-200 |

## Support & Resources

### Documentation Links
- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [Scikit-learn User Guide](https://scikit-learn.org/stable/user_guide.html)
- [TensorFlow Tutorials](https://www.tensorflow.org/tutorials)
- [PyTorch Tutorials](https://pytorch.org/tutorials/)
- [Jupyter Lab Documentation](https://jupyterlab.readthedocs.io/)

### Community Resources
- [Kaggle Learn](https://www.kaggle.com/learn) - Free data science courses
- [Papers with Code](https://paperswithcode.com/) - Latest research implementations
- [Towards Data Science](https://towardsdatascience.com/) - Data science articles

### Getting Help
1. Check the troubleshooting section above
2. Review framework-specific documentation
3. Use built-in help: `help(function_name)` or `function_name?` in Jupyter

---

**Happy Data Science! 📊🤖**