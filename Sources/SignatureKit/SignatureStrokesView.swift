import SwiftUI

/// Draws the strokes.
///
/// Variable width is obtained by grouping segments by rounded width and
/// stroking one `Path` per group. A filled outline would look finer but
/// opens the door to fill holes wherever two segments cross in opposite
/// directions; grouping is predictable and renders identically inside
/// `ImageRenderer`.
struct SignatureStrokesView: View {

    let strokes: [SignatureStroke]
    var ink: Color = .black

    /// Quantization step, in points. Finer = more layers.
    private let step: CGFloat = 0.5

    var body: some View {
		let layers = self.layers
		
		if layers.isEmpty {
			Color.clear
		} else {
			ZStack {
				ForEach(layers, id: \.width) { layer in
					layer.path.stroke(
						ink,
						style: StrokeStyle(lineWidth: layer.width, lineCap: .round, lineJoin: .round)
					)
				}
			}
			.drawingGroup()
		}
    }

    private struct Layer: Identifiable {
        let width: CGFloat
        let path: Path
        var id: CGFloat { width }
    }

    private var layers: [Layer] {
        var paths: [CGFloat: Path] = [:]

        for stroke in strokes {
            let points = stroke.points
            guard let first = points.first else { continue }

            // A single tap: one round dot.
            guard points.count > 1 else {
                let width = quantized(first.width)
                paths[width, default: Path()].move(to: first.cgPoint)
                paths[width]?.addLine(to: first.cgPoint)
                continue
            }

            for index in 1..<points.count {
                let previous = points[index - 1]
                let current = points[index]
                let width = quantized((previous.width + current.width) / 2)

                var path = paths[width] ?? Path()
                path.move(to: previous.cgPoint)
                path.addLine(to: current.cgPoint)
                paths[width] = path
            }
        }

        return paths
            .map { Layer(width: $0.key, path: $0.value) }
            .sorted { $0.width < $1.width }
    }

    private func quantized(_ width: CGFloat) -> CGFloat {
        max(step, (width / step).rounded() * step)
    }
}
