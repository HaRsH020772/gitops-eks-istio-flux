package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

// version is stamped at build time via -ldflags "-X main.version=..."
var version = "dev"

type response struct {
	App      string `json:"app"`
	Message  string `json:"message"`
	Version  string `json:"version"`
	Hostname string `json:"hostname"`
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	hostname, _ := os.Hostname()
	message := os.Getenv("APP_MESSAGE")
	if message == "" {
		message = "Hello from the weekend CI/CD pipeline!"
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response{
		App:      "demo-app",
		Message:  message,
		Version:  version,
		Hostname: hostname,
	})
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("ok"))
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", rootHandler)
	mux.HandleFunc("/healthz", healthHandler)

	log.Printf("demo-app %s listening on :%s", version, port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatal(err)
	}
}
