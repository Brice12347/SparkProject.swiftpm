import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var aiDrawing: PKDrawing
    var backgroundColor: UIColor
    var onCanvasChanged: () -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.tool = PKInkingTool(.pen, color: UIColor(SparkTheme.charcoal), width: 2)
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = backgroundColor
        canvas.delegate = context.coordinator
        canvas.isOpaque = false
        canvas.alwaysBounceVertical = true
        canvas.showsVerticalScrollIndicator = false
        canvas.contentSize = CGSize(width: canvas.bounds.width, height: 4000)

        let ruledLayer = RuledLinesLayer()
        ruledLayer.frame = CGRect(x: 0, y: 0, width: 2000, height: 4000)
        ruledLayer.setNeedsDisplay()
        canvas.layer.insertSublayer(ruledLayer, at: 0)

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if context.coordinator.isUpdatingFromDelegate { return }
        if canvas.drawing.strokes.count != drawing.strokes.count {
            canvas.drawing = drawing
        }
        context.coordinator.updateAIOverlay(on: canvas, aiDrawing: aiDrawing)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        var isUpdatingFromDelegate = false
        private var aiOverlayView: PKCanvasView?

        init(_ parent: CanvasView) {
            self.parent = parent
            super.init()
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUpdatingFromDelegate = true
            parent.drawing = canvasView.drawing
            parent.onCanvasChanged()
            isUpdatingFromDelegate = false
        }

        func updateAIOverlay(on canvas: PKCanvasView, aiDrawing: PKDrawing) {
            if aiOverlayView == nil {
                let overlay = PKCanvasView()
                overlay.isUserInteractionEnabled = false
                overlay.backgroundColor = .clear
                overlay.isOpaque = false
                overlay.frame = canvas.bounds
                overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                overlay.alpha = 0.85
                canvas.addSubview(overlay)
                aiOverlayView = overlay
            }
            aiOverlayView?.drawing = aiDrawing
        }
    }
}

class RuledLinesLayer: CALayer {
    override func draw(in ctx: CGContext) {
        let lineSpacing: CGFloat = 32
        let lineColor = UIColor(SparkTheme.gray200).withAlphaComponent(0.5).cgColor
        ctx.setStrokeColor(lineColor)
        ctx.setLineWidth(0.5)

        var y: CGFloat = lineSpacing
        while y < bounds.height {
            ctx.move(to: CGPoint(x: 20, y: y))
            ctx.addLine(to: CGPoint(x: bounds.width - 20, y: y))
            y += lineSpacing
        }
        ctx.strokePath()

        // Left margin line
        ctx.setStrokeColor(UIColor(SparkTheme.aiError).withAlphaComponent(0.15).cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: 60, y: 0))
        ctx.addLine(to: CGPoint(x: 60, y: bounds.height))
        ctx.strokePath()
    }
}
