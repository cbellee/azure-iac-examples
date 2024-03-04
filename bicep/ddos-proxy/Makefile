VERSION='0.1.0'

include ./.env

build:
	docker build -f ./nginx/Dockerfile -t proxyserver:${VERSION} ./nginx
	docker tag proxyserver:${VERSION} ${ACR_NAME}.azurecr.io/proxyserver:${VERSION}

push:
	docker login ${ACR_NAME}.azurecr.io -u ${ACR_NAME} -p ${ACR_PWD}
	docker push ${ACR_NAME}.azurecr.io/proxyserver:${VERSION}
