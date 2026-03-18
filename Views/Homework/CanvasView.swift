import SwiftUI
import PencilKit

private let kCanvasWidth: CGFloat = 2000

struct CanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var aiDrawing: PKDrawing
    var aiAnnotations: [AIAnnotation]
    var assignmentImage: UIImage?
    var backgroundColor: UIColor
    var selectedColor: UIColor
    var lineWidth: CGFloat
    var isEraser: Bool
    var onCanvasChanged: (PKDrawing) -> Void

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = backgroundColor
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.bouncesZoom = true
        scrollView.minimumZoomScale = 0.05
        scrollView.maximumZoomScale = 5.0
        scrollView.delegate = context.coordinator
        context.coordinator.scrollView = scrollView

        let containerView = UIView()
        containerView.backgroundColor = .clear
        context.coordinator.containerView = containerView

        let pkCanvas = PKCanvasView()
        pkCanvas.drawing = drawing
        pkCanvas.tool = PKInkingTool(.pen, color: selectedColor, width: lineWidth)
        pkCanvas.drawingPolicy = .anyInput
        pkCanvas.backgroundColor = .clear
        pkCanvas.isOpaque = false
        pkCanvas.isScrollEnabled = false
        pkCanvas.delegate = context.coordinator
        context.coordinator.pkCanvas = pkCanvas

        if let image = assignmentImage {
            let aspectRatio = image.size.height / max(image.size.width, 1)
            let imageHeight = kCanvasWidth * aspectRatio
            let contentHeight = max(imageHeight + 400, kCanvasWidth * 1.4)

            containerView.frame = CGRect(x: 0, y: 0, width: kCanvasWidth, height: contentHeight)

            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: kCanvasWidth, height: imageHeight)
            imageView.backgroundColor = .clear
            containerView.addSubview(imageView)
            context.coordinator.imageView = imageView

            pkCanvas.frame = containerView.bounds
            containerView.addSubview(pkCanvas)
        } else {
            let contentHeight: CGFloat = kCanvasWidth * 2
            containerView.frame = CGRect(x: 0, y: 0, width: kCanvasWidth, height: contentHeight)

            pkCanvas.frame = containerView.bounds

            let ruledLayer = RuledLinesLayer()
            ruledLayer.frame = pkCanvas.bounds
            ruledLayer.setNeedsDisplay()
            pkCanvas.layer.insertSublayer(ruledLayer, at: 0)

            containerView.addSubview(pkCanvas)
        }

        scrollView.addSubview(containerView)
        scrollView.contentSize = containerView.bounds.size

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.parent = self
        let coordinator = context.coordinator

        let viewWidth = scrollView.bounds.width
        if viewWidth > 0 && abs(viewWidth - coordinator.lastViewportWidth) > 1 {
            coordinator.lastViewportWidth = viewWidth
            let fitScale = viewWidth / kCanvasWidth
            scrollView.minimumZoomScale = max(fitScale * 0.5, 0.05)
            scrollView.setZoomScale(fitScale, animated: false)
            centerContent(scrollView: scrollView, coordinator: coordinator)
        }

        guard let pkCanvas = coordinator.pkCanvas else { return }

        if !coordinator.isUpdatingFromDelegate {
            if pkCanvas.drawing.strokes.count != drawing.strokes.count {
                pkCanvas.drawing = drawing
            }
        }

        if isEraser {
            pkCanvas.tool = PKEraserTool(.vector)
        } else {
            pkCanvas.tool = PKInkingTool(.pen, color: selectedColor, width: lineWidth)
        }

        coordinator.updateAIOverlay(on: pkCanvas, aiDrawing: aiDrawing, aiAnnotations: aiAnnotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func centerContent(scrollView: UIScrollView, coordinator: Coordinator) {
        let contentSize = scrollView.contentSize
        let scrollSize = scrollView.bounds.size
        let offsetX = max(0, (scrollSize.width - contentSize.width * scrollView.zoomScale) / 2)
        let offsetY = max(0, (scrollSize.height - contentSize.height * scrollView.zoomScale) / 2)
        coordinator.containerView?.center = CGPoint(
            x: contentSize.width * scrollView.zoomScale / 2 + offsetX,
            y: contentSize.height * scrollView.zoomScale / 2 + offsetY
        )
    }

    // MARK: - Coordinator

    @MainActor
    class Coordinator: NSObject, PKCanvasViewDelegate, UIScrollViewDelegate {
        var parent: CanvasView
        var isUpdatingFromDelegate = false
        var lastViewportWidth: CGFloat = 0

        weak var scrollView: UIScrollView?
        weak var containerView: UIView?
        weak var pkCanvas: PKCanvasView?
        weak var imageView: UIImageView?
        private var aiOverlayView: PKCanvasView?
        private var textAnnotationLabels: [UILabel] = []

        init(_ parent: CanvasView) {
            self.parent = parent
            super.init()
        }

        // MARK: PKCanvasViewDelegate

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUpdatingFromDelegate = true
            parent.drawing = canvasView.drawing
            parent.onCanvasChanged(canvasView.drawing)
            isUpdatingFromDelegate = false
        }

        // MARK: UIScrollViewDelegate

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            containerView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            let contentSize = scrollView.contentSize
            let scrollSize = scrollView.bounds.size
            let offsetX = max(0, (scrollSize.width - contentSize.width) / 2)
            let offsetY = max(0, (scrollSize.height - contentSize.height) / 2)
            containerView?.center = CGPoint(
                x: contentSize.width / 2 + offsetX,
                y: contentSize.height / 2 + offsetY
            )
        }

        // MARK: AI Overlay

        func updateAIOverlay(on canvas: PKCanvasView, aiDrawing: PKDrawing, aiAnnotations: [AIAnnotation]) {
            if aiOverlayView == nil {
                let overlay = PKCanvasView()
                overlay.isUserInteractionEnabled = false
                overlay.backgroundColor = .clear
                overlay.isOpaque = false
                overlay.isScrollEnabled = false
                overlay.frame = canvas.bounds
                overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                overlay.alpha = 0.85
                canvas.addSubview(overlay)
                aiOverlayView = overlay
            }
            aiOverlayView?.drawing = aiDrawing

            // R2: Remove previous text annotation labels
            for label in textAnnotationLabels {
                label.removeFromSuperview()
            }
            textAnnotationLabels.removeAll()

            // R2: Create UILabel overlays for "write" annotations
            for annotation in aiAnnotations where annotation.type == .write {
                guard let text = annotation.text, let pos = annotation.position else { continue }

                let point = CGPoint(
                    x: pos.x * canvas.bounds.width,
                    y: pos.y * canvas.bounds.height
                )

                let label = PaddedLabel()
                label.text = text
                label.textColor = .white
                label.font = .boldSystemFont(ofSize: 12)
                label.textAlignment = .center
                label.backgroundColor = UIColor(Color(hex: annotation.color)).withAlphaComponent(0.9)
                label.layer.cornerRadius = 4
                label.clipsToBounds = true
                label.contentInsets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)

                label.sizeToFit()
                label.center = point

                canvas.addSubview(label)
                textAnnotationLabels.append(label)
            }
        }
    }
}

/// UILabel subclass that supports content insets for padding around text.
private class PaddedLabel: UILabel {
    var contentInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let base = super.sizeThatFits(size)
        return CGSize(
            width: base.width + contentInsets.left + contentInsets.right,
            height: base.height + contentInsets.top + contentInsets.bottom
        )
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

        ctx.setStrokeColor(UIColor(SparkTheme.aiError).withAlphaComponent(0.15).cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: 60, y: 0))
        ctx.addLine(to: CGPoint(x: 60, y: bounds.height))
        ctx.strokePath()
    }
}
