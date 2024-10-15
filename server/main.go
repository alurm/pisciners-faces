// A simple HTTP server with TLS support.
package main

import (
	"flag"
	"log"
	"net/http"
	"os"

	"golang.org/x/crypto/acme/autocert"

	"crypto/tls"
)

type myTLS struct {
	enabled  bool
	email    string
	manager  autocert.Manager
	config   *tls.Config
	identity string
}

type myServer struct {
	host             string
	port             string
	contentPath      string
	httpPathPrefix   string
	certificatesPath string
	indexEnabled     bool
	tls              myTLS
}

func serve(s *myServer) {
	fs := http.FileServerFS(os.DirFS(s.contentPath))
	stripped := http.StripPrefix(s.httpPathPrefix, fs)

	indexed := stripped
	if !s.indexEnabled {
		indexed = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("x-robots-tag", "noindex")
			stripped.ServeHTTP(w, r)
		})
	}

	mux := http.ServeMux{}
	mux.Handle(s.httpPathPrefix, indexed)

	addr := s.host
	if s.port != "" {
		addr += ":" + s.port
	}

	server := http.Server{
		Handler:   &mux,
		TLSConfig: s.tls.config,
		Addr:      addr,
	}

	if s.tls.enabled {
		log.Fatal(server.ListenAndServeTLS("", ""))
	} else {
		log.Fatal(server.ListenAndServe())
	}
}

func main() {
	server := myServer{}

	flag.BoolVar(&server.tls.enabled, "tls", false, "Enable TLS")
	flag.StringVar(&server.certificatesPath, "certificates", "certificates", "TLS certificates path")
	flag.StringVar(&server.tls.email, "email", "", "Optional email for the certificate authority")
	flag.StringVar(&server.tls.identity, "identity", "", "Optional TLS identity, example: example.com")

	flag.StringVar(&server.host, "host", "", "Optional host to listen on")
	flag.StringVar(&server.port, "port", "", "Optional port to listen on")
	flag.StringVar(&server.httpPathPrefix, "http-prefix", "/", "Optional HTTP (path) prefix")
	flag.StringVar(&server.contentPath, "content", "content", "Content path")
	flag.BoolVar(&server.indexEnabled, "index", false, "Don't tell search engines not to index the site")

	flag.Parse()

	if server.httpPathPrefix == "" {
		server.httpPathPrefix = "/"
	}

	if server.httpPathPrefix[len(server.httpPathPrefix)-1] != '/' {
		server.httpPathPrefix += "/"
	}

	if server.tls.enabled {
		if server.tls.identity == "" {
			log.Fatal("server's identity can't be empty if TLS is enabled")
		}
		server.tls.manager = autocert.Manager{
			Prompt:     autocert.AcceptTOS,
			HostPolicy: autocert.HostWhitelist(server.tls.identity),
			Cache:      autocert.DirCache(server.certificatesPath),
			Email:      server.tls.email,
		}
		server.tls.config = server.tls.manager.TLSConfig()
	}

	serve(&server)
}
