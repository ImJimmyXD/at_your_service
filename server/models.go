package main

type User struct {
	Email    string `json:"email" bson:"email"`
	Password string `json:"password" bson:"password"`
	Type     string `json:"type,omitempty" bson:"type,omitempty"`
}

type Order struct {
	Address     string `json:"address" bson:"address"`
	Destination string `json:"destination" bson:"destination"`
	PhoneNumber string `json:"phoneNumber" bson:"phoneNumber"`
	Message     string `json:"message" bson:"message"`
	Type        string `json:"type,omitempty" bson:"type,omitempty"`
	OrderID     string `json:"orderID" bson:"orderID"`
	Email       string `json:"email" bson:"email"`
	Status      string `json:"status" bson:"status"`
}
