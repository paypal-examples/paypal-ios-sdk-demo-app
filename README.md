# PayPal Mobile SDK Demo Apps

Sample apps demonstrating PayPal payment integrations for iOS and Android. Clone, configure your sandbox credentials, and see payments working in under 90 seconds.

> **New to PayPal?** [Create a sandbox account](https://developer.paypal.com/dashboard/applications/sandbox) to get your Client ID and Secret.

---

## Pick Your Integration

| Integration | Description | iOS | Android | Server Required |
|---|---|---|---|---|
| **[Direct API — App Switch](./direct-api-app-switch/)** | Redirect to the PayPal app for payment approval using Orders v2 and Vault v3 with `app_switch_context`. No PayPal SDK dependency. | Swift | Kotlin | Yes (included) |
| **[Native SDK](./native-sdk/)** | Use the PayPal Mobile SDK for a fully managed checkout experience with built-in UI components. | Swift | Kotlin | Yes (Heroku hosted) |

### Which should I use?

| | Direct API (App Switch) | Native SDK |
|---|---|---|
| **SDK dependency** | None — raw URLSession / HttpURLConnection | PayPal iOS SDK / Android SDK |
| **UI ownership** | You build the UI | SDK provides checkout sheet |
| **Server calls** | Your app calls your server, server calls PayPal | SDK handles most communication |
| **App Switch** | Full control over redirect and return handling | Managed by SDK |
| **Best for** | Maximum control, custom UX, learning the API | Fastest integration, standard UX |

---

## Quick Start (Direct API — App Switch)

### 1. Get sandbox credentials

Create a [sandbox REST app](https://developer.paypal.com/dashboard/applications/sandbox) and copy your **Client ID** and **Client Secret**.

### 2. Start the demo server

```bash
cd demo-server
cp .env.sample .env        # paste your credentials in .env
npm install && npm start
```

You should see: `✅ Connected to PayPal sandbox (merchant: your-email@example.com)`

Or use Docker:
```bash
docker-compose up
```

### 3. Run the mobile app

**iOS:**
```bash
cd direct-api-app-switch/ios
cp Config.plist.example Config.plist   # paste credentials
# Open AppSwitchTest.xcodeproj in Xcode, run on device
```

**Android:**
```bash
cd direct-api-app-switch/android
cp local.properties.example local.properties   # paste credentials
# Open in Android Studio, run on device
```

### 4. Test a payment

1. Tap **Pay $25.00** — creates an order with `app_switch_context`
2. PayPal app opens (or browser fallback)
3. Approve the payment
4. App captures the order and shows the Capture ID

Check `http://localhost:3000/debug` to see every API request and response as copyable cURL commands.

---

## Project Structure

```
├── README.md                    ← You are here
├── ARCHITECTURE.md              ← Why the code is structured this way
├── PRODUCTION-CHECKLIST.md      ← Sandbox → production migration guide
├── LICENSE                      ← Apache 2.0
├── docker-compose.yml           ← One-command server startup
├── demo-server/                 ← Node.js server (OAuth, Orders, Vault)
├── direct-api-app-switch/       ← Direct API with app_switch_context
│   ├── ios/                     ← Swift sample app
│   └── android/                 ← Kotlin sample app
├── native-sdk/                  ← PayPal Mobile SDK integration
│   ├── ios/
│   └── android/
└── e2e/demos/                   ← Playwright demo recording scripts
```

---

## Debug Panel

The demo server includes a built-in request/response logger at `/debug`. Every API call is logged with:

- Timestamp and HTTP method
- Full request body (formatted JSON)
- Full response body with status code
- Copyable **cURL command** (credentials redacted)

This makes the sample app a learning tool — see exactly what PayPal API calls look like without reading docs.

---

## Documentation

- [App Switch Integration Guide](https://developer.paypal.com/docs/checkout/app-switch/)
- [Orders v2 API Reference](https://developer.paypal.com/docs/api/orders/v2/)
- [Vault v3 API Reference](https://developer.paypal.com/docs/api/payment-tokens/v3/)
- [Architecture Decisions](./ARCHITECTURE.md)
- [Production Checklist](./PRODUCTION-CHECKLIST.md)

---

## Contributing

See [CODEOWNERS](./.github/CODEOWNERS) for code ownership. To contribute:

1. Fork this repository
2. Create a feature branch
3. Submit a pull request

Please ensure your changes pass the CI build checks (iOS compile + Android compile).

---

## License

[Apache 2.0](./LICENSE) — Copyright 2026 PayPal, Inc.
