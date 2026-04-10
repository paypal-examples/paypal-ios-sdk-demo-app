# PayPal App Switch Direct API - iOS Sample App

Minimal SwiftUI test app for the PayPal App Switch Direct API integration.
Source: `direct-api.mdx` integration guide.

## Files

| File | Purpose |
|---|---|
| `AppSwitchTestApp.swift` | SwiftUI app entry point; handles `onOpenURL` for universal link returns |
| `ContentView.swift` | Single screen with Pay / Save buttons, status text, and results |
| `PayPalService.swift` | All PayPal API calls (OAuth, Orders v2, Vault v3) via URLSession |
| `AppSwitchHandler.swift` | App detection, redirect logic, ASWebAuthenticationSession fallback, return parsing |

## How to Open and Run

1. Create a new Xcode project: **File > New > Project > App** (SwiftUI, Swift)
   - Product Name: `AppSwitchTest`
   - Bundle Identifier: `com.example.AppSwitchTest`
   - Deployment Target: **iOS 14.0**
2. Delete the auto-generated `ContentView.swift` and app entry file
3. Drag the 4 `.swift` files from this directory into the Xcode project
4. Configure the project:

### Info.plist

Add `LSApplicationQueriesSchemes` so `canOpenURL` works for PayPal app detection:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>paypal-app-switch-checkout</string>
</array>
```

### Associated Domains (for universal link return)

In Xcode: **Signing & Capabilities > + Capability > Associated Domains**, add:

```
applinks:example.com
```

Replace `example.com` with your verified domain. You also need to host an
`apple-app-site-association` file at `https://your-domain/.well-known/apple-app-site-association`.

### Custom URL Scheme (iOS < 17.4 fallback)

For the ASWebAuthenticationSession fallback on iOS versions before 17.4, register:

- **URL Types > URL Schemes**: `appswitch-test`

5. Build and run on a **physical device** (simulators do not have the PayPal app)

## What to Test

### Happy Path (App Switch)

1. Install the PayPal sandbox app on the test device
2. Launch the test app -- confirm "PayPal App Installed: Yes"
3. Tap **Pay $25.00**
4. The app should switch to the PayPal app for authentication
5. Log in with a sandbox buyer account (SMS code: `111111` or `222222`)
6. After approval, the PayPal app redirects back to the test app
7. The app captures the order and displays the Order ID and Capture ID
8. Status should show `COMPLETED`

### Happy Path (Vault)

1. Tap **Save PayPal**
2. Same redirect flow -- buyer approves saving their PayPal account
3. After return, the app creates a payment token
4. Status shows `VAULTED` with the Payment Token ID

### Fallback (Browser)

1. Uninstall the PayPal app from the test device
2. Confirm "PayPal App Installed: No"
3. Tap **Pay $25.00**
4. An ASWebAuthenticationSession (in-app browser) should open
5. Complete the flow in the browser
6. On iOS 17.4+, the HTTPS callback returns directly
7. On older iOS, the custom URL scheme `appswitch-test://` handles the return

### Cancellation

1. Start either flow, then tap Cancel in the PayPal app or close the browser
2. Status should show "Buyer cancelled."

## Expected Results

| Flow | Expected Status | Key Fields |
|---|---|---|
| Pay $25.00 | `COMPLETED` | Order ID, Capture ID |
| Save PayPal | `VAULTED` | Payment Token (Vault) ID |
| Cancel | "Buyer cancelled." | No IDs populated |
| PayPal app not installed | Browser fallback opens | Same end result |

## Doc Gaps Found During Creation

These items are either missing or unclear in `direct-api.mdx`:

1. **OAuth token endpoint not documented.** The guide says "Generate an access token" and
   links to a generic get-started page, but does not show the `/v1/oauth2/token` request
   with `grant_type=client_credentials`. A developer building from this guide alone would
   need to look elsewhere for the token call.

2. **No iOS custom URL scheme name specified.** The doc says "Earlier versions require a
   registered custom URL scheme for the browser fallback" but does not specify what scheme
   string to use or how to register it in Info.plist (URL Types). The code sample uses
   `"your-app-scheme"` as a placeholder. Developers need guidance on naming conventions
   and where to set this in Xcode.

3. **Return parameters differ between flows but the table does not distinguish them.**
   The "Return URL Query Parameters" table lists only `token` and `PayerID`. For vault
   flows, the return parameter is `approval_session_id` (or `token_id`), which is
   documented in the Step 1 code samples but not in the Step 4 parameter table. This
   could confuse developers who read the table without studying the code.

4. **`chargeWithVaultId` / future charge has no capture step shown.** The doc shows how to
   create an order with `vault_id` but does not say whether that order auto-captures or
   needs a separate capture call. The `intent: CAPTURE` suggests it still needs capture,
   but this is not stated.

5. **`email_address` field inconsistency.** The minimal "App Switch" tab samples omit
   `email_address` on the `paypal` object, while the full "cURL" tab samples include it.
   The parameter reference says it is "Optional (strongly recommended)" but does not
   explain what happens to eligibility without it.

6. **No end-to-end SwiftUI example.** The doc provides UIKit-style `SceneDelegate` code
   for handling returns, but no SwiftUI `.onOpenURL` equivalent. SwiftUI is the default
   for new iOS projects. This sample app fills that gap.

7. **ASWebAuthenticationSession presentation context.** The doc shows
   `extension YourViewController: ASWebAuthenticationPresentationContextProviding` which
   is UIKit-specific. No guidance for SwiftUI's lack of a view controller. Developers
   need to know how to get a window reference in a SwiftUI app.

8. **No mention of `Prefer: return=representation` for create order.** The minimal
   "App Switch" tab curl sample omits this header, so the response may not include the
   full `payment_source.paypal.app_switch_eligibility` field. Only the "cURL" (full)
   tab includes it. This should be called out as required to get eligibility in the
   response.
