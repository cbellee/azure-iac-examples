package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
)

func main() {
	http.HandleFunc("/vars", envVarHandler)
	fmt.Println("Server is running on http://localhost:8080")
	http.ListenAndServe(":8080", nil)
}

func envVarHandler(w http.ResponseWriter, r *http.Request) {
	resp := dumpEnvVars()
	b := new(strings.Builder)
	json.NewEncoder(b).Encode(resp)
	w.Write([]byte(b.String()))
}

func dumpEnvVars() []string {
	var out []string
	for _, e := range os.Environ() {
		pair := strings.SplitN(e, "=", 2)
		out = append(out, fmt.Sprintf("%s: %s\n", pair[0], pair[1]))
	}

	return out
}
