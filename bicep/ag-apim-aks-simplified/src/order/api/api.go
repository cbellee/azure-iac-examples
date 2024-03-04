package api

import (
	"fmt"
	"net/http"
	spec "order/spec"
	"sync"

	"github.com/labstack/echo/v4"
)

type OrderStore struct {
	Orders map[int64]spec.Order
	NextId int64
	Lock   sync.Mutex
}

func NewOrderStore() *OrderStore {
	return &OrderStore{
		Orders: make(map[int64]spec.Order),
		NextId: 1000,
	}
}

func sendOrderStoreError(ctx echo.Context, code int, message string) error {
	petErr := spec.Error{
		Code:    int32(code),
		Message: message,
	}
	err := ctx.JSON(code, petErr)
	return err
}

// Get Orders
// (GET /orders)
func (o *OrderStore) GetOrders(ctx echo.Context) error {
	o.Lock.Lock()
	defer o.Lock.Unlock()

	result := []spec.Order{}

	for _, order := range o.Orders {
		result = append(result, order)
	}
	
	return ctx.JSON(http.StatusOK, result)
}

// Get Order
// (GET /orders/{id})
func (o *OrderStore) GetOrder(ctx echo.Context, id int) error {
	o.Lock.Lock()
	defer o.Lock.Unlock()

	order, found := o.Orders[int64(id)]
	if !found {
		return sendOrderStoreError(ctx, http.StatusNotFound,
			fmt.Sprintf("Order ID: '%d' not found", id))
	}
	return ctx.JSON(http.StatusOK, order)
}

// New Order
// (POST /orders)
func (o *OrderStore) NewOrder(ctx echo.Context) error {
	var newOrder spec.NewOrder
	err := ctx.Bind(&newOrder)
	if err != nil {
		return sendOrderStoreError(ctx, http.StatusBadRequest, "Invalid format for NewOrder")
	}

	o.Lock.Lock()
	defer o.Lock.Unlock()

	var order spec.Order
	order.ID = int(o.NextId)
	order.Name = newOrder.Name
	order.Description = newOrder.Description
	o.NextId = o.NextId + 1

	o.Orders[int64(order.ID)] = order

	return ctx.JSON(http.StatusCreated, order)
}

// Delete Order
// (DELETE /orders/{id})
func (o *OrderStore) DeleteOrder(ctx echo.Context, id int) error {
	o.Lock.Lock()
	defer o.Lock.Unlock()

	_, found := o.Orders[int64(id)]
	if !found {
		return sendOrderStoreError(ctx, http.StatusNotFound,
			fmt.Sprintf("Order ID: '%d' not found", id))
	}

	delete(o.Orders, int64(id))
	return ctx.NoContent(http.StatusNoContent)
}

// Update Order
// (PUT /orders/{id})
func (o *OrderStore) UpdateOrder(ctx echo.Context, id int) error {
	o.Lock.Lock()
	defer o.Lock.Unlock()

	var updateOrder spec.NewOrder
	err := ctx.Bind(&updateOrder)
	if err != nil {
		return sendOrderStoreError(ctx, http.StatusBadRequest, "Invalid format for Order")
	}

	order, found := o.Orders[int64(id)]
	if !found {
		return sendOrderStoreError(ctx, http.StatusNotFound,
			fmt.Sprintf("Order ID: '%d' not found", id))
	}

	order.Description = updateOrder.Description
	order.Name = updateOrder.Name
	o.Orders[int64(id)] = order

	return ctx.JSON(http.StatusOK, order)
}

// Get Swagger
// (GET /swagger)
func (o *OrderStore) GetSwagger(ctx echo.Context) error {
	s, err := spec.GetSwagger()
	if err != nil {
		return sendOrderStoreError(ctx, http.StatusNotFound,
			fmt.Sprintf("Err serving swagger endpoint: '%s' not found", err))
	}

	return ctx.JSON(http.StatusOK, s)
}
