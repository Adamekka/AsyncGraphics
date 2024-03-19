//
//  File.swift
//  
//
//  Created by Anton on 2024-03-19.
//

import Foundation
import Spatial
import SpatialExtensions

extension Graphic3D {
    
    public enum TileError: Error {
        case badResolution(Size3D)
        case badCount(Tile.Size)
    }
    
    /// Tile render a ``Graphic3D`` with a very large resolution.
    /// - Parameters:
    ///   - count: The number of tiles.
    ///   - padding: A padding relative to the final resolution height, it can be useful to use when working with distortion effects, tho has no effect on color effects.
    ///   - resolution: The final resolution.
    ///   - render: A callback where you render a tile of ``Graphic3D``. Pass the tile struct to the shape you are rendering.
    /// - Returns: A tilled ``Graphic3D``.
    public static func tiled(
        count: Tile.Size,
        padding: CGFloat = 0.0,
        resolution: Size3D,
        render: (Tile) async throws -> Graphic3D
    ) async throws -> Graphic3D {
        
        guard count.width > 0,
              count.height > 0,
              count.depth > 0 else {
            throw TileError.badCount(count)
        }
        guard resolution.width > CGFloat(count.width),
              resolution.height > CGFloat(count.height),
              resolution.depth > CGFloat(count.depth) else {
            throw TileError.badResolution(resolution)
        }
        
        let tilePadding = padding / (resolution.height / CGFloat(count.height))
        
        var volumeGraphic: Graphic3D?
        for z in 0..<count.depth {
            var gridGraphic: Graphic3D?
            for y in 0..<count.height {
                var rowGraphic: Graphic3D?
                for x in 0..<count.width {
                    
                    let tile = Tile(
                        origin: .init(x: x, y: y, z: z),
                        count: count,
                        padding: tilePadding)
                    
                    var tileGraphic: Graphic3D = try await render(tile)
                    
                    if padding > 0.0 {
                        let cropOrigin = Point3D(x: padding, y: padding, z: padding)
                        let cropResolution = Size3D(
                            width: resolution.width / CGFloat(count.width),
                            height: resolution.height / CGFloat(count.height),
                            depth: resolution.depth / CGFloat(count.depth))
                        tileGraphic = try await tileGraphic.crop(
                            to: Rect3D(origin: cropOrigin,
                                       size: cropResolution))
                    }
                    
                    if let previousGraphic: Graphic3D = rowGraphic {
                        rowGraphic = try await previousGraphic.hStacked(with: tileGraphic)
                    } else {
                        rowGraphic = tileGraphic
                    }
                }
                guard let rowGraphic: Graphic3D else {
                    fatalError("Tile Row Graphic Not Found")
                }
                if let previousGraphic: Graphic3D = gridGraphic {
                    gridGraphic = try await previousGraphic.vStacked(with: rowGraphic)
                } else {
                    gridGraphic = rowGraphic
                }
            }
            guard let gridGraphic: Graphic3D else {
                fatalError("Tile Grid Graphic Not Found")
            }
            if let previousGraphic: Graphic3D = volumeGraphic {
                volumeGraphic = try await previousGraphic.dStacked(with: gridGraphic)
            } else {
                volumeGraphic = gridGraphic
            }
        }
        guard let volumeGraphic: Graphic3D else {
            fatalError("Tile Volume Graphic Not Found")
        }
        return volumeGraphic
    }
}
