FROM golang:1.18.2-alpine3.15 AS builder

ARG SERVICE_PORT=""

RUN mkdir /build
WORKDIR /build
COPY . .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o server ./main.go

FROM scratch

ARG SERVICE_PORT=""

WORKDIR /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /build/server .

# run server
EXPOSE $SERVICE_PORT
CMD ["./server"]