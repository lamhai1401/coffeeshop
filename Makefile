SHELL := /bin/bash

proto:
	protoc ./*.proto \
		--go_out=. \
		--go-grpc_out=. \
		--go_opt=paths=source_relative \
		--go-grpc_opt=paths=source_relative \
		--proto_path=.

swagger:
	swagger generate spec -o ./swagger.json
	swagger serve ./swagger.json

nats:
	docker-compose -f nats-cluster.yml up

nats-stop:
	docker-compose -f nats-cluster.yml down && docker-compose -f nats-cluster.yml stop

init-schema:
	migrate create -ext sql -dir /db/migration -seq init_schema

pg-start:
	docker-compose -f postgres.yml up

pg-stop:
	docker-compose -f postgres.yml down && docker-compose -f postgres.yml stop

migrateup:
	migrate -path ./db/migration -database "postgresql://username:password@localhost:5432/simplebank?sslmode=disable" -verbose up

migratedown:
	migrate -path db/migration -database "postgresql://username:password@localhost:5432/simplebank?sslmode=disable" -verbose down

test:
	go test -v -cover ./...

test-circle:
	go test -v -race -coverprofile=c.out -cover $(go list ./... | circleci tests split --split-by=timings)
	go tool cover -html=c.out -o coverage.html

test-local:
	go test -v -race -coverprofile=c.out -cover ./...
	go tool cover -html=c.out -o coverage.html

mock:
	mockgen -package mockdb -destination db/mock/store.go github.com/lamhai1401/simplebank-ex/db/sqlc Store

run:
	go run . -addsvc -grpc-addr=:8082 -zipkin-url=http://localhost:9411/api/v2/spans

graph-init:
	go run github.com/99designs/gqlgen init

graph-modify:
	go run github.com/99designs/gqlgen generate .

.PHONY: test test-local