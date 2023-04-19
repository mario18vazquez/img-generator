package main

import (
	"context"
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-kit/kit/log"
)

// This file should be the main 'service' executable.

func main() {
	var (
		_ = flag.String("dsn", os.Getenv("TEMPLATE_SERVICE_MYSQL_DSN"), "MySQL DSN to connect")
		// TODO: Please rename `TEMPLATE_SERVICE_LISTEN_ADDR` to be specific to the new service. Follow the naming scheme "<service_name>_LISTEN_ADDR" ("PAYMENT_SERVICE_LISTEN_ADDR" for payment-service)
		httpAddr = flag.String("http.addr", envString("TEMPLATE_SERVICE_LISTEN_ADDR", ":8080"), "HTTP listen address")
	)

	flag.Parse()
	logger := log.With(log.NewJSONLogger(os.Stdout), "name", "template-service")

	server := http.Server{Addr: *httpAddr}

	idleConnsClosed := make(chan struct{})
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, syscall.SIGINT, syscall.SIGTERM)
		<-sigint
		logger.Log(
			"message", "received shutdown signal. gracefully shutting down http server.",
			"severity", "NOTICE",
		)

		sdCtx, cancel := context.WithTimeout(context.Background(), time.Second*15)
		defer cancel()
		if err := server.Shutdown(sdCtx); err != nil {
			logger.Log(
				"message", "http server stopped",
				"err", err,
				"severity", "ERROR",
			)
		}

		close(idleConnsClosed)
	}()

	logger.Log(
		"message", fmt.Sprintf("Starting server on %v", *httpAddr),
		"severity", "info",
	)

	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		logger.Log(
			"message", "error starting server",
			"err", err,
			"severity", "ERROR",
		)
		os.Exit(1)
	}

	<-idleConnsClosed
}

func envString(env, fallback string) string {
	e := os.Getenv(env)
	if e == "" {
		return fallback
	}
	return e
}
