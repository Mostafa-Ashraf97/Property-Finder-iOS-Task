//
//  ContactType.swift
//  Tahudu
//

import SwiftUI

/// Represents the various contact types
enum ContactType {
    case phone
    case email
    case whatsApp
    case sms

    var imageName: String? {
        switch self {
        case .whatsApp:
            return "whatsapp"
        default:
            return nil
        }
    }

    var imageNameFilled: String? {
        imageName?.filled
    }

    var imageSystemName: String? {
        switch self {
        case .phone:
            return "phone"
        case .email:
            return "envelope"
        case .sms:
            return "message"
        default:
            return nil
        }
    }

    var imageSystemNameFilled: String? {
        imageSystemName?.filled
    }

    var backgroundColor: Color {
        switch self {
        case .phone, .email, .sms:
            return .brand
        case .whatsApp:
            return .whatsApp
        }
    }
}

private extension String {
    /// Appends '.fill' to the given string. Useful for (Custom) SF Symbols.
    var filled: String {
        self + ".fill"
    }
}
