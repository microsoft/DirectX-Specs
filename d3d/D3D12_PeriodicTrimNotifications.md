# D3D12 Periodic Trim Notifications

This document specifies a new D3D12 feature that exposes kernel-level trim notifications through D3D12 runtime interfaces, enabling applications to receive notifications when the system should trim residency.

## Introduction

Applications can register callback functions to receive notifications when the system determines memory trimming is advisable. This feature exposes the existing `D3DKMTRegisterTrimNotification` and `D3DKMTUnregisterTrimNotification` kernel functions through new D3D12 runtime interfaces.

## Rationale and Use Cases

### Why Periodic Trim Notifications Are Needed

The goal is to enable idle memory trimming—evicting resources that haven't been used recently, even if the application is still running. This complements existing trimming mechanisms like submission-based LRU trimming (used by libraries like [D3DX12Residency](https://github.com/microsoft/DirectX-Graphics-Samples/tree/master/Libraries/D3DX12Residency) on every `ExecuteCommandLists` call) and budget-based trimming under memory pressure. Periodic trim notifications are designed to run on a regular cadence and help applications proactively clean up unused allocations that may not be caught by submission-based approaches.

### The D3D12 Residency Challenge

In D3D9 and D3D11, memory trimming was handled more automatically by the runtime and driver stack, including multiple mechanisms such as but not limited to submission/usage LRU tracking and also periodic trimming (e.g., via DXGK, UMD, and DX runtime interactions). Applications didn't need to manage residency directly. 

However, in D3D12:

- **Explicit Residency Management**: The residency manager sits above the runtime, so applications must explicitly handle trimming. D3D12 applications usually have their own residency algorithms, and mapping layers (like D3D9on12, D3D11on12, GLon12) usually have submission usage tracking mechanisms and LRU evictions, but not periodic trimming heuristics.

- **Mapping Layer Limitations**: These layers provide less optimal residency management compared to native D3D9, D3D11, or OpenGL driver stacks, which have built-in periodic trimming heuristics. This new D3D12 feature bridges that gap by allowing D3D9on12, D3D11on12, and GLon12 mapping layers to incorporate periodic trim notifications and heuristics into their residency algorithms.

### Target Applications and Scenarios

Applications such as video editors, image editors, and other tools that use D3D12 for effects or AI but only submit work sporadically. In some cases these apps run through mapping layers, and may allocate large buffers (e.g., for effects) and never touch them again, leading to persistent VRAM usage unless explicitly trimmed.

## Goals

- Expose kernel-level trim notifications through D3D12 runtime interfaces
- Support multiple simultaneous callback registrations per device
- Follow established D3D12 patterns for callback registration (e.g `ID3D12InfoQueue1::RegisterMessageCallback`)

## Non-Goals

