import CoreGraphics

public struct AGHStack: AGParentGraph {
    
    public var children: [any AGGraph] { graphs }
    
    let graphs: [any AGGraph]
    
    let alignment: Graphic.HStackAlignment
    
    public init(alignment: Graphic.HStackAlignment = .center,
                @AGGraphBuilder with graphs: @escaping () -> [any AGGraph]) {
        self.alignment = alignment
        self.graphs = graphs()
    }
    
    private func maxHeight(for specification: AGSpecification) -> CGFloat {
        {
            var height: CGFloat = 0.0
            for childGraph in children.all {
                let dynamicResolution = childGraph.resolution(for: specification)
                if let fixedHeight: CGFloat = dynamicResolution.fixedHeight {
                    height = max(height, fixedHeight)
                } else if case .spacer = dynamicResolution {
                    continue
                } else {
                    return nil
                }
            }
            return height
        }() ?? specification.resolution.height
    }
    
    public func resolution(for specification: AGSpecification) -> AGDynamicResolution {
        let maxHeight: CGFloat = maxHeight(for: specification)
        var dynamicResolution: AGDynamicResolution = .zero
        for child in children.all {
            let childDynamicResolution = child.resolution(for: specification)
            dynamicResolution = dynamicResolution.hMerge(maxHeight: maxHeight,
                                                         totalWidth: specification.resolution.width,
                                                         with: childDynamicResolution)
        }
        return dynamicResolution
    }
    
    private func width(_ childGraph: any AGGraph, at index: Int,
                       maxHeight: CGFloat, isFixed: Bool,
                       for specification: AGSpecification) -> CGFloat {
        
        var width: CGFloat = specification.resolution.width
        
        enum Item {
            case fixed(CGFloat)
            case auto
            case spacer(minLength: CGFloat)
        }
        var list: [Item] = []
        
        for (otherIndex, otherGraph) in children.all.enumerated() {
            guard otherIndex != index else { continue }
            let otherChildDynamicResolution: AGDynamicResolution = otherGraph.resolution(for: specification)
            if isFixed {
                if let otherWidth = otherChildDynamicResolution.fixedWidth {
                    list.append(.fixed(otherWidth))
                    continue
                }
            } else {
                if let otherWidth = otherChildDynamicResolution.width(forHeight: maxHeight) {
                    list.append(.fixed(otherWidth))
                    continue
                }
            }
            if case .spacer(minLength: let minLength) = otherChildDynamicResolution {
                list.append(.spacer(minLength: minLength))
                continue
            }
            list.append(.auto)
        }
        
        for item in list {
            if case .fixed(let length) = item {
                width -= length
            }
        }
        
        let autoCount: Int = list.filter({ item in
            if case .auto = item {
                return true
            }
            return false
        }).count
        
        let spacerCount: Int = list.filter({ item in
            if case .spacer = item {
                return true
            }
            return false
        }).count
        
//        let dividedWidth: CGFloat = width / CGFloat(autoCount + 1)
//        
//        if spacerCount > 0,
//           let dynamicWidth: CGFloat = childGraph.resolution(for: specification).width(forHeight: maxHeight) {
//            width = max(dynamicWidth, dividedWidth)
//        } else {
//            width = dividedWidth
//        }
        width /= CGFloat(autoCount + 1)
        
        let minLength: CGFloat = list.compactMap({ item in
            switch item {
            case .spacer(let minLength):
                return minLength
            default:
                return nil
            }
        }).reduce(0.0, +)
        
        width = max(width, minLength)
        
        return width
    }
    
    func childResolution(_ childGraph: any AGGraph, at index: Int,
                         for specification: AGSpecification) -> CGSize {
        let maxHeight: CGFloat = maxHeight(for: specification)
        let childDynamicResolution: AGDynamicResolution = childGraph.resolution(for: specification)
        let height: CGFloat = childDynamicResolution.fixedHeight ?? maxHeight
        let width: CGFloat = childDynamicResolution.fixedWidth ?? {
            let widthA: CGFloat = self.width(childGraph, at: index, maxHeight: maxHeight, isFixed: true, for: specification)
            let widthB: CGFloat = self.width(childGraph, at: index, maxHeight: maxHeight, isFixed: false, for: specification)
            return max(widthA, widthB)
        }()
        return CGSize(width: width, height: height)
    }
    
    public func render(with details: AGDetails) async throws -> Graphic {
        guard !graphs.isEmpty else {
            return try await .color(.clear, resolution: details.specification.resolution)
        }
        var graphics: [Graphic] = []
        for (index, graph) in graphs.all.enumerated() {
            let resolution: CGSize = childResolution(
                graph, at: index, for: details.specification)
            let details: AGDetails = details.with(resolution: resolution)
            let graphic: Graphic = try await graph.render(with: details)
            graphics.append(graphic)
        }
        return try await Graphic.hStacked(with: graphics, alignment: alignment)
    }
}

extension AGHStack: Equatable {

    public static func == (lhs: AGHStack, rhs: AGHStack) -> Bool {
        guard lhs.graphs.count == rhs.graphs.count else { return false }
        for (lhsAGGraphic, rhsAGGraphic) in zip(lhs.graphs, rhs.graphs) {
            guard lhsAGGraphic.isEqual(to: rhsAGGraphic) else { return false }
        }
        return true
    }
}

extension AGHStack: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        for graph in graphs {
            hasher.combine(graph)
        }
    }
}
