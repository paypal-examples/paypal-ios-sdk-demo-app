# Error Reference — PayPal App Switch Direct API

Common errors developers encounter when integrating, with causes and fixes.

## Authentication Errors

### AUTHENTICATION_FAILURE
- **HTTP:** 401
- **When:** OAuth token request with invalid credentials
- **Cause:** Wrong Client ID or Client Secret
- **Fix:** Verify credentials at https://developer.paypal.com/dashboard/applications/sandbox

### INVALID_CLIENT
- **HTTP:** 401
- **When:** OAuth token request
- **Cause:** Client ID doesn't exist or is deactivated
- **Fix:** Create a new REST app in the sandbox dashboard

## Order Creation Errors

### INVALID_PARAMETER_VALUE
- **HTTP:** 400
- **When:** POST /v2/checkout/orders
- **Cause:** Malformed amount, missing currency_code, invalid os_type
- **Fix:** Ensure amount.value is a string decimal ("25.00"), currency_code is ISO 4217, os_type is "IOS" or "ANDROID"

### PERMISSION_DENIED
- **HTTP:** 403
- **When:** POST /v2/checkout/orders with app_switch_context
- **Cause:** Sandbox app not enabled for App Switch
- **Fix:** Contact your PayPal account representative to enable App Switch for your sandbox app

### INVALID_RESOURCE_ID
- **HTTP:** 404
- **When:** POST /v2/checkout/orders/{id}/capture
- **Cause:** Order ID doesn't exist or has already been captured
- **Fix:** Verify the order ID from the create-order response. Each order can only be captured once.

## App Switch Errors

### App Switch Not Eligible (app_switch_eligibility: false)
- **When:** Order created but app_switch_eligibility is false in response
- **Cause:** Sandbox app not configured for App Switch, or os_type not set correctly
- **Fix:** Ensure app_switch_context.native_app includes os_type ("IOS" or "ANDROID") and valid return/cancel URLs

### Buyer Cancelled
- **When:** After redirect to PayPal
- **Cause:** Buyer tapped cancel in PayPal app/browser, or return URL didn't match callback scheme
- **Fix:** Check return_url matches your app's URL scheme. On simulator/emulator, use custom URL scheme (appswitch-test://) not HTTPS domain.

### Redirect to example.com
- **When:** After buyer approves payment in browser
- **Cause:** return_url set to https://example.com but no Associated Domains / App Links configured
- **Fix:** Replace example.com with your verified domain, or use custom URL scheme for testing

## Vault Errors

### INVALID_PARAMETER_VALUE (Vault)
- **HTTP:** 400
- **When:** POST /v3/vault/setup-tokens
- **Cause:** Missing usage_type, customer_type, or experience_context
- **Fix:** Include usage_type: "MERCHANT" and customer_type: "CONSUMER" in payment_source.paypal

### SETUP_TOKEN_NOT_APPROVED
- **HTTP:** 422
- **When:** POST /v3/vault/payment-tokens
- **Cause:** Trying to create payment token before buyer approved the setup token
- **Fix:** Wait for buyer to complete approval flow and return to your app before calling payment-tokens

## Capture Errors

### ORDER_NOT_APPROVED
- **HTTP:** 422
- **When:** POST /v2/checkout/orders/{id}/capture
- **Cause:** Attempting to capture before buyer approved
- **Fix:** Only call capture after receiving the return redirect with token and PayerID

### DUPLICATE_INVOICE_ID
- **HTTP:** 422
- **When:** POST /v2/checkout/orders/{id}/capture
- **Cause:** Same PayPal-Request-Id used for multiple capture calls
- **Fix:** Generate a unique UUID for each PayPal-Request-Id header

## Platform-Specific Errors

### iOS: "Missing Config.plist"
- **When:** App launch
- **Cause:** Config.plist not created from template
- **Fix:** cp Config.plist.example Config.plist and add your credentials

### iOS: ASWebAuthenticationSession cancelled immediately
- **When:** Tapping Pay on simulator
- **Cause:** .https callback requires Associated Domains not available on simulator
- **Fix:** App automatically uses custom URL scheme on simulator. If still failing, verify #if targetEnvironment(simulator) in AppSwitchHandler.swift

### Android: Missing credentials banner
- **When:** App launch
- **Cause:** local.properties not created or credentials empty
- **Fix:** cp local.properties.example local.properties and add credentials. They're injected via BuildConfig at build time — rebuild after editing.

### Android: Chrome "Something went wrong"
- **When:** First launch on fresh emulator
- **Cause:** Chrome first-run setup (no Google account)
- **Fix:** Tap "Use without an account" to dismiss Chrome setup, then return to the app
