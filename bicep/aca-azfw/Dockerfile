FROM golang:latest AS builder

ARG SERVICE_NAME=""
ARG SERVICE_PORT=""

RUN mkdir /build
WORKDIR /build
# RUN apk update && apk add --no-cache git
COPY ./cmd .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GO111MODULE=on \
    go build \
    -o server \
    ./${SERVICE_NAME}

# release container image
FROM scratch

ARG SERVICE_NAME=""
ARG SERVICE_PORT=""

WORKDIR /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /build/server .

# run server
EXPOSE $SERVICE_PORT
CMD ["./server"]