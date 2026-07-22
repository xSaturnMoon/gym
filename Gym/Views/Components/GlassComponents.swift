import SwiftUI

struct GlassCard<Content: View>: View {
    var tint: Color = .clear
    var interactive: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(
                interactive
                    ? .regular.tint(tint).interactive()
                    : .regular.tint(tint),
                in: .rect(cornerRadius: 20)
            )
    }
}

struct GlassPill: View {
    let title: String
    var icon: String? = nil
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(title)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(
            isSelected
                ? .regular.tint(.accentColor.opacity(0.3)).interactive()
                : .regular.interactive(),
            in: .capsule
        )
    }
}

struct GlassIconButton: View {
    let systemName: String
    var label: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let label {
                Label(label, systemImage: systemName)
            } else {
                Image(systemName: systemName)
                    .font(.title3)
            }
        }
        .buttonStyle(.glass)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.bold())
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DifficultyBadge: View {
    let level: DifficultyLevel

    var color: Color {
        switch level {
        case .beginner: .green
        case .intermediate: .orange
        case .advanced: .red
        }
    }

    var body: some View {
        Text(level.rawValue)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassEffect(.regular.tint(color.opacity(0.25)), in: .capsule)
    }
}

struct MetricChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        GlassEffectContainer {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .glassEffect(.regular, in: .circle)
                    .frame(width: 80, height: 80)

                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
        }
        .padding()
    }
}
