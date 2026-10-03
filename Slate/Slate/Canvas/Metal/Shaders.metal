//
//  Shaders.metal
//  Slate
//
//  Created for Slate Native Whiteboard.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 projectionMatrix;
    float2 viewportSize;
    float2 viewportOffset;
    float zoom;
    float gridSpacing;
    int gridType; // 0: Dots, 1: Grid, 2: Lines, 3: Blank
    float4 backgroundColor;
    float4 gridColor;
};

struct VertexIn {
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
    float2 uv [[attribute(2)]]; // u: progress along segment, v: distance from center line (-1.0 ... 1.0)
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 uv;
};

// Fullscreen quad for procedural grid background
struct BackgroundVertexOut {
    float4 position [[position]];
    float2 canvasCoord;
};

vertex BackgroundVertexOut backgroundVertexShader(
    uint vertexID [[vertex_id]],
    constant Uniforms &uniforms [[buffer(0)]]
) {
    // 2 triangles covering full screen
    float2 positions[6] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2(-1.0,  1.0),
        float2( 1.0, -1.0),
        float2( 1.0,  1.0)
    };
    
    BackgroundVertexOut out;
    float2 pos = positions[vertexID];
    out.position = float4(pos, 0.0, 1.0);
    
    // Map screen NDC back to canvas space
    float2 screenPos = float2((pos.x + 1.0) * 0.5 * uniforms.viewportSize.x,
                              (1.0 - pos.y) * 0.5 * uniforms.viewportSize.y);
    out.canvasCoord = (screenPos / uniforms.zoom) - uniforms.viewportOffset;
    return out;
}

fragment float4 backgroundFragmentShader(
    BackgroundVertexOut in [[stage_in]],
    constant Uniforms &uniforms [[buffer(0)]]
) {
    if (uniforms.gridType == 3) { // Blank
        return uniforms.backgroundColor;
    }
    
    float spacing = uniforms.gridSpacing * uniforms.zoom;
    if (spacing < 6.0) {
        return uniforms.backgroundColor; // Too dense to render cleanly
    }
    
    float2 screenCoord = (in.canvasCoord + uniforms.viewportOffset) * uniforms.zoom;
    float4 bg = uniforms.backgroundColor;
    float4 grid = uniforms.gridColor;
    
    if (uniforms.gridType == 0) { // Dots
        float2 modCoord = fmod(screenCoord, spacing);
        if (modCoord.x < 0.0) modCoord.x += spacing;
        if (modCoord.y < 0.0) modCoord.y += spacing;
        
        float dist = length(modCoord - float2(spacing * 0.5));
        float dotRadius = clamp(1.2 * min(uniforms.zoom, 1.5), 1.0, 2.5);
        float alpha = smoothstep(dotRadius + 0.6, dotRadius - 0.6, dist);
        return mix(bg, grid, alpha * grid.a);
    } else if (uniforms.gridType == 1) { // Grid
        float2 modCoord = fmod(screenCoord, spacing);
        if (modCoord.x < 0.0) modCoord.x += spacing;
        if (modCoord.y < 0.0) modCoord.y += spacing;
        
        float distToLineX = min(modCoord.x, spacing - modCoord.x);
        float distToLineY = min(modCoord.y, spacing - modCoord.y);
        float dist = min(distToLineX, distToLineY);
        float alpha = smoothstep(1.0, 0.0, dist);
        return mix(bg, grid, alpha * grid.a);
    } else if (uniforms.gridType == 2) { // Ruled Lines
        float modY = fmod(screenCoord.y, spacing);
        if (modY < 0.0) modY += spacing;
        float distToLineY = min(modY, spacing - modY);
        float alpha = smoothstep(1.0, 0.0, distToLineY);
        return mix(bg, grid, alpha * grid.a);
    }
    
    return bg;
}

// Stroke and geometry shaders
vertex VertexOut strokeVertexShader(
    VertexIn in [[stage_in]],
    constant Uniforms &uniforms [[buffer(1)]]
) {
    VertexOut out;
    float2 canvasPos = in.position;
    
    // Project canvas coordinate to NDC
    float2 screenPos = (canvasPos + uniforms.viewportOffset) * uniforms.zoom;
    float2 ndc = float2(
        (screenPos.x / uniforms.viewportSize.x) * 2.0 - 1.0,
        1.0 - (screenPos.y / uniforms.viewportSize.y) * 2.0
    );
    
    out.position = float4(ndc, 0.0, 1.0);
    out.color = in.color;
    out.uv = in.uv;
    return out;
}

fragment float4 strokeFragmentShader(
    VertexOut in [[stage_in]]
) {
    // UV v coordinate is distance from center line (-1.0 to 1.0)
    float distFromCenter = abs(in.uv.y);
    // Smooth anti-aliased edge
    float alpha = smoothstep(1.0, 0.85, distFromCenter) * in.color.a;
    return float4(in.color.rgb, alpha);
}

fragment float4 highlighterFragmentShader(
    VertexOut in [[stage_in]]
) {
    float distFromCenter = abs(in.uv.y);
    float alpha = smoothstep(1.0, 0.9, distFromCenter) * in.color.a * 0.35;
    return float4(in.color.rgb, alpha);
}

fragment float4 laserFragmentShader(
    VertexOut in [[stage_in]]
) {
    float distFromCenter = abs(in.uv.y);
    // Core beam + soft outer glow
    float core = smoothstep(0.4, 0.0, distFromCenter);
    float glow = smoothstep(1.0, 0.2, distFromCenter) * 0.6;
    float intensity = clamp(core + glow, 0.0, 1.0) * in.color.a;
    return float4(in.color.rgb, intensity);
}
