import { json, redirect } from "@remix-run/node";
import { getFirestore, collection, addDoc, doc, setDoc } from 'firebase-admin/firestore';

export const loader = async ({ request }) => {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const shop = url.searchParams.get("shop");
  
  if (!code || !state || !shop) {
    return new Response("Missing required parameters", { status: 400 });
  }

  try {
    // Parse state to get client info
    const stateData = JSON.parse(state);
    const clientId = stateData.clientId;
    
    // Exchange code for access token
    const tokenResponse = await fetch(`https://${shop}/admin/oauth/access_token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        client_id: process.env.SHOPIFY_API_KEY,
        client_secret: process.env.SHOPIFY_API_SECRET,
        code: code,
      }),
    });

    if (!tokenResponse.ok) {
      throw new Error('Failed to get access token');
    }

    const tokenData = await tokenResponse.json();
    const accessToken = tokenData.access_token;

    // Get shop information
    const shopResponse = await fetch(`https://${shop}/admin/api/2025-01/shop.json`, {
      headers: {
        'X-Shopify-Access-Token': accessToken,
      },
    });

    if (!shopResponse.ok) {
      throw new Error('Failed to get shop information');
    }

    const shopData = await shopResponse.json();
    const shopInfo = shopData.shop;

    // Store connection in Firestore
    const db = getFirestore();
    
    // Create shop connection document
    const connectionData = {
      clientId: clientId,
      shop: shop,
      shopName: shopInfo.name,
      shopEmail: shopInfo.email,
      shopDomain: shopInfo.domain,
      accessToken: accessToken,
      scope: tokenData.scope,
      connectedAt: new Date().toISOString(),
      status: 'active',
      lastSync: null,
    };

    // Store in shopConnections collection
    await addDoc(collection(db, 'shopConnections'), connectionData);

    // Update client with shop connection
    if (clientId) {
      await setDoc(doc(db, 'clients', clientId), {
        shopifyConnected: true,
        shopifyShop: shop,
        shopifyShopName: shopInfo.name,
        lastUpdated: new Date().toISOString(),
      }, { merge: true });
    }

    // Redirect back to Flutter app with success
    const redirectUrl = `https://passive-listprice-owen-exposed.trycloudflare.com/client?connected=success&shop=${encodeURIComponent(shop)}&shopName=${encodeURIComponent(shopInfo.name)}`;
    return redirect(redirectUrl);

  } catch (error) {
    console.error('Shopify OAuth error:', error);
    const redirectUrl = `https://passive-listprice-owen-exposed.trycloudflare.com/client?connected=error&error=${encodeURIComponent(error.message)}`;
    return redirect(redirectUrl);
  }
};

export const action = loader;
