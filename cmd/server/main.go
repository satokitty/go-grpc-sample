package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	grpchealth "github.com/bufbuild/connect-grpchealth-go"
	grpcreflect "github.com/bufbuild/connect-grpcreflect-go"
	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"

	"examples/grpc-greeter/internal/gen/api/greet/v1/greetv1connect"
	"examples/grpc-greeter/internal/greet/v1/server"
)

func main() {
	mux := setupHandler()
	server := &http.Server{
		Addr:              ":8080",
		Handler:           h2c.NewHandler(mux, &http2.Server{}),
		ReadHeaderTimeout: time.Second,
		ReadTimeout:       5 * time.Second,
		WriteTimeout:      5 * time.Second,
		MaxHeaderBytes:    8 * 1024,
	}

	signals := make(chan os.Signal, 1)
	signal.Notify(signals, os.Interrupt, syscall.SIGTERM)
	go func() {
		log.Printf("Start server at %s...\n", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalln("Server closed with error:", err)
		}
	}()

	log.Printf("SIGNAL %d received, shutting down...\n", <-signals)
	if err := shutdown(server); err != nil {
		log.Fatalln("Graceful shutdown failed:", err)
	}
}

func setupHandler() *http.ServeMux {
	mux := http.NewServeMux()
	mux.Handle(greetv1connect.NewGreetServiceHandler(&server.GreetServer{}))

	checker := grpchealth.NewStaticChecker(greetv1connect.GreetServiceName)
	mux.Handle(grpchealth.NewHandler(checker))

	reflector := grpcreflect.NewStaticReflector(greetv1connect.GreetServiceName)
	mux.Handle(grpcreflect.NewHandlerV1(reflector))
	mux.Handle(grpcreflect.NewHandlerV1Alpha(reflector))

	return mux
}

func shutdownGracePeriod() time.Duration {
	period, err := strconv.Atoi(os.Getenv("GRACE_SHUTDOWN_PERIOD"))
	if err != nil {
		return 10 * time.Second
	}
	return time.Duration(period) * time.Second
}

func shutdown(server *http.Server) error {
	period := shutdownGracePeriod()
	log.Printf("Wait %s before shutting down...", period.String())
	time.Sleep(period)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.Shutdown(ctx); err != nil {
		return err
	}
	log.Println("Server shutdown.")
	return nil
}
