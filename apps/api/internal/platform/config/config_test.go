package config_test

import (
	"strings"
	"testing"

	"example.com/lean-tracker/apps/api/internal/platform/config"
)

const (
	dsn     = "postgres://user:s3cret@localhost:5432/db"
	jwksURL = "https://example.supabase.co/auth/v1/.well-known/jwks.json"
)

func env(vars map[string]string) func(string) string {
	return func(key string) string { return vars[key] }
}

func TestLoad(t *testing.T) {
	tests := []struct {
		name     string
		vars     map[string]string
		wantPort string
		wantErr  []string // variable names the error must mention
	}{
		{
			name:     "all set",
			vars:     map[string]string{"PORT": "9000", "DATABASE_URL": dsn, "SUPABASE_JWKS_URL": jwksURL},
			wantPort: "9000",
		},
		{
			name:     "port unset defaults to 8080",
			vars:     map[string]string{"DATABASE_URL": dsn, "SUPABASE_JWKS_URL": jwksURL},
			wantPort: "8080",
		},
		{
			name:    "missing DATABASE_URL",
			vars:    map[string]string{"SUPABASE_JWKS_URL": jwksURL},
			wantErr: []string{"DATABASE_URL"},
		},
		{
			name:    "missing SUPABASE_JWKS_URL",
			vars:    map[string]string{"DATABASE_URL": dsn},
			wantErr: []string{"SUPABASE_JWKS_URL"},
		},
		{
			name:    "JWKS URL without scheme",
			vars:    map[string]string{"DATABASE_URL": dsn, "SUPABASE_JWKS_URL": "example.supabase.co/jwks"},
			wantErr: []string{"SUPABASE_JWKS_URL"},
		},
		{
			name:    "JWKS URL with a non-http scheme",
			vars:    map[string]string{"DATABASE_URL": dsn, "SUPABASE_JWKS_URL": "ftp://example.supabase.co/jwks"},
			wantErr: []string{"SUPABASE_JWKS_URL"},
		},
		{
			name:    "port is not a number",
			vars:    map[string]string{"PORT": "abc", "DATABASE_URL": dsn, "SUPABASE_JWKS_URL": jwksURL},
			wantErr: []string{"PORT"},
		},
		{
			name:    "port above 65535",
			vars:    map[string]string{"PORT": "70000", "DATABASE_URL": dsn, "SUPABASE_JWKS_URL": jwksURL},
			wantErr: []string{"PORT"},
		},
		{
			name:    "every problem is reported",
			vars:    map[string]string{"PORT": "0"},
			wantErr: []string{"PORT", "DATABASE_URL", "SUPABASE_JWKS_URL"},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cfg, err := config.Load(env(tt.vars))

			if len(tt.wantErr) == 0 {
				if err != nil {
					t.Fatalf("Load() error = %v, want nil", err)
				}
				if cfg.Port != tt.wantPort || cfg.DatabaseURL != dsn || cfg.SupabaseJWKSURL != jwksURL {
					t.Fatalf("Load() = %+v, want port %s and the given URLs", cfg, tt.wantPort)
				}
				return
			}
			if err == nil {
				t.Fatalf("Load() error = nil, want one naming %v", tt.wantErr)
			}
			for _, name := range tt.wantErr {
				if !strings.Contains(err.Error(), name) {
					t.Errorf("error %q does not name %s", err, name)
				}
			}
		})
	}
}

func TestLoadErrorNeverContainsValues(t *testing.T) {
	_, err := config.Load(env(map[string]string{
		"PORT":              "not-a-port-secret",
		"DATABASE_URL":      "",
		"SUPABASE_JWKS_URL": "s3cret-not-a-url",
	}))
	if err == nil {
		t.Fatal("Load() error = nil, want an error")
	}
	for _, leaked := range []string{"not-a-port-secret", "s3cret-not-a-url"} {
		if strings.Contains(err.Error(), leaked) {
			t.Errorf("error %q echoes the value %q", err, leaked)
		}
	}
}
