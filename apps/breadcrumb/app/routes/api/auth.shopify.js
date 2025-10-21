import { redirect } from "@remix-run/node";
import { getFirestore, collection, addDoc } from 'firebase-admin/firestore';

// Shopify app credentials
const SHOPIFY_API_KEY = process.env.SHOPIFY_API_KEY || "a4242369a1e8b5d7e512d82356262da9";
const SHOPIFY_REDIRECT_URI = process.env.SHOPIFY_REDIRECT_URI || "https://passive-listprice-owen-exposed.trycloudflare.com/api/auth/shopify/callback";
const SHOPIFY_SCOPES = "read_orders,read_products,read_customers,write_orders";

export const loader = async ({ request }) => {
  const url = new URL(request.url);
  const shop = url.searchParams.get("shop");
  const clientId = url.searchParams.get("clientId"); // Get client ID from Flutter app
  
  if (!shop) {
    return new Response("Missing shop parameter", { status: 400 });
  }

  // Validate shop domain
  if (!shop.endsWith('.myshopify.com')) {
    return new Response("Invalid shop domain", { status: 400 });
  }

  // Generate state parameter with client info
  const state = JSON.stringify({
    shop: shop,
    clientId: clientId,
    timestamp: Date.now()
  });

  // Build Shopify OAuth URL
  const shopifyAuthUrl = `https://${shop}/admin/oauth/authorize?client_id=${SHOPIFY_API_KEY}&scope=${SHOPIFY_SCOPES}&redirect_uri=${encodeURIComponent(SHOPIFY_REDIRECT_URI)}&state=${encodeURIComponent(state)}&grant_options[]=`;

  return redirect(shopifyAuthUrl);
};

export const action = loader; 