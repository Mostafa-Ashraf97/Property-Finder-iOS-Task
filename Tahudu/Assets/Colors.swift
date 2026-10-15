//
//  Colors.swift
//  Tahudu
//

import SwiftUI

extension UIColor {
    static let accentColor = UIColor(named: "Accent") ?? UIColor.systemBlue
    static let brand = UIColor(named: "Brand") ?? UIColor.systemRed

    // MARK: Social Media

    static let whatsApp = UIColor(named: "WhatsApp") ?? UIColor.systemGreen
}

extension Color {
    // Due to the "Global Accent Color Name" setting, AccentColor can already be found under Color.accentColor
    static let brand = Color("Brand")

    // MARK: Social Media

    static let whatsApp = Color("WhatsApp")
}
