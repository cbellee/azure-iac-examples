package models

import (
	"time"
)

// Checkin is a struct
type Checkin struct {
	ID                string    `json:"id"`
	UserID            string    `json:"user_id"`
	LocationID        string    `json:"location_id"`
	CheckInTimeStamp  time.Time `json:"checkin_timestamp"`
}

type Checkout struct {
	ID                string    `json:"id"`
	UserID            string    `json:"user_id"`
	LocationID        string    `json:"location_id"`
	CheckOutTimeStamp time.Time `json:"checkout_timestamp"`
}