import CoreGraphics
import PixelColor

extension CodableGraphic.Content.Solid {
    
    @GraphicMacro
    public class Gradient: SolidGraphicProtocol {
        
        public var type: CodableGraphicType {
            .content(.solid(.gradient))
        }
        
        public var direction: GraphicEnumMetadata<Graphic.GradientDirection> = .init(value: .vertical)
        
        public var stops: GraphicMetadata<[Graphic.GradientStop]> = .init(value: .fixed([
            Graphic.GradientStop(at: 0.0, color: .black),
            Graphic.GradientStop(at: 1.0, color: .white),
        ]))
        
        public var position: GraphicMetadata<CGPoint> = .init()
        
        public var scale: GraphicMetadata<CGFloat> = .init(value: .fixed(1.0),
                                                           maximum: .fixed(2.0))
        
        public var offset: GraphicMetadata<CGFloat> = .init(value: .fixed(0.0),
                                                            minimum: .fixed(-1.0))
        
        public var gamma: GraphicMetadata<CGFloat> = .init(value: .fixed(1.0),
                                                           maximum: .fixed(2.0))
        
        public var extend: GraphicEnumMetadata<Graphic.GradientExtend> = .init(value: .zero)
        public required init() {}
        
        public func render(
            at resolution: CGSize,
            options: AsyncGraphics.Graphic.ContentOptions = []
        ) async throws -> Graphic {
            
            try await .gradient(
                direction: direction.value,
                stops: stops.value.at(resolution: resolution),
                center: position.value.at(resolution: resolution),
                scale: scale.value.at(resolution: resolution),
                offset: offset.value.at(resolution: resolution),
                extend: extend.value,
                gamma: gamma.value.at(resolution: resolution),
                resolution: resolution,
                options: options)
        }
    }
}
