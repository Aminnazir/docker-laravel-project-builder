# Makefile for setting up Laravel project with Docker

# Color codes
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
NO_COLOR=\033[0m

# Website URL
WEBSITE_URL=http://localhost

# Function to set up the project by executing multiple steps
setup: capture_input create-project-folder check-laravel-env env-file docker-setup fix-permissions artisan-key migrate seed
	@echo "$(GREEN)Project setup completed successfully.$(NO_COLOR)"
	@echo "$(YELLOW)Visit the website at: $(GREEN)$(WEBSITE_URL):$(APP_PORT)$(NO_COLOR)"


# Function to display available project folders if PROJECT_FOLDER is not set
available_folder:
	@if [ -z "$(PROJECT_FOLDER)" ]; then \
		echo "$(YELLOW)Available project folders:$(NO_COLOR)"; \
		available_folders=$$(find . -maxdepth 1 -type d -not -name 'docker' -not -name 'nginx' -not -name '.*' -not -name '.' | sed 's|^\./||'); \
		echo "$(YELLOW)$$available_folders $(NO_COLOR)"; \
	fi

# Function to capture the project folder name from the user if not set
capture_project: available_folder
	$(eval PROJECT_FOLDER=$(shell read -p "Enter the project folder name: " folder && echo $$folder))
	@if [ ! -d "$(PROJECT_FOLDER)" ]; then \
		echo "$(RED)Invalid project folder name$(NO_COLOR)"; \
    		exit 1; \
     fi

# Function to capture the image name from the user if not set
capture_image: capture_project
	$(eval IMAGE=$(shell sh -c 'read -p "Enter the image name: " image && echo $$image'))
	@if [ -z "$(IMAGE)" ]; then \
		echo "$(RED)IMAGE name is not set$(NO_COLOR)"; \
		exit 1; \
	fi

# Capture various input values from the user to setup project
capture_input:
	$(eval PROJECT_FOLDER=$(shell read -p "Enter the project folder name: " folder && echo $$folder))
	$(eval APP_NAME=$(shell read -p "Enter the site name: " appname && echo $$appname))
	$(eval APP_PORT=$(shell read -p "Enter the application port: " appport && echo $$appport))
	$(eval CONTAINER_PREFIX=$(shell read -p "Enter the container prefix name: " prefix && echo $$prefix))
	$(eval DB_DATABASE=$(shell read -p "Enter the database name: " dbname && echo $$dbname))
	$(eval DB_USERNAME=$(shell read -p "Enter the database user: " dbuser && echo $$dbuser))
	$(eval DB_PASSWORD=$(shell read -p "Enter the database password: " dbpassword && echo $$dbpassword))
	$(eval DB_ROOT_PASSWORD=$(shell read -p "Enter the database root password: " dbrootpassword && echo $$dbrootpassword))
	$(eval DB_PORT=3306)
	$(eval DB_PORT_EXTERNAL=$(shell expr $(APP_PORT) + 1))
	$(eval PMA_PORT=$(shell expr $(APP_PORT) + 2))
	$(eval VITE_PORT=$(shell expr $(APP_PORT) + 3))

# Function to create project folder if it doesn't exist
create-project-folder:
	@if [ ! -d "$(PROJECT_FOLDER)" ]; then \
		echo "$(YELLOW)Creating project folder $(PROJECT_FOLDER)...$(NO_COLOR)"; \
		mkdir $(PROJECT_FOLDER); \
	fi

update-env : capture_input env-file

# Function to create or update the .env file with captured variables
env-file:
	@echo "$(YELLOW)Creating or updating .env file in $(PROJECT_FOLDER)...$(NO_COLOR)"
	@sudo sh -c '\
		export PROJECT_FOLDER="$(PROJECT_FOLDER)"; \
		for var in \
			"APP_NAME=$(APP_NAME)" \
			"APP_PORT=$(APP_PORT)" \
			"APP_ENV=local" \
			"APP_KEY=" \
			"APP_DEBUG=true" \
			"APP_URL=http://localhost:$(APP_PORT)" \
			"CONTAINER_PREFIX=$(CONTAINER_PREFIX)" \
			"LOG_CHANNEL=stack" \
			"DB_CONNECTION=mysql" \
			"DB_HOST=db" \
			"DB_PORT=3306" \
			"DB_PORT_EXTERNAL=$(DB_PORT_EXTERNAL)" \
			"PMA_PORT=$(PMA_PORT)" \
			"DB_DATABASE=$(DB_DATABASE)" \
			"DB_USERNAME=$(DB_USERNAME)" \
			"DB_PASSWORD=$(DB_PASSWORD)" \
			"DB_ROOT_PASSWORD=$(DB_ROOT_PASSWORD)" \
			"BROADCAST_DRIVER=log" \
			"CACHE_DRIVER=file" \
			"QUEUE_CONNECTION=sync" \
			"SESSION_DRIVER=file" \
			"SESSION_LIFETIME=120" \
			"VITE_PORT=$(VITE_PORT)"; \
		do \
			key=$$(echo $$var | cut -d= -f1); \
			value=$$(echo $$var | cut -d= -f2-); \
			if grep -q "^$$key=" $(PROJECT_FOLDER)/.env; then \
				sed -i "s|^$$key=.*|$$key=$$value|" $(PROJECT_FOLDER)/.env; \
			else \
				echo "$$key=$$value" >> $(PROJECT_FOLDER)/.env; \
			fi; \
		done; \
	'
	@echo "$(GREEN).env file created or updated successfully.$(NO_COLOR)"

# Function to check if Laravel is installed, if not, download it
check-laravel-env:
	@if [ ! -d "$(PROJECT_FOLDER)/vendor" ]; then \
		echo "$(YELLOW)Downloading Laravel into $(PROJECT_FOLDER)...$(NO_COLOR)"; \
		echo "$(YELLOW)Running Docker command to create Laravel project...$(NO_COLOR)"; \
		docker run --rm -v $(shell pwd)/$(PROJECT_FOLDER):/app composer create-project --prefer-dist laravel/laravel /app; \
		if [ $$?q 0 ]; then \
			echo "$(GREEN)Laravel project created successfully.$(NO_COLOR)"; \
		else \
			echo "$(RED)Failed to create Laravel project.$(NO_COLOR)"; \
		fi; \
	else \
		echo "$(YELLOW)Laravel project already exists in $(PROJECT_FOLDER).$(NO_COLOR)"; \
	fi


# Function to fix file and folder permissions for Laravel
fix-permissions: capture_project
	@echo "$(YELLOW)Fixing file and folder permissions for Laravel...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) app sh -c "mkdir -p /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public"
	@echo "$(GREEN)File and folder permissions fixed successfully.$(NO_COLOR)"

# Function to set up Docker for the Laravel project
docker-setup: capture_project
	@echo "$(YELLOW)Setting up Docker for Laravel project...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p "$(PROJECT_FOLDER)" build
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p "$(PROJECT_FOLDER)" up -d
	@echo "$(GREEN)Docker setup for Laravel project completed successfully.$(NO_COLOR)"
	@echo "$(YELLOW)Visit the website at: $(GREEN)$(WEBSITE_URL):$(APP_PORT)$(NO_COLOR)"

# Function to set up Docker for the Laravel project with no cache
docker-setup-fresh: capture_project
	@echo "$(YELLOW)Setting up Docker for Laravel project with no cache...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p "$(PROJECT_FOLDER)" build --no-cache
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p "$(PROJECT_FOLDER)" up -d
	@echo "$(GREEN)Docker setup for Laravel project with no cache completed successfully.$(NO_COLOR)"


# Docker Commands

# Function to start Docker containers
up: capture_project
	@echo "$(YELLOW)Starting Docker containers...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose  -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) up -d
	@echo "$(GREEN)Docker containers started successfully.$(NO_COLOR)"
	@echo "$(YELLOW)Visit the website at: $(GREEN)$(WEBSITE_URL):$(APP_PORT)$(NO_COLOR)"

# Function to stop Docker containers
stop: capture_project
	@echo "$(YELLOW)Stopping Docker containers...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) stop
	@echo "$(GREEN)Docker containers stopped successfully.$(NO_COLOR)"

# Function to remove Docker containers
down: capture_project
	@echo "$(YELLOW)Removing Docker containers...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) down
	@echo "$(GREEN)Docker containers removed successfully.$(NO_COLOR)"

# Function to restart Docker containers
restart: capture_project down up

# Function to build Docker images
build: capture_project
	@echo "$(YELLOW)Building Docker images...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) build
	@echo "$(GREEN)Docker images built successfully.$(NO_COLOR)"

# Function to rebuild any Docker image
re-build-image: capture_project capture_image
	@echo "$(YELLOW)Rebuilding Docker image: $(IMAGE)...$(NO_COLOR)"
	$(MAKE) stop
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p "$(PROJECT_FOLDER)" build --no-cache $(IMAGE)
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p "$(PROJECT_FOLDER)" up -d
	@echo "$(GREEN)Docker image $(IMAGE) rebuilt successfully.$(NO_COLOR)"

# Function to check DB container status
check_db_status:capture_project
	@echo "$(YELLOW)Checking database container status...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app dockerize -wait tcp://db:3306 -timeout 60s
	@echo "$(GREEN)Database container is ready.$(NO_COLOR)"

# Function to SSH into the app container
ssh-app: capture_project
	@echo "$(YELLOW)Connecting to app container...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app sh
	@echo "$(GREEN)Exited app container.$(NO_COLOR)"

ssh-node: capture_project
	@echo "$(YELLOW)Connecting to node container...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec node sh
	@echo "$(GREEN)Exited node container.$(NO_COLOR)"

ssh-db: capture_project
	@echo "$(YELLOW)Connecting to db container...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec db sh
	@echo "$(GREEN)Exited db container.$(NO_COLOR)"

# Function to view logs of Docker containers
logs: capture_project
	@echo "$(YELLOW)Displaying Docker container logs...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) logs -f

#Laravel Commands

# Function to execute Artisan commands within the Docker app container
artisan: capture_project
	@echo "$(YELLOW)Executing Artisan command...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app php artisan $(cmd)
	@echo "$(GREEN)Artisan command executed successfully.$(NO_COLOR)"

# Function to run Laravel migrations
migrate: capture_project check_db_status
	@echo "$(YELLOW)Running Laravel migrations...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app php artisan migrate
	@echo "$(GREEN)Migrations ran successfully.$(NO_COLOR)"

# Function to seed the Laravel database
seed: capture_project check_db_status
	@echo "$(YELLOW)Seeding the Laravel database...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app php artisan db:seed
	@echo "$(GREEN)Database seeded successfully.$(NO_COLOR)"

# Function to refresh migrations and seed the database
migrate-refresh: capture_project check_db_status
	@echo "$(YELLOW)Refreshing migrations and seeding the database...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app php artisan migrate:refresh --seed
	@echo "$(GREEN)Migrations refreshed and database seeded successfully.$(NO_COLOR)"

# Function to generate a new application key
artisan-key: capture_project
	@echo "$(YELLOW)Generating new application key...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app php artisan key:generate
	@echo "$(GREEN)New application key generated successfully.$(NO_COLOR)"

# Function to install Laravel UI and set up authentication
install-laravel-ui: capture_project
	@echo "$(YELLOW)Installing Laravel UI and setting up authentication...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app composer require laravel/ui
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app php artisan ui vue --auth
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app npm install
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app npm run dev
	@echo "$(GREEN)Laravel UI installed and authentication set up successfully.$(NO_COLOR)"

# Function to set up authentication (alias for install-laravel-ui)
auth-setup: install-laravel-ui

# Function to run PHPUnit tests
test: capture_project
	@echo "$(YELLOW)Running PHPUnit tests...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app ./vendor/bin/phpunit
	@echo "$(GREEN)PHPUnit tests ran successfully.$(NO_COLOR)"

# NPM commands

# Function to install NPM dependencies
npm-install: capture_project
	@echo "$(YELLOW)Running npm install...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec node npm install
	@echo "$(GREEN)Npm install completed successfully.$(NO_COLOR)"

# Function to run NPM development build
npm-dev: capture_project
	@echo "$(YELLOW)Running npm dev...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec node npm run dev
	@echo "$(GREEN)Npm dev completed successfully.$(NO_COLOR)"

# Function to run NPM production build
npm-prod: capture_project
	@echo "$(YELLOW)Running npm prod...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec node npm run prod
	@echo "$(GREEN)Npm prod completed successfully.$(NO_COLOR)"

# Function to run NPM build
npm-build: capture_project
	@echo "$(YELLOW)Running npm build...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec node npm run build
	@echo "$(GREEN)Npm build completed successfully.$(NO_COLOR)"

# Composer commands

# Function to install Composer dependencies
composer-install: capture_project
	@echo "$(YELLOW)Running composer install...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app composer install
	@echo "$(GREEN)Composer install completed successfully.$(NO_COLOR)"

# Function to update Composer dependencies
composer-update: capture_project
	@echo "$(YELLOW)Running composer update...$(NO_COLOR)"
	@PROJECT_FOLDER=$(PROJECT_FOLDER) docker-compose -f docker-compose.yml --env-file $(PROJECT_FOLDER)/.env -p $(PROJECT_FOLDER) exec app composer update
	@echo "$(GREEN)Composer update completed successfully.$(NO_COLOR)"
