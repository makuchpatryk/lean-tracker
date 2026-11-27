// Package jwttest issues signed test tokens and serves the matching JWKS. Used only by _test.go files.
package jwttest

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/golang-jwt/jwt/v5"
)

// KeyID is the `kid` of the one key every issuer publishes.
const KeyID = "test-1"

// NewIssuer generates an ES256 key and starts an httptest server serving its public half as a JWKS.
// The server is closed when the test ends. sign returns a token for the claims, signed with that key and
// carrying the `kid` header. Two issuers publish the same `kid` with different keys, so a token from one
// never verifies against the other's JWKS.
func NewIssuer(t *testing.T) (jwksURL string, sign func(jwt.MapClaims) string) {
	t.Helper()

	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("jwttest: generate key: %v", err)
	}
	coordinate := func(n interface{ FillBytes([]byte) []byte }) string {
		return base64.RawURLEncoding.EncodeToString(n.FillBytes(make([]byte, 32)))
	}
	jwks, err := json.Marshal(map[string]any{"keys": []map[string]string{{
		"kty": "EC", "crv": "P-256", "alg": "ES256", "use": "sig", "kid": KeyID,
		"x": coordinate(key.X), "y": coordinate(key.Y),
	}}})
	if err != nil {
		t.Fatalf("jwttest: marshal jwks: %v", err)
	}

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write(jwks)
	}))
	t.Cleanup(server.Close)

	sign = func(claims jwt.MapClaims) string {
		token := jwt.NewWithClaims(jwt.SigningMethodES256, claims)
		token.Header["kid"] = KeyID
		signed, err := token.SignedString(key)
		if err != nil {
			t.Fatalf("jwttest: sign token: %v", err)
		}
		return signed
	}
	return server.URL, sign
}
