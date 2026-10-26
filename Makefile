.PHONY: up down api-test portal-dev app-check

up:            ## Start Postgres + API
	docker compose up --build

down:
	docker compose down

api-test:      ## Lint and test the API
	cd services/api && ruff check . && ruff format --check . && pytest -q

portal-dev:    ## Run the promoter portal on :5173
	cd apps/promoter-portal && npm install && npm run dev

app-check:     ## Analyze and test the Flutter customer app
	cd apps/customer && flutter pub get && flutter analyze --no-fatal-infos && flutter test
