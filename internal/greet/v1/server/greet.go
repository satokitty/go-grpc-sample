package server

import (
	"context"
	"fmt"
	"log"
	"os"

	greetv1 "examples/grpc-greeter/gen/api/greet/v1"

	"github.com/bufbuild/connect-go"
)

type GreetServer struct{}

func (s *GreetServer) Greet(
	ctx context.Context,
	req *connect.Request[greetv1.GreetRequest],
) (*connect.Response[greetv1.GreetResponse], error) {
	log.Println("Request headers: ", req.Header())
	hostname, err := os.Hostname()
	if err != nil {
		hostname = ""
	}
	res := connect.NewResponse(&greetv1.GreetResponse{
		Greeting: fmt.Sprintf("Hello, %s! from %s", req.Msg.Name, hostname),
	})
	res.Header().Set("Greet-Version", "v1")
	return res, nil
}
