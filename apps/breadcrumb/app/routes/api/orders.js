import { authenticate } from '~/shopify.server';

export async function loader({ request }) {
  const { admin } = await authenticate.admin(request);

  const response = await admin.graphql(`
    {
      orders(first: 20) {
        edges {
          node {
            id
            name
            createdAt
            totalPriceSet { shopMoney { amount currencyCode } }
            lineItems(first: 10) {
              edges {
                node {
                  title
                  quantity
                }
              }
            }
            customer {
              firstName
              lastName
              email
            }
            fulfillments {
              trackingInfo {
                number
                url
              }
              createdAt
              status
            }
          }
        }
      }
    }
  `);

  const data = await response.json();
  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' }
  });
} 