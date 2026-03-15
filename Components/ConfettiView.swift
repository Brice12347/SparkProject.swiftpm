import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let age = now - particle.createdAt
                    guard age < particle.lifetime else { continue }
                    let progress = age / particle.lifetime
                    let x = particle.startX * size.width + particle.velocityX * age
                    let y = particle.startY * size.height + particle.velocityY * age + 200 * age * age
                    let opacity = 1.0 - progress
                    let rotation = Angle.degrees(particle.rotationSpeed * age)

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)
                    
                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.size * (particle.isSquare ? 1.0 : 0.5)
                    )
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: particle.isSquare ? 2 : 1),
                        with: .color(particle.color)
                    )
                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                    context.opacity = 1
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { emitConfetti() }
    }

    private func emitConfetti() {
        let colors: [Color] = [
            SparkTheme.teal, SparkTheme.aiCorrection,
            SparkTheme.practiceAmber, SparkTheme.strengthGreen,
            Color(hex: "9B6BF2"), SparkTheme.aiError
        ]
        let now = Date().timeIntervalSinceReferenceDate

        particles = (0..<80).map { _ in
            ConfettiParticle(
                startX: CGFloat.random(in: 0.1...0.9),
                startY: CGFloat.random(in: -0.2...0.1),
                velocityX: CGFloat.random(in: -80...80),
                velocityY: CGFloat.random(in: -200 ... -50),
                rotationSpeed: Double.random(in: -360...360),
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement()!,
                isSquare: Bool.random(),
                lifetime: Double.random(in: 2.0...3.5),
                createdAt: now + Double.random(in: 0...0.5)
            )
        }
    }
}

private struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let rotationSpeed: Double
    let size: CGFloat
    let color: Color
    let isSquare: Bool
    let lifetime: Double
    let createdAt: TimeInterval
}
