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

.PHONY: gen gen-go gen-dart lint lint-go lint-dart test test-go test-dart check check-go check-dart auth-keys up down db-reset run-api sync-contract check-contract

gen: gen-go gen-dart
lint: lint-go lint-dart
test: test-go test-dart

# Quick loop: `make test-dart T=test/diary` or `make test-go T=./internal/settings/...` runs one package.
# T is relative to the app (apps/mobile for Dart, apps/api for Go); empty means everything.
#
# `make -j2 check` runs Go and Flutter side by side. Go lint and tests share no state with Flutter.
# Flutter lint and tests both run `pub get` and chown apps/mobile, so check-dart runs them one after the other.
check: check-go check-dart
check-go: lint-go test-go
check-dart:
	$(MAKE) lint-dart
	$(MAKE) test-dart

# The API owns the contract; the mobile app keeps a committed copy (D-70).
sync-contract:
	cp apps/api/openapi.yaml apps/mobile/openapi.yaml

check-contract:
	@cmp -s apps/api/openapi.yaml apps/mobile/openapi.yaml || { echo "apps/mobile/openapi.yaml differs from apps/api/openapi.yaml: run make sync-contract"; exit 1; }

gen-go:
	$(GO_RUN) $(GO_IMAGE) go generate ./internal/gen/...

gen-dart:
	$(FLUTTER_RUN) 'flutter pub get && flutter gen-l10n && dart run swagger_parser && dart run build_runner build --delete-conflicting-outputs $(FLUTTER_FIX)'

lint-go:
	$(GO_RUN) $(GOLANGCI_IMAGE) golangci-lint run ./...

test-go:
	$(GO_RUN) $(GO_IMAGE) go test -count=1 $(or $(T),./...)

lint-dart:
	$(FLUTTER_RUN) 'flutter pub get && dart format --output=none --set-exit-if-changed lib/main.dart lib/app lib/kernel lib/ui lib/auth lib/settings lib/diary test && flutter analyze --fatal-infos $(FLUTTER_FIX)'

test-dart:
	$(FLUTTER_RUN) 'flutter test $(T) $(FLUTTER_FIX)'

# The local GoTrue signing key (PRD D-71): created once in the git-ignored .cache/, never overwritten.
auth-keys:
	@test -f .cache/auth/jwt-keys.json || $(GO_RUN) $(GO_IMAGE) go run ./cmd/devjwk -out /work/.cache/auth/jwt-keys.json

up: auth-keys
	docker compose --profile auth up -d --wait db auth auth-gateway mailpit

down:
	docker compose --profile app --profile auth down

# Local data is disposable: drop the volumes, start an empty Postgres, apply the auth stub and every migration in order, then start the auth stack (it runs after our migrations).
db-reset:
	docker compose --profile app --profile auth down -v
	docker compose up -d --wait db
	for f in apps/api/db/local/00_auth_stub.sql apps/api/db/migrations/*.sql; do \
	  echo "apply $$f"; \
	  docker compose exec -T db psql -v ON_ERROR_STOP=1 -U postgres -d postgres -f - < $$f || exit 1; \
	done
	$(MAKE) up

run-api:
	docker compose --profile app up --build -d --wait
