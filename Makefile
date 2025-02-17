ENV_FILE=.env

.PHONY: dev prod

watch:
	@echo "ENVIRONMENT=development" > $(ENV_FILE)
	@docker compose up --build --watch

run:
	@echo "ENVIRONMENT=production" > $(ENV_FILE)
	@docker compose up --build