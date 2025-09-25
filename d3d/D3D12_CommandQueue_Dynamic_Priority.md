# ID3D12CommandQueue Dynamic Priority

## Introduction

Currently in `ID3D12Device::CreateCommandQueue` parameters, `D3D12_COMMAND_QUEUE_DESC.Priority` allows setting the `D3D12_COMMAND_QUEUE_PRIORITY` that the created queue object will have for its entire lifetime, but that priority cannot be adjusted dynamically. In the existing API `D3D12_COMMAND_QUEUE_PRIORITY_NORMAL` and `D3D12_COMMAND_QUEUE_PRIORITY_HIGH` correspond to process priorities, and `D3D12_COMMAND_QUEUE_PRIORITY_GLOBAL_REALTIME` corresponds to global priority.

> **Note that this feature is disabled when DIRECT or COMPUTE queues are grouped in Scheduling Groups, and in that case the creation priority parameter is ignored.** This must be kept this way for app-compat, but the new APIs in this spec would allow creation of such queue types with new defined flags that will not ignore the creation parameter priority.

There are certain scenarios where the apps calling into D3D12 needs to _dynamically_ adjust the priorities on specific command queues. This spec states the necessary changes to the D3D12 runtime to allow such command queue dynamic global/process priority setting. No driver changes are involved.

## Scheduling groups and command queues

### Exposing new information to apps

Introducing a new `CheckFeatureSupport` cap `D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS` with associated data structure `D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS`.

```C++
typedef struct D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS
{
    [annotation("_Out_")] UINT ComputeQueuesPer3DQueue;
} D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS;
```

*ComputeQueuesPer3DQueue*

When reported as greater than zero, indicates the maximum number of `COMPUTE` command queues (with the same `CreatorID`) can be grouped together with a `DIRECT` queue in the same scheduling group.

When reported as zero, means that scheduling groups do not group more than one queue.

### Intro to grouping algorithm

When hardware scheduling is enabled and `ID3D12CommandQueue` of `DIRECT` or `COMPUTE` type objects are created, they are grouped into a scheduling group that shares their engine `NodeIndex` and `CreatorID`.

The scheduling groups can hold up to 1 `DIRECT` queue and up to `ComputeQueuesPer3DQueue` compute queues, before they become full. Once they are full, a new scheduling group is created as the next queue of these types is created. 

At queue creation, the runtime looks for a non-full scheduling group from the first to the last existing scheduling groups in creation order to associate the new queue with, or creates a new one if no suitable scheduling group was found.

Deleting a command queue that was associated to a scheduling group will open up a spot in an otherwise possibly full scheduling group, and the next queue created will be able to take up this spot and prevent creation of a new scheduling group if no other spots were available.

### Relation to dynamic priorities feature

Given that priorities apply to scheduling groups (as opposed to applying to individual command queues), we need to first extend the _command queue to scheduling group_ mapping algorithm at queue creation, using new `D3D12_COMMAND_QUEUE_FLAGS`, to allow for apps to opt-in to new grouping modes when dynamic priority adjustement is enabled.

If the app doesn't opt-in explicitly when creating a queue with the new defined flags, the scheduling group to queue grouping algorithm remains unchanged, and queues created without them cannot adjust their priority dynamically. Any priority specification (either at queue creation or dynamically adjusted) of queues created with the new flags defined in `D3D12_COMMAND_QUEUE_FLAGS` does not affect the priorities of any other queues created without the flags, to maintain app compat.

## STRUCT: D3D12_COMMAND_QUEUE_FLAGS

```C++
typedef enum D3D12_COMMAND_QUEUE_FLAGS
{
  // ... new flags ...
  D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY = ...,
} D3D12_COMMAND_QUEUE_FLAGS;
```

*D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY*

If set, indicates that the runtime will allow dynamically adjusting the priority of the underlying scheduling group associated with this command queue. Altering the priority of this queue or any other in the same scheduling group, affects the priority of all other queues in the scheduling group.

Furthermore, when creating a queue with this flag, the creation priority parameter overrides the priority of all other queues already associated to the same scheduling group.

If set, on command queue creation, the runtime will group this new command queue with scheduling groups with the same `CreatorID` **and that only contain other queues with this flag also set**. The latter restriction ensures that queues created without any of the new flags don't get their priorities affected by the usage of the new APIs.

