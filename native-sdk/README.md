# PayPal iOS Demo App - SDK & Payment Link Integration

This repository contains a **SwiftUI demo application** that simulates a real-world merchant experience — including a cart and payment/checkout flow. It also demonstrates the steps to receive payments for in-app purchases through direct integration with PayPal. This can be used for both one time and recurring payments (for example: monthly subscriptions).
Its primary purpose is to **demonstrate two integration options** to accept payments in iOS Apps through PayPal:

1. **Direct SDK integration**, offering seamless in-app checkout using native components.
2. **Payment Links integration**, which redirects users to a PayPal hosted checkout experience via universal links.  

By providing practical examples for both approaches, this app helps developers choose the method that best fits their needs while simplifying implementation.

| Payment Link | PayPal Native SDK |
| -------- | ------- |
| <video src="https://github.com/user-attachments/assets/39fae8f4-8015-4604-9ade-03b242e535a9"> | <video src="https://github.com/user-attachments/assets/7f2ec1ee-fb85-4c0c-9eff-51a1351848d9"> |

---

### 🚀 Version 1.1 Features

- Checkout with PayPal
- Checkout with Cards
- Checkout with Payment Links <code>New</code>
- Seamless PayPal checkout experience
##
### 🔧 Requirements

- Xcode 15.0+
- iOS 15.0+
- PayPal Business Account to receive payment
  - You can create an account by visiting [PayPal.com](https://www.PayPal.com)
- PayPal iOS SDK (Optional if you're using Payment Links)
- Payment Links (Optional if you're using PayPal iOS SDK)

---

### 🛠 Setup

Clone this repository:
```
git clone https://github.com/paypal-examples/paypal-ios-sdk-demo-app.git
cd paypal-ios-sdk-demo-app
```
Open the project in Xcode.
Run the app on a simulator or device.
##
### 🔗+💳 Steps to create/manage Payment Links (One-Time Payment)
- Log into PayPal Business Account
  - Go to [PayPal.com](https://www.paypal.com) and sign in with your business account
  - Make sure you're logged in with a Business account (not Personal)
  - If you don’t have a business account, you’ll need to upgrade or create one by clicking on `Sign up`
- Go to `Pay & Get Paid` -> `Create Payment Links and Buttons` in the navigation menu
- Enter the product & payment details
  - Configure the Product Name, Description, Price & Currency
  - Optional: To let your customer decide the order amount (for example, to decide how many credits to buy), choose type as `Customer set price`
  - Go to `Checkout` tab and select if shipping address is required (It can be turned off for digital goods)
  - Go to `Confirmation` tab and use the universal link as `Auto-return URL` to redirect your customer to your app after they complete the payment
    - This is used to redirect users back to your app automatically through universal links after they complete a payment along with PDT (Payment Data Transfer)
    - This is required for order fulfillment and reconciliation. Refer to section below ["How to do order fulfillment using Auto-Return URL, PDT and Webhook"](#how-to-do-order-fulfillment-using-auto-return-url-pdt-and-webhook)
- Click `Build It`
- To find/view the previously created links, click on [Back to saved links and buttons](https://www.paypal.com/buttons/saved)
- Payment Links support PayPal, Venmo, Pay Later, Card Payments and Apple Pay payment methods by default. You can update your preference by visiting [settings](https://www.paypal.com/ncp/settings).
- For a step-by-step walkthrough, check out the video tutorial on YouTube:
  - [How to Create Payment Links and Buy Buttons](https://youtu.be/2LsuYc-9iU8?si=_fUr_YjKOYcmY3TL)
  - [Configuring the Payment Links and Buttons Settings](https://youtu.be/Nx5JznuBr9I?si=3GwGVVLvZUwPUSjE)

##
### 🔗+🔄+💳 Steps to create/manage recurring payment links (Subscription)
- Log into PayPal Business Account
  - Go to [PayPal.com](https://www.paypal.com) and sign in with your business account
  - If you don’t have a business account, you’ll need to upgrade or create one by clicking on `Sign up`
- Go to `PayPal Subscriptions`
  - Click `Pay & Get Paid` -> `Subscriptions` in the navigation menu
- Go to `Subscription plans` tab
  - This view displays all the previously created payment links
- To create a new payment links, click `Create Plan`
  - Choose the product or service you want to set up subscriptions for
  - If you haven't created a product before, you'll need to create a product first by entering:
    - Product Name
    - Description
    - Product Type (Digital or Physical)
  - Set Up subscription plan
    - Choose pricing (fixed, quantity-based, tiered, etc.), billing cycle, etc.,
  - Confirm your plan details and turn it ON
- To copy the shareable payment link
  - Go to `Subscription plans` tab
  - Click on the action menu `vertical three-dot menu` and select `Copy Link`
  - Use this URL anywhere — in your app, websites, emails, etc.,
- **Auto-Return URL for recurring payment links**
  - This is used to redirect users back to your app automatically through universal links after they complete a payment
  - It can be used for improving the user experience and ensuring smooth post-payment flow
  - To setup **Auto-Return URL and PDT** for order fulfillment and reconciliation
    - Click on `Account Settings` in top-right corner of the navigation menu
    - In the left menu, click `Website payments` (under `Products & Services`)
    - Then click `Update` next to `Website preferences`
    - Select `On` in `Auto return` section and provide the URL
    - Select `On` in `Payment data transfer` section
    - Refer to section below ["How to do order fulfillment using Auto-Return URL, PDT and Webhook"](#how-to-do-order-fulfillment-using-auto-return-url-pdt-and-webhook)

##
### 🌐 Steps to setup universal links
- To support universal linking — allowing your app to automatically handle return URLs after a user completes a PayPal Payment Link — follow the steps below.
  - Host the Apple App Site Association (AASA) file 
    - Create the `apple-app-site-association` file<br>
    - To enable universal linking, create a file named **`apple-app-site-association`** (with no `.json` extension) and include the following content:

    ```json
    {
      "applinks": {
        "details": [
          {
            "appIDs": [ "YOUR_TEAM_ID.YOUR_BUNDLE_ID" ],
            "components": [
              {
                "/": "/pay/success*",
                "comment": "Matches return URLs like /pay/success"
              }
            ]
          }
        ]
      }
    }
    ```

    - Replace `YOUR_TEAM_ID` with your Apple Developer Team ID.
    - Replace `YOUR_BUNDLE_ID` with your app's bundle identifier.

    - Host this file at the root of your domain (e.g., `https://yourdomain.com/.well-known/apple-app-site-association`) to allow iOS to verify your app's association with the domain.
      - Must be served with Content-Type: application/json and no redirects
      - Use a valid HTTPS certificate
- Enable Associated Domains in your app
  - Open Xcode and go to your app target -> Signing & Capabilities
  - Add a new capability: Associated Domains
  - Add the following entry:
   ```json
   applinks:yourdomain.com
   ```
  - Do not include https://
- Handle the return URL in your app  
  - SwiftUI Example:
    Use the .onOpenURL modifier to handle the return:
  ```swift
  @main
  struct PayPalDemoApp: App {
    var body: some Scene {
        WindowGroup {
            CheckoutFlow()
                .onOpenURL { url in
                    if url.path.contains("/pay/success") {
                        // Parse query params and handle success
                    }
                }
        }
    }
  }
  ```
  - UIKit Example:
    - In AppDelegate:
    ```swift
    func application(_ application: UIApplication,
          continue userActivity: NSUserActivity,
          restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
      guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else { return false }
      if url.path.contains("/pay/success") {
        // Handle payment success or failure
        return true
      }
    }
    ```
    - In SceneDelegate.swift:
    ```
    func scene(_ scene: UIScene,
           continue userActivity: NSUserActivity) {
      if let url = userActivity.webpageURL {
        // Handle navigation or update state
      }
    }
    ```
##
### How to do order fulfillment using Auto-Return URL, PDT and Webhook
- PDT (Payment Data Transfer) with Auto-Return URL is a combination of two PayPal features that will help you manage post-payment processes seamlessly
- These features work together to ensure that after a user makes a payment, they are automatically redirected to your app, and you receive all relevant payment information for processing/display
- It has transaction details such as currency (`cc`), amount (`amt`), transaction id (`tx`) and status (`st`)
- Implement PDT on your Server
  - PDT allows you to retrieve detailed transaction data from PayPal after the payment is made
  - Once the customer is redirected back to your Auto Return URL, you can use the transaction ID (`tx`) parameter in the URL to make a server-side request to PayPal
  - PayPal will then send you the transaction details via a secure HTTPS request
##
### 🔔 Steps to receive payment notification through Webhooks
- Using PayPal Webhooks allows your application to be automatically notified when specific events occur in your PayPal account—like a successful payment, subscription renewal, or refund
- It can be used by Merchants for real-time backend updates
- For more details on how to integrate with webhooks - [click here](https://developer.paypal.com/api/rest/webhooks/rest/#link-integratewebhooks)

---

## 📂 Project Structure

- **Where to find key logic**<br>
If you are just interested in code to implement server side and SDK API calls, you can skip to `CardPaymentViewModel` or `PayPalViewModel`
- **CheckoutFlow**<br>
SwiftUI view that is the entry point for the checkout process. It sets up the overall navigation structure using a `NavigationStack`, so users can move from cart checkout and finally OrderCompletion
- **CheckoutCoordinator (Navigation and Flow Manager)**<br>
Handles navigation logic and handles loading and error states of flows that do not have a dedicated SwiftUI view (e.g., PayPal Web Checkout)
- **CartView**<br>
Displays items in the cart and total amount<br>
Buttons to initiate Card or PayPalWeb checkout<br>
Tapping either calls into a `CheckoutCoordinator` that starts the respective flow
- **Card Checkout**<br>
This uses a SwiftUI screen called `CardCheckoutView` which references a `CardPaymentViewModel`<br>
The view model handles network calls for creating order, approving the card and final capture<br>
When complete, the user is navigated to `OrderCompleteView`
- **PayPal Web Checkout**<br>
No dedicated SwiftUI screen - once triggered, it opens a web flow
Because there is no dedicated PayPal view, we handle loading and errors in a `CheckoutCoordinator`<br>
If the user completes the PayPal flow, we capture the order and show `OrderCompleteView` 
- **Payment Links *(New)***<br>
Opens a universal link or URL that redirects to the hosted checkout.
 After completion, app is notified via webhook callback
