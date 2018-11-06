package correlation

import (
	"net/http"
)

const propagationHeader = "X-Request-ID"

// injectRequest will pass the CorrelationId through to a downstream http request
// for propagation
func injectRequest(req *http.Request) {
	correlationID := ExtractFromContext(req.Context())
	if correlationID != "" {
		req.Header.Set(propagationHeader, correlationID)
	}
}

type instrumentedRoundTripper struct {
	delegate http.RoundTripper
}

func (c instrumentedRoundTripper) RoundTrip(req *http.Request) (res *http.Response, e error) {
	injectRequest(req)
	return c.delegate.RoundTrip(req)
}

// NewInstrumentedRoundTripper acts as a "client-middleware" for outbound http requests
// adding instrumentation to the outbound request and then delegating to the underlying
// transport
func NewInstrumentedRoundTripper(delegate http.RoundTripper) http.RoundTripper {
	return &instrumentedRoundTripper{delegate: delegate}
}
