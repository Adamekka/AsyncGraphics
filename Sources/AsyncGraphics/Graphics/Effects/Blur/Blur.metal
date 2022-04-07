//
//  EffectSingleBlurPIX.metal
//  PixelKit Shaders
//
//  Created by Anton Heestand on 2017-11-14.
//  Copyright © 2017 Anton Heestand. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "../../../Metal/Content/random_header.metal"

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct Uniforms {
    int type;
    float radius;
    int count;
    float angle;
    float2 position;
};

fragment float4 blur(VertexOut out [[stage_in]],
                     texture2d<float>  texture [[ texture(0) ]],
                     const device Uniforms& uniforms [[ buffer(0) ]],
                     sampler sampler [[ sampler(0) ]]) {
    
    float pi = M_PI_F;
    int max_count = 16384 - 1;
    
    float u = out.texCoord[0];
    float v = out.texCoord[1];
    float2 uv = float2(u, v);
    
    float4 color = texture.sample(sampler, uv);
    
    uint width = texture.get_width();
    uint height = texture.get_height();
    float aspect = float(width) / float(height);
    
    int count = uniforms.count;
    
    float angle = uniforms.angle * pi * 2;
    float2 position = float2(uniforms.position.x, uniforms.position.y);
    
    float radius = uniforms.radius;

    int type = uniforms.type;
    
    float amounts = 1.0;
    
    if (type == 1) {
        
        // Box
        
        for (int x = -count; x <= count; ++x) {
            for (int y = -count; y <= count; ++y) {
                if (x != 0 && y != 0) {
                    float dist = sqrt(pow(float(x), 2) + pow(float(y), 2));
                    if (dist <= count) {
                        float amount = pow(1.0 - dist / (count + 1), 0.5);
                        float xu = u;
                        float yv = v;
                        if (aspect < 1.0) {
                            xu += ((float(x) / iw) * radius) / count;
                            yv += (((float(y) / iw) * radius) / count) * aspect;
                        } else {
                            xu += ((float(x) / ih) * radius) / count;
                            yv += (((float(y) / ih) * radius) / count) * aspect;
                        }
                        color += texture.sample(sampler, float2(xu, yv)) * amount;
                        amounts += amount;
                    }
                }
            }
        }
        
    } else if (type == 2) {
        
        // Angle
        
        for (int x = -count; x <= count; ++x) {
            if (x != 0) {
                float amount = pow(1.0 - x / (count + 1), 0.5);
                float xu = u;
                float yv = v;
                if (aspect < 1.0) {
                    xu += ((float(x) / iw) * cos(-angle) * radius) / count;
                    yv += (((float(x) / iw) * sin(-angle) * radius) / count) * aspect;
                } else {
                    xu += ((float(x) / ih) * cos(-angle) * radius) / count;
                    yv += (((float(x) / ih) * sin(-angle) * radius) / count) * aspect;
                }
                color += texture.sample(sampler, float2(xu, yv)) * amount;
                amounts += amount;
            }
        }
        
    } else if (type == 3) {
        
        // Zoom
        
        for (int x = -count; x <= count; ++x) {
            if (x != 0) {
                float amount = pow(1.0 - x / (count + 1), 0.5);
                float xu = u;
                float yv = v;
                if (aspect < 1.0) {
                    xu += (((float(x) * (u - 0.5 - position.x)) / iw) * radius) / count;
                    yv += ((((float(x) * (v - 0.5 + position.y)) / iw) * radius) / count);// * aspect;
                } else {
                    xu += (((float(x) * (u - 0.5 - position.x)) / ih) * radius) / count;
                    yv += ((((float(x) * (v - 0.5 + position.y)) / ih) * radius) / count);// * aspect;
                }
                color += texture.sample(sampler, float2(xu, yv)) * amount;
                amounts += amount;
            }
        }
        
    }
    //    else if (type == 4) {
    //
    //        // Radial
    //
    //        for (int x = -count; x <= count; ++x) {
    //            if (x != 0) {
    //                float amount = pow(1.0 - x / (count + 1), 0.5);
    //                float xu = u;
    //                float yv = v;
    //                if (aspect < 1.0) {
    //                    xu += ((float(x) / iw) * cos(atan2(v - 0.5 + position.y, u - 0.5 - position.x) + pi / 2) * radius) / count;
    //                    yv += ((float(x) / iw) * sin(atan2(v - 0.5 + position.y, u - 0.5 - position.x) + pi / 2) * radius) / count;
    //                } else {
    //                    xu += ((float(x) / ih) * cos(atan2(v - 0.5 + position.y, u - 0.5 - position.x) + pi / 2) * radius) / count;
    //                    yv += ((float(x) / ih) * sin(atan2(v - 0.5 + position.y, u - 0.5 - position.x) + pi / 2) * radius) / count;
    //                }
    //                color += texture.sample(sampler, float2(xu, yv)) * amount;
    //                amounts += amount;
    //            }
    //        }
    //
    //    }
    else if (type == 4) {
        
        // Random
        Loki loki_rnd_u = Loki(0, u * max_count, v * max_count);
        float ru = loki_rnd_u.rand();
        Loki loki_rnd_v = Loki(1, u * max_count, v * max_count);
        float rv = loki_rnd_v.rand();
        float2 ruv = uv + (float2(ru, rv) - 0.5) * radius * 0.001 * float2(1.0, aspect);
        color = texture.sample(sampler, ruv);
        
    }
    
    color /= amounts;
    
    return color;
}


