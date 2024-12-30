//-----------------------------------------------------------------------------
// Copyright (c) 2024 Electronic Arts.  All rights reserved.网格坐标转换为一维数组，粒子的position进行地板除法取整，设置
//-----------------------------------------------------------------------------这个结构体用于存储与每个 bukkit 相关的计算线程数据。它帮助在计算过程中追踪粒子在 bukkit 中的范围和位置。

//!include simConstants.inc

fn bukkitAddressToIndex(address: vec2u, bukkitCountX: u32) -> u32
{
    return address.y*bukkitCountX + address.x;
}

fn positionToBukkitId(position: vec2f) -> vec2i
{
    return vec2i((position) / f32(BukkitSize));
}

struct BukkitThreadData
{
    rangeStart: u32,
    rangeCount: u32,
    bukkitX: u32,
    bukkitY: u32,
};
