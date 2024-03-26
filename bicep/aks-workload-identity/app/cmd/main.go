package main

import (
	"context"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/security/keyvault/azsecrets"
)

func main() {
	keyVaultUrl := os.Getenv("KEYVAULT_URL")
	secretName := os.Getenv("SECRET_NAME")

	credential, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		slog.Error("failed to create AzureCredential", "error", err)
		os.Exit(1)
	}

	client, err := azsecrets.NewClient(keyVaultUrl, credential, nil)
	if err != nil {
		slog.Error("failed to create keyVault client", "error", err)
		os.Exit(1)
	}

	secret, err := client.GetSecret(context.Background(), secretName, "", nil)
	if err != nil {
		slog.Error("failed to get secret", "error", err, "keyVaultUrl", keyVaultUrl, "secretName", secretName)
		os.Exit(1)
	}
	slog.Info("got secret", "secret", *secret.Value)
	fmt.Sprintf("Secret Value: %s", *secret.Value)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Secret Value: %s", *secret.Value)
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
