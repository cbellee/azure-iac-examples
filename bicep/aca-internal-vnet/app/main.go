package main

import (
	"flag"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"sort"
	"strconv"
)

type page struct {
	Colour        string
	Location      string
	EnvVars       []string
	Headers       []string
	Host          string
	RequestURI    string
	ClientAddress string
	HostName      string
	Version       string
}

var (
	colour, colourOk     = os.LookupEnv("COLOUR")
	version, versionOk   = os.LookupEnv("VERSION")
	location, locationOk = os.LookupEnv("LOCATION")
	validColours         = []string{"red", "green", "blue", "yellow"}
	port                 = 80
)

func contains(a []string, b string) bool {
	for _, s := range a {
		if b == s {
			return true
		}
	}
	return false
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func livenessHandler(w http.ResponseWriter, r *http.Request) {
	requestURL := fmt.Sprintf("http://localhost:%d", port)
	res, err := http.Get(requestURL)
	if err != nil {
		fmt.Printf("error making http request: %s\n", err)
		w.WriteHeader(res.StatusCode)
		w.Write([]byte(res.Status))
	}

	w.WriteHeader(res.StatusCode)
	w.Write([]byte(res.Status))
}

func startupHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Print("Checking environment variables...\n")
	fmt.Print("Colour: ", colour, " - ", colourOk, "\n")
	fmt.Print("Version: ", version, " - ", versionOk, "\n")
	fmt.Print("Location: ", location, " - ", locationOk, "\n")

	if !colourOk || colour == "" && !versionOk || version == "" && !locationOk || location == ""{
		http.Error(w, "Missing environment variables", http.StatusInternalServerError)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("500 - Missing environment variable(s). Please check the logs for more information."))
		return
	} else {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	}
}

func viewHandler(w http.ResponseWriter, r *http.Request) {
	envVars := make([]string, len(os.Environ()))
	headers := make([]string, len(r.Header))
	hostName, err := os.Hostname()
	if err != nil {
		hostName = ""
	}

	envVars = append(envVars, os.Environ()...)
	sort.Strings(envVars)

	for name, values := range r.Header {
		for _, value := range values {
			header := name + ": " + value
			headers = append(headers, header)
		}
	}

	sort.Strings(headers)
	err = renderTemplate(w, colour, &page{Location: location, Version: version, Colour: colour, EnvVars: envVars, Headers: headers, ClientAddress: r.RemoteAddr, RequestURI: r.URL.RequestURI(), HostName: hostName})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func renderTemplate(w http.ResponseWriter, tmpl string, p *page) error {
	t, err := template.ParseFiles("html/" + "main.html")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return err
	}
	err = t.Execute(w, p)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return err
	}

	return nil
}

func main() {
	flag.Parse()
	// validate colour flag
	if contains(validColours, colour) {
		http.HandleFunc("/", viewHandler)
		http.Handle("/css/", http.StripPrefix("/css/", http.FileServer(http.Dir("./css"))))
		http.HandleFunc("/healthz", healthHandler)
		http.HandleFunc("/startupz", startupHandler)
		http.HandleFunc("/livez", livenessHandler)
		log.Printf("Server starting on port %s...", strconv.Itoa(port))
		log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", strconv.Itoa(port)), nil))
	} else {
		fmt.Fprintln(os.Stderr, "missing colour option! ('red', 'green', 'blue', 'yellow')")
		os.Exit(127)
	}
}
