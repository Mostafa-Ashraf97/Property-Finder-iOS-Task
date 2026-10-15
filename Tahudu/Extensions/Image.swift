//
//  Image.swift
//  Tahudu
//

import SwiftUI

extension Image {
    /// Tries to use systemImage first, imageName second and lastly uiImage.
    init?(imageSystemName: String?, imageName: String?, uiImage: UIImage? = nil) {
        if let imageSystemName = imageSystemName {
            self.init(systemName: imageSystemName)
        } else if let imageName = imageName {
            self.init(imageName)
        } else if let uiImage = uiImage {
            self.init(uiImage: uiImage)
        } else {
            return nil
        }
    }
}
