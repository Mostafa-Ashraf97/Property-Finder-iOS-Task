package extension Int {
    /// The number with the singular or plural noun, e.g. `1.counted("Bed", plural: "Beds")` is "1 Bed".
    func counted(_ singular: String, plural: String) -> String {
        "\(self) \(self == 1 ? singular : plural)"
    }
}
