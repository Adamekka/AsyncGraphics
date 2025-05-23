import SwiftUI
import Spatial
import SpatialExtensions
import CoreGraphics
import CoreGraphicsExtensions
import PixelColor

public protocol GraphicValue: Codable {
    
    static var zero: Self { get }
    static var one: Self { get }
    static var `default`: GraphicMetadataValue<Self> { get }
    static var minimum: GraphicMetadataValue<Self> { get }
    static var maximum: GraphicMetadataValue<Self> { get }
    
    static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self
    
    func scaled(by scale: CGFloat) -> Self
}

extension GraphicValue {
    
    public var graphicValueType: GraphicValueType? {
        switch self {
        case is Bool:
            .bool
        case is Int:
            .int
        case is Double, is CGFloat:
            .double
        case is Angle:
            .angle
        case is CGSize:
            .size
        case is CGPoint:
            .point
        case is CGRect:
            .rect
        case is PixelColor:
            .color
        case is Point3D:
            .point3D
        case is Size3D:
            .size3D
        case is [Graphic.GradientStop]:
            .gradient
        default:
            fatalError("Unknown Graphic Value Type")
        }
    }
}

extension Bool: GraphicValue {
    
    public static var zero: Self { false }
    public static var one: Self { true }
    public static var `default`: GraphicMetadataValue<Self> { .fixed(false) }
    public static var minimum: GraphicMetadataValue<Self> { .fixed(false) }
    public static var maximum: GraphicMetadataValue<Self> { .fixed(true) }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        fraction > 0.0 ? trailing : leading
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        self
    }
}

extension Int: GraphicValue {
    
    public static var one: Self { 1 }
    public static var `default`: GraphicMetadataValue<Self> { .fixed(1) }
    public static var minimum: GraphicMetadataValue<Self> { .fixed(1) }
    public static var maximum: GraphicMetadataValue<Self> { .fixed(10) }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        Int(Double(leading) * (1.0 - fraction) + Double(trailing) * fraction)
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        Int(Double(self) * scale)
    }
}

extension Double: GraphicValue {
    
    public static var one: Self { 1.0 }
    public static var `default`: GraphicMetadataValue<Self> { .fixed(0.0) }
    public static var minimum: GraphicMetadataValue<Self> { .fixed(0.0) }
    public static var maximum: GraphicMetadataValue<Self> { .fixed(1.0) }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        leading * (1.0 - fraction) + trailing * fraction
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        self * scale
    }
}

extension CGFloat: GraphicValue {
    
    public static var one: Self { 1.0 }
    public static var `default`: GraphicMetadataValue<Self> { .fixed(0.0) }
    public static var minimum: GraphicMetadataValue<Self> { .fixed(0.0) }
    public static var maximum: GraphicMetadataValue<Self> { .fixed(1.0) }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        leading * (1.0 - fraction) + trailing * fraction
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        self * scale
    }
}

extension Angle: GraphicValue {
    
    public static var one: Self { .degrees(360) }
    public static var `default`: GraphicMetadataValue<Self> { .zero }
    public static var minimum: GraphicMetadataValue<Self> { .fixed(.degrees(-180)) }
    public static var maximum: GraphicMetadataValue<Self> { .fixed(.degrees(180)) }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        .degrees(Double.lerp(at: fraction, from: leading.degrees, to: trailing.degrees))
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        .degrees(degrees.scaled(by: scale))
    }
}

extension CGSize: GraphicValue {
    
//    public static var one: Self { CGSize(width: 1.0, height: 1.0) }
    public static var `default`: GraphicMetadataValue<Self> { .resolution }
    public static var minimum: GraphicMetadataValue<Self> { .zero }
    public static var maximum: GraphicMetadataValue<Self> { .resolution }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        CGSize(width: Double.lerp(at: fraction, from: leading.width, to: trailing.width),
               height: Double.lerp(at: fraction, from: leading.height, to: trailing.height))
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        CGSize(width: width.scaled(by: scale),
               height: height.scaled(by: scale))
    }
}

extension CGPoint: GraphicValue {
    
    public static var one: Self { CGPoint(x: 1.0, y: 1.0) }
    public static var `default`: GraphicMetadataValue<Self> { .resolutionAlignment(.center) }
    public static var minimum: GraphicMetadataValue<Self> { .zero }
    public static var maximum: GraphicMetadataValue<Self> { .resolution }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        CGPoint(x: Double.lerp(at: fraction, from: leading.x, to: trailing.x),
                y: Double.lerp(at: fraction, from: leading.y, to: trailing.y))
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        CGPoint(x: x.scaled(by: scale),
                y: y.scaled(by: scale))
    }
}

extension CGRect: GraphicValue {
    
    public static var one: Self { CGRect(origin: .zero, size: .one) }
    public static var `default`: GraphicMetadataValue<Self> { .resolution }
    public static var minimum: GraphicMetadataValue<Self> { .zero }
    public static var maximum: GraphicMetadataValue<Self> { .resolution }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        CGRect(origin: CGPoint.lerp(at: fraction, from: leading.origin, to: trailing.origin),
               size: CGSize.lerp(at: fraction, from: leading.size, to: trailing.size))
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        CGRect(origin: origin.scaled(by: scale),
               size: size.scaled(by: scale))
    }
}

