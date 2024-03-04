package main

import (
	"fmt"
	"log"
	"os"

	fiber "github.com/gofiber/fiber/v2"
)

func main() {
    app := fiber.New()

	host, err := os.Hostname()
	if err !=nil {
		_ = fmt.Errorf(err.Error())
	}

	str := fmt.Sprintf("Reply from hostname: %s \n", host)

    app.Get("/", func(c *fiber.Ctx) error {
        return c.SendString(str)
    })

    log.Fatal(app.Listen(":3000"))
}