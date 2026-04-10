#!/usr/bin/env node
/**
 * PayPal App Switch Demo Server — Zero-Config Setup
 *
 * Validates Node version, configures .env credentials,
 * and verifies sandbox connectivity in one step.
 *
 * Usage: node setup.js   (or: npm run setup)
 */

const fs = require("fs");
const path = require("path");
const readline = require("readline");
const https = require("https");

// ANSI color helpers
const GREEN = "\x1b[32m";
const RED = "\x1b[31m";
const YELLOW = "\x1b[33m";
const CYAN = "\x1b[36m";
const BOLD = "\x1b[1m";
const RESET = "\x1b[0m";

const DASHBOARD_URL =
  "https://developer.paypal.com/dashboard/applications/sandbox";
const TOKEN_URL = "https://api-m.sandbox.paypal.com/v1/oauth2/token";
const ENV_FILE = path.join(__dirname, ".env");
const ENV_SAMPLE = path.join(__dirname, ".env.sample");

// ── Step 1: Check Node version ──────────────────────────────────────────────

function checkNodeVersion() {
  const major = parseInt(process.versions.node.split(".")[0], 10);
  if (major < 18) {
    console.log(
      `${YELLOW}Warning: Node.js v18+ is required. You are running v${process.versions.node}.${RESET}`
    );
    console.log(
      `${YELLOW}Download the latest LTS at https://nodejs.org${RESET}\n`
    );
  } else {
    console.log(`${GREEN}Node.js v${process.versions.node}${RESET}`);
  }
}

// ── Step 2: Ensure .env exists ──────────────────────────────────────────────

function ensureEnvFile() {
  if (!fs.existsSync(ENV_FILE)) {
    if (!fs.existsSync(ENV_SAMPLE)) {
      // Create a minimal .env if no sample exists either
      fs.writeFileSync(
        ENV_FILE,
        [
          "PAYPAL_CLIENT_ID=",
          "PAYPAL_CLIENT_SECRET=",
          "PAYPAL_API_BASE=https://api-m.sandbox.paypal.com",
          "RETURN_DOMAIN=https://example.com",
          "PORT=3000",
          "",
        ].join("\n")
      );
      console.log(`Created ${CYAN}.env${RESET} with defaults.`);
    } else {
      fs.copyFileSync(ENV_SAMPLE, ENV_FILE);
      console.log(`Created ${CYAN}.env${RESET} from .env.sample.`);
    }
  } else {
    console.log(`${CYAN}.env${RESET} already exists.`);
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

function readEnv() {
  const content = fs.readFileSync(ENV_FILE, "utf-8");
  const vars = {};
  for (const line of content.split("\n")) {
    const match = line.match(/^([A-Z_]+)=(.*)$/);
    if (match) vars[match[1]] = match[2].trim();
  }
  return vars;
}

function writeCredentials(clientId, clientSecret) {
  let content = fs.readFileSync(ENV_FILE, "utf-8");
  content = content.replace(
    /^PAYPAL_CLIENT_ID=.*$/m,
    `PAYPAL_CLIENT_ID=${clientId}`
  );
  content = content.replace(
    /^PAYPAL_CLIENT_SECRET=.*$/m,
    `PAYPAL_CLIENT_SECRET=${clientSecret}`
  );
  fs.writeFileSync(ENV_FILE, content);
}

function ask(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

// ── Step 3: Prompt for credentials if missing ───────────────────────────────

async function ensureCredentials() {
  const env = readEnv();
  const hasId = env.PAYPAL_CLIENT_ID && env.PAYPAL_CLIENT_ID.length > 0;
  const hasSecret =
    env.PAYPAL_CLIENT_SECRET && env.PAYPAL_CLIENT_SECRET.length > 0;

  if (hasId && hasSecret) {
    return { clientId: env.PAYPAL_CLIENT_ID, clientSecret: env.PAYPAL_CLIENT_SECRET };
  }

  console.log(
    `\n${BOLD}Paste your sandbox credentials.${RESET}`
  );
  console.log(`Get them at: ${CYAN}${DASHBOARD_URL}${RESET}\n`);

  const clientId = await ask("Client ID: ");
  const clientSecret = await ask("Client Secret: ");

  if (!clientId || !clientSecret) {
    console.log(`${RED}Both Client ID and Client Secret are required.${RESET}`);
    process.exit(1);
  }

  writeCredentials(clientId, clientSecret);
  console.log(`\n${GREEN}Credentials saved to .env${RESET}`);
  return { clientId, clientSecret };
}

// ── Step 4: Validate credentials against sandbox ────────────────────────────

function validateCredentials(clientId, clientSecret) {
  return new Promise((resolve) => {
    const auth = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");
    const body = "grant_type=client_credentials";

    const url = new URL(TOKEN_URL);
    const options = {
      hostname: url.hostname,
      path: url.pathname,
      method: "POST",
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/x-www-form-urlencoded",
        "Content-Length": Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        if (res.statusCode === 200) {
          resolve(true);
        } else {
          resolve(false);
        }
      });
    });

    req.on("error", () => resolve(false));
    req.write(body);
    req.end();
  });
}

// ── Main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`\n${BOLD}${CYAN}PayPal App Switch Demo Server Setup${RESET}\n`);

  checkNodeVersion();
  ensureEnvFile();

  const { clientId, clientSecret } = await ensureCredentials();

  process.stdout.write("\nValidating credentials... ");
  const valid = await validateCredentials(clientId, clientSecret);

  if (valid) {
    console.log(`${GREEN}Connected to PayPal sandbox${RESET}\n`);
    console.log(`Run ${CYAN}npm start${RESET} to start the server.\n`);
  } else {
    console.log(
      `${RED}Invalid credentials${RESET}\n`
    );
    console.log(
      `Double-check your Client ID and Secret at:\n${CYAN}${DASHBOARD_URL}${RESET}\n`
    );
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(`${RED}Setup failed: ${err.message}${RESET}`);
  process.exit(1);
});
