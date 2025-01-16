//
//  Item.swift
//  paypal-ios-sdk-demo-app
//
//  Created by Nirvan Nagar on 1/16/25.
//

import Foundation

struct Item: Identifiable {
    let id: String = UUID().uuidString
    let name: String
    let imageName: String
    let amount: Double
}
