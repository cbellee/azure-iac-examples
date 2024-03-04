package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	fiber "github.com/gofiber/fiber/v2"
)

var (
	ScheduledEventsMetaDataEndpointUri = "http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01"
	InstanceMetaDataEndpointUri        = "http://169.254.169.254/metadata/instance?api-version=2020-07-01"
	PollFrequencyInSeconds             = 1
)

func main() {
	app := fiber.New()

	host, err := os.Hostname()
	if err != nil {
		fmt.Printf("error getting hostname: %s", err.Error())
	}

	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString(fmt.Sprintf("Reply from hostname: %s \n", host))
	})

	res, err := GetVmMetadata(InstanceMetaDataEndpointUri)
	if err != nil {
		fmt.Printf("Error getting vm metadata: %s", err)
	}
	fmt.Printf("Instance metadata: %d\n", res)

	go PollVmMetadataEndpoint(ScheduledEventsMetaDataEndpointUri, PollFrequencyInSeconds)

	log.Fatal(app.Listen(":3000"))
}

func PollVmMetadataEndpoint(endpointUri string, pollFrequency int) {
	for {
		req, err := http.NewRequest("GET", endpointUri, nil)
		if err != nil {
			fmt.Printf("error creating new http request %s", err)
		}

		req.Header.Add("Metadata", "true")
		res, err := http.DefaultClient.Do(req)
		if err != nil {
			fmt.Printf("error sending http request to %s:  %s", endpointUri, err)
			break
		}

		bytes, err := io.ReadAll(res.Body)
		if err != nil {
			fmt.Printf("error reading response body: %s", err)
		}

		fmt.Printf("Response body: %s\n", string(bytes))
		time.Sleep(time.Duration(pollFrequency) * time.Second)
	}
}

func GetVmMetadata(endpointUri string) (response []byte, err error) {
	req, err := http.NewRequest("GET", endpointUri, nil)
	if err != nil {
		fmt.Printf("error creating new http request %s", err)
		return nil, err
	}

	req.Header.Add("Metadata", "true")
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		fmt.Printf("error sending http request to %s:  %s", endpointUri, err)
		return nil, err
	}

	byteArr, err := io.ReadAll(res.Body)
	if err != nil {
		fmt.Printf("error reading response body: %s", err)
		return nil, err
	}

	return byteArr, nil
}
