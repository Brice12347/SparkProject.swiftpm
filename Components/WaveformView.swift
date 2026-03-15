import SwiftUI

struct WaveformView: View {
    var isActive: Bool
    var barCount: Int = 5
    var color: Color = SparkTheme.teal

    @State private var phase: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isActive ? color : SparkTheme.gray400)
                    .frame(
                        width: 4,
                        height: isActive ? barHeight(for: index) : 6
                    )
            }
        }
        .frame(height: 28)
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: phase)
        .onChange(of: isActive) { _, active in
            phase = active
        }
        .onAppear {
            if isActive { phase = true }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: [CGFloat] = [14, 22, 18, 24, 16]
        let alt: [CGFloat] = [20, 12, 24, 14, 22]
        let heights = phase ? base : alt
        return heights[index % heights.count]
    }
}
