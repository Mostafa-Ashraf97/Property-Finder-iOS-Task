import DesignSystem
import SwiftUI

struct ListingPhotos: View {
    let images: [String]
    @State private var page: Int? = 0

    var body: some View {
        Color.clear
            .aspectRatio(3.0 / 2.0, contentMode: .fit)
            .overlay {
                if images.count > 1 {
                    carousel
                } else {
                    photo(named: images.first)
                }
            }
            .clipped()
            .onChange(of: images) { page = 0 }
    }

    private var carousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(images.indices, id: \.self) { index in
                    photo(named: images[index])
                        .containerRelativeFrame([.horizontal, .vertical])
                        .clipped()
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $page)
        .overlay(alignment: .bottom) {
            HStack(spacing: Spacing.pt4) {
                ForEach(images.indices, id: \.self) { index in
                    Circle()
                        .fill(.white.opacity(index == (page ?? 0) ? 1 : 0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .shadow(color: .black.opacity(0.25), radius: 4)
            .padding(.bottom, Spacing.pt8)
        }
    }

    @ViewBuilder
    private func photo(named name: String?) -> some View {
        let assetName = switch name {
        case "first_image": "FirstImage"
        case "second_image": "SecondImage"
        default: name
        }
        if let assetName, let image = UIImage(designSystemNamed: assetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Label("Image unavailable", systemImage: "house")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
        }
    }
}
