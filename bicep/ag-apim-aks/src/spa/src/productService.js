import { apiConfig } from "./authConfig";

/**
 * Attaches a given access token to a MS Graph API call. Returns information about the user
 * @param accessToken 
 */

export async function getProducts(accessToken) {
    const headers = new Headers();
    const bearer = `Bearer ${accessToken}`;

    headers.append("Authorization", bearer);

    const options = {
        method: "GET",
        headers: headers
    };

    return fetch(apiConfig.productApiEndpoint, options)
        .then(response => response.json())
        .catch(error => console.log(error));
}

export async function getProduct(accessToken, id) {
    const headers = new Headers();
    const bearer = `Bearer ${accessToken}`;

    headers.append("Authorization", bearer);

    const options = {
        method: "GET",
        headers: headers
    };

    url = apiConfig.productApiEndpoint + "/" + id
    return fetch(url, options)
        .then(response => response.json())
        .catch(error => console.log(error));
}