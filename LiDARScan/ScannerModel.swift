import SwiftUI
import ARKit
import RealityKit

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

@MainActor
final class ScannerModel: ObservableObject {
    let supported = ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification)

    weak var arView: ARView?
    @Published var isScanning = false
    @Published var isExporting = false
    @Published var triangleCount = 0
    @Published var anchorCount = 0
    @Published var shareItem: ShareItem?
    @Published var errorMessage: String?

    private var snapshot: [ARMeshAnchor] = []
    private var statsTask: Task<Void, Never>?

    // MARK: Session control

    func toggle() {
        isScanning ? stop() : begin(reset: false)
    }

    func reset() {
        snapshot = []
        triangleCount = 0
        anchorCount = 0
        begin(reset: true)
    }

    private func begin(reset: Bool) {
        guard let arView else { return }
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .meshWithClassification
        config.environmentTexturing = .none
        let options: ARSession.RunOptions = reset ? [.resetTracking, .removeExistingAnchors] : []
        arView.session.run(config, options: options)
        isScanning = true
        UIApplication.shared.isIdleTimerDisabled = true
        startStats()
    }

    private func stop() {
        snapshot = liveAnchors()
        arView?.session.pause()
        isScanning = false
        UIApplication.shared.isIdleTimerDisabled = false
        statsTask?.cancel()
        refreshStats()
    }

    private func liveAnchors() -> [ARMeshAnchor] {
        let live = arView?.session.currentFrame?.anchors.compactMap { $0 as? ARMeshAnchor } ?? []
        return live.isEmpty ? snapshot : live
    }

    private func startStats() {
        statsTask?.cancel()
        statsTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refreshStats()
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }
    }

    private func refreshStats() {
        let anchors = liveAnchors()
        anchorCount = anchors.count
        triangleCount = anchors.reduce(0) { $0 + $1.geometry.faces.count }
    }

    // MARK: Export

    func export(_ format: MeshExporter.Format) {
        let anchors = liveAnchors()
        guard !anchors.isEmpty else {
            errorMessage = "No mesh yet. Start scanning and move around the object first."
            return
        }
        isExporting = true
        Task.detached {
            do {
                let url = try MeshExporter.export(anchors, format: format)
                await MainActor.run {
                    self.isExporting = false
                    self.shareItem = ShareItem(url: url)
                }
            } catch {
                await MainActor.run {
                    self.isExporting = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
