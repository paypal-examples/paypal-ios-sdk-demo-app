# PayPal App Switch Demo Server

Backend server for the App Switch sample apps. Handles OAuth, Orders v2, and Vault v3 API calls using raw `fetch` so you can see exactly what each request looks like.

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Copy .env.sample and add your sandbox credentials
npm run setup
# Then edit .env with your Client ID and Secret from https://developer.paypal.com/dashboard/applications/sandbox

# 3. Start the server
npm start
```

Or with Docker:

```bash
# From the sample-apps/ directory
cp demo-server/.env.sample demo-server/.env
# Edit demo-server/.env with your credentials
docker compose up
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/token` | Get OAuth access token |
| POST | `/orders` | Create order with app_switch_context |
| POST | `/orders/:id/capture` | Capture an approved order |
| POST | `/vault/setup-tokens` | Create vault setup token with app_switch_context |
| POST | `/vault/payment-tokens` | Exchange setup token for payment token |
| POST | `/orders/vault-charge` | Charge a saved payment method |
| GET | `/health` | Credential validation and merchant info |
| GET | `/debug` | Last 50 API request/response logs with cURL commands |

## Getting Sandbox Credentials

1. Go to [developer.paypal.com/dashboard](https://developer.paypal.com/dashboard/applications/sandbox)
2. Create or select a REST API app
3. Copy the **Client ID** and **Secret** into your `.env` file
