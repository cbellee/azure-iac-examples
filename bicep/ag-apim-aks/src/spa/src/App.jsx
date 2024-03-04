import React, { useState, useEffect } from 'react';
import { AuthenticatedTemplate, UnauthenticatedTemplate, useMsal } from "@azure/msal-react";
import { PageLayout } from "./components/PageLayout";
import { ProductGrid } from './components/ProductGrid';
import { OrderGrid } from './components/OrderGrid';
import "./styles/App.css";

/**
 * If a user is authenticated the ProfileContent component above is rendered. Otherwise a message indicating a user is not authenticated is rendered.
 */
const MainContent = () => {
    return (
        <div className="App">
            <AuthenticatedTemplate>
                <ProductGrid />
                <OrderGrid />
            </AuthenticatedTemplate>
            <UnauthenticatedTemplate>
                <h5 className="card-title">Please sign-in</h5>
            </UnauthenticatedTemplate>
        </div>
    );
};

export default function App() {
    return (
        <PageLayout>
            <MainContent />
        </PageLayout>
    );
}
