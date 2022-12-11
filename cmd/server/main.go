package main

import (
	"fmt"
	"net/http"

	"golang.org/x/net/http2"
	"golang.org/x/net/http2/h2c"

	"examples/grpc-greeter/gen/api/greet/v1/greetv1connect"
	"examples/grpc-greeter/internal/greet/v1/server"
)

func main() {
	greeter := &server.GreetServer{}
	mux := http.NewServeMux()
	path, handler := greetv1connect.NewGreetServiceHandler(greeter)
	mux.Handle(path, handler)

	fmt.Println("Start server...")

	http.ListenAndServe(
		":8080",
		h2c.NewHandler(mux, &http2.Server{}),
	)
}
