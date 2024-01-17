package main

import (
	"context"
	"fmt"
	"go.mongodb.org/mongo-driver/mongo"
	"log"
	"net/http"
)

func main() {
	client, err := ConnectToDB()
	if err != nil {
		log.Fatal(err)
	}
	defer func(client *mongo.Client, ctx context.Context) {
		err := client.Disconnect(ctx)
		if err != nil {
			fmt.Println("Could not disconnect...")
			return
		}
	}(client, context.TODO())

	err = CheckOrCreateDatabase(client)
	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/signup", signupHandler(client))
	http.HandleFunc("/signin", signinHandler(client))
	http.HandleFunc("/read", readUserHandler(client))
	http.HandleFunc("/update", updateUserHandler(client))
	http.HandleFunc("/delete", deleteUserHandler(client))
	// ... other route handlers

	fmt.Println("Server is running on port 8080...")
	err = http.ListenAndServe(":8080", nil)
	if err != nil {
		fmt.Println("Server cannot listen to port 8080...")
		return
	}
}
