package extension Sequence {
    /// The elements in their original order, keeping only the first element for each key.
    func uniqued<Key: Hashable>(by key: (Element) -> Key) -> [Element] {
        var seen = Set<Key>()
        return filter { seen.insert(key($0)).inserted }
    }
}

package extension Sequence where Element: Hashable {
    /// The elements in their original order, keeping only the first occurrence of each.
    func uniqued() -> [Element] {
        uniqued { $0 }
    }
}
