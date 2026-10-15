//
//  ContactButton.swift
//  Tahudu
//

import SwiftUI

struct ContactButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    let type: ContactType
    let cornerRadius: CGFloat = 4
    let size: CGFloat = 36

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .foregroundColor(.white)
            .background(!isEnabled || configuration.isPressed ? type.backgroundColor.opacity(0.25) : type.backgroundColor)
            .cornerRadius(cornerRadius)
    }
}

struct ContactButton: View {
    // MARK: - Private Properties

    private let type: ContactType
    private let action: () -> Void

    // MARK: - Lifecycle

    init(_ type: ContactType, action: @escaping () -> Void) {
        self.type = type
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: self.action) {
            Image(imageSystemName: type.imageSystemNameFilled, imageName: type.imageNameFilled)
        }
        .buttonStyle(ContactButtonStyle(type: self.type))
    }
}
