package main

import (
	"fmt"
	"os"

	"product/api"
	"product/spec"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	productStore := api.NewProductStore()

	e := echo.New()
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowMethods: []string{echo.GET, echo.DELETE, echo.PUT, echo.POST},
		AllowOrigins: []string{"*"},
		AllowCredentials: true,
		AllowHeaders: []string{"*"},
	}))

	spec.RegisterHandlers(e, productStore)

	port, ok := os.LookupEnv("SERVICE_PORT")
	if !ok {
		port = "8081"
	}

	err := e.Start(":" + port)
	if err != nil {
		fmt.Printf("Error starting server om port '%s': %s.", port, err)
		return
	}
}
