FROM golang:latest
COPY ./api/ /api
WORKDIR /api
RUN CGO_ENABLED=1 GOOS=linux go build -o handler .

FROM mcr.microsoft.com/azure-functions/dotnet:4.9.1-slim
# FROM mcr.microsoft.com/azure-functions/dotnet:3.0-appservice
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

COPY --from=0 /api/ /home/site/wwwroot