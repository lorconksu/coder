# Spring Boot & Node.js Coder Template

Enterprise-grade development template for Spring Boot and Node.js applications with integrated security scanning and code quality tools.

## 🚀 Features

### Core Development Stack
- **Java 21 LTS** with Maven 3.9.6
- **Node.js 20.x LTS** with npm
- **Rocky Linux 9** enterprise base image
- **Git** version control
- **Docker CLI** for containerization

### Database & Tools
- **PostgreSQL client** (psql) for database operations
- **SonarQube Scanner** for code quality analysis
- **Security scanners**: Trivy and Grype for vulnerability detection

### Security & Best Practices
- Non-root `coder` user with appropriate sudo permissions
- Docker-in-Docker support with proper socket mounting
- Persistent storage for Maven and npm caches
- Pre-configured development aliases and environment

## 📋 Prerequisites

- Coder v2.x installation
- Docker daemon running on the host
- Terraform installed (for template deployment)

## 🛠 Template Structure

```
├── Dockerfile                    # Container image definition
├── main.tf                      # Terraform configuration
├── .coder/
│   └── template-metadata.yaml   # Template metadata
└── README.md                    # This file
```

## 🚀 Quick Start

### 1. Deploy Template to Coder

```bash
# Clone this repository
git clone <your-repo-url>
cd coder-spring-node-template

# Create template in Coder
coder templates push spring-node-dev
```

### 2. Create Workspace

1. Navigate to your Coder dashboard
2. Click "Create Workspace"
3. Select "Spring Boot & Node.js Development" template
4. Configure parameters:
   - **CPU cores**: 1-8 (default: 2)
   - **Memory**: 2-16 GB (default: 4 GB)
   - **Disk size**: 10-100 GB (default: 20 GB)
5. Click "Create Workspace"

### 3. Access Your Workspace

- **VS Code**: Click the VS Code app in your workspace
- **Terminal**: Click the Terminal app for command-line access

## 🔧 Development Tools

### Java Development
```bash
# Check Java version
java --version

# Maven commands (with aliases)
mvnci      # mvn clean install
mvncp      # mvn clean package
mvnt       # mvn test

# Create new Spring Boot project
mvn archetype:generate -DgroupId=com.example -DartifactId=demo \
    -DarchetypeArtifactId=maven-archetype-quickstart
```

### Node.js Development
```bash
# Check Node.js version
node --version
npm --version

# Global tools pre-installed
typescript --version
nodemon --version
eslint --version
prettier --version

# Create new Node.js project
npm init -y
npm install express
```

### Database Operations
```bash
# Connect to PostgreSQL
psql -h hostname -U username -d database_name

# Example connection
psql -h localhost -U postgres -d myapp
```

## 🛡 Security Scanning

### Vulnerability Scanning

```bash
# Scan with Trivy (comprehensive security scanner)
scan-trivy
# or
trivy fs --security-checks vuln,config,secret .

# Scan with Grype (container/dependency scanner)
scan-grype
# or
grype dir:.
```

### Code Quality Analysis

```bash
# Run SonarQube analysis
sonar
# or
sonar-scanner

# Configure sonar-project.properties for your project
cat > sonar-project.properties << EOF
sonar.projectKey=my-project
sonar.sources=src
sonar.host.url=http://your-sonar-server:9000
sonar.token=your-sonar-token
EOF
```

## 🐳 Docker Operations

```bash
# Docker aliases available
d          # docker
dc         # docker-compose
dps        # docker ps
dpsa       # docker ps -a

# Build and run containers
docker build -t myapp .
docker run -p 8080:8080 myapp

# Docker-in-Docker is configured and ready to use
```

## 💾 Persistent Storage

The template provides persistent storage for:

- **Workspace files**: `/home/coder/workspace` (persists across workspace restarts)
- **Maven repository**: `/home/coder/.m2` (cached dependencies)
- **npm cache**: `/home/coder/.npm` (cached packages)

## 🎯 Common Use Cases

### Spring Boot Application

```bash
# Create new Spring Boot app
cd ~/workspace
curl https://start.spring.io/starter.zip \
    -d dependencies=web,data-jpa,postgresql \
    -d name=myapp -d packageName=com.example.myapp -o myapp.zip
unzip myapp.zip
cd myapp

# Build and test
mvnci
mvn spring-boot:run
```

### Node.js Express Application

```bash
# Create new Express app
cd ~/workspace
mkdir mynode-app && cd mynode-app
npm init -y
npm install express cors helmet

# Create basic server
cat > server.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({ message: 'Hello from Coder workspace!' });
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
EOF

# Run the application
node server.js
```

## ⚙️ Configuration

### Environment Variables

The workspace automatically sets up:
- `JAVA_HOME`: Java installation path
- `MAVEN_HOME`: Maven installation path
- `WORKSPACE_NAME`: Current workspace name
- `WORKSPACE_OWNER`: Workspace owner

### Git Configuration

Git is pre-configured with default settings. Update as needed:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"
```

## 🔍 Monitoring & Insights

The workspace provides real-time metrics:
- CPU usage monitoring
- RAM usage tracking
- Disk usage for workspace directory

Access these metrics through the Coder dashboard.

## 🚨 Troubleshooting

### Docker Socket Issues
```bash
# If Docker commands fail, check socket permissions
sudo chmod 666 /var/run/docker.sock
```

### Memory Issues
```bash
# Check current memory usage
free -h

# Increase workspace memory through Coder UI if needed
```

### Package Installation Issues
```bash
# Update package repositories
sudo dnf update -y

# Install additional packages
sudo dnf install -y package-name
```

## 📚 Additional Resources

- [Coder Documentation](https://coder.com/docs)
- [Spring Boot Reference](https://spring.io/projects/spring-boot)
- [Node.js Documentation](https://nodejs.org/en/docs/)
- [Maven Documentation](https://maven.apache.org/guides/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Grype Documentation](https://github.com/anchore/grype)

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test the template thoroughly
5. Submit a pull request

## 📄 License

This template is provided under the MIT License. See LICENSE file for details.

---

**Happy Coding! 🚀**

For questions or issues, please open an issue in this repository.