> Note: In case apps want to create queues that can have their priorities dynamically adjusted without altering other queues in the same scheduling group, they can use the existing `CreatorID` API with a unique `CreatorID` to keep the queue associated 1:1 with a scheduling group.

## Command queue priorities

### Queue creation priority assignment

On command queue creation, `D3D12_COMMAND_QUEUE_PRIORITY` (passed in `D3D12_COMMAND_QUEUE_DESC.Priority`) determines the initial command queue priority relative to other contexts within the same process, or for global realtime, relative to other apps in the system.

### Dynamic queue priority adjustment

Two kinds of orthogonal priority settings can be dynamically adjusted on command queues after creation:

- `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` specifies a priority relative to other apps in the system.

- `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY` specifies a non-yielding boost relative to other contexts within the same process.

### Mapping table: D3D12_COMMAND_QUEUE_PRIORITY - D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY/D3D12_COMMAND_QUEUE_PROCESS_PRIORITY

The value of `D3D12_COMMAND_QUEUE_DESC.Priority` at creation will map to default values for `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY` and `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY`.

When the app aims to dynamically set a priority to match a definition of `D3D12_COMMAND_QUEUE_PRIORITY`, the app must set the `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` and/or `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY` values to the corresponding values in the table (e.g reverse mapping lookup).

Note that the app has more flexibility when adjusting `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY` and `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` dynamically to configure new combinations not expressed by `D3D12_COMMAND_QUEUE_PRIORITY` at creation.

| `D3D12_COMMAND_QUEUE_PRIORITY` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` |
| -------- | -------- | -------- |
| `D3D12_COMMAND_QUEUE_PRIORITY_GLOBAL_REALTIME` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_HIGH` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_HARD_REALTIME` |
| `D3D12_COMMAND_QUEUE_PRIORITY_HIGH` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_HIGH` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT` |
| `D3D12_COMMAND_QUEUE_PRIORITY_NORMAL` | `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL` | `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT` |

## STRUCT: D3D12_COMMAND_QUEUE_PRIORITY

```C++
typedef enum D3D12_COMMAND_QUEUE_PRIORITY
{
  D3D12_COMMAND_QUEUE_PRIORITY_NORMAL = 0,
  D3D12_COMMAND_QUEUE_PRIORITY_HIGH = 100,
  D3D12_COMMAND_QUEUE_PRIORITY_GLOBAL_REALTIME = 10000
} D3D12_COMMAND_QUEUE_PRIORITY;
```

## STRUCT: D3D12_COMMAND_QUEUE_PROCESS_PRIORITY

```C++
typedef enum D3D12_COMMAND_QUEUE_PROCESS_PRIORITY
{
  D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL = 0,
  D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_HIGH = 1,
} D3D12_COMMAND_QUEUE_PROCESS_PRIORITY;
```

> Note that `D3D12_COMMAND_QUEUE_PROCESS_PRIORITY` numeric definitions don't exactly match dxgk nor allow undefined values to be used. Only well defined enum values will be mapped/accepted by the runtime and mapped into dxgk values. New D3D12 definitions will be needed to be added to expose more dxgk granularity in the future.

## STRUCT: D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY

```C++
typedef enum D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY
{
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_IDLE = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_NORMAL = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_0 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_1 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_2 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_3 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_4 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_5 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_6 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_7 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_8 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_9 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_10 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_11 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_12 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_13 = ...,
  D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_HARD_REALTIME = ...,

} D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY;
```

> Note that `D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY` numeric definitions don't exactly match dxgk nor allow undefined values to be used. Only well defined enum values will be mapped/accepted by the runtime and mapped into dxgk values. New D3D12 definitions will be needed to be added to expose more dxgk granularity in the future.

## INTERFACE: ID3D12CommandQueue1

```C++
interface ID3D12CommandQueue1
    : ID3D12CommandQueue
{
    HRESULT SetProcessPriority(D3D12_COMMAND_QUEUE_PROCESS_PRIORITY Priority);
    HRESULT GetProcessPriority(D3D12_COMMAND_QUEUE_PROCESS_PRIORITY* pOutValue);

    HRESULT SetGlobalPriority(D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY Priority);
    HRESULT GetGlobalPriority(D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY* pOutValue);
}
```

*SetProcessPriority*

Requires a queue created with `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`.

Sets a `Priority` for this queue for the current process. On success, the priority is applied immediately. All the work scheduled with calls to `ID3D12CommandQueue::ExecuteCommandLists` that is still pending execution before the call to `SetProcessPriority` is executed with the new priority set. All the new work submitted with `ID3D12CommandQueue::ExecuteCommandLists` after the call to `SetProcessPriority` also is executed with the new priority.

**Return values**

| HRESULT | Message |
| -------- | -------- |
| `S_OK` | The priority was set correctly |
| `S_FALSE` | The priority request for this adapter couldn't be applied and the request was ignored |
| `E_INVALIDARG` | Invalid parameter |
| `DXGI_ERROR_UNSUPPORTED ` | `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY` not present in this queue |
| `E_ACCESSDENIED` | Not enough permissions to set this priority |

> Note that elevation is required to configure some priorities.

*GetProcessPriority*

Returns the latest value set by `SetProcessPriority`, or the value assigned at queue creation based on `D3D12_COMMAND_QUEUE_DESC.Priority` creation arguments (see mapping table above).

**Return values**

| HRESULT | Message |
| -------- | -------- |
| `S_OK` | The returned priority was set using `SetProcessPriority` |
| `E_INVALIDARG` | Invalid parameter |

*SetGlobalPriority*

Requires a queue created with `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY`.

Sets a global `Priority` for this queue. On success, the priority is applied immediately. All the work scheduled with calls to `ID3D12CommandQueue::ExecuteCommandLists` that is still pending execution before the call to `SetProcessPriority` is executed with the new priority set. All the new work submitted with `ID3D12CommandQueue::ExecuteCommandLists` after the call to `SetProcessPriority` also is executed with the new priority.

**Return values**

| HRESULT | Message |
| -------- | -------- |
| `S_OK` | The priority was set correctly |
| `S_FALSE` | The priority request for this adapter couldn't be applied and the request was ignored |
| `E_INVALIDARG` | Invalid parameter |
| `DXGI_ERROR_UNSUPPORTED ` | `D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY` not present in this queue |
| `E_ACCESSDENIED` | Not enough permissions to set this priority |

> Note that elevation is required to configure some priorities.

*GetGlobalPriority*

Returns the latest value set by `SetGlobalPriority`, or the value assigned at queue creation based on `D3D12_COMMAND_QUEUE_DESC.Priority` creation arguments (see mapping table above).

**Return values**

| HRESULT | Message |
| -------- | -------- |
| `S_OK` | The returned priority was set using `SetProcessPriority` |
| `E_INVALIDARG` | Invalid parameter |

# Scheduling groups and command queues grouping example

## Example 1: Grouping algorithm without priority adjusting

```C++
CComPtr<ID3D12Device9> spDevice9;
// ... Get spDevice9 ...

