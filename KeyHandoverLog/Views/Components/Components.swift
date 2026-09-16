import SwiftUI

struct AvatarView: View {
    let initials: String
    let name: String
    var size: CGFloat = 38
    @ScaledMetric(relativeTo: .body) private var scaledSize: CGFloat = 38

    init(initials: String, name: String, size: CGFloat = 38) {
        self.initials = initials
        self.name = name
        self.size = size
        self._scaledSize = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        let diameter = min(scaledSize, size * 1.6)
        Text(initials)
            .font(.system(size: diameter * 0.4, weight: .semibold))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .foregroundStyle(.white)
            .frame(width: diameter, height: diameter)
            .background(Color.accentColor.gradient, in: Circle())
            .accessibilityLabel(name)
    }
}

struct KeyTagView: View {
    let key: LighthouseKey

    var body: some View {
        Circle()
            .fill(key.tagColor.color.gradient)
            .frame(width: 14, height: 14)
            .accessibilityLabel("\(key.name) colour tag")
    }
}

struct StatusBadge: View {
    let title: String
    var tint: Color = .red

    var body: some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
            .accessibilityLabel(title)
    }
}

extension Date {
    var shortDateTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}

func displayName(_ id: UUID?, store: any KeyLogStore) -> String {
    store.volunteer(id: id)?.name ?? "Lockbox"
}
