FROM golang:latest as builder
ADD ./app /app
WORKDIR /app
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o /main .

FROM scratch
ARG VERSION
ARG COLOUR
ARG LOCATION
ENV VERSION=${VERSION}
ENV COLOUR=${COLOUR}
ENV LOCATION=${LOCATION}
COPY --from=builder /main ./
COPY --from=builder /app/html ./html 
ENTRYPOINT ["./main"]
EXPOSE 80