// App to query the caps to obtain the N value indicating the scheduling groups capacity for compute queues
D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS hwsQueueGroupingCapData = { };
VERIFY_SUCCEEDED(spDevice9->CheckFeatureSupport(D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS, &hwsQueueGroupingCapData, sizeof(hwsQueueGroupingCapData)));
// Let's assume hwsQueueGroupingCapData.ComputeQueuesPer3DQueue = 2; for the example.
// hwsQueueGroupingCapData.ComputeQueuesPer3DQueue indicates how many compute queues can be grouped in a scheduling group. Additionally, 1 DIRECT queue can be added to a scheduling group

//
// Expectation for group mapping when creating DIRECT and COMPUTE queues
//
{
    GUID NullCreatorID = {}; // Calling CreateCommandQueue1 with a null creator ID applies the same queue grouping as calling CreateCommandQueue.
    D3D12_COMMAND_QUEUE_DESC QueueDesc = { };
    QueueDesc.Type = D3D12_COMMAND_LIST_TYPE_COMPUTE;
    
    D3D12_COMMAND_QUEUE_DESC QueueDescDirect = { };
    QueueDescDirect.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;

    //
    // Use NullCreatorID to illustrate the general grouping algorithm
    //

    CComPtr<ID3D12CommandQueue> spComputeQueue0;
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDesc, NullCreatorID, IID_PPV_ARGS(&spComputeQueue0)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0 } }

    CComPtr<ID3D12CommandQueue> spDirectQueue0;
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDescDirect, NullCreatorID, IID_PPV_ARGS(&spDirectQueue0)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0 } }

    CComPtr<ID3D12CommandQueue> spComputeQueue1;
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDesc, NullCreatorID, IID_PPV_ARGS(&spComputeQueue1)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0, spComputeQueue1 } }

    CComPtr<ID3D12CommandQueue> spComputeQueue2;
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDesc, NullCreatorID, IID_PPV_ARGS(&spComputeQueue2)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0, spComputeQueue1 } } <--- full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 1 = { NullCreatorID, { spComputeQueue2 } } <--- new scheduling group is created for the new queue

    CComPtr<ID3D12CommandQueue> spComputeQueue3;
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDesc, NullCreatorID, IID_PPV_ARGS(&spComputeQueue3)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0, spComputeQueue1 } } <--- full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 1 = { NullCreatorID, { spComputeQueue2, spComputeQueue3 } }


    spComputeQueue1.Release(); // Delete spComputeQueue1
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0 } } <--- removed spComputeQueue1
    //    Scheduling group 1 = { NullCreatorID, { spComputeQueue2, spComputeQueue3 } }

    CComPtr<ID3D12CommandQueue> spComputeQueue4;
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDesc, NullCreatorID, IID_PPV_ARGS(&spComputeQueue4)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0, spComputeQueue4 } } <--- uses empty slot from spComputeQueue1's removal on a previously full scheduling group
    //    Scheduling group 1 = { NullCreatorID, { spComputeQueue2, spComputeQueue3 } }

    //
    // Use non-null CustomCreatorID1 and CustomCreatorID2 to illustrate the general grouping algorithm
    //
    CComPtr<ID3D12CommandQueue> spComputeQueue5;
    GUID CustomCreatorID1 = { 0x2600d0ff, 0xfeea, 0x4500, { 0x85, 0x6a, 0x44, 0x76, 0xbb, 0xc4, 0x72, 0x66 } };
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDesc, CustomCreatorID1, IID_PPV_ARGS(&spComputeQueue5)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0, spComputeQueue4 } } <--- full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 1 = { NullCreatorID, { spComputeQueue2, spComputeQueue3 } } <--- NOT full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 2 = { CustomCreatorID1, { spComputeQueue5 } } <--- Creates a new scheduling group for CustomCreatorID1

    CComPtr<ID3D12CommandQueue> spComputeQueue6;
    GUID CustomCreatorID2 = { 0x78a0defe, 0xabb0, 0xc4b1, { 0x77, 0x23, 0x56, 0x78, 0xaa, 0x7c, 0x1a, 0x33 } };
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDesc, CustomCreatorID2, IID_PPV_ARGS(&spComputeQueue6)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0, spComputeQueue4 } } <--- full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 1 = { NullCreatorID, { spComputeQueue2, spComputeQueue3 } } <--- NOT full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 2 = { CustomCreatorID1, { spComputeQueue5 } } <--- NOT full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 2 = { CustomCreatorID2, { spComputeQueue6 } } <--- Creates a new scheduling group for CustomCreatorID1

    CComPtr<ID3D12CommandQueue> spComputeQueue7;
    GUID CustomCreatorID2 = { 0x78a0defe, 0xabb0, 0xc4b1, { 0x77, 0x23, 0x56, 0x78, 0xaa, 0x7c, 0x1a, 0x33 } };
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDesc, CustomCreatorID2, IID_PPV_ARGS(&spComputeQueue7)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0, spComputeQueue4 } } <--- full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 1 = { NullCreatorID, { spComputeQueue2, spComputeQueue3 } } <--- NOT full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 2 = { CustomCreatorID1, { spComputeQueue5 } } <--- NOT full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 2 = { CustomCreatorID2, { spComputeQueue6, spComputeQueue7 } } <--- Adds new queue to non-full scheduling group with same CreatorID

    CComPtr<ID3D12CommandQueue> spComputeQueue7;
    GUID CustomCreatorID2 = { 0x78a0defe, 0xabb0, 0xc4b1, { 0x77, 0x23, 0x56, 0x78, 0xaa, 0x7c, 0x1a, 0x33 } };
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDesc, CustomCreatorID2, IID_PPV_ARGS(&spComputeQueue7)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0, spComputeQueue4 } } <--- full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 1 = { NullCreatorID, { spComputeQueue2, spComputeQueue3 } } <--- NOT full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 2 = { CustomCreatorID1, { spComputeQueue5 } } <--- NOT full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 2 = { CustomCreatorID2, { spComputeQueue6, spComputeQueue7 } } <--- Adds new queue to non-full scheduling group with same CreatorID

    CComPtr<ID3D12CommandQueue> spDirectQueue1;
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDescDirect, NullCreatorID, IID_PPV_ARGS(&spDirectQueue1)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { NullCreatorID, { spComputeQueue0, spDirectQueue0, spComputeQueue4 } } <--- full as per D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS.ComputeQueuesPer3DQueue
    //    Scheduling group 1 = { NullCreatorID, { spComputeQueue2, spComputeQueue3, spDirectQueue1 } } <--- Adds new queue to non-full scheduling group with same CreatorID
    //    Scheduling group 2 = { CustomCreatorID1, { spComputeQueue5 } }
    //    Scheduling group 2 = { CustomCreatorID2, { spComputeQueue6, spComputeQueue7 } }
}
```

## Example 2: Grouping algorithm and dynamic priority adjusting

```C++
CComPtr<ID3D12Device9> spDevice9;
// ... Get spDevice9 ...

