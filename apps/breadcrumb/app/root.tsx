import type { MetaFunction, LinksFunction } from "@remix-run/node";
import {
  Links,
  LiveReload,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
} from "@remix-run/react";
import styles from "./styles.css";

export const meta: MetaFunction = () => ({
  charset: "utf-8",
  title: "Breadcrumb - Connect Shopify Orders to WMS",
  viewport: "width=device-width,initial-scale=1",
});

export const links: LinksFunction = () => [
  { rel: "stylesheet", href: styles },
];

export default function App() {
  return (
    <html lang="en">
      <head>
        <Meta />
        <Links />
      </head>
      <body>
        <div className="app">
          <header>
            <h1>Breadcrumb</h1>
            <p>Connect Shopify Orders to WMS</p>
          </header>
          <main>
            <Outlet />
          </main>
        </div>
        <ScrollRestoration />
        <Scripts />
        <LiveReload />
      </body>
    </html>
  );
}

