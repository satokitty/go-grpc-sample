package server

import (
	"context"
	"fmt"
	"log"
	"os"

	greetv1 "examples/grpc-greeter/internal/gen/api/greet/v1"

	"github.com/bufbuild/connect-go"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

type GreetServer struct{}

var greetCallCount = promauto.NewCounter(prometheus.CounterOpts{
	Name: "greeter_greet_call_total",
	Help: "The total number of times greet has been called",
})

func (s *GreetServer) Greet(
	ctx context.Context,
	req *connect.Request[greetv1.GreetRequest],
) (*connect.Response[greetv1.GreetResponse], error) {
	// 呼び出しカウント
	greetCallCount.Inc()

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
