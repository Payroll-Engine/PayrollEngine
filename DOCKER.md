# Payroll Engine Docker Stack

This document describes how to set up and run the Payroll Engine stack using Docker.

## Prerequisites

- Docker
- Docker Compose

## Getting Started

### 1. Environment Configuration

The application uses a `.env` file to manage the database password. This file must be created in the same directory as the `docker-compose.yml` file (`PayrollEngine/`).

Create a file named `.env` with the following content:

```
# PayrollEngine Docker Stack Configuration
DB_PASSWORD=PayrollStrongPass789
```

**Important Password Requirements:**
- Use **alphanumeric characters only** (letters and numbers)
- **Avoid special characters** like `!`, `@`, `#`, `$`, etc.
- Special characters can cause authentication failures that appear as misleading "sqlcmd not found" errors
- Example of good password: `PayrollStrongPass789`
- Example of problematic password: `PayrollStrongPass789!` (contains `!`)

### 2. Build and Run the Stack

To build and start all the services, run the following command from the `PayrollEngine/` directory:

```sh
docker-compose up --build
```

This command will:
- Build the Docker images for the `backend-api`, `webapp`, and `db-init` services.
- Start all the services in the correct order.
- Initialize the database.

### 3. Accessing the Applications

Once the stack is running, you can access the following services:

- **PayrollEngine WebApp**: `http://localhost:8081`
- **PayrollEngine Backend API**: `http://localhost:5001` (HTTP) or `https://localhost:5002` (HTTPS)
- **SQL Server Database**: Connect using a client on `localhost:1433` with the `sa` user and the password you defined in the `.env` file.
-  **Verification:** : Test the SQL Server connection:
```sh
docker exec payroll-db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourPassword" -C -Q "SELECT @@VERSION"
```

### 4. Stopping the Stack

To stop the services, press `Ctrl+C` in the terminal where `docker-compose up` is running.

To stop and remove the containers, run:

```sh
docker-compose down
```

To remove the database volume as well, run:
```sh
docker-compose down -v
```


 **Verification:**
 Test the SQL Server connection:
```sh
docker exec payroll-db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "YourPassword" -C -Q "SELECT @@VERSION"
```