FROM golang:1.22.1-alpine3.19 AS builder

RUN mkdir /build
WORKDIR /build
COPY ./app .

# install dependencies
WORKDIR /build/cmd
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o server ./main.go

FROM scratch

WORKDIR /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /build/cmd/server .

# run server
EXPOSE 8080
CMD ["./server"]