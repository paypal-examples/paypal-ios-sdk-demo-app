# Production Checklist

What to change before going live with real transactions.

## API Configuration

- [ ] Switch API base URL from `api-m.sandbox.paypal.com` to `api-m.paypal.com`
- [ ] Create a live app at [developer.paypal.com/dashboard](https://developer.paypal.com/dashboard) and use its credentials
- [ ] Replace sandbox client ID and secret on your server with live credentials
- [ ] Store credentials in environment variables or a secrets manager, not in code

## Return Domain

- [ ] Register a return URL on a verified domain you own (not `example.com`)
- [ ] **iOS:** Update Associated Domains entitlement to match your return domain
- [ ] **iOS:** Serve an Apple App Site Association (AASA) file from `https://yourdomain.com/.well-known/apple-app-site-association`
- [ ] **Android:** Update App Links intent filter to match your return domain
- [ ] **Android:** Serve a Digital Asset Links file from `https://yourdomain.com/.well-known/assetlinks.json`

## Webhooks

- [ ] Register a production webhook endpoint for `CHECKOUT.ORDER.COMPLETED` events
- [ ] Verify webhook signatures on your server to prevent spoofed notifications
- [ ] Confirm your webhook endpoint returns `200` for valid events

## Apple Pay (if applicable)

- [ ] Register an Apple Pay merchant ID in your Apple Developer account
- [ ] Upload the PayPal-signed domain association file to your server
- [ ] Verify the domain in your PayPal developer dashboard

## Final Verification

- [ ] Run a small real transaction (e.g., $0.01) to confirm the full flow works
- [ ] Verify the transaction appears in your PayPal business dashboard
- [ ] Confirm your webhook endpoint received the event
- [ ] Refund the test transaction
