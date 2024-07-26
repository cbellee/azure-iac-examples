# Use the official Golang image as the base image
FROM golang:1.22-alpine

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy the source code into the container
COPY /app .

# Download all dependencies
RUN go mod download

# Build the Go app
RUN go build -o main .

# Expose port 8080 to the outside world
EXPOSE 8080

# Command to run the executable
CMD ["./main"]