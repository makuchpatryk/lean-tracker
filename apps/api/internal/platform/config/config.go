// Package config reads and validates the API's environment (CODE_QUALITY: configuration names live here
// and in the *.example env files).
package config

import (
	"errors"
	"fmt"
	"net/url"
	"strconv"
)

const defaultPort = "8080"

// Config holds the settings the API needs to start.
type Config struct {
	Port            string // PORT, default "8080", must be 1–65535
	DatabaseURL     string // DATABASE_URL, required
	SupabaseJWKSURL string // SUPABASE_JWKS_URL, required, absolute http(s) URL
}

// Load reads the configuration through getenv. The error names every missing or invalid variable and
// never echoes a value (a DSN or URL can hold credentials).
func Load(getenv func(string) string) (Config, error) {
	cfg := Config{
		Port:            getenv("PORT"),
		DatabaseURL:     getenv("DATABASE_URL"),
		SupabaseJWKSURL: getenv("SUPABASE_JWKS_URL"),
	}
	if cfg.Port == "" {
		cfg.Port = defaultPort
	}

	var problems []error
	if port, err := strconv.Atoi(cfg.Port); err != nil || port < 1 || port > 65535 {
		problems = append(problems, errors.New("PORT must be a number from 1 to 65535"))
	}
	if cfg.DatabaseURL == "" {
		problems = append(problems, errors.New("DATABASE_URL is required"))
	}
	switch {
	case cfg.SupabaseJWKSURL == "":
		problems = append(problems, errors.New("SUPABASE_JWKS_URL is required"))
	case !isAbsoluteHTTPURL(cfg.SupabaseJWKSURL):
		problems = append(problems, errors.New("SUPABASE_JWKS_URL must be an absolute http(s) URL"))
	}
	if err := errors.Join(problems...); err != nil {
		return Config{}, fmt.Errorf("config: %w", err)
	}
	return cfg, nil
}

func isAbsoluteHTTPURL(raw string) bool {
	u, err := url.Parse(raw)
	return err == nil && (u.Scheme == "http" || u.Scheme == "https") && u.Host != ""
}
