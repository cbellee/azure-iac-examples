package main

import (
	"context"
	"fmt"
	"time"

	eventhub "github.com/Azure/azure-event-hubs-go/v2"
)

func main() {
	connStr := "Endpoint=sb://cbellee-namespace-1.servicebus.windows.net/;SharedAccessKeyName=send_listen_policy;SharedAccessKey=PsHXZIslD4b78N2ZlDXn72+wKtBXhA1pq7iSXr2I7Fk=;EntityPath=ehcbellee1"
	hub, err := eventhub.NewHubFromConnectionString(connStr)

	if err != nil {
		fmt.Println(err)
		return
	}

	i := 0
	for {
		ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
		defer cancel()

		msg := fmt.Sprintf("hello world, %d", i)
		err = hub.Send(ctx, eventhub.NewEventFromString(msg))
		if err != nil {
			fmt.Println(err)
			return
		}
		
		fmt.Printf("sent message: %s \n", msg)
		time.Sleep(1 * time.Second)
		i++
	}
}
