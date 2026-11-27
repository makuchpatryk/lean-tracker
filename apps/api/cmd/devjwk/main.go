// Command devjwk writes a throwaway ES256 private key as a JWK array for the local Supabase Auth
// container (GOTRUE_JWT_KEYS, PRD D-71). It is a development tool: the key lives in the git-ignored
// .cache/ and never reaches git or an image.
package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
)

type jwk struct {
	Kty    string   `json:"kty"`
	Crv    string   `json:"crv"`
	X      string   `json:"x"`
	Y      string   `json:"y"`
	D      string   `json:"d"`
	Kid    string   `json:"kid"`
	Alg    string   `json:"alg"`
	Use    string   `json:"use"`
	KeyOps []string `json:"key_ops"`
}

func main() {
	out := flag.String("out", "", "path of the key file to create")
	flag.Parse()
	if *out == "" {
		fmt.Fprintln(os.Stderr, "devjwk: -out is required")
		os.Exit(2)
	}
	if err := run(*out); err != nil {
		fmt.Fprintln(os.Stderr, "devjwk:", err)
		os.Exit(1)
	}
}

func run(path string) error {
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return err
	}
	kid := make([]byte, 16)
	if _, err := rand.Read(kid); err != nil {
		return err
	}
	data, err := json.Marshal([]jwk{{
		Kty:    "EC",
		Crv:    "P-256",
		X:      b64(key.X.FillBytes(make([]byte, 32))),
		Y:      b64(key.Y.FillBytes(make([]byte, 32))),
		D:      b64(key.D.FillBytes(make([]byte, 32))),
		Kid:    hex.EncodeToString(kid),
		Alg:    "ES256",
		Use:    "sig",
		KeyOps: []string{"sign", "verify"},
	}})
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	// O_EXCL: never overwrite a key the running auth container already signs with. 0644 because the
	// container user differs from the host user; the key is local-only and git-ignored.
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o644) //nolint:gosec // local dev key, see above
	if errors.Is(err, os.ErrExist) {
		return fmt.Errorf("%s already exists, not overwriting", path)
	}
	if err != nil {
		return err
	}
	if _, err := f.Write(data); err != nil {
		_ = f.Close()
		return err
	}
	return f.Close()
}

func b64(b []byte) string { return base64.RawURLEncoding.EncodeToString(b) }
