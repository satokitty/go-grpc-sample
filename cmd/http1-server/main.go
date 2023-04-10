package main

import (
	"context"
	"errors"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"
)

type contextKey struct{}

var sessionContextKey = contextKey{}

type Session struct {
	username string
}

type SessionCache struct {
	mu      sync.RWMutex
	session *Session
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/test", func(writer http.ResponseWriter, request *http.Request) {
		cache, ok := request.Context().Value(sessionContextKey).(*SessionCache)
		if !ok {
			log.Println("SessionCache not stored in Context")
			return
		}
		if cache.session == nil {
			log.Println("Create session cache")
			cache.session = &Session{
				username: request.FormValue("name"),
			}
		}

		log.Printf("session value: username=%s\n", cache.session.username)
	})

	server := &http.Server{
		Addr:    ":8080",
		Handler: mux,
		ConnContext: func(ctx context.Context, c net.Conn) context.Context {
			return context.WithValue(ctx, sessionContextKey, &SessionCache{})
		},
	}

	signals := make(chan os.Signal, 1)
	signal.Notify(signals, os.Interrupt, syscall.SIGTERM)
	go func() {
		log.Printf("HTTP1 Start server at %s...\n", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalln("Server closed with error:", err)
		}
	}()

	log.Printf("SIGNAL %d received, shutting down...\n", <-signals)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		log.Fatalln("Shutdown failed:", err)
	}
	log.Println("Server shutdown.")
}
