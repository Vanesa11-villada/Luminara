package config

import (
	"fmt"
	"os"
)

type Config struct {
	AppPort string

	DBHost string
	DBPort string
	DBUser string
	DBPass string
	DBName string
}

func Load() Config {
	return Config{
		AppPort: getEnv("APP_PORT", "8085"),

		DBHost: getEnv("DB_HOST", "localhost"),
		DBPort: getEnv("DB_PORT", "3307"),
		DBUser: getEnv("DB_USER", "root"),
		DBPass: getEnv("DB_PASS", "rootpassword"),
		DBName: getEnv("DB_NAME", "db_auth"),
	}
}

func (c Config) MySQLDSN() string {
	// parseTime=true para mapear TIMESTAMP/DATETIME a time.Time
	// multiStatements=true ayuda si luego haces scripts/seed desde Go
	return fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&multiStatements=true",
		c.DBUser, c.DBPass, c.DBHost, c.DBPort, c.DBName,
	)
}

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}
