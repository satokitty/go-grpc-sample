package metrics

import (
	"log"
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

func init() {
	promauto.NewCounterFunc(prometheus.CounterOpts{
		Name: "greeter_sample_counter_func",
	}, func() float64 {
		log.Println("Call counterfunc")
		return float64(1)
	})
}

var metricCallCount = promauto.NewCounter(prometheus.CounterOpts{
	Name: "greeter_sample_retrieve_counter",
})

func WithRetrieveMetrics(handler http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		log.Println("Call metrics endpoint.")
		retrieveMetrics()
		handler.ServeHTTP(w, r)
	}
}

func retrieveMetrics() {
	log.Println("Call retrieveMetrics()")
	metricCallCount.Inc()
}
