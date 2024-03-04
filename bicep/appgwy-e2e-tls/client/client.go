package main

import (
	"bufio"
	"crypto/sha1"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt"
	"github.com/google/uuid"
	"golang.org/x/crypto/pkcs12"
)

func main() {
	jwtToken, err := getAuthJWTToken(os.Getenv("CLIENT_ID"), os.Getenv("TENANT_NAME"), os.Getenv("PFX_FILE_PATH"), os.Getenv("CERT_PASSWORD"))
	if err != nil {
		fmt.Println(fmt.Sprintf("error creating JWT token: %s", err))
	}

	fmt.Println(fmt.Sprintf("JWT token: %s", jwtToken))

	URL := fmt.Sprintf("https://login.microsoftonline.com/%s/oauth2/v2.0/token", os.Getenv("TENANT_NAME"))
	scope := os.Getenv("SCOPE")
	clientID := os.Getenv("CLIENT_ID")
	tenant := os.Getenv("TENANT_NAME")

	resp, err := getAccessToken(URL, scope, clientID, tenant, jwtToken)
	if err != nil {
		fmt.Printf("Error obtaining access token %s", err)
		return
	}

	fmt.Printf("Body: %s", resp)
	// call todolist api

}

func getAccessToken(URL string, scope string, clientID string, tenant string, assertion string) (response interface{}, err error) {
	client := &http.Client{}

	param := url.Values{}
	param.Add("scope", scope)
	param.Add("client_id", clientID)
	param.Add("tenant", tenant)
	param.Add("client_assertion_type", "urn:ietf:params:oauth:client-assertion-type:jwt-bearer")
	param.Add("client_assertion", assertion)
	param.Add("tenant", tenant)
	param.Add("grant_type", "client_credentials")

	req, err := http.NewRequest("POST", URL, strings.NewReader(param.Encode()))
	if err != nil {
		fmt.Println("Error creating http request %s", err)
		return nil, err
	}

	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	res, err := client.Do(req)
	if err != nil {
		fmt.Printf("Error setting request Header: %s", err)
		return nil, err
	}

	defer res.Body.Close()
	var target interface{}
	body, err := ioutil.ReadAll(res.Body)
	fmt.Printf("Body: %s", body)
	json.Unmarshal(body, target)

	return target, nil

	/* decoder := json.NewDecoder(req.Body)
	var b body
	err := decoder.Decode(&b)
	json.
	if err != nil {
		panic(err.Error())
	} */

}

func getAuthJWTToken(clientID string, tenantName string, pfxFilePath string, certPassword string) (string, error) {
	authToken := ""
	pfxFile, err := os.Open(pfxFilePath)

	if err != nil {
		fmt.Printf("error opening certificate file %s", err)
		return authToken, err
	}

	pfxfileinfo, _ := pfxFile.Stat()
	var size int64 = pfxfileinfo.Size()

	pfxbytes := make([]byte, size)
	buffer := bufio.NewReader(pfxFile)
	_, err = buffer.Read(pfxbytes)

	//PFX to PEM for computation of signature
	var pembytes []byte
	blocks, err := pkcs12.ToPEM(pfxbytes, certPassword)

	
	for i, b := range blocks {
		fmt.Printf("Found certificate: %d \n", i)
		fmt.Printf("PEM block: %s \n", b)
		pembytes = append(pembytes, pem.EncodeToMemory(b)...)
	}

	//Decoding the certificate contents from pfxbytes
	pk, cert, err := pkcs12.Decode(pfxbytes, certPassword)
	if cert == nil {
		fmt.Printf("Error Decoding PFX certificate: %s", err)
		return authToken, nil
	}
	if pk == nil {

	}

	pfxFile.Close() // close file

	notToBeUsedBefore := time.Now()
	expirationTime := time.Now().Add(3000 * time.Minute)
	URL := fmt.Sprintf("https://login.microsoftonline.com/%s/oauth2/token", tenantName)

	id := uuid.New()

	claims := jwt.StandardClaims{
		Audience:  URL,
		ExpiresAt: expirationTime.Unix(),
		IssuedAt:  notToBeUsedBefore.Unix(),
		Id:        id.String(),
		Issuer:    clientID,
		NotBefore: notToBeUsedBefore.Unix(),
		Subject:   clientID,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)

	fmt.Printf("CERT: %s", cert.Signature)
	sha1Fingerprint := sha1.Sum(cert.Raw) //  sha1.Sum(pembytes)
	var slice []byte
	slice = sha1Fingerprint[:]
	b64FingerPrint := base64.StdEncoding.EncodeToString([]byte(slice))
	token.Header["x5t"] = b64FingerPrint

	signKey, err := jwt.ParseRSAPrivateKeyFromPEM(pembytes) // parse the RSA key
	// fmt.Printf("signKey: %d", signKey)
	tokenString, err := token.SignedString(signKey)         // sign the claims with private key

	return tokenString, err
}

/* func passInterface(v interface{}) (by []byte) {
	b, ok := v.(*[]byte)
	fmt.Println(ok)
	fmt.Println(b)
	return *b
}
 */