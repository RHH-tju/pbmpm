//-----------------------------------------------------------------------------
// Copyright (c) 2024 Electronic Arts.  All rights reserved.这段代码的主要作用是为粒子系统中的每个 bukkit 计算调度工作组，并将粒子分配给各个工作组进行处理。它通过：

根据网格地址计算 bukkit 索引。
根据每个 bukkit 中的粒子数量，计算需要多少个工作组来处理这些粒子。
通过原子操作管理并发计算过程中的粒子索引和工作组调度。
为每个工作组分配任务，并记录每个工作组处理的粒子范围和位置。
这种方法是为了提高粒子计算的并行效率，确保在 GPU 上能够充分利用多个计算单元。
//-----------------------------------------------------------------------------

//!include dispatch.inc
//!include simConstants.inc
//!include bukkit.inc

@group(0) @binding(0) var<uniform> g_simConstants : SimConstants;
@group(0) @binding(1) var<storage> g_bukkitCounts : array<u32>;
@group(0) @binding(2) var<storage, read_write> g_bukkitIndirectDispatch : array<atomic<u32>>;
@group(0) @binding(3) var<storage, read_write> g_bukkitThreadData : array<BukkitThreadData>;
@group(0) @binding(4) var<storage, read_write> g_bukkitParticleAlloctor : array<atomic<u32>>;
@group(0) @binding(5) var<storage, read_write> g_bukkitIndexStart : array<u32>;

@compute @workgroup_size(GridDispatchSize, GridDispatchSize)
fn csMain( @builtin(global_invocation_id) id: vec3<u32> )
{
    if(id.x >= g_simConstants.bukkitCountX || id.y >= g_simConstants.bukkitCountY)
    {
        return;
    }

    let bukkitIndex = bukkitAddressToIndex(id.xy, g_simConstants.bukkitCountX);

    let bukkitCount = g_bukkitCounts[bukkitIndex];
    let bukkitCountResidual = bukkitCount % ParticleDispatchSize;

    if(bukkitCount == 0)
    {
        return;
    }

    let dispatchCount = divUp(bukkitCount, ParticleDispatchSize);

    let dispatchStartIndex = atomicAdd(&g_bukkitIndirectDispatch[0], dispatchCount);
    let particleStartIndex = atomicAdd(&g_bukkitParticleAlloctor[0], bukkitCount);

    g_bukkitIndexStart[bukkitIndex] = particleStartIndex;

    for(var i: u32 = 0; i < dispatchCount; i++)
    {
        // Group count is equal to ParticleDispatchSize except for the final dispatch for this
        // bukkit in which case it's equal to the residual count
        var groupCount : u32 = ParticleDispatchSize;
        if(bukkitCountResidual != 0 && i == dispatchCount - 1)
        {
            groupCount = bukkitCountResidual;
        }

        g_bukkitThreadData[i + dispatchStartIndex] = BukkitThreadData(
            particleStartIndex + i * ParticleDispatchSize,
            groupCount,
            id.x,
            id.y
        );
    }
}
