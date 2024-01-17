package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"golang.org/x/crypto/bcrypt"
	"log"
	"net/http"
)

func signupHandler(client *mongo.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			http.Error(w, "Only POST method is accepted", http.StatusMethodNotAllowed)
			return
		}

		var user User
		err := json.NewDecoder(r.Body).Decode(&user)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		err = CreateUser(client, user)
		if err != nil {
			http.Error(w, "Failed to create user", http.StatusInternalServerError)
			return
		}

		_, err = fmt.Fprintf(w, "User created successfully")
		if err != nil {
			return
		}
	}
}

func signinHandler(client *mongo.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Make sure you're accepting only POST requests
		if r.Method != "POST" {
			http.Error(w, "Only POST method is accepted", http.StatusMethodNotAllowed)
			return
		}

		var user User
		// Decode the request body into the user struct
		err := json.NewDecoder(r.Body).Decode(&user)
		if err != nil {
			log.Printf("Error decoding request body: %v", err)
			http.Error(w, "Error decoding request body", http.StatusBadRequest)
			return
		}

		// Log the email that is being used to sign in for debugging
		log.Printf("Attempting to find user with email: %s", user.Email)

		// Find the user in the database by email
		collection := client.Database("users").Collection("users_collection")
		var foundUser User
		err = collection.FindOne(context.TODO(), bson.M{"email": user.Email}).Decode(&foundUser)
		if err != nil {
			if errors.Is(err, mongo.ErrNoDocuments) {
				log.Printf("User not found with email: %s", user.Email)
				http.Error(w, "User not found", http.StatusUnauthorized)
			} else {
				log.Printf("Error finding user: %v", err)
				http.Error(w, "Error while finding user", http.StatusInternalServerError)
			}
			return
		}

		// Log for debugging the found user
		log.Printf("User found with email: %s", foundUser.Email)

		// Compare the provided password with the stored hash
		err = bcrypt.CompareHashAndPassword([]byte(foundUser.Password), []byte(user.Password))
		if err != nil {
			log.Printf("Invalid password for user: %s", user.Email)
			http.Error(w, "Invalid credentials", http.StatusUnauthorized)
			return
		}

		// If all checks out, the user is signed in successfully
		log.Printf("User signed in: %s", user.Email)
		_, err = fmt.Fprintf(w, "Signin successful")
		if err != nil {
			return
		}
	}
}

func readUserHandler(client *mongo.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "GET" {
			http.Error(w, "Only GET method is accepted", http.StatusMethodNotAllowed)
			return
		}

		email := r.URL.Query().Get("email")
		if email == "" {
			http.Error(w, "Email query parameter is required", http.StatusBadRequest)
			return
		}

		collection := client.Database("users").Collection("users_collection")
		var user User
		err := collection.FindOne(context.TODO(), bson.M{"email": email}).Decode(&user)
		if err != nil {
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}

		user.Password = "" // Do not return the password hash
		err = json.NewEncoder(w).Encode(user)
		if err != nil {
			fmt.Println("Error when encoding password!")
			return
		}
	}
}

func updateUserHandler(client *mongo.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "PUT" {
			http.Error(w, "Only PUT method is accepted", http.StatusMethodNotAllowed)
			return
		}

		var user User
		err := json.NewDecoder(r.Body).Decode(&user)
		if err != nil {
			http.Error(w, "Error decoding request body", http.StatusBadRequest)
			return
		}

		collection := client.Database("users").Collection("users_collection")
		filter := bson.M{"email": user.Email}
		update := bson.M{"$set": user}

		_, err = collection.UpdateOne(context.TODO(), filter, update)
		if err != nil {
			http.Error(w, "Failed to update user", http.StatusInternalServerError)
			return
		}

		_, err = fmt.Fprintf(w, "User updated successfully")
		if err != nil {
			fmt.Println("User was not updated successfully!")
			return
		}
	}
}

func deleteUserHandler(client *mongo.Client) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Ensure you're using the DELETE method
		if r.Method != "DELETE" {
			http.Error(w, "Only DELETE method is accepted", http.StatusMethodNotAllowed)
			return
		}

		// Extract the email from the query parameter
		email := r.URL.Query().Get("email")
		if email == "" {
			http.Error(w, "Email query parameter is required", http.StatusBadRequest)
			return
		}

		// Connect to the collection
		collection := client.Database("users").Collection("users_collection")

		// Perform the delete operation
		result, err := collection.DeleteOne(context.TODO(), bson.M{"email": email})
		if err != nil {
			// Handle error
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Check if a document was actually deleted
		if result.DeletedCount == 0 {
			http.Error(w, "No user found with the given email", http.StatusNotFound)
			return
		}

		// Send a success message
		_, err = fmt.Fprintf(w, "User deleted successfully")
		if err != nil {
			return
		}
	}
}

// ... other handlers
