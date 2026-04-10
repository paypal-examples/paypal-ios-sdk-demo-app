# Architecture Decisions

Why the code is structured the way it is.

## Why the server creates orders (not the client)

Your mobile app never touches PayPal API credentials. The server holds the
client ID and secret, creates the order via the Orders API, and returns only
the order ID to the app. If credentials lived in the app binary, anyone could
extract them and create charges on your account.

## Why app_switch_context is used

When you include `payment_source.paypal.experience_context.app_switch_context`
in the create-order request, PayPal returns approval links that open the
native PayPal app instead of a web view. This gives buyers a faster, more
familiar checkout experience with biometric auth already set up in their
PayPal app.

## Why webhooks matter for order fulfillment

After the buyer approves and your server captures the order, the capture
response confirms the payment. But network failures happen. Always register
a `CHECKOUT.ORDER.COMPLETED` webhook so your backend can reconcile orders
even if the mobile app never receives the capture response. Do not fulfill
orders based solely on the client-side redirect.

## Why idempotency keys are included

The `PayPal-Request-Id` header prevents duplicate charges. If your server
sends a capture request, gets a timeout, and retries, PayPal recognizes the
duplicate request ID and returns the original response instead of charging
the buyer twice. Always generate a unique key per order operation.

## Where to add your business logic

The sample apps show the minimum PayPal integration. Your production code
goes in between capture confirmation and the success screen:

1. Server captures the order and gets a `COMPLETED` status
2. **Your code here:** save the transaction, update inventory, send receipt
3. Server responds to the app with a success payload
4. App shows the confirmation screen

## Security: always use a backend server

These sample apps use a demo server for a reason. A mobile app is untrusted
code running on a device you do not control. Every PayPal API call that
requires credentials must go through your server. The mobile app only knows
the order ID and the approval redirect URL -- never the client secret.

Ship the app with your server URL. Ship the server with your PayPal
credentials. Never the other way around.
