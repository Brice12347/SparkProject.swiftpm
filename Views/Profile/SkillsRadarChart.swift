import SwiftUI

struct SkillsRadarChart: View {
    let data: [SubjectSkillLevel]
    var size: CGFloat = 220

    @Environment(\.colorScheme) private var colorScheme

    private var axes: [SubjectSkillLevel] {
        data.isEmpty
            ? Subject.allCases.prefix(5).map { SubjectSkillLevel(subject: $0, level: 0) }
            : Array(data.prefix(6))
    }

    var body: some View {
        ZStack {
            // Grid rings
            ForEach(1..<6) { ring in
                radarPath(values: axes.map { _ in Double(ring) / 5.0 })
                    .stroke(SparkTheme.gray200, lineWidth: 0.5)
            }

            // Axis lines
            ForEach(0..<axes.count, id: \.self) { index in
                let angle = angleFor(index: index)
                Path { path in
                    path.move(to: center)
                    path.addLine(to: pointAt(angle: angle, radius: size / 2))
                }
                .stroke(SparkTheme.gray200, lineWidth: 0.5)
            }

            // Data fill
            radarPath(values: axes.map(\.level))
                .fill(SparkTheme.teal.opacity(0.25))

            radarPath(values: axes.map(\.level))
                .stroke(SparkTheme.teal, lineWidth: 2)

            // Data points
            ForEach(0..<axes.count, id: \.self) { index in
                let angle = angleFor(index: index)
                let point = pointAt(angle: angle, radius: size / 2 * axes[index].level)
                Circle()
                    .fill(SparkTheme.teal)
                    .frame(width: 6, height: 6)
                    .position(point)
            }

            // Labels
            ForEach(0..<axes.count, id: \.self) { index in
                let angle = angleFor(index: index)
                let labelPoint = pointAt(angle: angle, radius: size / 2 + 24)
                Text(axes[index].subject.displayName)
                    .font(SparkTypography.label)
                    .foregroundStyle(SparkTheme.textSecondary(colorScheme))
                    .position(labelPoint)
            }
        }
        .frame(width: size + 80, height: size + 80)
    }

    private var center: CGPoint {
        CGPoint(x: (size + 80) / 2, y: (size + 80) / 2)
    }

    private func angleFor(index: Int) -> Double {
        let count = axes.count
        return Double(index) / Double(count) * 2 * .pi - .pi / 2
    }

    private func pointAt(angle: Double, radius: Double) -> CGPoint {
        CGPoint(
            x: center.x + CGFloat(cos(angle) * radius),
            y: center.y + CGFloat(sin(angle) * radius)
        )
    }

    private func radarPath(values: [Double]) -> Path {
        Path { path in
            guard !values.isEmpty else { return }
            for (index, value) in values.enumerated() {
                let angle = angleFor(index: index)
                let point = pointAt(angle: angle, radius: size / 2 * value)
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }
}
