import SwiftUI
import UIKit

package extension Image {
    static var whatsApp: Image {
        Image("whatsapp.fill", bundle: .module)
    }
}

package extension UIImage {
    /// Looks up an image in this module's catalog, such as the placeholder listing photos.
    convenience init?(designSystemNamed name: String) {
        self.init(named: name, in: .module, compatibleWith: nil)
    }
}