// App to query the caps to obtain the N value indicating the scheduling groups capacity for compute queues
D3D12_FEATURE_DATA_HARDWARE_SCHEDULING_QUEUE_GROUPINGS hwsQueueGroupingCapData = { };
VERIFY_SUCCEEDED(spDevice9->CheckFeatureSupport(D3D12_FEATURE_HARDWARE_SCHEDULING_QUEUE_GROUPINGS, &hwsQueueGroupingCapData, sizeof(hwsQueueGroupingCapData)));
// Let's assume hwsQueueGroupingCapData.ComputeQueuesPer3DQueue = 2; for the example.
// hwsQueueGroupingCapData.ComputeQueuesPer3DQueue indicates how many compute queues can be grouped in a scheduling group. Additionally, 1 DIRECT queue can be added to a scheduling group

//
// Expectation for group mapping when creating DIRECT and COMPUTE queues
//
{
    GUID NullCreatorID = {}; // Calling CreateCommandQueue1 with a null creator ID applies the same queue grouping as calling CreateCommandQueue.
    D3D12_COMMAND_QUEUE_DESC QueueDescWithDynamicPrio = { };
    QueueDescWithDynamicPrio.Type = D3D12_COMMAND_LIST_TYPE_COMPUTE;
    QueueDescWithDynamicPrio.Flags = D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY;
    QueueDescWithDynamicPrio.Priority = D3D12_COMMAND_QUEUE_PRIORITY_NORMAL;

    D3D12_COMMAND_QUEUE_DESC QueueDesc = { };
    QueueDesc.Type = D3D12_COMMAND_LIST_TYPE_COMPUTE;

    //
    // Create command queues with D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY and different creator ids
    //

    CComPtr<ID3D12CommandQueue> spPriorityComputeQueue0;
    GUID CustomCreatorID1 = { 0x2600d0ff, 0xfeea, 0x4500, { 0x85, 0x6a, 0x44, 0x76, 0xbb, 0xc4, 0x72, 0x66 } };
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDescWithDynamicPrio, CustomCreatorID1, IID_PPV_ARGS(&spPriorityComputeQueue0)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { DynamicPriorityEnabled, CustomCreatorID1, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spPriorityComputeQueue0 } } <--- Creates a new scheduling group for CustomCreatorID1

    CComPtr<ID3D12CommandQueue> spPriorityComputeQueue1;
    GUID CustomCreatorID2 = { 0x78a0defe, 0xabb0, 0xc4b1, { 0x77, 0x23, 0x56, 0x78, 0xaa, 0x7c, 0x1a, 0x33 } };
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDescWithDynamicPrio, CustomCreatorID2, IID_PPV_ARGS(&spPriorityComputeQueue1)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { DynamicPriorityEnabled, CustomCreatorID1, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spPriorityComputeQueue0 } }
    //    Scheduling group 1 = { DynamicPriorityEnabled, CustomCreatorID2, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spPriorityComputeQueue1 } } <--- Creates a new scheduling group for CustomCreatorID2

    CComPtr<ID3D12CommandQueue> spPriorityComputeQueue2;
    QueueDescWithDynamicPrio.Priority = D3D12_COMMAND_QUEUE_PRIORITY_GLOBAL_REALTIME; // Creation priority overrides priority of all queues in the scheduling group this queue will land on
    GUID CustomCreatorID2 = { 0x78a0defe, 0xabb0, 0xc4b1, { 0x77, 0x23, 0x56, 0x78, 0xaa, 0x7c, 0x1a, 0x33 } };
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDescWithDynamicPrio, CustomCreatorID2, IID_PPV_ARGS(&spPriorityComputeQueue2)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { DynamicPriorityEnabled, CustomCreatorID1, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spPriorityComputeQueue0 } }
    //    Scheduling group 1 = { DynamicPriorityEnabled, CustomCreatorID2, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_HARD_REALTIME, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_HIGH, { spPriorityComputeQueue1, spPriorityComputeQueue2 } } <--- Places in existing scheduling group for CustomCreatorID2 and overrides the priority of all queues in this scheduling group

    //
    // Create command queue with the same creator ID as before but without D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY
    //
    CComPtr<ID3D12CommandQueue> spComputeQueue3;
    GUID CustomCreatorID2 = { 0x78a0defe, 0xabb0, 0xc4b1, { 0x77, 0x23, 0x56, 0x78, 0xaa, 0x7c, 0x1a, 0x33 } };
    VERIFY_SUCCEEDED(spDevice9->CreateCommandQueue1(&QueueDesc, CustomCreatorID2, IID_PPV_ARGS(&spComputeQueue3)));
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { DynamicPriorityEnabled, CustomCreatorID1, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spPriorityComputeQueue0 } }
    //    Scheduling group 1 = { DynamicPriorityEnabled, CustomCreatorID2, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_HARD_REALTIME, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_HIGH, { spPriorityComputeQueue1, spPriorityComputeQueue2 } }
    //    Scheduling group 2 = { DynamicPriorityDisabled, CustomCreatorID2, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spComputeQueue3 } } <--- Creates a new scheduling group for CustomCreatorID2 since queues with and without D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY do not mix nor affect each other scheduling groups

    CComPtr<ID3D12CommandQueue1> spPriorityIface1;
    VERIFY_SUCCEEDED(spPriorityComputeQueue1->QueryInterface(&spPriorityIface1));
    spPriorityIface1->SetGlobalPriority(D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_1); // This will change the priority of all queues in the scheduling group associated to spPriorityComputeQueue1
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { DynamicPriorityEnabled, CustomCreatorID1, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spPriorityComputeQueue0 } }
    //    Scheduling group 1 = { DynamicPriorityEnabled, CustomCreatorID2, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_1, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spPriorityComputeQueue1, spPriorityComputeQueue2 } } <--- Sets the priority of all queues in this scheduling group to D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_1
    //    Scheduling group 2 = { DynamicPriorityDisabled, CustomCreatorID2, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spComputeQueue3 } }

    CComPtr<ID3D12CommandQueue1> spPriorityIface0;
    VERIFY_SUCCEEDED(spPriorityComputeQueue0->QueryInterface(&spPriorityIface0));
    spPriorityIface0->SetGlobalPriority(D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_IDLE); // In this case since there is only one queue in this scheduling group (by using CustomCreatorID1), the priority can be changed only to affect this queue.
    // Scheduling groups mapping state expectation:
    //    Scheduling group 0 = { DynamicPriorityEnabled, CustomCreatorID1, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_IDLE, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spPriorityComputeQueue0 } } <--- Sets the priority of all queues in this scheduling group to D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_IDLE
    //    Scheduling group 1 = { DynamicPriorityEnabled, CustomCreatorID2, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_SOFT_REALTIME_1, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spPriorityComputeQueue1, spPriorityComputeQueue2 } }
    //    Scheduling group 2 = { DynamicPriorityDisabled, CustomCreatorID2, D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_DEFAULT, D3D12_COMMAND_QUEUE_PROCESS_PRIORITY_NORMAL, { spComputeQueue3 } }

  CComPtr<ID3D12CommandQueue1> spPriorityIface3;
  VERIFY_SUCCEEDED(spComputeQueue3->QueryInterface(&spPriorityIface3));
  spPriorityIface3->SetGlobalPriority(D3D12_COMMAND_QUEUE_GLOBAL_PRIORITY_IDLE); // Fails call since spComputeQueue3 was not created with D3D12_COMMAND_QUEUE_FLAG_ALLOW_DYNAMIC_PRIORITY
}
```
