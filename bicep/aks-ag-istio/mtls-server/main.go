package main

import (
	"crypto/tls"
	"crypto/x509"
	"io"
	"os"
	"log"
	"net/http"
)

func helloHandler(w http.ResponseWriter, r *http.Request) {
	// print headers and connection state
	printHeader(r)
	if r.TLS != nil {
		printConnState(r.TLS)
	}
	io.WriteString(w, "Hello, world!\n")
}

func main() {
	// Set up a /hello resource handler
	http.HandleFunc("/hello", helloHandler)

	dirList("/mnt/certs")
	
	// Create a CA certificate pool and add ca.crt to it
	caCertFile, err := os.ReadFile("/mnt/certs/ca-cert")
	if err != nil {
		log.Fatal(err)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCertFile)

	// Create the TLS Config with the CA pool and enable Client certificate validation
	tlsConfig := &tls.Config{
		ClientCAs: caCertPool,
		ClientAuth: tls.RequireAndVerifyClientCert,
	}
	// tlsConfig.BuildNameToCertificate()

	// Create a Server instance to listen on port 8443 with the TLS config
	server := &http.Server{
		Addr:      ":8443",
		TLSConfig: tlsConfig,
	}

	// Listen to HTTPS connections with the server certificate and wait
	log.Printf("Listening on port 8443...")
	log.Fatal(server.ListenAndServeTLS("mnt/certs/server-cert.crt", "/mnt/certs/server-cert.key"))
}

func printHeader(r *http.Request) {
	log.Print(">>>>>>>>>>>>>>>> Headers <<<<<<<<<<<<<<<<")
	// Loop over header names
	for name, values := range r.Header {
		// Loop over all values for the name.
		for _, value := range values {
			log.Printf("%v:%v", name, value)
		}
	}
}

func printConnState(state *tls.ConnectionState) {
	log.Print(">>>>>>>>>>>>>>>> State <<<<<<<<<<<<<<<<")

	log.Printf("Version: %x", state.Version)
	log.Printf("HandshakeComplete: %t", state.HandshakeComplete)
	log.Printf("DidResume: %t", state.DidResume)
	log.Printf("CipherSuite: %x", state.CipherSuite)
	log.Printf("NegotiatedProtocol: %s", state.NegotiatedProtocol)

	log.Print("Certificate chain:")
	for i, cert := range state.PeerCertificates {
		subject := cert.Subject
		issuer := cert.Issuer
		log.Printf(" %d s:/C=%v/ST=%v/L=%v/O=%v/OU=%v/CN=%s", i, subject.Country, subject.Province, subject.Locality, subject.Organization, subject.OrganizationalUnit, subject.CommonName)
		log.Printf("   i:/C=%v/ST=%v/L=%v/O=%v/OU=%v/CN=%s", issuer.Country, issuer.Province, issuer.Locality, issuer.Organization, issuer.OrganizationalUnit, issuer.CommonName)
	}
}

func dirList(dirPath string) {
	dirEntries, err := os.ReadDir(dirPath)
	if err != nil {
		log.Print(err.Error())
	}

	for i, de := range dirEntries {
		log.Printf("%d: %s", i, de.Name())
	}
}