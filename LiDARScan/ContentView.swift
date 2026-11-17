import SwiftUI

struct ContentView: View {
    @StateObject private var model = ScannerModel()

    var body: some View {
        ZStack {
            if model.supported {
                ARScannerView(model: model).ignoresSafeArea()
                VStack {
                    hud
                    Spacer()
                    controls
                }
                .padding()
                if model.isExporting {
                    ProgressView("Exporting…")
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                    Text("LiDAR scene reconstruction not supported on this device.")
                        .multilineTextAlignment(.center)
                    Text("Requires iPhone 12 Pro or newer Pro model / iPad Pro with LiDAR.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .sheet(item: $model.shareItem) { item in
            ShareSheet(url: item.url)
        }
        .alert("Error",
               isPresented: Binding(get: { model.errorMessage != nil },
                                    set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var hud: some View {
        Text("\(model.triangleCount.formatted()) tris · \(model.anchorCount) chunks")
            .font(.system(.footnote, design: .monospaced))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(model.isScanning ? "Stop" : "Start") { model.toggle() }
                .buttonStyle(.borderedProminent)
                .tint(model.isScanning ? .red : .green)

            Button("Reset") { model.reset() }
                .buttonStyle(.bordered)

            Menu("Export") {
                Button("OBJ (Blender, etc.)") { model.export(.obj) }
                Button("PLY") { model.export(.ply) }
            }
            .buttonStyle(.bordered)
            .disabled(model.isExporting)
        }
        .controlSize(.large)
        .padding(10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
