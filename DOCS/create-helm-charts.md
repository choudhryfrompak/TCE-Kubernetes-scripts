I'll document the complete process of creating and publishing a Helm chart from scratch:

# Complete Helm Chart Creation and Publishing Guide

## 1. Initial Chart Creation
```bash
# Create a new chart
helm create mychart

# Basic chart structure:
mychart/
  ├── Chart.yaml          # Chart metadata
  ├── values.yaml         # Default values
  ├── charts/            # Dependencies
  ├── templates/         # Kubernetes manifests
  └── templates/NOTES.txt # Usage notes
```

## 2. Chart Development
```bash
# Key files to modify:

# Chart.yaml - Set metadata
apiVersion: v2
name: mychart
description: A Helm chart for your application
version: 0.1.0
appVersion: "1.0.0"

# values.yaml - Define configurable values
image:
  repository: nginx
  tag: "1.14.2"
  pullPolicy: IfNotPresent

# Create K8s manifests in templates/
# - deployment.yaml
# - service.yaml
# - ingress.yaml
# etc.
```

## 3. Testing and Validation
```bash
# Lint the chart
helm lint mychart/

# Test template rendering
helm template mychart/

# Dry run install
helm install --dry-run --debug myrelease mychart/

# Test install in a test namespace
kubectl create namespace test
helm install myrelease mychart/ --namespace test
```

## 4. Packaging the Chart
```bash
# Package the chart
helm package mychart/
# Creates: mychart-0.1.0.tgz
```

## 5. Setting Up GitHub Repository
```bash
# Create new repository on GitHub
# Clone locally
git clone git@github.com:username/helm-charts.git
cd helm-charts

# Create proper structure
mkdir -p charts/mychart
cp -r /path/to/mychart/* charts/mychart/

# Add and commit source files
git add .
git commit -m "Add mychart source"
git push origin main
```

## 6. Setting Up GitHub Pages (gh-pages branch)
```bash
# Create gh-pages branch
git checkout --orphan gh-pages
git rm -rf .

# Move packaged chart
cp /path/to/mychart-0.1.0.tgz .

# Create index
helm repo index .

# Add and commit
git add .
git commit -m "Add helm repository"
git push origin gh-pages
```

## 7. GitHub Repository Settings
1. Go to repository Settings
2. Navigate to Pages
3. Set Source to "gh-pages" branch
4. Save and wait for deployment

## 8. Using the Repository
```bash
# Add repository
helm repo add myrepo https://username.github.io/helm-charts

# Update repositories
helm repo update

# Search for chart
helm search repo myrepo/mychart

# Install chart
helm install myrelease myrepo/mychart
```

## 9. Updating the Chart
```bash
# Update version in Chart.yaml
version: 0.1.1

# Package new version
helm package charts/mychart/

# Switch to gh-pages
git checkout gh-pages

# Move new package
mv mychart-0.1.1.tgz .

# Update index
helm repo index .

# Commit and push
git add .
git commit -m "Update chart to 0.1.1"
git push origin gh-pages

# Switch back to main
git checkout main
```

## 10. Common Issues and Solutions

### Chart Not Found
```bash
# Verify index.yaml is accessible
curl https://username.github.io/helm-charts/index.yaml

# Check repository is properly added
helm repo list

# Update repositories
helm repo update
```

### GitHub Pages Not Working
1. Verify gh-pages branch exists
2. Check repository settings
3. Wait a few minutes for deployment
4. Check deployment status in Actions tab

### Repository Structure
```
helm-charts/          # Main branch
├── README.md
└── charts/
    └── mychart/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/

helm-charts/          # gh-pages branch
├── index.yaml
└── mychart-0.1.0.tgz
```

### Important Commands Reference
```bash
# Repository management
helm repo add [name] [url]
helm repo update
helm repo list
helm repo remove [name]

# Chart management
helm create [chart]
helm package [chart]
helm lint [chart]
helm template [chart]

# Installation
helm install [release] [chart]
helm upgrade [release] [chart]
helm uninstall [release]

# Status
helm list
helm status [release]
helm history [release]
```

Remember to always:
1. Version your charts properly
2. Test thoroughly before publishing
3. Keep documentation updated
4. Maintain both source (main branch) and packaged (gh-pages branch) versions
5. Follow semantic versioning for chart versions

Would you like me to elaborate on any of these sections?