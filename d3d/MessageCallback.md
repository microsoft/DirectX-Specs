# D3D12 ID3D12InfoQueue1 APIs

To date, D3D12 has had ID3D12InfoQueue API. However, *message callback* has always been a debug feature requested by our ISV partners. The InfoQueue needs an API to register a callback that is called at the time a debug message is produced. This solves a couple issues:

* ISV's can more easily investigate callstacks of live errors.
* ISV's can instrument their own error accounting and reporting mechanisms.

## ID3D12InfoQueue1 

ID3D12InfoQueue1 inherits ID3D12InfoQueue and supports message callback with RegisterMessageCallback and UnregisterMessageCallback method.

```c++
interface ID3D12InfoQueue1
    : ID3D12InfoQueue
{
    HRESULT RegisterMessageCallback(
        D3D12MessageFunc CallbackFunc, 
        D3D12_MESSAGE_CALLBACK_FLAGS CallbackFilterFlags,
        void* pContext,
        DWORD *pCallbackCookie);

    HRESULT UnregisterMessageCallback(
        DWORD CallbackCookie);
}


typedef void (*D3D12MessageFunc)(
    D3D12_MESSAGE_CATEGORY Category, 
    D3D12_MESSAGE_SEVERITY Severity, 
    D3D12_MESSAGE_ID ID, 
    LPCSTR pDescription, 
    void* pContext);


typedef enum D3D12_MESSAGE_CALLBACK_FLAGS
{
    D3D12_MESSAGE_CALLBACK_FLAG_NONE = 0x00,
    D3D12_MESSAGE_CALLBACK_IGNORE_FILTERS = 0x01,
} D3D12_MESSAGE_CALLBACK_FLAGS;
```


### ID3D12InfoQueue1::RegisterMessageCallback Method

RegisterMessageCallback registers a callback that is called at the time a debug message is produced.

| Parameter | Description |
|--------|-------------|
| `CallbackFunc` | A callback function pointer which allows users to register a callback that is called at the time a debug message is produced. |
| `pContext` | Can be set to point to anything users want. They can access pContext they specified here in D3D12MessageFunc. This allows users to attach their own additional data to the callback. |
| `CallbackFilterFlags` | If this value is set to D3D12_MESSAGE_CALLBACK_IGNORE_FILTERS, current callback is unfiltered. If this value is set to D3D12_MESSAGE_CALLBACK_FLAG_NONE, current callback is filtered in the exact same way as what gets logged as debug text. |
| `pCallbackCookie` | An output parameter that uniquely identifies the registered callback, the value pointed to by pCallbackCookie is set to zero if the callback registration fails. |

| Return Type | Description |
|--------|-------------|
| `HRESULT` | Returns E_OUTOFMEMORY if there is insufficient memory to register the callback. [See Direct3D 12 Return Codes for other possible return values.](https://docs.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues) |

#### Remarks

Apps should not rely on callbacks being invoked on the same thread that the API call was made. In particular callbacks could be invoked from internal debug layer threads related to queue virtualization and GPU-Based Validation. Callbacks implementations must not make any D3D API calls. If multiple callbacks are active, they will be called sequentially in the same order that the callbacks were registered.

### ID3D12InfoQueue1::UnregisterMessageCallback Method

UnregisterMessageCallback unregisters a previously registered callback.

| Parameter | Description |
|--------|-------------|
| `CallbackCookie` | The cookie that identifies the callback to unregister. |

| Return Type | Description |
|--------|-------------|
| `HRESULT` | Returns E_INVALIDARG if the provided cookie is not associated with any registered callbacks. [See Direct3D 12 Return Codes for other possible return values.](https://docs.microsoft.com/en-us/windows/win32/direct3d12/d3d12-graphics-reference-returnvalues) |

#### Remarks

It is guaranteed that UnregisterMessageCallback won’t return until any outstanding callbacks have completed.

### D3D12MessageFunc

| Parameter | Description |
|--------|-------------|
| `Category` | Category of the debug message produced. |
| `Severity` | Severity of the debug message produced. |
| `ID` | ID of the debug message produced. |
| `pDescription` | Debug message description. |
| `pContext` | Pointer to user-supplied data that will be passed into each callback invocation. The memory pointed to by pContext must remain valid until the callback has been unregistered. |

## Restrictions

Callbacks may be invoked with the internal runtimes in states which are unsafe to make other D3D calls. Any D3D API calls from a callback implementation could result in deadlocks and crashes.

## Design Decisions

* Single Callback vs Multiple Callbacks

The D3D12 ID3D12InfoQueue infrastructure is mostly shared across all ID3D12Device instances in a given process. Supporting multiple callback registration allows a D3D12 component within a process to handle messages without breaking callbacks registered by any other D3D12 components in the same process.

* Callback Order

If multiple callbacks are active, they will be called sequentially in the same order that the callbacks were registered.

* Documenting Restrictions vs Implementing Validations

Restrictions are documented. Implementing validations to check if a D3D API call is valid inside the callback takes too much time to implement, and can add a lot of runtime checks. Adding these runtime checks also creates a lot of runtime overhead and thus we don't want this.

* Threading Requirement

Callback may execute on a thread other than the one that originally issued the API call, users need to ensure that their callbacks can properly handle this.

* Use CallbackFilterFlags

We use this enum to make sure that we provide users with the most commonly used two scenarios. 1. If users want their own message filtering mechanism in callback, they can set this value to D3D12_MESSAGE_CALLBACK_FLAG_NONE and this will disable message filtering. 2. If users want current callback to be filtered in the exact same way as what gets logged as debug text. They can set this value to D3D12_MESSAGE_CALLBACK_IGNORE_FILTERS.
