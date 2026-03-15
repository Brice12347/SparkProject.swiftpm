import SwiftUI

struct ChipSelector<Item: Identifiable & Hashable>: View {
    let items: [Item]
    let label: KeyPath<Item, String>
    var icon: KeyPath<Item, String>? = nil
    var multiSelect: Bool = false
    @Binding var selectedItems: Set<Item>

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items) { item in
                    chipView(for: item)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func chipView(for item: Item) -> some View {
        let isSelected = selectedItems.contains(item)

        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            if multiSelect {
                if isSelected {
                    selectedItems.remove(item)
                } else {
                    selectedItems.insert(item)
                }
            } else {
                selectedItems = [item]
            }
        } label: {
            HStack(spacing: 6) {
                if let iconPath = icon {
                    Text(item[keyPath: iconPath])
                }
                Text(item[keyPath: label])
                    .font(SparkTypography.bodyMedium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? SparkTheme.teal : SparkTheme.surfaceSecondary(colorScheme))
            .foregroundStyle(isSelected ? .white : SparkTheme.textPrimary(colorScheme))
            .clipShape(Capsule())
        }
    }
}

struct SubjectChipItem: Identifiable, Hashable {
    let subject: Subject
    var id: String { subject.rawValue }
    var name: String { subject.displayName }
    var emoji: String { subject.icon }
}
