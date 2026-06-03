# Running the Flask Web App Locally

This document explains how to set up and run the containerized Flask application and PostgreSQL database locally using individual Docker containers, and how to connect the local application to Azure services.

## Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed (only if connecting to Azure Database for PostgreSQL).

---

## Method 1: Running Both Database and App Locally using Docker

Since you do not have PostgreSQL installed on your machine, you can run it inside a Docker container, and then run the application container connecting to it.

### Step 1: Create a Shared Docker Network
To allow the application container and the PostgreSQL container to communicate with each other, create a shared Docker network:
```bash
docker network create flask-app-network
```

### Step 2: Start the PostgreSQL Container
Run a PostgreSQL container attached to the network:
```bash
docker run --name local-postgres \
  --network flask-app-network \
  -e POSTGRES_USER=dbuser \
  -e POSTGRES_PASSWORD=dbpass \
  -e POSTGRES_DB=restaurant \
  -p 5432:5432 \
  -d postgres:15-alpine
```

### Step 3: Build the Application Docker Image
From the root of this project (where the `Dockerfile` is located), build the application container image:
```bash
docker build -t msdocs-flask-app .
```

### Step 4: Run the Application Container
Start the application container attached to the same network. We configure the database host (`DBHOST`) to point to the name of the database container (`local-postgres`):
```bash
docker run -dp 8000:8000 \
  --name web-app \
  --network flask-app-network \
  -e DBHOST=local-postgres \
  -e DBNAME=restaurant \
  -e DBUSER=dbuser \
  -e DBPASS=dbpass \
  -e SECRET_KEY=some-local-dev-secret-key \
  msdocs-flask-app
```

The application will be accessible at: **`http://localhost:8000`**

---

## Method 2: Running Locally while connecting to Azure Services

You can also run the application container locally but have it connect directly to your Azure Database for PostgreSQL (Flexible Server).

### Step 1: Configure Azure Network Security
1. Go to your **Azure Database for PostgreSQL Flexible Server** in the Azure Portal.
2. Select **Networking** (under Settings).
3. Add your local computer's public IP address to the firewall rules (or enable public access) so the container can connect.

### Step 2: Log in to Azure on your machine
Run the login command in your terminal:
```bash
az login
```

### Step 3: Build and Run the App Container
Since the code is configured to support Azure Managed Identity credentials, `DefaultAzureCredential` will automatically fetch authentication tokens using your active Azure CLI login session.

Run the container by mounting your local Azure credentials folder into the container's home directory:

#### For Windows (PowerShell):
```powershell
# Build the image
docker build -t msdocs-flask-app .

# Run the container (using $env:USERPROFILE to locate your Azure credentials directory)
docker run -dp 8000:8000 `
  --name web-app-azure `
  -e DBHOST=<your-azure-postgresql-server>.postgres.database.azure.com `
  -e DBNAME=<your-azure-database-name> `
  -e DBUSER=<your-azure-database-username> `
  -e SECRET_KEY=some-local-dev-secret-key `
  -v ${env:USERPROFILE}/.azure:/app/.azure `
  msdocs-flask-app
```

#### For Linux / macOS / Git Bash:
```bash
# Build the image
docker build -t msdocs-flask-app .

# Run the container (using ~/.azure directory mount)
docker run -dp 8000:8000 \
  --name web-app-azure \
  -e DBHOST=<your-azure-postgresql-server>.postgres.database.azure.com \
  -e DBNAME=<your-azure-database-name> \
  -e DBUSER=<your-azure-database-username> \
  -e SECRET_KEY=some-local-dev-secret-key \
  -v ~/.azure:/app/.azure \
  msdocs-flask-app
```