Automatic resource trimming or management done by the D3D12 runtime is _not_ a goal. Diverse layers on top of D3D12 runtime such as [D3DX12Residency](https://github.com/microsoft/DirectX-Graphics-Samples/tree/master/Libraries/D3DX12Residency), 9on12, 11on12, and GLOn12 or other 3rd party apps would need to be updated later to take advantage of this new D3D12 runtime callback in their own residency libraries.

## Overall Design

The trim notification system introduces a new interface `ID3D12Device15` with callback registration capabilities. Applications register callback functions that are invoked during periodic trim events, with cookie-based management for unregistration. Multiple callbacks are supported and called sequentially.

## API

### ENUM: D3D12_TRIM_NOTIFICATION_FLAGS

```cpp
typedef enum D3D12_TRIM_NOTIFICATION_FLAGS
{
    D3D12_TRIM_NOTIFICATION_FLAG_NONE                  = 0x00,
    D3D12_TRIM_NOTIFICATION_FLAG_PERIODIC_TRIM         = 0x01,
    D3D12_TRIM_NOTIFICATION_FLAG_RESTART_PERIODIC_TRIM = 0x02,
    D3D12_TRIM_NOTIFICATION_FLAG_TRIM_TO_BUDGET        = 0x04,
} D3D12_TRIM_NOTIFICATION_FLAGS;
```

*D3D12_TRIM_NOTIFICATION_FLAG_PERIODIC_TRIM*

When `D3D12_TRIM_NOTIFICATION_FLAG_PERIODIC_TRIM` flag is set, the application is advised to perform the following operations:
- Trim all allocations that were not referenced since the previous periodic trim request by comparing the allocation last referenced fence with the last periodic trim context fence
- Refresh the last periodic trim context fence with the last completed context fence

> Note: "context fence" refers to fence values associated with D3D12 Command Queue contexts, not the callback `pContext` parameter.

*D3D12_TRIM_NOTIFICATION_FLAG_RESTART_PERIODIC_TRIM*

May not be set together with `D3D12_TRIM_NOTIFICATION_FLAG_PERIODIC_TRIM` flag. When this flag is set, the application must reset the last periodic trim context fence to the last completed context fence.

> Note: "context fence" refers to fence values associated with D3D12 Command Queue contexts, not the callback `pContext` parameter.

*D3D12_TRIM_NOTIFICATION_FLAG_TRIM_TO_BUDGET*

Indicates that the application usage is over the memory budget, and `NumBytesToTrim` bytes should be trimmed to fit in the new memory budget.

### STRUCT: D3D12_TRIM_NOTIFICATION

```cpp
typedef struct D3D12_TRIM_NOTIFICATION
{
    VOID*                         pContext;
    D3D12_TRIM_NOTIFICATION_FLAGS Flags;
    UINT64                        NumBytesToTrim;
} D3D12_TRIM_NOTIFICATION;
```

*pContext*

Pointer to user-supplied data that was provided during callback registration. This allows applications to access their context data within the callback.

*Flags*

Bitwise combination of `D3D12_TRIM_NOTIFICATION_FLAGS` values indicating the type of trim operation being requested.

*NumBytesToTrim*

When `D3D12_TRIM_NOTIFICATION_FLAG_TRIM_TO_BUDGET` flag is set, this value indicates how much the runtime requests the app to trim to fit in the new budget.

### CALLBACK: D3D12_PFN_TRIM_NOTIFICATION_CALLBACK

```cpp
typedef VOID (APIENTRY *D3D12_PFN_TRIM_NOTIFICATION_CALLBACK)(_Inout_ D3D12_TRIM_NOTIFICATION*);
```

**Remarks**

Callback function that is invoked when the system determines that memory trimming is advisable. The callback receives a `D3D12_TRIM_NOTIFICATION` structure containing context data and trim parameters.

### STRUCT: D3D12_REGISTER_TRIM_NOTIFICATION

```cpp
typedef struct D3D12_REGISTER_TRIM_NOTIFICATION
{
    D3D12_PFN_TRIM_NOTIFICATION_CALLBACK pfnCallback;
    VOID*                                pContext;
    DWORD                                CallbackCookie;
} D3D12_REGISTER_TRIM_NOTIFICATION;
```

*pfnCallback*

Callback function pointer which allows users to register a callback that is called at the time a trim notification is produced.

*pContext*

Can be set to point to anything users want. They can access `pContext` they specified here in `D3D12_PFN_TRIM_NOTIFICATION_CALLBACK`. This allows users to attach their own additional data to the callback.

*CallbackCookie*

An output parameter that receives the callback cookie that uniquely identifies the registered callback. Set to zero if the callback registration fails.

> Note: The valid `CallbackCookie` values range returned by the runtime after registering a callback is `[0, DWORD_MAX)`.


### INTERFACE: ID3D12Device15

```cpp
interface ID3D12Device15 : ID3D12Device14
{
    HRESULT RegisterTrimNotificationCallback(
        D3D12_REGISTER_TRIM_NOTIFICATION* pData
    );

    HRESULT UnregisterTrimNotificationCallback(
        DWORD CallbackCookie
    );
};
```

### RegisterTrimNotificationCallback

Registers a callback function to receive periodic trim notifications when the system determines that memory trimming is advisable.

**Parameters:**
- `pData` - Pointer to a `D3D12_REGISTER_TRIM_NOTIFICATION` structure that describes the callback registration.

**Return Values:**

| Return Value | Description |
|--------------|-------------|
| `S_OK` | The callback was successfully registered |
| `E_INVALIDARG` | Invalid parameters |
| `E_OUTOFMEMORY` | Insufficient memory to register the callback |
| `DXGI_ERROR_ALREADY_EXISTS` | The callback was already registered. User must unregister that `D3D12_REGISTER_TRIM_NOTIFICATION.pfnCallback` before being able to register it again. |
| `E_NOTIMPL` | This feature is not available on this system. |

### UnregisterTrimNotificationCallback

Unregisters a previously registered trim notification callback.

**Parameters:**
- `CallbackCookie` - The cookie that identifies the callback to unregister.

**Return Values:**

| Return Value | Description |
|--------------|-------------|
| `S_OK` | The callback was successfully unregistered |
| `E_INVALIDARG` | Invalid parameters |
| `DXGI_ERROR_NOT_FOUND` | The specified callback was not found |
| `E_NOTIMPL` | This feature is not available on this system. |

## Threading Considerations

- Callbacks may execute on any system thread, not necessarily the thread that registered the callback
- Please note that **it is NOT allowed** to call `RegisterTrimNotificationCallback` nor `UnregisterTrimNotificationCallback` from within any `D3D12_REGISTER_TRIM_NOTIFICATION.pfnCallback`.

## Example Implementation

This section demonstrates how a creative application (video editor, image editor) can implement periodic trim notifications to manage infrequently used effect resources.

```cpp
class CreativeApp
{
    enum class EffectType { Blur, GrayScale };
    
    enum class ResourceResidencyStatus {
        Resident = 0,
        Evicted = 1,
    };
    
    static constexpr UINT64 c_OpportunisticSubmissionEvictionLRUWindow = 3; // Evict if not used in last 3 submissions
    
    struct ResourceInfo
    {
        UINT64 LastNotificationUsage;  // Last usage relative to trim notifications
        UINT64 LastSubmissionUsage;    // Last usage relative to command submissions
        ResourceResidencyStatus Status; // Current residency status
    };
    
    ID3D12Device* m_pDevice;
    ID3D12CommandQueue* m_pCommandQueue;
    ComPtr<ID3D12Fence> m_pResidencyFence;
    UINT64 m_pResidencyFenceValue;
    DWORD m_CallbackCookie;
    
    // Incremental counter to track resource usage relative to trim notifications
    UINT64 m_LastTrimNotificationReceivedIndex;
    
    // Counter to track ExecuteCommandLists submissions for opportunistic eviction
    UINT64 m_ExecuteCommandListsIndex;
    
    // Maps effect types to their resources and dual usage timestamps
    std::map<EffectType, std::map<ID3D12Resource*, ResourceInfo>> m_EffectResources;
    
    // Thread synchronization for callback safety
    std::mutex m_ResourcesMutex;

    CreativeApp(ID3D12Device* pDevice, ID3D12CommandQueue* pCommandQueue) :
        m_pDevice(pDevice), m_pCommandQueue(pCommandQueue), m_pResidencyFenceValue(0),
        m_CallbackCookie(0), m_LastTrimNotificationReceivedIndex(0), m_ExecuteCommandListsIndex(0)
    {
        // Create fence for residency synchronization
        m_pDevice->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&m_pResidencyFence));
        
        // Register for periodic trim notifications
        D3D12_REGISTER_TRIM_NOTIFICATION trimNotification = { TrimCallback, this };
        if (SUCCEEDED(m_pDevice->RegisterTrimNotificationCallback(&trimNotification)))
            m_CallbackCookie = trimNotification.CallbackCookie;
    }
    
    ~CreativeApp()
    {
        if (m_pDevice && m_CallbackCookie)
            m_pDevice->UnregisterTrimNotificationCallback(m_CallbackCookie);
    }
    
    void ApplyEffect(EffectType effectType)
    {
        std::lock_guard<std::mutex> lock(m_ResourcesMutex);
        
        // Opportunistic eviction: evict resources not used within the LRU window
        for (auto& [otherEffectType, resources] : m_EffectResources)
        {
            if (otherEffectType != effectType) // Don't evict resources we're about to use
            {
                for (auto& [pResource, info] : resources)
                {
                    // Evict if resource hasn't been used within the opportunistic submission eviction LRU window
                    // Prevent underflow: only evict if we have enough submissions and resource is old enough
                    if (m_ExecuteCommandListsIndex >= c_OpportunisticSubmissionEvictionLRUWindow &&
                        info.LastSubmissionUsage <= (m_ExecuteCommandListsIndex - c_OpportunisticSubmissionEvictionLRUWindow) &&
                        info.Status != ResourceResidencyStatus::Evicted)
                    {
                        pResource->Evict();
                        info.Status = ResourceResidencyStatus::Evicted;
                    }
                }
            }
        }
        
        auto& resources = m_EffectResources[effectType];
        
        // Collect resources that need to be made resident (skip already resident resources)
        std::vector<ID3D12Pageable*> pageables;
        pageables.reserve(resources.size());
        for (auto& [pResource, info] : resources)
            if (info.Status != ResourceResidencyStatus::Resident)
                pageables.push_back(pResource);
        
        // GPU-side wait ensures resources are resident before command execution (only if needed)
        if (!pageables.empty())
        {
            m_pCommandQueue->EnqueueMakeResident(pageables.size(), pageables.data(), 
                                               m_pResidencyFence.Get(), ++m_pResidencyFenceValue);
            m_pCommandQueue->Wait(m_pResidencyFence.Get(), m_pResidencyFenceValue);
        }
        
        // Record and execute effect commands
        // m_pCommandQueue->ExecuteCommandLists(...);
        m_ExecuteCommandListsIndex++; // Track command list submission
        
        // Update usage timestamps for all effect resources after incrementing submission counter
        for (auto& [pResource, info] : resources)
        {
            info.LastSubmissionUsage = m_ExecuteCommandListsIndex;
            // Update notification usage to current generation to prevent eviction in next periodic trim
            info.LastNotificationUsage = m_LastTrimNotificationReceivedIndex;
            info.Status = ResourceResidencyStatus::Resident;
        }
    }
    
    void RegisterEffectResource(ID3D12Resource* pResource, EffectType effectType, ResourceResidencyStatus status)
    {
        std::lock_guard<std::mutex> lock(m_ResourcesMutex);
        
        // Initialize with current indices to prevent immediate eviction
        // Resources are considered "used" at registration time
        // Use max(1, current) to ensure newly registered resources aren't immediately evictable
        m_EffectResources[effectType][pResource] = {
            .LastNotificationUsage = m_LastTrimNotificationReceivedIndex,
            .LastSubmissionUsage = std::max(m_ExecuteCommandListsIndex, 1ULL),
            .Status = status
        };
    }
    
private:
    static void APIENTRY TrimCallback(D3D12_TRIM_NOTIFICATION* pNotification)
    {
        CreativeApp* pApp = static_cast<CreativeApp*>(pNotification->pContext);
        std::lock_guard<std::mutex> lock(pApp->m_ResourcesMutex);
        
        if (pNotification->Flags & D3D12_TRIM_NOTIFICATION_FLAG_PERIODIC_TRIM)
        {
            // Increment notification counter - creates new "generation" for usage tracking
            pApp->m_LastTrimNotificationReceivedIndex++;
            // Resources with LastNotificationUsage < current generation should be evicted
            UINT64 notificationThreshold = pApp->m_LastTrimNotificationReceivedIndex;
            
            // Evict resources that haven't been used since the previous notification
            for (auto& [effectType, resources] : pApp->m_EffectResources)
                for (auto& [pResource, info] : resources)
                    if ((info.LastNotificationUsage < notificationThreshold) &&
                        (info.Status != ResourceResidencyStatus::Evicted) && 
                        // and make sure the resource is not in flight from the very latest submission
                        (info.LastSubmissionUsage < pApp->m_ExecuteCommandListsIndex))
                    {
                        pResource->Evict();
                        info.Status = ResourceResidencyStatus::Evicted;
                    }
        }
        
        if (pNotification->Flags & D3D12_TRIM_NOTIFICATION_FLAG_TRIM_TO_BUDGET)
        {
            // Trim resources to meet budget - prioritize least recently used resources
            UINT64 bytesToTrim = pNotification->NumBytesToTrim;
            UINT64 bytesFreed = 0;
            
            // Collect all resources with their complete info for LRU sorting
            std::vector<std::pair<ID3D12Resource*, ResourceInfo*>> resourcesByUsage;
            for (auto& [effectType, resources] : pApp->m_EffectResources)
                for (auto& [pResource, info] : resources)
                    resourcesByUsage.emplace_back(pResource, &info);
            
            // Sort by submission usage timestamp (oldest first) for LRU eviction
            std::sort(resourcesByUsage.begin(), resourcesByUsage.end(),
                     [](const auto& a, const auto& b) { return a.second->LastSubmissionUsage < b.second->LastSubmissionUsage; });
            
            // Evict resources starting with least recently used until budget is met
            for (auto& [pResource, pInfo] : resourcesByUsage)
            {
                if (bytesFreed >= bytesToTrim) break;
                
                // Only evict if resource is not already evicted
                if ((pInfo->Status != ResourceResidencyStatus::Evicted) &&
                // and make sure the resource is not in flight from the very latest submission
                    (pInfo->LastSubmissionUsage < pApp->m_ExecuteCommandListsIndex))
                {
                    D3D12_RESOURCE_DESC desc = pResource->GetDesc();
                    // Calculate resource size based on dimensions, format, and mip levels
                    D3D12_RESOURCE_ALLOCATION_INFO allocInfo = pApp->m_pDevice->GetResourceAllocationInfo(0, 1, &desc);
                    UINT64 resourceSize = allocInfo.SizeInBytes;
                    
                    pResource->Evict();
                    bytesFreed += resourceSize;
                    pInfo->Status = ResourceResidencyStatus::Evicted;
                }
            }
        }
        
        if (pNotification->Flags & D3D12_TRIM_NOTIFICATION_FLAG_RESTART_PERIODIC_TRIM)
        {
            // Reset usage tracking - treat all resources as equally aged
            pApp->m_LastTrimNotificationReceivedIndex = 0;
            for (auto& [effectType, resources] : pApp->m_EffectResources)
                for (auto& [pResource, info] : resources)
                    info.LastNotificationUsage = 0;
        }
    }
};
```

### Usage in Creative Application

```cpp
int main()
{
    ID3D12Device* pDevice = nullptr; // Initialize D3D12 device...
    ID3D12CommandQueue* pCommandQueue = nullptr; // Create command queue...
    CreativeApp app(pDevice, pCommandQueue);
    
    // Create effect resources (working buffers, temp storage, kernel weights)
    ID3D12Resource* blurResources[] = { 
        CreateBlurBuffer(),     // Main working buffer
        CreateTempBuffer(),     // Intermediate results  
        CreateKernelBuffer()    // Blur coefficients
    };
    // Demonstrate lazy residency: GrayScale resources start as non-resident to save VRAM
    // They will only consume GPU memory when ApplyEffect(GrayScale) is called
    ID3D12Resource* grayScaleResources[] = {
        CreateGrayScaleBuffer(D3D12_HEAP_FLAG_CREATE_NOT_RESIDENT),    // Color conversion buffer (created non-resident)
        CreateLuminanceBuffer(D3D12_HEAP_FLAG_CREATE_NOT_RESIDENT)     // Luminance coefficients (created non-resident)
    };
    
    // Register Blur resources as Resident (immediately available for use)
    for (auto* pResource : blurResources)
        app.RegisterEffectResource(pResource, CreativeApp::EffectType::Blur, CreativeApp::ResourceResidencyStatus::Resident);
    
    // Register GrayScale resources as Evicted to match their D3D12_HEAP_FLAG_CREATE_NOT_RESIDENT creation
    // This demonstrates lazy residency: resources are tracked but won't be made resident until first use
    for (auto* pResource : grayScaleResources)
        app.RegisterEffectResource(pResource, CreativeApp::EffectType::GrayScale, CreativeApp::ResourceResidencyStatus::Evicted);
    
    // Event-driven effect application
    auto OnBlurButtonPressed = [&app]() { app.ApplyEffect(CreativeApp::EffectType::Blur); };
    auto OnGrayScaleButtonPressed = [&app]() { app.ApplyEffect(CreativeApp::EffectType::GrayScale); };
    
    // Standard UI message loop
    while (applicationRunning)
    {
        ProcessUIMessages(); // Handles button clicks -> OnBlurButtonPressed
        Sleep(16);           // 60 FPS UI responsiveness
    }
    
    return 0;
}
```

## Summary

This example demonstrates a complete implementation of D3D12 Periodic Trim Notifications in a creative application. The `CreativeApp` class manages multiple effect types (Blur, GrayScale) with individual resource tracking, implementing all three trimming modes: periodic generational trimming, budget-based LRU trimming, and restart trimming. 

Additionally, the implementation includes opportunistic submission eviction that proactively trims resources during normal operation. This feature uses an LRU window (controlled by `c_OpportunisticSubmissionEvictionLRUWindow`) to evict resources that haven't been used within the last few command list submissions, providing immediate memory cleanup without waiting for periodic notifications. This hybrid approach combines system-driven periodic trimming with application-driven opportunistic eviction for optimal memory management.

The event-driven architecture with GPU-side synchronization provides an efficient solution for applications with sporadic GPU usage patterns.
