package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/dapr/go-sdk/service/common"
	"models"
	dapr "github.com/dapr/go-sdk/client"
	daprd "github.com/dapr/go-sdk/service/http"
)

var (
	version     = "0.0.1"
	serviceName = os.Getenv("SERVICE_NAME") //"frontend"
	servicePort = os.Getenv("SERVICE_PORT") //"80"
	bindingName = os.Getenv("QUEUE_BINDING_NAME") //"servicebus"
	queueName   = os.Getenv("QUEUE_NAME")   //"checkin"
	bindingOperation = "create"
	logger      = log.New(os.Stdout, "", 0)
)

func main() {
	logger.Printf("starting service : %v v%v...", serviceName, version)

	port := fmt.Sprintf(":%s", servicePort)
	server := daprd.NewService(port)

	logger.Printf("serviceName: %s", serviceName)
	logger.Printf("servicePort: %s", servicePort)
	logger.Printf("bindingName: %s", bindingName)
	logger.Printf("bindingOperation: %s", bindingOperation)
	logger.Printf("queueName: %s", queueName)

	if err := server.AddServiceInvocationHandler("/checkin", checkinHandler); err != nil {
		logger.Panicf("failed to add service invocation handler '/checkin' : %s", err)
	} else {
		logger.Printf("invocation handler for service '%s' added successfully!", serviceName)
	}

	if err := server.Start(); err != nil && err != http.ErrServerClosed {
		logger.Fatalf("error listening: %s", err)
	}
}

func checkinHandler(ctx context.Context, in *common.InvocationEvent) (out *common.Content, err error) {
	if in == nil {
		err = errors.New("invocation parameter required")
		return
	}

	ctx = context.Background()
	
	client, err := dapr.NewClient()
	if err != nil {
		logger.Panicf("failed to create Dapr client: %s", err)
	}

	logger.Printf("echo - ContentType:%s, Verb:%s, QueryString:%s, %s", in.ContentType, in.Verb, in.QueryString, in.Data)

	var c models.Checkin
	err = json.Unmarshal(in.Data, &c)
	if err != nil {
		logger.Print(err.Error())
	}

	br := &dapr.InvokeBindingRequest{
		Name:      bindingName,
		Operation: bindingOperation,
		Data:      in.Data,
	}

	if err := client.InvokeOutputBinding(ctx, br); err != nil {
		logger.Panicf("failed to send event to queue '%s' : %s", queueName, err)
		return nil, err
	} else {
		logger.Printf("successfully sent event to queue %s", queueName)
	}

	return out, nil
}
