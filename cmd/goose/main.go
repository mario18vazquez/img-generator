package main

import (
	"flag"
	"log"
	"os"

	// blank import to get the side-effects from registering a dialer
	_ "github.com/GoogleCloudPlatform/cloudsql-proxy/proxy/dialers/mysql"

	"github.com/pressly/goose"
)

func main() {
	var (
		dir     = flag.String("dir", envString("GOOSE_MIGRATION_DIR", "/migrations"), "directory with migration files")
		driver  = flag.String("driver", envString("GOOSE_DRIVER", "mysql"), "database driver")
		dsn     = flag.String("dsn", envString("GOOSE_DSN", ""), "DSN for database connection")
		command = flag.String("command", envString("GOOSE_COMMAND", "up"), "goose command: up, down, version, status")
	)
	flag.Parse()

	db, err := goose.OpenDBWithDriver(*driver, *dsn)
	if err != nil {
		log.Fatalf("goose: failed to open DB: %v\n", err)
	}

	if err := goose.Run(*command, db, *dir, []string{}...); err != nil {
		log.Fatalf("goose %v: %v", command, err)
	}
}

func envString(env, fallback string) string {
	e := os.Getenv(env)
	if e == "" {
		return fallback
	}
	return e
}
