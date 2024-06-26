// Package spec provides primitives to interact with the openapi HTTP API.
//
// Code generated by github.com/deepmap/oapi-codegen version v1.11.0 DO NOT EDIT.
package spec

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"fmt"
	"net/http"
	"net/url"
	"path"
	"strings"

	"github.com/deepmap/oapi-codegen/pkg/runtime"
	"github.com/getkin/kin-openapi/openapi3"
	"github.com/labstack/echo/v4"
)

// Error defines model for Error.
type Error struct {
	// Error code
	Code int32 `json:"code"`

	// Error message
	Message string `json:"message"`
}

// HTTPValidationError defines model for HTTPValidationError.
type HTTPValidationError struct {
	Detail *[]ValidationError `json:"detail,omitempty"`
}

// NewOrder defines model for NewOrder.
type NewOrder struct {
	Description *string `json:"Description,omitempty"`
	Name        string  `json:"Name"`
}

// Order defines model for Order.
type Order struct {
	Description *string `json:"Description,omitempty"`
	ID          int     `json:"ID"`
	Name        string  `json:"Name"`
}

// ValidationError defines model for ValidationError.
type ValidationError struct {
	Loc  []interface{} `json:"loc"`
	Msg  string        `json:"msg"`
	Type string        `json:"type"`
}

// NewOrderJSONBody defines parameters for NewOrder.
type NewOrderJSONBody = NewOrder

// UpdateOrderJSONBody defines parameters for UpdateOrder.
type UpdateOrderJSONBody = NewOrder

// NewOrderJSONRequestBody defines body for NewOrder for application/json ContentType.
type NewOrderJSONRequestBody = NewOrderJSONBody

// UpdateOrderJSONRequestBody defines body for UpdateOrder for application/json ContentType.
type UpdateOrderJSONRequestBody = UpdateOrderJSONBody

// ServerInterface represents all server handlers.
type ServerInterface interface {
	// Get Orders
	// (GET /orders)
	GetOrders(ctx echo.Context) error
	// New Order
	// (POST /orders)
	NewOrder(ctx echo.Context) error
	// Delete Order
	// (DELETE /orders/{id})
	DeleteOrder(ctx echo.Context, id int) error
	// Get Order
	// (GET /orders/{id})
	GetOrder(ctx echo.Context, id int) error
	// Update Order
	// (PUT /orders/{id})
	UpdateOrder(ctx echo.Context, id int) error
	// Get Swagger
	// (GET /swagger)
	GetSwagger(ctx echo.Context) error
}

// ServerInterfaceWrapper converts echo contexts to parameters.
type ServerInterfaceWrapper struct {
	Handler ServerInterface
}

// GetOrders converts echo context to params.
func (w *ServerInterfaceWrapper) GetOrders(ctx echo.Context) error {
	var err error

	// Invoke the callback with all the unmarshalled arguments
	err = w.Handler.GetOrders(ctx)
	return err
}

// NewOrder converts echo context to params.
func (w *ServerInterfaceWrapper) NewOrder(ctx echo.Context) error {
	var err error

	// Invoke the callback with all the unmarshalled arguments
	err = w.Handler.NewOrder(ctx)
	return err
}

// DeleteOrder converts echo context to params.
func (w *ServerInterfaceWrapper) DeleteOrder(ctx echo.Context) error {
	var err error
	// ------------- Path parameter "id" -------------
	var id int

	err = runtime.BindStyledParameterWithLocation("simple", false, "id", runtime.ParamLocationPath, ctx.Param("id"), &id)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Invalid format for parameter id: %s", err))
	}

	// Invoke the callback with all the unmarshalled arguments
	err = w.Handler.DeleteOrder(ctx, id)
	return err
}

// GetOrder converts echo context to params.
func (w *ServerInterfaceWrapper) GetOrder(ctx echo.Context) error {
	var err error
	// ------------- Path parameter "id" -------------
	var id int

	err = runtime.BindStyledParameterWithLocation("simple", false, "id", runtime.ParamLocationPath, ctx.Param("id"), &id)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Invalid format for parameter id: %s", err))
	}

	// Invoke the callback with all the unmarshalled arguments
	err = w.Handler.GetOrder(ctx, id)
	return err
}

