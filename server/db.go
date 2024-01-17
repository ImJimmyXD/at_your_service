package main

import (
	"context"
	"fmt"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"
	// ... other imports as needed
)

func ConnectToDB() (*mongo.Client, error) {
	clientOptions := options.Client().ApplyURI("mongodb://localhost:27017")
	client, err := mongo.Connect(context.TODO(), clientOptions)
	if err != nil {
		return nil, err
	}
	return client, nil
}

// CheckOrCreateDatabase checks if the 'users' database exists, and creates it if it doesn't
func CheckOrCreateDatabase(client *mongo.Client) error {
	databases, err := client.ListDatabaseNames(context.TODO(), bson.M{})
	if err != nil {
		return fmt.Errorf("error listing database names: %v", err)
	}

	dbExists := false
	for _, dbName := range databases {
		if dbName == "users" {
			dbExists = true
			break
		}
	}

	if dbExists {
		fmt.Println("Database 'users' already exists")
		return nil
	}

	// Creating a dummy document to insert
	dummyDocument := bson.M{"name": "initial_document"}

	collection := client.Database("users").Collection("users_collection")
	_, err = collection.InsertOne(context.TODO(), dummyDocument)
	if err != nil {
		return fmt.Errorf("error creating initial document in 'users' database: %v", err)
	}

	fmt.Println("Database 'users' created with a new collection")
	return nil
}

func CreateUser(client *mongo.Client, user User) error {
	collection := client.Database("users").Collection("users_collection")

	// Hash and salt the password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	user.Password = string(hashedPassword)

	_, err = collection.InsertOne(context.TODO(), user)
	return err
}

// ... other CRUD functions
