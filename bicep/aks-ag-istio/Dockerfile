FROM golang:1.19.3 AS build
RUN mkdir /build
WORKDIR /build
COPY . .
RUN useradd -u 10001 scratchuser

RUN CGO_ENABLED=0 GOOS=linux go build -o server ./main.go

FROM scratch
COPY --from=build /build/server .

USER 10001
CMD [ "./server" ] 
EXPOSE 8080