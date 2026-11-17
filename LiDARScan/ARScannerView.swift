import SwiftUI
import RealityKit
import ARKit

struct ARScannerView: UIViewRepresentable {
    let model: ScannerModel

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.automaticallyConfigureSession = false
        view.debugOptions.insert(.showSceneUnderstanding) // live mesh overlay
        view.renderOptions.insert(.disableMotionBlur)
        model.arView = view
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
