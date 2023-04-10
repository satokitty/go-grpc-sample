package main

import (
	"context"
	"crypto/tls"
	"log"
	"net"
	"net/http"
	"os"

	greetv1 "examples/grpc-greeter/internal/gen/api/greet/v1"
	"examples/grpc-greeter/internal/gen/api/greet/v1/greetv1connect"

	"github.com/bufbuild/connect-go"
	"golang.org/x/net/http2"
)

func main() {
	log.Println("test with insecure http2 client")
	client := greetv1connect.NewGreetServiceClient(
		newInsecureClient(),
		getServerHost(),
		connect.WithGRPC(),
	)
	res, err := client.Greet(
		context.Background(),
		connect.NewRequest(&greetv1.GreetRequest{
			Name: "Jane",
		}),
	)
	if err != nil {
		log.Println(err)
		return
	}
	log.Println(res.Msg.Greeting)

}

func newInsecureClient() *http.Client {
	return &http.Client{
		Transport: &http2.Transport{
			AllowHTTP: true,
			DialTLS: func(network, addr string, _ *tls.Config) (net.Conn, error) {
				return net.Dial(network, addr)
			},
		},
	}
}

func getServerHost() string {
	host := os.Getenv("GREETER_HOST")
	if host == "" {
		return "http://localhost:8080"
	}
	return host
}
