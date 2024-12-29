//-----------------------------------------------------------------------------
// Copyright (c) 2024 Electronic Arts.  All rights reserved.该计算着色器的主要目的是更新与粒子数量和渲染相关的间接参数。具体来说：

计算模拟阶段的工作组数：通过 divUp 函数计算需要的工作组数，并将结果存储在 g_simIndirectArgs[0] 中。
更新渲染阶段的粒子计数：将粒子数量存储到 g_renderIndirectArgs[1] 中，告知渲染阶段需要渲染多少粒子。
这种类型的计算着色器通常用于粒子系统中，其中模拟和渲染可能是分开处理的，使用间接参数来动态地调整计算和渲染的工作量。
//-----------------------------------------------------------------------------

//!include dispatch.inc

@group(0) @binding(0) var<storage> g_particleCount : array<u32>;
@group(0) @binding(1) var<storage, read_write> g_simIndirectArgs : array<u32>;
@group(0) @binding(2) var<storage, read_write> g_renderIndirectArgs : array<u32>;

@compute @workgroup_size(1)
fn csMain( @builtin(global_invocation_id) id: vec3<u32> )
{
    g_simIndirectArgs[0] = divUp(g_particleCount[0], ParticleDispatchSize);
    g_renderIndirectArgs[1] = g_particleCount[0];
}
