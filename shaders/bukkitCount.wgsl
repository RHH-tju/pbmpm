//-----------------------------------------------------------------------------
// Copyright (c) 2024 Electronic Arts.  All rights reserved.粒子位置到网格块的转换：

使用 positionToBukkitId 函数，将粒子的 position 转换为所在的网格块坐标 particleBukkit。
判断粒子是否在有效范围内：

判断粒子是否在有效的网格范围内。如果超出了有效网格的范围，则忽略该粒子。
更新粒子所在网格块的计数：

使用 bukkitAddressToIndex 将网格块的坐标转换为网格块的线性索引 bukkitIndex。
使用 atomicAdd 操作安全地增加该网格块的粒子计数。
//-----------------------------------------------------------------------------

//!include dispatch.inc
//!include simConstants.inc
//!include particle.inc
//!include bukkit.inc

@group(0) @binding(0) var<uniform> g_simConstants : SimConstants;
@group(0) @binding(1) var<storage> g_particleCount : array<u32>;
@group(0) @binding(2) var<storage> g_particles : array<Particle>;
@group(0) @binding(3) var<storage, read_write> g_bukkitCounts : array<atomic<u32>>;

@compute @workgroup_size(ParticleDispatchSize)
fn csMain( @builtin(global_invocation_id) id: vec3<u32> )
{
    if(id.x >= g_particleCount[0])
    {
        return;
    }

    let particle = g_particles[id.x];

    if(particle.enabled == 0)
    {
        return;
    }

    let position = particle.position;

    let particleBukkit = positionToBukkitId(position);

    if(any(particleBukkit < vec2i(0)) || u32(particleBukkit.x) >= g_simConstants.bukkitCountX || u32(particleBukkit.y) >= g_simConstants.bukkitCountY)
    {
        return;
    }

    let bukkitIndex = bukkitAddressToIndex(vec2u(particleBukkit), g_simConstants.bukkitCountX);

    atomicAdd(&g_bukkitCounts[bukkitIndex], 1);    
}
