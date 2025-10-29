var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf, __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: !0 });
}, __copyProps = (to, from, except, desc) => {
  if (from && typeof from == "object" || typeof from == "function")
    for (let key of __getOwnPropNames(from))
      !__hasOwnProp.call(to, key) && key !== except && __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: !0 }) : target,
  mod
)), __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: !0 }), mod);

// <stdin>
var stdin_exports = {};
__export(stdin_exports, {
  assets: () => assets_manifest_default,
  assetsBuildDirectory: () => assetsBuildDirectory,
  entry: () => entry,
  future: () => future,
  mode: () => mode,
  publicPath: () => publicPath,
  routes: () => routes
});
module.exports = __toCommonJS(stdin_exports);

// node_modules/@remix-run/dev/dist/config/defaults/entry.server.node.tsx
var entry_server_node_exports = {};
__export(entry_server_node_exports, {
  default: () => handleRequest
});
var import_node_stream = require("node:stream"), import_node = require("@remix-run/node"), import_react = require("@remix-run/react"), isbotModule = __toESM(require("isbot")), import_server = require("react-dom/server"), import_jsx_runtime = require("react/jsx-runtime"), ABORT_DELAY = 5e3;
function handleRequest(request, responseStatusCode, responseHeaders, remixContext, loadContext) {
  return isBotRequest(request.headers.get("user-agent")) || remixContext.isSpaMode ? handleBotRequest(
    request,
    responseStatusCode,
    responseHeaders,
    remixContext
  ) : handleBrowserRequest(
    request,
    responseStatusCode,
    responseHeaders,
    remixContext
  );
}
function isBotRequest(userAgent) {
  return userAgent ? "isbot" in isbotModule && typeof isbotModule.isbot == "function" ? isbotModule.isbot(userAgent) : "default" in isbotModule && typeof isbotModule.default == "function" ? isbotModule.default(userAgent) : !1 : !1;
}
function handleBotRequest(request, responseStatusCode, responseHeaders, remixContext) {
  return new Promise((resolve, reject) => {
    let shellRendered = !1, { pipe, abort } = (0, import_server.renderToPipeableStream)(
      /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
        import_react.RemixServer,
        {
          context: remixContext,
          url: request.url,
          abortDelay: ABORT_DELAY
        }
      ),
      {
        onAllReady() {
          shellRendered = !0;
          let body = new import_node_stream.PassThrough(), stream = (0, import_node.createReadableStreamFromReadable)(body);
          responseHeaders.set("Content-Type", "text/html"), resolve(
            new Response(stream, {
              headers: responseHeaders,
              status: responseStatusCode
            })
          ), pipe(body);
        },
        onShellError(error) {
          reject(error);
        },
        onError(error) {
          responseStatusCode = 500, shellRendered && console.error(error);
        }
      }
    );
    setTimeout(abort, ABORT_DELAY);
  });
}
function handleBrowserRequest(request, responseStatusCode, responseHeaders, remixContext) {
  return new Promise((resolve, reject) => {
    let shellRendered = !1, { pipe, abort } = (0, import_server.renderToPipeableStream)(
      /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
        import_react.RemixServer,
        {
          context: remixContext,
          url: request.url,
          abortDelay: ABORT_DELAY
        }
      ),
      {
        onShellReady() {
          shellRendered = !0;
          let body = new import_node_stream.PassThrough(), stream = (0, import_node.createReadableStreamFromReadable)(body);
          responseHeaders.set("Content-Type", "text/html"), resolve(
            new Response(stream, {
              headers: responseHeaders,
              status: responseStatusCode
            })
          ), pipe(body);
        },
        onShellError(error) {
          reject(error);
        },
        onError(error) {
          responseStatusCode = 500, shellRendered && console.error(error);
        }
      }
    );
    setTimeout(abort, ABORT_DELAY);
  });
}

// app/root.tsx
var root_exports = {};
__export(root_exports, {
  default: () => App,
  links: () => links,
  meta: () => meta
});
var import_react2 = require("@remix-run/react");

// app/styles.css
var styles_default = "/build/_assets/styles-BFD7OPC4.css";

