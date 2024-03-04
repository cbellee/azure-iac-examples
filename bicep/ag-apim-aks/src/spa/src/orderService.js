import { apiConfig } from "./authConfig";

/**
 * Attaches a given access token to a MS Graph API call. Returns information about the user
 * @param accessToken 
 */

export async function getOrders(accessToken) {
    const headers = new Headers();
    const bearer = `Bearer ${accessToken}`;

    headers.append("Authorization", bearer);

    const options = {
        method: "GET",
        headers: headers,
    };

    return fetch(apiConfig.orderApiEndpoint, options)
        .then(response => response.json())
        .catch(error => console.log(error));
}

export async function getOrder(accessToken, id) {
    const headers = new Headers();
    const bearer = `Bearer ${accessToken}`;

    headers.append("Authorization", bearer);

    const options = {
        method: "GET",
        headers: headers
    };

    url = apiConfig.orderApiEndpoint + "/" + id
    return fetch(url, options)
        .then(response => response.json())
        .catch(error => console.log(error));
}

export async function updateOrder(accessToken, id, data) {
    const headers = new Headers();
    const bearer = `Bearer ${accessToken}`;

    headers.append("Authorization", bearer);
    headers.append("Content-Type", "application/json");

    const options = {
        method: "POST",
        headers: headers,
        body: data
    };

    url = apiConfig.orderApiEndpoint + "/" + id
    return fetch(url, options)
        .then(response => response.json())
        .catch(error => console.log(error));
}
