# Lean Tracker: every tool runs in a pinned Docker image, the repo is mounted at /work.
# Single source for tool versions; apps/api/Dockerfile and apps/api/go.mod follow GO_IMAGE.
GO_IMAGE       ?= golang:1.27.4-bookworm
GOLANGCI_IMAGE ?= golangci/golangci-lint:v2.15.0
FLUTTER_IMAGE  ?= ghcr.io/cirruslabs/flutter:3.44.0
UID_GID        := $(shell id -u):$(shell id -g)

# Go tools run as the host user; caches live in the gitignored .cache/.
GO_RUN = docker run --rm --user $(UID_GID) -e HOME=/tmp \
  -e GOCACHE=/work/.cache/go-build -e GOMODCACHE=/work/.cache/go-mod -e GOLANGCI_LINT_CACHE=/work/.cache/golangci \
  -v $(CURDIR):/work -w /work/apps/api
# Flutter runs as root (the SDK cache in the image is root-owned) and hands files back to the host user.
FLUTTER_RUN = docker run --rm -e PUB_CACHE=/work/.cache/pub -v $(CURDIR):/work -w /work/apps/mobile $(FLUTTER_IMAGE) sh -c
FLUTTER_FIX = ; status=$$?; chown -R $(UID_GID) /work/apps/mobile /work/.cache/pub; exit $$status

.PHONY: gen gen-go gen-dart lint lint-go lint-dart test test-go test-dart up down db-reset run-api

gen: gen-go gen-dart
lint: lint-go lint-dart
test: test-go test-dart

gen-go:
	$(GO_RUN) $(GO_IMAGE) go generate ./internal/gen/...

gen-dart:
	$(FLUTTER_RUN) 'flutter pub get && dart run swagger_parser && dart run build_runner build --delete-conflicting-outputs $(FLUTTER_FIX)'

lint-go:
	$(GO_RUN) $(GOLANGCI_IMAGE) golangci-lint run ./...

test-go:
	$(GO_RUN) $(GO_IMAGE) go test -count=1 ./...

lint-dart:
	$(FLUTTER_RUN) 'flutter pub get && dart format --output=none --set-exit-if-changed lib/main.dart lib/app test && flutter analyze --fatal-infos $(FLUTTER_FIX)'

test-dart:
	$(FLUTTER_RUN) 'flutter test $(FLUTTER_FIX)'

up:
	docker compose up -d --wait db

down:
	docker compose --profile app down

# Local data is disposable: drop the volume, start an empty Postgres, apply the auth stub and every migration in order.
db-reset:
	docker compose down -v
	$(MAKE) up
	for f in db/local/00_auth_stub.sql db/migrations/*.sql; do \
	  echo "apply $$f"; \
	  docker compose exec -T db psql -v ON_ERROR_STOP=1 -U postgres -d postgres -f - < $$f || exit 1; \
	done

run-api:
	docker compose --profile app up --build -d --wait
