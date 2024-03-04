VERSION := $(shell git rev-parse --short HEAD)
BUILD_DATE := $(shell date -R)
NAME := $(shell basename `git rev-parse --show-toplevel`)
VENDOR := $(shell whoami)
SEMVER := 0.1.5
ENVIRONMENT := dev
COLOUR := green
TAG := ${ENVIRONMENT}-${SEMVER}-${VERSION}
CONTAINER_NAME := belstarr/colourserver:${TAG}

print:
	@echo VERSION=${VERSION}
	@echo SEMVER=${SEMVER}
	@echo BUILD_DATE=${BUILD_DATE}
	@echo NAME=${NAME}
	@echo VENDOR=${VENDOR}
	@echo COLOUR=${COLOUR}

build:
	docker build \
	-t ${CONTAINER_NAME} \
	--build-arg VERSION="${TAG}" \
	--build-arg SEMVER="${SEMVER}" \
	--build-arg COLOUR="${COLOUR}" \
	--build-arg BUILD_DATE="${BUILD_DATE}" \
	--build-arg NAME="${NAME}" \
	--build-arg VENDOR="${VENDOR}" .

push:
	docker push ${CONTAINER_NAME}

deploy:
	sed 's|CONTAINER_NAME|${CONTAINER_NAME}|g' ./manifests/deploy-project1.tmpl > ./manifests/deploy-project1.yml
	sed 's|CONTAINER_NAME|${CONTAINER_NAME}|g' ./manifests/deploy-project2.tmpl > ./manifests/deploy-project2.yml

	kubectl create ns project1
	kubectl create ns project2

	kubectl apply -f ./manifests/deploy-project1.yml
	kubectl apply -f ./manifests/deploy-project2.yml

run:
	docker run \
	-d \
	-p 8080:80 \
	-e VERSION=${TAG} \
	-e COLOUR="blue" \
	${CONTAINER_NAME}
