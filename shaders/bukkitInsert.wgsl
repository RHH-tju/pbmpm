//-----------------------------------------------------------------------------
// Copyright (c) 2024 Electronic Arts.  All rights reserved.粒子遍历：

每个工作项（线程）对应一个粒子，根据全局索引 id.x 获取粒子。
粒子分配到网格：

根据粒子的位置，计算其所在的网格块（bukkit）。
如果粒子位于有效网格范围内，将其分配到对应的网格块。
原子操作更新粒子计数：

使用 atomicAdd 确保粒子安全地插入到相应的网格块内。
计算插入的位置，并将粒子索引存入 g_particleData 数组中。
//-----------------------------------------------------------------------------

//!include dispatch.inc
//!include simConstants.inc
//!include bukkit.inc
//!include particle.inc

@group(0) @binding(0) var<uniform> g_simConstants : SimConstants;
@group(0) @binding(1) var<storage> g_particleCount : array<u32>;
@group(0) @binding(2) var<storage, read_write> g_particleInsertCounters : array<atomic<u32>>;
@group(0) @binding(3) var<storage> g_particles : array<Particle>;
@group(0) @binding(4) var<storage, read_write> g_particleData : array<u32>;
@group(0) @binding(5) var<storage> g_bukkitIndexStart : array<u32>;

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
    let bukkitIndexStart = g_bukkitIndexStart[bukkitIndex];

    let particleInsertCounter = atomicAdd(&g_particleInsertCounters[bukkitIndex], 1u);


    g_particleData[particleInsertCounter + bukkitIndexStart] = id.x;
}
