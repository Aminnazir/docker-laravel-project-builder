
# Setup Multiple Laravel Projects With Docker

This repository provides a convenient Makefile for setting up a Laravel project using Docker. The Makefile automates common tasks such as starting and stopping Docker containers, running migrations, seeding the database, and more.


## Prerequisites

- Docker and Docker Compose installed on your machine
- Basic understanding of Docker, Laravel, and Vite

## Makefile Commands

The Makefile includes several commands to manage your Laravel project. Below is a list of the commands and their descriptions.

### Setup Commands

-  `setup`: Captures input from the user, creates the project folder, downloads Laravel if necessary, sets up the Docker environment, and performs initial configurations.

```bash
 make setup
```

- `capture_input`: Captures necessary project details from the user, such as project folder name, site name, application port, container prefix, and database credentials.
- `create-project-folder`: Creates the project folder if it does not already exist.
- `check-laravel-env`: Checks if Laravel is installed in the project folder; if not, downloads it.
- `env-file`: Creates or updates the .env file in the project folder with captured variables.

### Laravel Artisan Commands
- `artisan`: Executes Artisan commands within the Docker app container.
- `migrate`: Runs Laravel migrations.
- `seed`: Seeds the Laravel database.
- `migrate-refresh`: Refreshes migrations and seeds the database.
- `artisan-key`: Generates a new application key.

### Composer and NPM Commands
- `composer-install`: Installs Composer dependencies.
- `composer-update`: Updates Composer dependencies.
- `npm-install`: Installs NPM dependencies.
- `npm-dev`: Runs NPM development build.
- `npm-prod`: Runs NPM production build.
- `npm-build`: Runs NPM build.

### Other Useful Commands
- `logs`: Views logs of Docker containers.
- `fix-permissions`: Fixes file and folder permissions for Laravel.
- `install-laravel-ui: Installs Laravel UI and sets up authentication.
- `auth-setup: Sets up authentication (alias for install-laravel-ui).


### SSH Commands
- `ssh-app`: SSH into the app container.
- `ssh-db`: SSH into the database container.
- `ssh-node`: SSH into the node container.

## Docker Configuration
The Docker setup uses a `docker-compose.yml` file to define the services required for the Laravel project, including the app, database, and node services. Ensure you have a valid .env file in your project folder to configure environment variables for these services.

## Vite Configuration
Vite is used as the build tool for this Laravel project. The `vite.config.js` file includes the configuration necessary for Vite to work with Laravel and Vue.

```bash
  server: {
        hmr: {
            clientPort: 3001,
            host: true,
        },
        watch: {
            usePolling: true,
        },
    }
```

## Using the Makefile

1. Clone the repository: Clone the repository to your local machine.

```bash
 git clone [url](https://github.com/Aminnazir/docker-laravel-project-builder) .
```

2. Navigate to the project directory: Open a terminal and navigate to the project directory.

```bash
cd your-project
```

3. Run the setup command: Execute `make setup` to set up the project. This command will guide you through capturing necessary input and setting up the Docker environment.

```bash
 make setup
```

4. Start the Docker containers: Run `make up` to start the Docker containers.

```bash
 make up
```

## Example Commands
- To start the Docker containers: `make up`

```bash
 make up
```

- To stop the Docker containers: `make stop`

```bash
 make stop
```

- To rebuild the Docker containers: `make build`

```bash
 make build
```

- To run migrations: `make migrate`

```bash
 make migrate
```
- To seed the database: `make seed`

```bash
 make seed
```

- To run the Vite development build: `make npm-dev`

```bash
 make npm-dev
```

### Conclusion 

this repository offers a streamlined solution for setting up multiple Laravel projects using Docker. With the provided Makefile, you can effortlessly initialize and manage your projects by simply inputting the project name. Whether you're working on a single project or managing multiple ones, this setup ensures consistency and ease of use across the board. Say goodbye to manual configuration hassles and hello to efficient project setup with Docker and the versatile Makefile included in this repository.