// UpdateOrder converts echo context to params.
func (w *ServerInterfaceWrapper) UpdateOrder(ctx echo.Context) error {
	var err error
	// ------------- Path parameter "id" -------------
	var id int

	err = runtime.BindStyledParameterWithLocation("simple", false, "id", runtime.ParamLocationPath, ctx.Param("id"), &id)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Invalid format for parameter id: %s", err))
	}

	// Invoke the callback with all the unmarshalled arguments
	err = w.Handler.UpdateOrder(ctx, id)
	return err
}

// GetSwagger converts echo context to params.
func (w *ServerInterfaceWrapper) GetSwagger(ctx echo.Context) error {
	var err error

	// Invoke the callback with all the unmarshalled arguments
	err = w.Handler.GetSwagger(ctx)
	return err
}

// This is a simple interface which specifies echo.Route addition functions which
// are present on both echo.Echo and echo.Group, since we want to allow using
// either of them for path registration
type EchoRouter interface {
	CONNECT(path string, h echo.HandlerFunc, m ...echo.MiddlewareFunc) *echo.Route
	DELETE(path string, h echo.HandlerFunc, m ...echo.MiddlewareFunc) *echo.Route
	GET(path string, h echo.HandlerFunc, m ...echo.MiddlewareFunc) *echo.Route
	HEAD(path string, h echo.HandlerFunc, m ...echo.MiddlewareFunc) *echo.Route
	OPTIONS(path string, h echo.HandlerFunc, m ...echo.MiddlewareFunc) *echo.Route
	PATCH(path string, h echo.HandlerFunc, m ...echo.MiddlewareFunc) *echo.Route
	POST(path string, h echo.HandlerFunc, m ...echo.MiddlewareFunc) *echo.Route
	PUT(path string, h echo.HandlerFunc, m ...echo.MiddlewareFunc) *echo.Route
	TRACE(path string, h echo.HandlerFunc, m ...echo.MiddlewareFunc) *echo.Route
}

// RegisterHandlers adds each server route to the EchoRouter.
func RegisterHandlers(router EchoRouter, si ServerInterface) {
	RegisterHandlersWithBaseURL(router, si, "")
}

// Registers handlers, and prepends BaseURL to the paths, so that the paths
// can be served under a prefix.
func RegisterHandlersWithBaseURL(router EchoRouter, si ServerInterface, baseURL string) {

	wrapper := ServerInterfaceWrapper{
		Handler: si,
	}

	router.GET(baseURL+"/orders", wrapper.GetOrders)
	router.POST(baseURL+"/orders", wrapper.NewOrder)
	router.DELETE(baseURL+"/orders/:id", wrapper.DeleteOrder)
	router.GET(baseURL+"/orders/:id", wrapper.GetOrder)
	router.PUT(baseURL+"/orders/:id", wrapper.UpdateOrder)
	router.GET(baseURL+"/swagger", wrapper.GetSwagger)

}