// app/root.tsx
var import_jsx_runtime2 = require("react/jsx-runtime"), meta = () => ({
  charset: "utf-8",
  title: "Breadcrumb - Connect Shopify Orders to WMS",
  viewport: "width=device-width,initial-scale=1"
}), links = () => [
  { rel: "stylesheet", href: styles_default }
];
function App() {
  return /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("html", { lang: "en", children: [
    /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("head", { children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(import_react2.Meta, {}),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(import_react2.Links, {})
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("body", { children: [
      /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("div", { className: "app", children: [
        /* @__PURE__ */ (0, import_jsx_runtime2.jsxs)("header", { children: [
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("h1", { children: "Breadcrumb" }),
          /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("p", { children: "Connect Shopify Orders to WMS" })
        ] }),
        /* @__PURE__ */ (0, import_jsx_runtime2.jsx)("main", { children: /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(import_react2.Outlet, {}) })
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(import_react2.ScrollRestoration, {}),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(import_react2.Scripts, {}),
      /* @__PURE__ */ (0, import_jsx_runtime2.jsx)(import_react2.LiveReload, {})
    ] })
  ] });
}

// app/routes/webhooks.fulfillment-orders.request.js
var webhooks_fulfillment_orders_request_exports = {};
__export(webhooks_fulfillment_orders_request_exports, {
  action: () => action
});
var import_node2 = require("@remix-run/node"), import_firestore = require("firebase-admin/firestore");
async function action({ request }) {
  if (request.method !== "POST")
    return (0, import_node2.json)({ error: "Method not allowed" }, { status: 405 });
  try {
    let fulfillmentOrder = await request.json(), db = (0, import_firestore.getFirestore)(), fulfillmentData = {
      shopifyFulfillmentOrderId: fulfillmentOrder.id,
      status: fulfillmentOrder.status,
      requestStatus: fulfillmentOrder.request_status,
      assignedLocationId: fulfillmentOrder.assigned_location?.id,
      assignedLocationName: fulfillmentOrder.assigned_location?.name,
      destination: fulfillmentOrder.destination,
      lineItems: fulfillmentOrder.line_items?.map((item) => ({
        id: item.id,
        sku: item.sku,
        title: item.title,
        quantity: item.quantity,
        remainingQuantity: item.remaining_quantity,
        variantId: item.variant?.id,
        variantTitle: item.variant?.title,
        imageUrl: item.variant?.image?.url
      })) || [],
      shopifyData: fulfillmentOrder,
      createdAt: (/* @__PURE__ */ new Date()).toISOString(),
      updatedAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    return await db.collection("fulfillmentOrders").add(fulfillmentData), console.log("Fulfillment order request received:", {
      id: fulfillmentOrder.id,
      status: fulfillmentOrder.status,
      requestStatus: fulfillmentOrder.request_status,
      lineItemsCount: fulfillmentOrder.line_items?.length || 0
    }), (0, import_node2.json)({ success: !0 });
  } catch (error) {
    return console.error("Error processing fulfillment order webhook:", error), (0, import_node2.json)({ error: "Internal server error" }, { status: 500 });
  }
}

// app/routes/webhooks.orders.fulfilled.js
var webhooks_orders_fulfilled_exports = {};
__export(webhooks_orders_fulfilled_exports, {
  action: () => action2
});
var import_node3 = require("@remix-run/node"), import_firestore2 = require("firebase-admin/firestore");
async function action2({ request }) {
  if (request.method !== "POST")
    return (0, import_node3.json)({ error: "Method not allowed" }, { status: 405 });
  try {
    let order = await request.json(), db = (0, import_firestore2.getFirestore)(), ordersSnapshot = await db.collection("orders").where("shopifyOrderId", "==", order.id.toString()).get();
    if (!ordersSnapshot.empty) {
      let orderDoc = ordersSnapshot.docs[0];
      await db.collection("orders").doc(orderDoc.id).update({
        status: "fulfilled",
        fulfillmentStatus: "fulfilled",
        fulfilledAt: (/* @__PURE__ */ new Date()).toISOString(),
        shopifyData: order,
        updatedAt: (/* @__PURE__ */ new Date()).toISOString()
      }), console.log("Order fulfillment processed:", {
        orderId: order.id,
        orderNumber: order.order_number,
        fulfillmentStatus: order.fulfillment_status
      });
    }
    return (0, import_node3.json)({ success: !0 });
  } catch (error) {
    return console.error("Error processing order fulfillment webhook:", error), (0, import_node3.json)({ error: "Internal server error" }, { status: 500 });
  }
}

// app/routes/webhooks.app.uninstalled.jsx
var webhooks_app_uninstalled_exports = {};
__export(webhooks_app_uninstalled_exports, {
  action: () => action3
});
var import_node4 = require("@remix-run/node"), import_firestore3 = require("firebase-admin/firestore");
async function action3({ request }) {
  if (request.method !== "POST")
    return (0, import_node4.json)({ error: "Method not allowed" }, { status: 405 });
  try {
    let webhookData = await request.json(), db = (0, import_firestore3.getFirestore)();
    console.log("App uninstalled webhook received:", {
      shop: webhookData.domain,
      shopId: webhookData.id
    });
    let connectionsQuery = await db.collection("shopifyConnections").where("shop", "==", webhookData.domain).get();
    for (let doc of connectionsQuery.docs)
      await doc.ref.update({
        status: "uninstalled",
        uninstalledAt: (/* @__PURE__ */ new Date()).toISOString()
      });
    let clientsQuery = await db.collection("clients").where("shopifyShop", "==", webhookData.domain).get();
    for (let doc of clientsQuery.docs)
      await doc.ref.update({
        shopifyConnected: !1,
        shopifyShop: null,
        shopifyShopName: null,
        lastUpdated: (/* @__PURE__ */ new Date()).toISOString()
      });
    return console.log("App uninstallation processed:", {
      connectionsUpdated: connectionsQuery.docs.length,
      clientsUpdated: clientsQuery.docs.length
    }), (0, import_node4.json)({ success: !0 });
  } catch (error) {
    return console.error("Error processing app uninstalled webhook:", error), (0, import_node4.json)({ error: "Internal server error" }, { status: 500 });
  }
}

// app/routes/webhooks.products.create.js
var webhooks_products_create_exports = {};
__export(webhooks_products_create_exports, {
  action: () => action4
});
var import_node5 = require("@remix-run/node"), import_firestore4 = require("firebase-admin/firestore");
async function action4({ request }) {
  if (request.method !== "POST")
    return (0, import_node5.json)({ error: "Method not allowed" }, { status: 405 });
  try {
    let product = await request.json(), db = (0, import_firestore4.getFirestore)(), productData = {
      shopifyProductId: product.id.toString(),
      title: product.title,
      handle: product.handle,
      vendor: product.vendor,
      productType: product.product_type,
      tags: product.tags,
      status: product.status,
      shop: product.shop_domain,
      variants: product.variants?.map((variant) => ({
        id: variant.id,
        title: variant.title,
        sku: variant.sku,
        price: parseFloat(variant.price || 0),
        compareAtPrice: parseFloat(variant.compare_at_price || 0),
        inventoryQuantity: variant.inventory_quantity || 0,
        weight: variant.weight || 0,
        weightUnit: variant.weight_unit,
        requiresShipping: variant.requires_shipping,
        taxable: variant.taxable,
        barcode: variant.barcode,
        imageId: variant.image_id,
        position: variant.position,
        option1: variant.option1,
        option2: variant.option2,
        option3: variant.option3
      })) || [],
      images: product.images?.map((image) => ({
        id: image.id,
        src: image.src,
        alt: image.alt,
        position: image.position,
        width: image.width,
        height: image.height
      })) || [],
      options: product.options?.map((option) => ({
        id: option.id,
        name: option.name,
        position: option.position,
        values: option.values
      })) || [],
      shopifyData: product,
      createdAt: (/* @__PURE__ */ new Date()).toISOString(),
      updatedAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    return await db.collection("products").add(productData), console.log("Product created:", {
      productId: product.id,
      title: product.title,
      handle: product.handle,
      variantsCount: product.variants?.length || 0
    }), (0, import_node5.json)({ success: !0 });
  } catch (error) {
    return console.error("Error processing product creation webhook:", error), (0, import_node5.json)({ error: "Internal server error" }, { status: 500 });
  }
}

// app/routes/webhooks.products.update.js
var webhooks_products_update_exports = {};
__export(webhooks_products_update_exports, {
  action: () => action5
});
var import_node6 = require("@remix-run/node"), import_firestore5 = require("firebase-admin/firestore");
async function action5({ request }) {
  if (request.method !== "POST")
    return (0, import_node6.json)({ error: "Method not allowed" }, { status: 405 });
  try {
    let product = await request.json(), db = (0, import_firestore5.getFirestore)(), productsSnapshot = await db.collection("products").where("shopifyProductId", "==", product.id.toString()).get();
    if (!productsSnapshot.empty) {
      let productDoc = productsSnapshot.docs[0];
      await db.collection("products").doc(productDoc.id).update({
        title: product.title,
        handle: product.handle,
        vendor: product.vendor,
        productType: product.product_type,
        tags: product.tags,
        status: product.status,
        variants: product.variants?.map((variant) => ({
          id: variant.id,
          title: variant.title,
          sku: variant.sku,
          price: parseFloat(variant.price || 0),
          compareAtPrice: parseFloat(variant.compare_at_price || 0),
          inventoryQuantity: variant.inventory_quantity || 0,
          weight: variant.weight || 0,
          weightUnit: variant.weight_unit,
          requiresShipping: variant.requires_shipping,
          taxable: variant.taxable,
          barcode: variant.barcode,
          imageId: variant.image_id,
          position: variant.position,
          option1: variant.option1,
          option2: variant.option2,
          option3: variant.option3
        })) || [],
        images: product.images?.map((image) => ({
          id: image.id,
          src: image.src,
          alt: image.alt,
          position: image.position,
          width: image.width,
          height: image.height
        })) || [],
        options: product.options?.map((option) => ({
          id: option.id,
          name: option.name,
          position: option.position,
          values: option.values
        })) || [],
        shopifyData: product,
        updatedAt: (/* @__PURE__ */ new Date()).toISOString()
      }), console.log("Product updated:", {
        productId: product.id,
        title: product.title,
        handle: product.handle
      });
    }
    return (0, import_node6.json)({ success: !0 });
  } catch (error) {
    return console.error("Error processing product update webhook:", error), (0, import_node6.json)({ error: "Internal server error" }, { status: 500 });
  }
}

// app/routes/webhooks.orders.updated.js
var webhooks_orders_updated_exports = {};
__export(webhooks_orders_updated_exports, {
  action: () => action6
});
var import_node7 = require("@remix-run/node"), import_firestore6 = require("firebase-admin/firestore");
async function action6({ request }) {
  if (request.method !== "POST")
    return (0, import_node7.json)({ error: "Method not allowed" }, { status: 405 });
  try {
    let order = await request.json(), db = (0, import_firestore6.getFirestore)(), ordersSnapshot = await db.collection("orders").where("shopifyOrderId", "==", order.id.toString()).get();
    if (!ordersSnapshot.empty) {
      let orderDoc = ordersSnapshot.docs[0];
      await db.collection("orders").doc(orderDoc.id).update({
        status: order.fulfillment_status || "unfulfilled",
        totalPrice: parseFloat(order.total_price || 0),
        notes: order.note || "",
        tags: order.tags || "",
        shopifyData: order,
        updatedAt: (/* @__PURE__ */ new Date()).toISOString()
      });
    }
    return (0, import_node7.json)({ success: !0 });
  } catch (error) {
    return console.error("Error processing order update webhook:", error), (0, import_node7.json)({ error: "Internal server error" }, { status: 500 });
  }
}

// app/routes/webhooks.orders.create.js
var webhooks_orders_create_exports = {};
__export(webhooks_orders_create_exports, {
  action: () => action7
});
var import_node8 = require("@remix-run/node"), import_firestore7 = require("firebase-admin/firestore");
async function action7({ request }) {
  if (request.method !== "POST")
    return (0, import_node8.json)({ error: "Method not allowed" }, { status: 405 });
  try {
    let order = await request.json(), db = (0, import_firestore7.getFirestore)(), orderData = {
      shopifyOrderId: order.id.toString(),
      shopifyOrderNumber: order.order_number.toString(),
      shop: order.shop_domain,
      customerName: order.customer?.first_name + " " + order.customer?.last_name || "Guest",
      customerEmail: order.customer?.email || "",
      totalPrice: parseFloat(order.total_price || 0),
      currency: order.currency || "USD",
      status: order.fulfillment_status || "unfulfilled",
      items: order.line_items?.map((item) => ({
        productId: item.product_id?.toString(),
        variantId: item.variant_id?.toString(),
        sku: item.sku || "",
        name: item.name || "",
        quantity: item.quantity || 0,
        price: parseFloat(item.price || 0),
        totalPrice: parseFloat(item.price || 0) * (item.quantity || 0)
      })) || [],
      shippingAddress: order.shipping_address ? {
        firstName: order.shipping_address.first_name || "",
        lastName: order.shipping_address.last_name || "",
        company: order.shipping_address.company || "",
        address1: order.shipping_address.address1 || "",
        address2: order.shipping_address.address2 || "",
        city: order.shipping_address.city || "",
        province: order.shipping_address.province || "",
        country: order.shipping_address.country || "",
        zip: order.shipping_address.zip || "",
        phone: order.shipping_address.phone || ""
      } : null,
      billingAddress: order.billing_address ? {
        firstName: order.billing_address.first_name || "",
        lastName: order.billing_address.last_name || "",
        company: order.billing_address.company || "",
        address1: order.billing_address.address1 || "",
        address2: order.billing_address.address2 || "",
        city: order.billing_address.city || "",
        province: order.billing_address.province || "",
        country: order.billing_address.country || "",
        zip: order.billing_address.zip || "",
        phone: order.billing_address.phone || ""
      } : null,
      notes: order.note || "",
      tags: order.tags || "",
      shopifyData: order,
      createdAt: (/* @__PURE__ */ new Date()).toISOString(),
      updatedAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    await db.collection("orders").add(orderData);
    let shopConnections = await db.collection("shopConnections").where("shop", "==", order.shop_domain).where("status", "==", "active").get();
    if (!shopConnections.empty) {
      let clientId = shopConnections.docs[0].data().clientId;
      clientId && await db.collection("clients").doc(clientId).update({
        "stats.orders": db.FieldValue.increment(1),
        "stats.lastActivity": /* @__PURE__ */ new Date(),
        updatedAt: /* @__PURE__ */ new Date()
      });
    }
    return (0, import_node8.json)({ success: !0 });
  } catch (error) {
    return console.error("Error processing order webhook:", error), (0, import_node8.json)({ error: "Internal server error" }, { status: 500 });
  }
}

// app/routes/webhooks.orders.paid.js
var webhooks_orders_paid_exports = {};
__export(webhooks_orders_paid_exports, {
  action: () => action8
});
var import_node9 = require("@remix-run/node"), import_firestore8 = require("firebase-admin/firestore");
async function action8({ request }) {
  if (request.method !== "POST")
    return (0, import_node9.json)({ error: "Method not allowed" }, { status: 405 });
  try {
    let order = await request.json(), db = (0, import_firestore8.getFirestore)(), ordersSnapshot = await db.collection("orders").where("shopifyOrderId", "==", order.id.toString()).get();
    if (!ordersSnapshot.empty) {
      let orderDoc = ordersSnapshot.docs[0];
      await db.collection("orders").doc(orderDoc.id).update({
        paymentStatus: "paid",
        paidAt: (/* @__PURE__ */ new Date()).toISOString(),
        shopifyData: order,
        updatedAt: (/* @__PURE__ */ new Date()).toISOString()
      }), console.log("Order payment processed:", {
        orderId: order.id,
        orderNumber: order.order_number,
        totalPrice: order.total_price
      });
    }
    return (0, import_node9.json)({ success: !0 });
  } catch (error) {
    return console.error("Error processing order payment webhook:", error), (0, import_node9.json)({ error: "Internal server error" }, { status: 500 });
  }
}

// app/routes/webhooks.compliance.js
var webhooks_compliance_exports = {};
__export(webhooks_compliance_exports, {
  action: () => action9
});
var import_node10 = require("@remix-run/node"), import_firestore9 = require("firebase-admin/firestore"), import_crypto = __toESM(require("crypto"), 1);
function verifyWebhook(data, signature, secret) {
  let hmac = import_crypto.default.createHmac("sha256", secret);
  return hmac.update(data, "utf8"), hmac.digest("base64") === signature;
}
async function action9({ request }) {
  if (request.method !== "POST")
    return (0, import_node10.json)({ error: "Method not allowed" }, { status: 405 });
  try {
    let signature = request.headers.get("X-Shopify-Hmac-Sha256"), webhookSecret = process.env.SHOPIFY_WEBHOOK_SECRET || "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", body = await request.text();
    if (signature && !verifyWebhook(body, signature, webhookSecret))
      return console.error("Invalid webhook signature for compliance webhook"), (0, import_node10.json)({ error: "Unauthorized" }, { status: 401 });
    let webhookData = JSON.parse(body), db = (0, import_firestore9.getFirestore)();
    return console.log("Compliance webhook received:", {
      shopId: webhookData.shop_id,
      shopDomain: webhookData.shop_domain,
      webhookType: webhookData.webhook_type || "unknown"
    }), webhookData.customer && webhookData.orders_requested ? await handleDataRequest(db, webhookData) : webhookData.customer && webhookData.orders_to_redact ? await handleCustomerRedact(db, webhookData) : webhookData.shop_id && webhookData.shop_domain && !webhookData.customer ? await handleShopRedact(db, webhookData) : console.log("Unknown compliance webhook type:", webhookData), (0, import_node10.json)({ success: !0, message: "Compliance webhook processed" });
  } catch (error) {
    return console.error("Error processing compliance webhook:", error), (0, import_node10.json)({ success: !1, error: "Internal server error" });
  }
}
async function handleDataRequest(db, webhookData) {
  try {
    let { shop_id, shop_domain, customer, orders_requested, data_request } = webhookData;
    await db.collection("complianceRequests").add({
      type: "data_request",
      shopId: shop_id,
      shopDomain: shop_domain,
      customerId: customer.id,
      customerEmail: customer.email,
      customerPhone: customer.phone,
      ordersRequested: orders_requested,
      dataRequestId: data_request.id,
      status: "pending",
      createdAt: (/* @__PURE__ */ new Date()).toISOString(),
      processedAt: null
    }), console.log("Data request stored:", {
      customerId: customer.id,
      ordersRequested: orders_requested.length,
      dataRequestId: data_request.id
    });
  } catch (error) {
    console.error("Error handling data request:", error);
  }
}
async function handleCustomerRedact(db, webhookData) {
  try {
    let { shop_id, shop_domain, customer, orders_to_redact } = webhookData;
    await db.collection("complianceRequests").add({
      type: "customer_redact",
      shopId: shop_id,
      shopDomain: shop_domain,
      customerId: customer.id,
      customerEmail: customer.email,
      customerPhone: customer.phone,
      ordersToRedact: orders_to_redact,
      status: "pending",
      createdAt: (/* @__PURE__ */ new Date()).toISOString(),
      processedAt: null
    });
    let customerQuery = await db.collection("customers").where("shopifyCustomerId", "==", customer.id.toString()).where("shopId", "==", shop_id.toString()).get();
    for (let doc of customerQuery.docs)
      await doc.ref.update({
        status: "deleted",
        deletedAt: (/* @__PURE__ */ new Date()).toISOString(),
        redactionRequestId: webhookData.data_request?.id || "manual"
      });
    for (let orderId of orders_to_redact) {
      let orderQuery = await db.collection("orders").where("shopifyOrderId", "==", orderId.toString()).where("shopId", "==", shop_id.toString()).get();
      for (let doc of orderQuery.docs)
        await doc.ref.update({
          status: "deleted",
          deletedAt: (/* @__PURE__ */ new Date()).toISOString(),
          redactionRequestId: webhookData.data_request?.id || "manual"
        });
    }
    console.log("Customer redaction processed:", {
      customerId: customer.id,
      ordersRedacted: orders_to_redact.length
    });
  } catch (error) {
    console.error("Error handling customer redaction:", error);
  }
}
async function handleShopRedact(db, webhookData) {
  try {
    let { shop_id, shop_domain } = webhookData;
    await db.collection("complianceRequests").add({
      type: "shop_redact",
      shopId: shop_id,
      shopDomain: shop_domain,
      status: "pending",
      createdAt: (/* @__PURE__ */ new Date()).toISOString(),
      processedAt: null
    });
    let collections = ["orders", "customers", "products", "fulfillmentOrders", "shopifyConnections"];
    for (let collectionName of collections) {
      let query = await db.collection(collectionName).where("shopId", "==", shop_id.toString()).get();
      for (let doc of query.docs)
        await doc.ref.update({
          status: "deleted",
          deletedAt: (/* @__PURE__ */ new Date()).toISOString(),
          redactionType: "shop_redact"
        });
    }
    console.log("Shop redaction processed:", {
      shopId: shop_id,
      shopDomain: shop_domain
    });
  } catch (error) {
    console.error("Error handling shop redaction:", error);
  }
}

// app/routes/_index.tsx
var index_exports = {};
__export(index_exports, {
  default: () => Index,
  loader: () => loader
});
var import_node11 = require("@remix-run/node"), import_react3 = require("@remix-run/react"), import_jsx_runtime3 = require("react/jsx-runtime"), loader = async ({ request }) => {
  let url = new URL(request.url), shop = url.searchParams.get("shop"), hmac = url.searchParams.get("hmac");
  return (0, import_node11.json)({ shop, hmac });
};
function Index() {
  let { shop, hmac } = (0, import_react3.useLoaderData)();
  return /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("div", { className: "container", children: /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)("div", { className: "hero", children: [
    /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("h1", { children: "Welcome to Breadcrumb" }),
    /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("p", { className: "subtitle", children: "Connect your Shopify store to your WMS" }),
    shop && /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("div", { className: "shop-info", children: /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)("p", { children: [
      "Connected to: ",
      /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("strong", { children: shop })
    ] }) }),
    /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)("div", { className: "features", children: [
      /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)("div", { className: "feature-card", children: [
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("h3", { children: "Real-time Order Sync" }),
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("p", { children: "Automatically sync orders from Shopify to your WMS" })
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)("div", { className: "feature-card", children: [
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("h3", { children: "Inventory Management" }),
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("p", { children: "Keep inventory levels in sync between systems" })
      ] }),
      /* @__PURE__ */ (0, import_jsx_runtime3.jsxs)("div", { className: "feature-card", children: [
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("h3", { children: "Webhooks" }),
        /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("p", { children: "Real-time updates for orders, products, and more" })
      ] })
    ] }),
    /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("div", { className: "status", children: /* @__PURE__ */ (0, import_jsx_runtime3.jsx)("p", { children: "Ready to connect" }) })
  ] }) });
}

// server-assets-manifest:@remix-run/dev/assets-manifest
var assets_manifest_default = { entry: { module: "/build/entry.client-IMV6FZ4G.js", imports: ["/build/_shared/chunk-PZI2ANUT.js", "/build/_shared/chunk-Q3IECNXJ.js"] }, routes: { root: { id: "root", parentId: void 0, path: "", index: void 0, caseSensitive: void 0, module: "/build/root-HNHTXBW2.js", imports: void 0, hasAction: !1, hasLoader: !1, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 }, "routes/_index": { id: "routes/_index", parentId: "root", path: void 0, index: !0, caseSensitive: void 0, module: "/build/routes/_index-FFGY6FKK.js", imports: void 0, hasAction: !1, hasLoader: !0, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 }, "routes/webhooks.app.uninstalled": { id: "routes/webhooks.app.uninstalled", parentId: "root", path: "webhooks/app/uninstalled", index: void 0, caseSensitive: void 0, module: "/build/routes/webhooks.app.uninstalled-I5ERYZQE.js", imports: void 0, hasAction: !0, hasLoader: !1, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 }, "routes/webhooks.compliance": { id: "routes/webhooks.compliance", parentId: "root", path: "webhooks/compliance", index: void 0, caseSensitive: void 0, module: "/build/routes/webhooks.compliance-DJSSFTMH.js", imports: void 0, hasAction: !0, hasLoader: !1, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 }, "routes/webhooks.fulfillment-orders.request": { id: "routes/webhooks.fulfillment-orders.request", parentId: "root", path: "webhooks/fulfillment-orders/request", index: void 0, caseSensitive: void 0, module: "/build/routes/webhooks.fulfillment-orders.request-CHHDVBWS.js", imports: void 0, hasAction: !0, hasLoader: !1, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 }, "routes/webhooks.orders.create": { id: "routes/webhooks.orders.create", parentId: "root", path: "webhooks/orders/create", index: void 0, caseSensitive: void 0, module: "/build/routes/webhooks.orders.create-6OTKYQ2R.js", imports: void 0, hasAction: !0, hasLoader: !1, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 }, "routes/webhooks.orders.fulfilled": { id: "routes/webhooks.orders.fulfilled", parentId: "root", path: "webhooks/orders/fulfilled", index: void 0, caseSensitive: void 0, module: "/build/routes/webhooks.orders.fulfilled-NRCGH474.js", imports: void 0, hasAction: !0, hasLoader: !1, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 }, "routes/webhooks.orders.paid": { id: "routes/webhooks.orders.paid", parentId: "root", path: "webhooks/orders/paid", index: void 0, caseSensitive: void 0, module: "/build/routes/webhooks.orders.paid-FFGWI7SC.js", imports: void 0, hasAction: !0, hasLoader: !1, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 }, "routes/webhooks.orders.updated": { id: "routes/webhooks.orders.updated", parentId: "root", path: "webhooks/orders/updated", index: void 0, caseSensitive: void 0, module: "/build/routes/webhooks.orders.updated-DYFI5FHS.js", imports: void 0, hasAction: !0, hasLoader: !1, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 }, "routes/webhooks.products.create": { id: "routes/webhooks.products.create", parentId: "root", path: "webhooks/products/create", index: void 0, caseSensitive: void 0, module: "/build/routes/webhooks.products.create-YFBBKRXF.js", imports: void 0, hasAction: !0, hasLoader: !1, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 }, "routes/webhooks.products.update": { id: "routes/webhooks.products.update", parentId: "root", path: "webhooks/products/update", index: void 0, caseSensitive: void 0, module: "/build/routes/webhooks.products.update-E3Z3XX4O.js", imports: void 0, hasAction: !0, hasLoader: !1, hasClientAction: !1, hasClientLoader: !1, hasErrorBoundary: !1 } }, version: "291f5fa3", hmr: void 0, url: "/build/manifest-291F5FA3.js" };

// server-entry-module:@remix-run/dev/server-build
var mode = "production", assetsBuildDirectory = "public/build", future = { v3_fetcherPersist: !1, v3_relativeSplatPath: !1, v3_throwAbortReason: !1, v3_routeConfig: !1, v3_singleFetch: !1, v3_lazyRouteDiscovery: !1, unstable_optimizeDeps: !1 }, publicPath = "/build/", entry = { module: entry_server_node_exports }, routes = {
  root: {
    id: "root",
    parentId: void 0,
    path: "",
    index: void 0,
    caseSensitive: void 0,
    module: root_exports
  },
  "routes/webhooks.fulfillment-orders.request": {
    id: "routes/webhooks.fulfillment-orders.request",
    parentId: "root",
    path: "webhooks/fulfillment-orders/request",
    index: void 0,
    caseSensitive: void 0,
    module: webhooks_fulfillment_orders_request_exports
  },
  "routes/webhooks.orders.fulfilled": {
    id: "routes/webhooks.orders.fulfilled",
    parentId: "root",
    path: "webhooks/orders/fulfilled",
    index: void 0,
    caseSensitive: void 0,
    module: webhooks_orders_fulfilled_exports
  },
  "routes/webhooks.app.uninstalled": {
    id: "routes/webhooks.app.uninstalled",
    parentId: "root",
    path: "webhooks/app/uninstalled",
    index: void 0,
    caseSensitive: void 0,
    module: webhooks_app_uninstalled_exports
  },
  "routes/webhooks.products.create": {
    id: "routes/webhooks.products.create",
    parentId: "root",
    path: "webhooks/products/create",
    index: void 0,
    caseSensitive: void 0,
    module: webhooks_products_create_exports
  },
  "routes/webhooks.products.update": {
    id: "routes/webhooks.products.update",
    parentId: "root",
    path: "webhooks/products/update",
    index: void 0,
    caseSensitive: void 0,
    module: webhooks_products_update_exports
  },
  "routes/webhooks.orders.updated": {
    id: "routes/webhooks.orders.updated",
    parentId: "root",
    path: "webhooks/orders/updated",
    index: void 0,
    caseSensitive: void 0,
    module: webhooks_orders_updated_exports
  },
  "routes/webhooks.orders.create": {
    id: "routes/webhooks.orders.create",
    parentId: "root",
    path: "webhooks/orders/create",
    index: void 0,
    caseSensitive: void 0,
    module: webhooks_orders_create_exports
  },
  "routes/webhooks.orders.paid": {
    id: "routes/webhooks.orders.paid",
    parentId: "root",
    path: "webhooks/orders/paid",
    index: void 0,
    caseSensitive: void 0,
    module: webhooks_orders_paid_exports
  },
  "routes/webhooks.compliance": {
    id: "routes/webhooks.compliance",
    parentId: "root",
    path: "webhooks/compliance",
    index: void 0,
    caseSensitive: void 0,
    module: webhooks_compliance_exports
  },
  "routes/_index": {
    id: "routes/_index",
    parentId: "root",
    path: void 0,
    index: !0,
    caseSensitive: void 0,
    module: index_exports
  }
};
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  assets,
  assetsBuildDirectory,
  entry,
  future,
  mode,
  publicPath,
  routes
});
