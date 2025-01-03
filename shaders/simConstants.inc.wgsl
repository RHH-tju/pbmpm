//-----------------------------------------------------------------------------
// Copyright (c) 2024 Electronic Arts.  All rights reserved.作用包括两个gridVertexIndex：根据网格的二维坐标计算顶点的索引。
decodeFixedPoint：将固定点数值转换为浮动值，通常用于从存储格式中读取数据。
encodeFixedPoint：将浮动值编码为固定点格式，通常用于将计算结果存储为整数，以优化存储和性能。
//-----------------------------------------------------------------------------

// Code-generated by UniformBufferFactory
//!insert SimConstants

// const values like SolverTypeExplicit etc
// that are plugged in from js 
//!insert SimEnums

fn gridVertexIndex(gridVertex : vec2u, gridSize : vec2u) -> u32
{
    // Currently using lexicographical ordering
    // 4 components per grid vertex
    return u32(4*(gridVertex.y * gridSize.x + gridVertex.x));
}

fn decodeFixedPoint(fixedPoint : i32, fixedPointMultiplier : u32) -> f32
{
    return f32(fixedPoint) / f32(fixedPointMultiplier);
}

fn encodeFixedPoint(floatingPoint : f32, fixedPointMultiplier: u32) -> i32
{
    return i32(floatingPoint * f32(fixedPointMultiplier));
}
