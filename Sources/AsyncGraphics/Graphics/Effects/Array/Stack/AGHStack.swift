import CoreGraphics

public struct AGHStack: AGGraph {
    
    public var resolution: AGResolution {
        let width: CGFloat? = {
            var totalWidth: CGFloat = 0.0
            for graph in graphs.allGraphs {
                if let width = graph.width {
                    totalWidth = totalWidth + width
                } else {
                    return nil
                }
            }
            return totalWidth
        }()
        let height: CGFloat? = {
            var totalHeight: CGFloat = 0.0
            for graph in graphs.allGraphs {
                if let height = graph.height {
                    totalHeight = max(totalHeight, height)
                } else {
                    return nil
                }
            }
            return totalHeight
        }()
        return AGResolution(width: width, height: height)
    }
    
    let graphs: [any AGGraph]
    
    let alignment: Graphic.HStackAlignment
    
    public init(alignment: Graphic.HStackAlignment = .center,
                @AGGraphBuilder with graphs: @escaping () -> [any AGGraph]) {
        self.alignment = alignment
        self.graphs = graphs()
    }
    
    public func render(at resolution: CGSize) async throws -> Graphic {
        guard !graphs.isEmpty else {
            return try await .color(.clear, resolution: resolution)
        }
        var graphics: [Graphic] = []
        for (index, graph) in graphs.allGraphs.enumerated() {
            let resolution: CGSize = {
                var width: CGFloat = graph.width ?? resolution.width
                let height: CGFloat = graph.height ?? resolution.height
                if graph.width == nil {
                    var autoCount: Int = 1
                    for (otherIndex, otherGraph) in graphs.allGraphs.enumerated() {
                        guard otherIndex != index else { continue }
                        if let otherWidth = otherGraph.width {
                            width -= otherWidth
                        } else {
                            autoCount += 1
                        }
                    }
                    width /= CGFloat(autoCount)
                }
                return CGSize(width: width, height: height)
            }()
            let graphic: Graphic = try await graph.render(at: resolution)
            graphics.append(graphic)
        }
        return try await Graphic.hStacked(with: graphics, alignment: alignment)
    }
}

extension AGHStack: Equatable {

    public static func == (lhs: AGHStack, rhs: AGHStack) -> Bool {
        guard lhs.resolution == rhs.resolution else { return false }
        guard lhs.graphs.count == rhs.graphs.count else { return false }
        for (lhsAGGraphic, rhsAGGraphic) in zip(lhs.graphs, rhs.graphs) {
            guard lhsAGGraphic.isEqual(to: rhsAGGraphic) else { return false }
        }
        return true
    }
}

extension AGHStack: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(resolution)
        for graph in graphs {
            hasher.combine(graph)
        }
    }
}
