package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/golang-jwt/jwt/v4"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"golang.org/x/crypto/bcrypt"
	"log"
	"net/http"
	"os"
	"time"
)

func getJWTKey() []byte {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		log.Fatal("JWT_SECRET is not set")
	}
	return []byte(secret)
}

var jwtKey = getJWTKey()

// Claims struct which will be encoded to a JWT.
// Make sure to use jwt.RegisteredClaims if you want to use the standardized claim names.
type Claims struct {
	Email string `json:"email"`
	jwt.RegisteredClaims
}

func generateJWT(email string) (string, error) {
	// Set the expiration time of the token
	// Here, we have kept it as 24 hours
	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &Claims{
		Email: email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			// IssuedAt and Issuer are also commonly included
		},
	}

	// Declare the token with the algorithm used for signing and the claims
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// Create the JWT string
	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		return "", err
	}
	return tokenString, nil
}

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

		// Log the creation of the user
		log.Printf("User created successfully: Email - %s", user.Email)

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

		// Generate JWT token
		tokenString, err := generateJWT(foundUser.Email)
		if err != nil {
			log.Printf("Token generation failed: %v", err)
			http.Error(w, "Error generating token", http.StatusInternalServerError)
			return
		}
		// Create a response struct
		type SigninResponse struct {
			Message string `json:"message"`
			Token   string `json:"token,omitempty"` // Include the token if you have one
		}

		// Create a success response
		response := SigninResponse{
			Message: "Signin successful",
			Token:   tokenString,
		}

		// Send the response as JSON
		w.Header().Set("Content-Type", "application/json")
		err = json.NewEncoder(w).Encode(response)
		if err != nil {
			log.Printf("Error sending response: %v", err)
			http.Error(w, "Error sending response", http.StatusInternalServerError)
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
