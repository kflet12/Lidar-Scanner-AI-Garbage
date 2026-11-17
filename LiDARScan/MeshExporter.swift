import ARKit

enum MeshExporter {
    enum Format {
        case obj, ply
        var ext: String { self == .obj ? "obj" : "ply" }
    }

    struct ExportError: LocalizedError {
        let errorDescription: String?
    }

    /// Writes all mesh anchors (transformed to world space) into one file in Documents.
    /// Files are visible in the Files app under "On My iPhone > LiDAR Scan".
    static func export(_ anchors: [ARMeshAnchor], format: Format) throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd-HHmmss"
        let url = docs.appendingPathComponent("Scan-\(df.string(from: Date())).\(format.ext)")

        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw ExportError(errorDescription: "Could not create file.")
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }

        let totalVerts = anchors.reduce(0) { $0 + $1.geometry.vertices.count }
        let totalFaces = anchors.reduce(0) { $0 + $1.geometry.faces.count }

        func write(_ s: String) { handle.write(Data(s.utf8)) }

        if format == .ply {
            write("""
            ply
            format ascii 1.0
            comment LiDAR Scan export
            element vertex \(totalVerts)
            property float x
            property float y
            property float z
            element face \(totalFaces)
            property list uchar int vertex_indices
            end_header

            """)
        } else {
            write("# LiDAR Scan export\n# vertices \(totalVerts) faces \(totalFaces)\no scan\n")
        }

        // Pass 1: vertices
        for anchor in anchors {
            var s = ""
            s.reserveCapacity(anchor.geometry.vertices.count * 32)
            for p in worldVertices(anchor) {
                s += format == .obj ? "v \(p.x) \(p.y) \(p.z)\n" : "\(p.x) \(p.y) \(p.z)\n"
            }
            write(s)
        }

        // Pass 2: faces (indices offset per anchor)
        var base: UInt32 = 0
        for anchor in anchors {
            let faces = anchor.geometry.faces
            guard faces.bytesPerIndex == 4, faces.indexCountPerPrimitive == 3 else {
                throw ExportError(errorDescription: "Unexpected mesh index format.")
            }
            var s = ""
            s.reserveCapacity(faces.count * 24)
            let ptr = faces.buffer.contents()
            for f in 0..<faces.count {
                let i = f * 3
                let a = ptr.load(fromByteOffset: (i + 0) * 4, as: UInt32.self) + base
                let b = ptr.load(fromByteOffset: (i + 1) * 4, as: UInt32.self) + base
                let c = ptr.load(fromByteOffset: (i + 2) * 4, as: UInt32.self) + base
                if format == .obj {
                    s += "f \(a + 1) \(b + 1) \(c + 1)\n"   // OBJ is 1-based
                } else {
                    s += "3 \(a) \(b) \(c)\n"
                }
            }
            write(s)
            base += UInt32(anchor.geometry.vertices.count)
        }
        return url
    }

    private static func worldVertices(_ anchor: ARMeshAnchor) -> [SIMD3<Float>] {
        let src = anchor.geometry.vertices
        let base = src.buffer.contents().advanced(by: src.offset)
        var out = [SIMD3<Float>]()
        out.reserveCapacity(src.count)
        for i in 0..<src.count {
            let p = base.advanced(by: i * src.stride)
            let x = p.load(fromByteOffset: 0, as: Float.self)
            let y = p.load(fromByteOffset: 4, as: Float.self)
            let z = p.load(fromByteOffset: 8, as: Float.self)
            let w = anchor.transform * SIMD4<Float>(x, y, z, 1)
            out.append(SIMD3<Float>(w.x, w.y, w.z))
        }
        return out
    }
}
