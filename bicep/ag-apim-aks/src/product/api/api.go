package api

import (
	"fmt"
	"net/http"
	spec "product/spec"
	"sync"

	"github.com/labstack/echo/v4"
)

type ProductStore struct {
	Products map[int64]spec.Product
	NextId int64
	Lock   sync.Mutex
}

func NewProductStore() *ProductStore {
	return &ProductStore{
		Products: make(map[int64]spec.Product),
		NextId: 1000,
	}
}

func sendProductStoreError(ctx echo.Context, code int, message string) error {
	petErr := spec.Error{
		Code:    int32(code),
		Message: message,
	}
	err := ctx.JSON(code, petErr)
	return err
}

// Get Products
// (GET /products)
func (o *ProductStore) GetProducts(ctx echo.Context) error {
	o.Lock.Lock()
	defer o.Lock.Unlock()

	result := []spec.Product{}

	for _, product := range o.Products {
		result = append(result, product)
	}

	return ctx.JSON(http.StatusOK, result)
}

// Get Product
// (GET /products/{id})
func (o *ProductStore) GetProduct(ctx echo.Context, id int) error {
	o.Lock.Lock()
	defer o.Lock.Unlock()

	product, found := o.Products[int64(id)]
	if !found {
		return sendProductStoreError(ctx, http.StatusNotFound,
			fmt.Sprintf("Product ID: '%d' not found", id))
	}
	return ctx.JSON(http.StatusOK, product)
}

// New Product
// (POST /products)
func (o *ProductStore) NewProduct(ctx echo.Context) error {
	var newProduct spec.NewProduct
	err := ctx.Bind(&newProduct)
	if err != nil {
		return sendProductStoreError(ctx, http.StatusBadRequest, "Invalid format for NewProduct")
	}

	o.Lock.Lock()
	defer o.Lock.Unlock()

	var product spec.Product
	product.ID = int(o.NextId)
	product.Name = newProduct.Name
	product.Description = newProduct.Description
	o.NextId = o.NextId + 1

	o.Products[int64(product.ID)] = product

	return ctx.JSON(http.StatusCreated, product)
}

// Delete Product
// (DELETE /products/{id})
func (o *ProductStore) DeleteProduct(ctx echo.Context, id int) error {
	o.Lock.Lock()
	defer o.Lock.Unlock()

	_, found := o.Products[int64(id)]
	if !found {
		return sendProductStoreError(ctx, http.StatusNotFound,
			fmt.Sprintf("Product ID: '%d' not found", id))
	}

	delete(o.Products, int64(id))
	return ctx.NoContent(http.StatusNoContent)
}

// Update Product
// (PUT /products/{id})
func (o *ProductStore) UpdateProduct(ctx echo.Context, id int) error {
	o.Lock.Lock()
	defer o.Lock.Unlock()

	var updateProduct spec.NewProduct
	err := ctx.Bind(&updateProduct)
	if err != nil {
		return sendProductStoreError(ctx, http.StatusBadRequest, "Invalid format for Product")
	}

	product, found := o.Products[int64(id)]
	if !found {
		return sendProductStoreError(ctx, http.StatusNotFound,
			fmt.Sprintf("Product ID: '%d' not found", id))
	}

	product.Description = updateProduct.Description
	product.Name = updateProduct.Name
	o.Products[int64(id)] = product

	return ctx.JSON(http.StatusOK, product)
}

// Get Swagger
// (GET /swagger)
func (o *ProductStore) GetSwagger(ctx echo.Context) error {
	s, err := spec.GetSwagger()
	if err != nil {
		return sendProductStoreError(ctx, http.StatusNotFound,
			fmt.Sprintf("Err serving swagger endpoint: '%s' not found", err))
	}

	return ctx.JSON(http.StatusOK, s)
}
