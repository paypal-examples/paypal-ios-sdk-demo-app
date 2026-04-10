// AppSwitchTestApp.swift
// PayPal App Switch Direct API - iOS Test App
//
// Source: direct-api.mdx integration guide
// Target: iOS 14+, no external dependencies
//
// INFO.PLIST ENTRIES REQUIRED:
// ------------------------------------------------------------------
// 1. LSApplicationQueriesSchemes (allows canOpenURL check):
//    <key>LSApplicationQueriesSchemes</key>
//    <array>
//        <string>paypal-app-switch-checkout</string>
//    </array>
//
// 2. Associated Domains entitlement (Xcode > Signing & Capabilities):
//    applinks:example.com
//
// 3. Host apple-app-site-association at:
//    https://example.com/.well-known/apple-app-site-association
//    {
//      "applinks": {
//        "apps": [],
//        "details": [{
//          "appID": "TEAM_ID.com.example.AppSwitchTest",
//          "paths": ["/paypal/*", "/app-link/*"]
//        }]
//      }
//    }
// ------------------------------------------------------------------

import SwiftUI

@main
struct AppSwitchTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle return from PayPal app via universal link
                    AppSwitchHandler.shared.handleReturn(url: url)
                }
        }
    }
}
