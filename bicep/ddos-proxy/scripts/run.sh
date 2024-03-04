#!/bin/bash

while getopts r:l:i:p: option; do
    case "${option}" in
    r) ACR_NAME=${OPTARG} ;;
    l) ACR_LOGIN_NAME=${OPTARG} ;;
    i) IMAGE_NAME=${OPTARG} ;;
    p) ACR_PASSWORD=${OPTARG} ;;
    esac
done

docker login $ACR_NAME -u $ACR_LOGIN_NAME -p $ACR_PASSWORD
docker pull $ACR_NAME/$IMAGE_NAME
docker run --name docker-nginx -p 80:80 -d $IMAGE_NAME