// Base64 encoded, gzipped, json marshaled Swagger object
var swaggerSpec = []string{

	"H4sIAAAAAAAC/+xXUW/bLBT9K9b9vkeUZOme/LYp01Zpa6e120vVB2ZuXCobGOB1kcV/nwDbIYnTdG1V",
	"9SFPwfjCPfdw7iFuoZC1kgKFNZC3YIobrGkYftBaaj9QWirUlmOYLiRD/8vQFJory6WAPAZn4R2BpdQ1",
	"tZADF/ZkDgTsSmF8xBI1OAI1GkPLvRv1r4elxmouSnCOgMZfDdfIIL+CLmEffk3Aclthv896vfx5i4X1",
	"mT9dXn79QSvOqM+4p0iGlvLKj7jFOkz9r3EJOfw3XRM27diabu/n1jgWcacBCNWarkIdfcQYoBHcZ3h3",
	"rhmOgF2kBLZJ5vX0Do8EzmiNaXh4PsR3CEpYHkCNAH5WtKeLNPh0MSqqx5cUEiR17S3qoHIqWWzIhorV",
	"+RLyq3anpnangutEFZ9lQTfJ6JRDoDZlWuWXfb3ST7SbTZFd+tlDtPg6YqouMmHnoFr9ZlwsZZo7UJq9",
	"UxwI/EZtYrvPJm8mMw9VKhRUccjhZDKbeNNQ1N4ECqfSLw3DEq3/8YSH/KcMcviI9jxG+BKMksLEs5jP",
	"ZtGxhEURFlKlKh6Jnd6aqMDYxA/u9SiN5KS+dSmzAcRWqzuy5XEXTVGgMcumyvrFfsO38/k/wb0P5Zip",
	"jCBZh2SDczFc0qayzwZlb/JG4B+FhUWWYRdDwDR1TfUqHmtPqSOgpBk5+sR/vHjR2PeSrZ4N+rC922wP",
	"qxt0TxTbAzR2VM7jlHOGd1lPIentY9py5uLdXqHFXS0twnwvJ0U1rdEG37lqgfu03pGAgAjXDHAG25og",
	"SWG9PYSwbad3109Tz1Eaj5RGPORsMPF7L5RXL4OjibzA9RNun2ZEJt8Voy9rGMcb7ijOIM4ovfSSM3e0",
	"LOP31j5Pu+hCnnisB//3pl8BDzrc19TyPUnOOfc3AAD//x5ztyAdEQAA",
}

// GetSwagger returns the content of the embedded swagger specification file
// or error if failed to decode
func decodeSpec() ([]byte, error) {
	zipped, err := base64.StdEncoding.DecodeString(strings.Join(swaggerSpec, ""))
	if err != nil {
		return nil, fmt.Errorf("error base64 decoding spec: %s", err)
	}
	zr, err := gzip.NewReader(bytes.NewReader(zipped))
	if err != nil {
		return nil, fmt.Errorf("error decompressing spec: %s", err)
	}
	var buf bytes.Buffer
	_, err = buf.ReadFrom(zr)
	if err != nil {
		return nil, fmt.Errorf("error decompressing spec: %s", err)
	}

	return buf.Bytes(), nil
}

var rawSpec = decodeSpecCached()

// a naive cached of a decoded swagger spec
func decodeSpecCached() func() ([]byte, error) {
	data, err := decodeSpec()
	return func() ([]byte, error) {
		return data, err
	}
}

// Constructs a synthetic filesystem for resolving external references when loading openapi specifications.
func PathToRawSpec(pathToFile string) map[string]func() ([]byte, error) {
	var res = make(map[string]func() ([]byte, error))
	if len(pathToFile) > 0 {
		res[pathToFile] = rawSpec
	}

	return res
}

// GetSwagger returns the Swagger specification corresponding to the generated code
// in this file. The external references of Swagger specification are resolved.
// The logic of resolving external references is tightly connected to "import-mapping" feature.
// Externally referenced files must be embedded in the corresponding golang packages.
// Urls can be supported but this task was out of the scope.
func GetSwagger() (swagger *openapi3.T, err error) {
	var resolvePath = PathToRawSpec("")

	loader := openapi3.NewLoader()
	loader.IsExternalRefsAllowed = true
	loader.ReadFromURIFunc = func(loader *openapi3.Loader, url *url.URL) ([]byte, error) {
		var pathToFile = url.String()
		pathToFile = path.Clean(pathToFile)
		getSpec, ok := resolvePath[pathToFile]
		if !ok {
			err1 := fmt.Errorf("path not found: %s", pathToFile)
			return nil, err1
		}
		return getSpec()
	}
	var specData []byte
	specData, err = rawSpec()
	if err != nil {
		return
	}
	swagger, err = loader.LoadFromData(specData)
	if err != nil {
		return
	}
	return
}
