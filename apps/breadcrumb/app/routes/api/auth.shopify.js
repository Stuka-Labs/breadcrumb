import { redirect } from "@remix-run/node";

// Replace these with your actual Shopify app credentials
const SHOPIFY_API_KEY = process.env.SHOPIFY_API_KEY || "your_shopify_api_key";
const SHOPIFY_REDIRECT_URI = process.env.SHOPIFY_REDIRECT_URI || "https://breadcrumb-bd857.web.app/api/auth/shopify/callback";
const SHOPIFY_SCOPES = "read_orders,read_products";

export const loader = async ({ request }) => {
  // Get shop from query string (?shop=yourshop.myshopify.com)
  const url = new URL(request.url);
  const shop = url.searchParams.get("shop");
  if (!shop) {
    return new Response("Missing shop parameter", { status: 400 });
  }

  // Build Shopify OAuth URL
  const shopifyAuthUrl = `https://${shop}/admin/oauth/authorize?client_id=${SHOPIFY_API_KEY}&scope=${SHOPIFY_SCOPES}&redirect_uri=${encodeURIComponent(SHOPIFY_REDIRECT_URI)}&state=nonce&grant_options[]=`;

  // Redirect to Shopify OAuth
  return redirect(shopifyAuthUrl);
};

export const action = loader; 