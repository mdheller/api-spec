PWD := $(shell pwd)
PHONY: lint spec-tmp.yaml

SWAGGER_VERSION=2.2.3

# YAML linting
lint:
	docker run --rm -ti \
		-v $(PWD):/workdir \
		-w /workdir \
		giantswarm/yamllint \
		-c ./yamllint/config.yaml \
		./spec/*

# Validate the swagger/OAI spec
validate:
	# Useful to ensure gsclientgen client generation works
	@echo "Validating with go-swagger"
	docker run --rm -it \
		-v ${PWD}:/workdir \
		-w /workdir \
		quay.io/goswagger/swagger:0.16.0 \
			validate ./spec/spec.yaml

	@echo "Generating swagger representation"
	docker run --rm -it \
		-v $(shell pwd):/code/yaml \
		jimschubert/swagger-codegen-cli:${SWAGGER_VERSION} generate \
		--input-spec /code/yaml/spec/spec.yaml \
		--lang swagger --output /tmp/

	@echo "Generating JavaScript client code for test purposes"
	docker run --rm -it \
		-v $(shell pwd):/code/yaml \
		jimschubert/swagger-codegen-cli:${SWAGGER_VERSION} generate \
		--input-spec /code/yaml/spec/spec.yaml \
		--lang javascript --output /tmp/

# This is exclusively for testing on CircleCI.
# The --rm=false is required to prevent an error on CircleCI.
test: lint
	docker run --rm=false -it \
		-v $(shell pwd):/code/yaml \
		jimschubert/swagger-codegen-cli:${SWAGGER_VERSION} generate \
		--input-spec /code/yaml/spec/spec.yaml \
		--lang swagger --output /tmp/
	docker run --rm=false -it \
		-v $(shell pwd):/code/yaml \
		jimschubert/swagger-codegen-cli:${SWAGGER_VERSION} generate \
		--input-spec /code/yaml/spec/spec.yaml \
		--lang javascript --output /tmp/

# Run a server to show the HTML docs UI on http://localhost:8080
run-server:
	docker build -t api-spec-dev -f Dockerfile .
	docker run --rm -p 8080:8000 api-spec-dev
