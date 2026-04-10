require("dotenv").config();
const express = require("express");
const cors = require("cors");
const crypto = require("crypto");

const app = express();
app.use(express.json());
app.use(cors({ origin: /localhost/ }));

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const {
  PAYPAL_CLIENT_ID,
  PAYPAL_CLIENT_SECRET,
  PAYPAL_API_BASE = "https://api-m.sandbox.paypal.com",
  RETURN_DOMAIN = "https://example.com",
  PORT = 3000,
} = process.env;

// ---------------------------------------------------------------------------
// In-memory debug log (last 50 API calls)
// ---------------------------------------------------------------------------
const debugLog = [];
const MAX_LOG = 50;

function logEntry(entry) {
  debugLog.push(entry);
  if (debugLog.length > MAX_LOG) debugLog.shift();
}

// ---------------------------------------------------------------------------
// PayPal API helper — raw fetch, no SDK
// ---------------------------------------------------------------------------
function buildCurl(method, url, headers, body) {
  const parts = [`curl -X ${method} '${url}'`];
  for (const [k, v] of Object.entries(headers)) {
    if (k.toLowerCase() === "authorization") {
      parts.push(`  -H '${k}: Bearer <ACCESS_TOKEN>'`);
    } else {
      parts.push(`  -H '${k}: ${v}'`);
    }
  }
  if (body) parts.push(`  -d '${JSON.stringify(body)}'`);
  return parts.join(" \\\n");
}

