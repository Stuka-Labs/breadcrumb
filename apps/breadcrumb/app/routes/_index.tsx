import type { LoaderFunctionArgs } from "@remix-run/node";
import { json } from "@remix-run/node";
import { useLoaderData } from "@remix-run/react";

export const loader = async ({ request }: LoaderFunctionArgs) => {
  // Get shop parameter from query string
  const url = new URL(request.url);
  const shop = url.searchParams.get("shop");
  const hmac = url.searchParams.get("hmac");
  
  return json({ shop, hmac });
};

export default function Index() {
  const { shop, hmac } = useLoaderData<typeof loader>();
  
  return (
    <div className="container">
      <div className="hero">
        <h1>Welcome to Breadcrumb</h1>
        <p className="subtitle">Connect your Shopify store to your WMS</p>
        
        {shop && (
          <div className="shop-info">
            <p>Connected to: <strong>{shop}</strong></p>
          </div>
        )}
        
        <div className="features">
          <div className="feature-card">
            <h3>Real-time Order Sync</h3>
            <p>Automatically sync orders from Shopify to your WMS</p>
          </div>
          
          <div className="feature-card">
            <h3>Inventory Management</h3>
            <p>Keep inventory levels in sync between systems</p>
          </div>
          
          <div className="feature-card">
            <h3>Webhooks</h3>
            <p>Real-time updates for orders, products, and more</p>
          </div>
        </div>
        
        <div className="status">
          <p>Ready to connect</p>
        </div>
      </div>
    </div>
  );
}

