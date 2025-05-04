# PayPal iOS SDK Demo App

This repository contains a **SwiftUI demo application** that simulates a real-world merchant experience — including a store, cart, and checkout flow.  
Its primary purpose is to **demonstrate two integration options** to accept payments through PayPal:

1. **Direct SDK integration**, offering seamless in-app checkout using native components.  
2. **Payment Link integration**, which redirects users to a hosted checkout experience via universal links.  

By providing practical examples for both approaches, this app helps developers choose the method that best fits their needs while simplifying implementation.

---

## Version 1.1 Features

- Checkout with PayPal
- Checkout with Cards
- Checkout with Payment Links <code>New</code>
- Seamless PayPal checkout experience  

---

## Project Structure

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
No dedicated SwiftUI screen - once triggered, it opens a web flow<br>
Becuase there is no dedicated PayPal view, we handle loading and errors in a `CheckoutCoordinator`<br>
If the user completes the PayPal flow, we capture the order and show `OrderCompleteView` 
- **Payment Links *(New)***<br>
Opens a universal link or URL that redirects to the hosted checkout.<br>
After completion, app is notified via webhook callback

---

## Requirements

- Xcode 15.0+  
- iOS 15.0+  
- PayPal iOS SDK or Payment Link (can be created through https://www.paypal.com)


## Setup

Clone this repository:
```
git clone https://github.com/paypal-examples/paypal-ios-sdk-demo-app.git
cd paypal-ios-sdk-demo-app
```
Open the project in Xcode.
Run the app on a simulator or device.

## Steps to create a Payment Link
- Login to PayPal Dashboard by visiting [PayPal.com](https://www.paypal.com), 
- Go to `Pay & Get Paid` -> `Create Payment Links and Buttons`
- Optional: To let your customer decide the order amount (for example, to decide how many credits to buy), choose type as `Customer set price`
- Go to `Checkout` tab and select if shipping address is required
- Go to `Confirmation` tab and use the universal link as `Auto-return URL` to direct your customer to your app after they complete the payment.
- Click `Buid It`
Payment Links support PayPal, Venmo, Pay Later, Card Payments and Apple Pay by default. You can update your preference by visiting [setttings](https://www.sandbox.paypal.com/ncp/settings).

## Steps to setup universal links
WIP

## Steps to receive payment data through Return URL
WIP

## Steps to receive payment notificaiton through Webhooks
WIP