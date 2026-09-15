import SwiftUI

/// Rend les traits.
///
/// L'épaisseur variable est obtenue en regroupant les segments par épaisseur
/// arrondie et en traçant un `Path` par groupe. Un contour rempli donnerait
/// un rendu plus fin mais ouvre la porte aux trous de remplissage quand deux
/// segments se croisent en sens inverse ; le regroupement est prévisible et
/// se rend à l'identique dans `ImageRenderer`.
struct SignatureStrokesView: View {

    let strokes: [SignatureStroke]
    var ink: Color = .black

    /// Pas de quantification, en points. Plus fin = plus de calques.
    private let step: CGFloat = 0.5

    var body: some View {
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

            // Un simple appui : un point rond.
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