async function paypalRequest(method, path, { body, token, extraHeaders } = {}) {
  const url = `${PAYPAL_API_BASE}${path}`;
  const headers = {
    "Content-Type": "application/json",
    Accept: "application/json",
    ...extraHeaders,
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  // Add idempotency key on mutating requests
  if (method !== "GET") {
    headers["PayPal-Request-Id"] = crypto.randomUUID();
  }

  const curlCommand = buildCurl(method, url, headers, body);

  const res = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  const responseBody = await res.json().catch(() => ({}));

  logEntry({
    timestamp: new Date().toISOString(),
    method,
    url,
    requestBody: body || null,
    responseStatus: res.status,
    responseBody,
    curlCommand,
  });

  return { status: res.status, data: responseBody };
}

// ---------------------------------------------------------------------------
// OAuth token cache
// ---------------------------------------------------------------------------
let cachedToken = null;
let tokenExpiry = 0;

async function getAccessToken() {
  if (cachedToken && Date.now() < tokenExpiry) {
    return cachedToken;
  }

  const credentials = Buffer.from(
    `${PAYPAL_CLIENT_ID}:${PAYPAL_CLIENT_SECRET}`
  ).toString("base64");

  const url = `${PAYPAL_API_BASE}/v1/oauth2/token`;
  const headers = {
    Authorization: `Basic ${credentials}`,
    "Content-Type": "application/x-www-form-urlencoded",
  };
  const bodyStr = "grant_type=client_credentials";

  const curlCommand = [
    `curl -X POST '${url}'`,
    `  -H 'Authorization: Basic <BASE64_CREDENTIALS>'`,
    `  -H 'Content-Type: application/x-www-form-urlencoded'`,
    `  -d '${bodyStr}'`,
  ].join(" \\\n");

  const res = await fetch(url, {
    method: "POST",
    headers,
    body: bodyStr,
  });

  const data = await res.json();

  logEntry({
    timestamp: new Date().toISOString(),
    method: "POST",
    url,
    requestBody: bodyStr,
    responseStatus: res.status,
    responseBody: data,
    curlCommand,
  });

  if (!res.ok) {
    throw new Error(`OAuth failed: ${res.status} ${JSON.stringify(data)}`);
  }

  cachedToken = data.access_token;
  // Expire 60 seconds early to avoid edge cases
  tokenExpiry = Date.now() + (data.expires_in - 60) * 1000;

  return cachedToken;
}

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

// POST /auth/token — return an access token to the mobile app
app.post("/auth/token", async (_req, res) => {
  try {
    const token = await getAccessToken();
    res.json({
      access_token: token,
      expires_in: Math.max(0, Math.floor((tokenExpiry - Date.now()) / 1000)),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /orders — create an order with app_switch_context
app.post("/orders", async (req, res) => {
  try {
    const token = await getAccessToken();
    const { amount = "10.00", os_type = "Android", os_version = "14" } = req.body || {};

    const orderBody = {
      intent: "CAPTURE",
      purchase_units: [
        {
          amount: {
            currency_code: "USD",
            value: amount,
          },
        },
      ],
      payment_source: {
        paypal: {
          experience_context: {
            return_url: `${RETURN_DOMAIN}/return`,
            cancel_url: `${RETURN_DOMAIN}/cancel`,
            shipping_preference: "NO_SHIPPING",
            user_action: "PAY_NOW",
          },
          app_switch_context: {
            os_type,
            os_version,
          },
        },
      },
    };

    const { status, data } = await paypalRequest("POST", "/v2/checkout/orders", {
      token,
      body: orderBody,
    });

    res.status(status).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /orders/:id/capture — capture an approved order
app.post("/orders/:id/capture", async (req, res) => {
  try {
    const token = await getAccessToken();
    const { status, data } = await paypalRequest(
      "POST",
      `/v2/checkout/orders/${req.params.id}/capture`,
      { token }
    );
    res.status(status).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /vault/setup-tokens — create a vault setup token with app_switch_context
app.post("/vault/setup-tokens", async (req, res) => {
  try {
    const token = await getAccessToken();
    const { os_type = "Android", os_version = "14" } = req.body || {};

    const setupBody = {
      payment_source: {
        paypal: {
          experience_context: {
            return_url: `${RETURN_DOMAIN}/return`,
            cancel_url: `${RETURN_DOMAIN}/cancel`,
            shipping_preference: "NO_SHIPPING",
          },
          app_switch_context: {
            os_type,
            os_version,
          },
        },
      },
    };

    const { status, data } = await paypalRequest("POST", "/v3/vault/setup-tokens", {
      token,
      body: setupBody,
    });

    res.status(status).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /vault/payment-tokens — exchange setup token for payment token
app.post("/vault/payment-tokens", async (req, res) => {
  try {
    const token = await getAccessToken();
    const { setup_token_id } = req.body || {};

    if (!setup_token_id) {
      return res.status(400).json({ error: "setup_token_id is required" });
    }

    const paymentTokenBody = {
      payment_source: {
        token: {
          id: setup_token_id,
          type: "SETUP_TOKEN",
        },
      },
    };

    const { status, data } = await paypalRequest("POST", "/v3/vault/payment-tokens", {
      token,
      body: paymentTokenBody,
    });

    res.status(status).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /orders/vault-charge — charge using a saved payment method (vault ID)
app.post("/orders/vault-charge", async (req, res) => {
  try {
    const token = await getAccessToken();
    const { vault_id, amount = "10.00" } = req.body || {};

    if (!vault_id) {
      return res.status(400).json({ error: "vault_id is required" });
    }

    const orderBody = {
      intent: "CAPTURE",
      purchase_units: [
        {
          amount: {
            currency_code: "USD",
            value: amount,
          },
        },
      ],
      payment_source: {
        paypal: {
          vault_id,
        },
      },
    };

    const { status, data } = await paypalRequest("POST", "/v2/checkout/orders", {
      token,
      body: orderBody,
    });

    // If order created successfully with vault, capture immediately
    if (status >= 200 && status < 300 && data.id) {
      const capture = await paypalRequest(
        "POST",
        `/v2/checkout/orders/${data.id}/capture`,
        { token }
      );
      return res.status(capture.status).json(capture.data);
    }

    res.status(status).json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /health — validate sandbox credentials
app.get("/health", async (_req, res) => {
  try {
    const token = await getAccessToken();
    // Fetch merchant identity to confirm credentials work
    const { status, data } = await paypalRequest(
      "GET",
      "/v1/identity/oauth2/userinfo?schema=paypalv1.1",
      { token }
    );

    if (status >= 200 && status < 300) {
      const email =
        data.emails?.find((e) => e.primary)?.value ||
        data.emails?.[0]?.value ||
        "unknown";
      res.json({ status: "ok", merchant: email });
    } else {
      res.status(500).json({
        status: "error",
        message: "Credentials invalid or expired",
        dashboard: "https://developer.paypal.com/dashboard/applications/sandbox",
      });
    }
  } catch (err) {
    res.status(500).json({
      status: "error",
      message: err.message,
      dashboard: "https://developer.paypal.com/dashboard/applications/sandbox",
    });
  }
});

// GET /debug — return last 50 API request/response logs
app.get("/debug", (_req, res) => {
  res.json(debugLog);
});

// ---------------------------------------------------------------------------
// Startup
// ---------------------------------------------------------------------------
async function startup() {
  if (!PAYPAL_CLIENT_ID || !PAYPAL_CLIENT_SECRET) {
    console.error("\x1b[31m✗ Missing PAYPAL_CLIENT_ID or PAYPAL_CLIENT_SECRET in .env\x1b[0m");
    console.error("  Run: npm run setup");
    console.error("  Then edit .env with credentials from https://developer.paypal.com/dashboard/applications/sandbox");
    process.exit(1);
  }

  console.log(`\nPayPal App Switch Demo Server`);
  console.log(`API Base: ${PAYPAL_API_BASE}\n`);

  // Validate credentials
  try {
    const token = await getAccessToken();
    const { status, data } = await paypalRequest(
      "GET",
      "/v1/identity/oauth2/userinfo?schema=paypalv1.1",
      { token }
    );

    if (status >= 200 && status < 300) {
      const email =
        data.emails?.find((e) => e.primary)?.value ||
        data.emails?.[0]?.value ||
        "unknown";
      console.log(`\x1b[32m✓ Credentials valid — merchant: ${email}\x1b[0m`);
    } else {
      console.error(`\x1b[31m✗ Credential check failed (${status})\x1b[0m`);
      console.error(`  Update credentials: https://developer.paypal.com/dashboard/applications/sandbox`);
    }
  } catch (err) {
    console.error(`\x1b[31m✗ Credential check failed: ${err.message}\x1b[0m`);
    console.error(`  Update credentials: https://developer.paypal.com/dashboard/applications/sandbox`);
  }

  app.listen(PORT, () => {
    console.log(`\n\x1b[32m✓ Listening on http://localhost:${PORT}\x1b[0m`);
    console.log(`  Health:  http://localhost:${PORT}/health`);
    console.log(`  Debug:   http://localhost:${PORT}/debug\n`);
  });
}

startup();
