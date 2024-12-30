//-----------------------------------------------------------------------------
// Copyright (c) 2024 Electronic Arts.  All rights reserved.粒子发射器

//-----------------------------------------------------------------------------

//!include dispatch.inc
//!include simConstants.inc
//!include particle.inc
//!include matrix.inc
//!include shapes.inc
//!include random.inc

@group(0) @binding(0) var<uniform> g_simConstants : SimConstants;
@group(0) @binding(1) var<storage, read_write> g_particleCount : array<atomic<u32>>;
@group(0) @binding(2) var<storage, read_write> g_particles : array<Particle>;
@group(0) @binding(3) var<storage> g_shapes : array<SimShape>;
@group(0) @binding(4) var<storage, read_write> g_freeIndices : array<atomic<i32>>;
@group(0) @binding(5) var<storage> g_grid : array<i32>;

fn createParticle(position: vec2f, material: f32, mass: f32, volume: f32, color: vec3f) -> Particle
{
    return Particle(
        position,
        vec2f(0,0),
        Identity,
        ZeroMatrix,
        1.0,
        mass,
        material,
        volume,
        0.0,
        1.0,
        color,
        1.0
    );
}

fn addParticle(position: vec2f, material: f32, volume: f32, density: f32, jitterScale: f32)
{
    var particleIndex = 0u;
    // First check the free list to see if we can reuse a particle slot
    let freeIndexSlot = atomicSub(&g_freeIndices[0], 1i) - 1i;
    if(freeIndexSlot >= 0)
    {
        particleIndex = u32(atomicLoad(&g_freeIndices[u32(freeIndexSlot) + 1]));
    }
    else // If free list is empty then grow the particle count
    {
        particleIndex = atomicAdd(&g_particleCount[0], 1);
    }

    var color = vec3f(1,1,1);

    if(material == MaterialLiquid)
    {
        color = vec3f(0.2,0.2,1);
    }
    else if(material == MaterialElastic)
    {
        color = vec3f(0.2,1,0.2);
    }
    else if(material == MaterialSand)
    {
        color = vec3f(1,1,0.2);
    }
    else if(material == MaterialVisco)
    {
        color = vec3f(1, 0.5, 1);
    }

    let jitterX = hash(particleIndex);
    let jitterY = hash(u32(position.x * position.y * 100));

    let jitter = vec2f(-0.25, -0.25) + 0.5*vec2f(f32(jitterX % 10) / 10, f32(jitterY % 10) / 10);

    var newParticle = createParticle(
        position + jitter*jitterScale,
        material,
        volume*density,
        volume,
        color
    );

    g_particles[particleIndex] = newParticle;
}

@compute @workgroup_size(GridDispatchSize, GridDispatchSize)
fn csMain( @builtin(global_invocation_id) id: vec3u )
{
    if(!insideGuardian(id.xy, g_simConstants.gridSize, GuardianSize+1))
    {
        return;
    }

    let gridSize = g_simConstants.gridSize;
    let pos = vec2f(id.xy);

    let weightInfo = quadraticWeightInit(pos);
    let nearestCell = vec2i(weightInfo.cellIndex) + vec2i(1,1); 
    let nearestCellVolume = decodeFixedPoint(g_grid[gridVertexIndex(vec2u(nearestCell), g_simConstants.gridSize) + 3], g_simConstants.fixedPointMultiplier);

    for(var shapeIndex = 0u; shapeIndex < g_simConstants.shapeCount; shapeIndex++)
    {
        let shape = g_shapes[shapeIndex];

        let isEmitter = shape.functionality == ShapeFunctionEmit;
        let isInitialEmitter = shape.functionality == ShapeFunctionInitialEmit;

        if(!(isEmitter || isInitialEmitter))
        {
            continue;
        }

        // Skip emission if we are spewing liquid into an already compressed space
        if(isEmitter && shape.emitMaterial == MaterialLiquid && nearestCellVolume > 1.5)
        {
            continue;
        } 

        let particleCountPerCellAxis = u32(g_simConstants.particlesPerCellAxis);
        let volumePerParticle = 1.0f / f32(particleCountPerCellAxis*particleCountPerCellAxis);

        var c = collide(shape, pos);
        if(c.collides)
        {
            let emitEvery = u32(1.0 / (shape.emissionRate * g_simConstants.deltaTime));

            for(var i = 0u; i < particleCountPerCellAxis; i++)
            {
                for(var j = 0u; j < particleCountPerCellAxis; j++)
                {
                    let hashCodeX = hash(id.x*particleCountPerCellAxis + i);
                    let hashCodeY = hash(id.y*particleCountPerCellAxis + j);
                    let hashCode = hash(hashCodeX + hashCodeY);

                    let emitDueToMyTurnHappening = isEmitter && 0 == ((hashCode + g_simConstants.simFrame) % emitEvery);
                    let emitDueToInitialEmission = isInitialEmitter && g_simConstants.simFrame == 0;

                    let emitPos = pos + vec2f(f32(i),f32(j))/f32(particleCountPerCellAxis);

                    if(emitDueToInitialEmission || emitDueToMyTurnHappening)
                    {
                        addParticle(emitPos, shape.emitMaterial, volumePerParticle, 1.0, 1.0/f32(particleCountPerCellAxis));
                    }
                }
            }
        }
    }
}
