//-----------------------------------------------------------------------------
// Copyright (c) 2024 Electronic Arts.  All rights reserved.divUp 的目的是计算 threadCount 除以 divisor 的结果，并向上取整。它确保即使存在余数，也能保证除法的结果足够大，以涵盖所有的线程。
divUp 是一个用来处理线程数分配的常见工具函数，尤其是在计算GPU或并行计算任务时，常常需要将任务分割成一定大小的块。向上取整是为了确保没有线程被遗漏，并且能够完整处理所有数据。
//-----------------------------------------------------------------------------


//!insert DispatchSizes

fn divUp(threadCount : u32, divisor : u32) -> u32
{
    return (threadCount + divisor - 1) / divisor;
}
