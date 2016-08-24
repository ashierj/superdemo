package api

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

func Block(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := &blocker{rw: w}
		defer rw.Flush()
		h.ServeHTTP(rw, r)
	})
}

type blocker struct {
	rw       http.ResponseWriter
	hijacked bool
	status   int
}

// Prevent internal API responses intended for gitlab-workhorse from
// leaking to the end user
func (b *blocker) Header() http.Header {
	return b.rw.Header()
}

func (b *blocker) Write(data []byte) (int, error) {
	if b.status == 0 {
		b.WriteHeader(http.StatusOK)
	}
	if b.hijacked {
		return 0, nil
	}

	return b.rw.Write(data)
}

func (b *blocker) WriteHeader(status int) {
	if b.status != 0 {
		return
	}

	if b.Header().Get("Content-Type") == ResponseContentType {
		b.status = 500
		b.Header().Del("Content-Length")
		b.hijacked = true
		helper.Fail500(b.rw, fmt.Errorf("api.blocker: forbidden content-type: %q", ResponseContentType))
		return
	}

	b.status = status
	b.rw.WriteHeader(b.status)
}

func (b *blocker) Flush() {
	b.WriteHeader(http.StatusOK)
}