extension PixelColor: GraphicValue {
    
    public static var zero: Self { .clear }
    public static var one: Self { .white }
    public static var `default`: GraphicMetadataValue<Self> { .fixed(.white) }
    public static var minimum: GraphicMetadataValue<Self> { .fixed(.clear) }
    public static var maximum: GraphicMetadataValue<Self> { .fixed(.white) }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        PixelColor(red: Double.lerp(at: fraction, from: leading.red, to: trailing.red),
                   green: Double.lerp(at: fraction, from: leading.green, to: trailing.green),
                   blue: Double.lerp(at: fraction, from: leading.blue, to: trailing.blue),
                   opacity: Double.lerp(at: fraction, from: leading.opacity, to: trailing.opacity))
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        PixelColor(red: red.scaled(by: scale),
                   green: green.scaled(by: scale),
                   blue: blue.scaled(by: scale),
                   opacity: opacity.scaled(by: scale))
    }
}

extension Point3D: GraphicValue {
    
    public static var one: Self { Point3D(x: 1.0, y: 1.0, z: 1.0) }
    public static var `default`: GraphicMetadataValue<Self> { .resolutionAlignment(.center) }
    public static var minimum: GraphicMetadataValue<Self> { .zero }
    public static var maximum: GraphicMetadataValue<Self> { .resolution }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        Point3D(x: Double.lerp(at: fraction, from: leading.x, to: trailing.x),
                y: Double.lerp(at: fraction, from: leading.y, to: trailing.y),
                z: Double.lerp(at: fraction, from: leading.z, to: trailing.z))
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        Point3D(x: x.scaled(by: scale),
                y: y.scaled(by: scale),
                z: z.scaled(by: scale))
    }
}

extension Size3D: GraphicValue {
    
    public static var `default`: GraphicMetadataValue<Self> { .resolution }
    public static var minimum: GraphicMetadataValue<Self> { .zero }
    public static var maximum: GraphicMetadataValue<Self> { .resolution }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        Size3D(width: Double.lerp(at: fraction, from: leading.width, to: trailing.width),
               height: Double.lerp(at: fraction, from: leading.height, to: trailing.height),
               depth: Double.lerp(at: fraction, from: leading.depth, to: trailing.depth))
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        Size3D(width: width.scaled(by: scale),
               height: height.scaled(by: scale),
               depth: depth.scaled(by: scale))
    }
}

extension Angle3D: GraphicValue {
    
    public static let one = Angle3D(
        x: Angle2D(degrees: 360),
        y: Angle2D(degrees: 360),
        z: Angle2D(degrees: 360)
    )
    public static var `default`: GraphicMetadataValue<Self> { .zero }
    public static var minimum: GraphicMetadataValue<Self> {
        .fixed(Angle3D(
            x: Angle2D(degrees: -180),
            y: Angle2D(degrees: -180),
            z: Angle2D(degrees: -180)
        ))
    }
    public static var maximum: GraphicMetadataValue<Self> {
        .fixed(Angle3D(
            x: Angle2D(degrees: 180),
            y: Angle2D(degrees: 180),
            z: Angle2D(degrees: 180)
        ))
    }
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        Angle3D(x: Angle2D(radians: Double.lerp(at: fraction, from: leading.x.radians, to: trailing.x.radians)),
                y: Angle2D(radians: Double.lerp(at: fraction, from: leading.y.radians, to: trailing.y.radians)),
                z: Angle2D(radians: Double.lerp(at: fraction, from: leading.z.radians, to: trailing.z.radians)))
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        Angle3D(x: Angle2D(radians: x.radians.scaled(by: scale)),
                y: Angle2D(radians: y.radians.scaled(by: scale)),
                z: Angle2D(radians: z.radians.scaled(by: scale)))
    }
}

extension [Graphic.GradientStop]: GraphicValue {
    
    public static var zero: Self { [] }
    public static var one: Self { 
        [
            .init(at: 0.0, color: .clear),
            .init(at: 1.0, color: .white)
        ]
    }
    public static var `default`: GraphicMetadataValue<Self> {
        .fixed([
            .init(at: 0.0, color: .clear),
            .init(at: 1.0, color: .white)
        ])
    }
    public static var minimum: GraphicMetadataValue<Self> { .fixed([]) }
    public static var maximum: GraphicMetadataValue<Self> { 
        .fixed([
            .init(at: 0.0, color: .clear),
            .init(at: 1.0, color: .white)
        ])
    }
    
    public static func lerp(at fraction: CGFloat, from leading: Self, to trailing: Self) -> Self {
        if leading.count == trailing.count {
            var gradient: Self = []
            for (leading, trailing) in zip(leading, trailing) {
                let stop = Graphic.GradientStop(
                    at: Double.lerp(at: fraction, from: leading.location, to: trailing.location),
                    color: PixelColor.lerp(at: fraction, from: leading.color, to: trailing.color))
                gradient.append(stop)
            }
            return gradient
        }
        return leading
    }
    
    public func scaled(by scale: CGFloat) -> Self {
        var gradient: Self = []
        for stop in self {
            let stop = Graphic.GradientStop(
                at: stop.location.scaled(by: scale),
                color: stop.color.scaled(by: scale))
            gradient.append(stop)
        }
        return gradient
    }
}
