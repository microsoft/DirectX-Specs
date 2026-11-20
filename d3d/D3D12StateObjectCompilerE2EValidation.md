# D3D12 State Object Compiler End-to-End Testing

- [D3D12 State Object Compiler End-to-End Testing](#d3d12-state-object-compiler-end-to-end-testing)
  - [Introduction](#introduction)
  - [How E2E Testing Works](#how-e2e-testing-works)
  - [Supported Stores](#supported-stores)
    - [Xbox](#xbox)
      - [Titles](#titles)
      - [Requesting Access](#requesting-access)
      - [Installing the Test](#installing-the-test)
  - [Running the Test in Validate Mode](#running-the-test-in-validate-mode)
    - [Command-Line Options](#command-line-options)
    - [Exit Codes](#exit-codes)
    - [Sample Output](#sample-output)
  - [References](#references)

## Introduction

This document describes an optional end-to-end (E2E) testing option for hardware vendors that publish their offline compiler plugin through Nuget. Vendors may use it to confirm that the precompiled shader databases (PSDBs) produced from a pre-release compiler are consumed correctly by their driver at runtime.

E2E testing is not a requirement for publishing a compiler plugin package, and it does not change the package
requirements in the D3D12 State Object Compiler Plugin NuGet Packages
specification. Vendors can choose whether to use it and which supported store to test with.

Testing is performed by running the `SODBCompilerValidation.exe` test in validate mode on the vendor's own hardware and
drivers. For the full test design, see the
SODB Compiler Validation Test Specification.

## How E2E Testing Works

A vendor that chooses to perform E2E testing can follow these steps:

1. The hardware vendor may publish the new compiler as a pre-release package (`releaseType` set to `preview`).
2. A store that supports Advanced Shader Delivery (ASD) can use the pre-release compiler to compile a selection of State
   Object Databases (SODBs) into PSDBs.
3. When the new PSDBs are available, the store notifies the hardware vendor.
4. The hardware vendor can test the PSDBs internally by running `SODBCompilerValidation` in validate mode, as described
   in [Running the Test in Validate Mode](#running-the-test-in-validate-mode).
5. The test results can inform the vendor's decision to publish the compiler as a public package (`releaseType` set to
   `release`).

## Supported Stores

E2E testing is available through stores that support ASD. Xbox Store currently supports it. Other stores
will become available for testing in the future.

### Xbox

If you choose to test with Xbox, the test and the PSDBs compiled by Xbox services are distributed through an Xbox app.

#### Titles

Xbox services use the following titles to test pre-release compilers by compiling their SODBs:

| Title |
| ----- |
| SODBCompilerValidation |
| Avowed  |
| Forza Horizon 6  |

#### Requesting Access

The Xbox playtest is limited to approved Microsoft Accounts (MSAs). To request access, send the list of MSAs that will
install the test to ASD-Developer Engagement (asd-questions@microsoft.com). Access is granted per account, so include every account that installs the test.

#### Installing the Test

After your MSAs are approved:

1. Sign in to the Xbox app on the test machine with an approved MSA.
2. Open the following link to go to the playtest game page:

   ```text
   msxbox://playtest/?productId=2SDT4X91KJ6S&featuregates=EnableXPlaytestScreen:true
   ```

3. Install the `SODBCompilerValidation` title from the playtest game page.
4. Locate the test executable at `<XboxGames Folder>\grgony GDK Test\Content\SODBCompilerValidation.exe`.
   1. Find the `XboxGames` folder by clicking the "..." button, then selecting
      **Manage** > **Files** > **Browse**.

## Running the Test in Validate Mode

Validate mode does not load a compiler plugin. It uses the reference SODB bundled with the test to issue the
corresponding D3D12 pipeline state and state object creation calls, using the PSDB delivered by the store. It then
uses the device's shader cache statistics to confirm that every object is a PSDB cache hit.

Run the test from its installed location:

```cmd
SODBCompilerValidation --mode validate --output <path_to_output>.json
```

The run passes when the process exits with code `0` and the JSON report contains `"result": "PASS"`. Any cache miss
indicates that the PSDB produced by the pre-release compiler does not match what the driver expects at runtime, and is
worth investigating before publishing the compiler as a `release`.

### Command-Line Options

| Option | Mode | Description |
| ------ | ---- | ----------- |
| `--mode <full\|validate>` | Required | Execution mode. Use `validate` to check the delivered PSDB against the bundled SODB. |
| `--output <path>` | Both | Path for the JSON results report. If omitted, the report is written to stdout. |
| `--sodb <path>` | Both | Reference SODB file. Defaults to the SODB bundled next to the executable. |
| `--verbose` | Both | Emits per-object compilation and validation detail. |
| `--plugin <path>` | Full only | Compiler plugin DLL. Rejected in validate mode. |
| `--psdb <path>` | Full only | Where to write the produced PSDB. Defaults to a temporary file. |
| `--force-validation` | Full only | Runs PSDB validation even if compilation fails. |

### Exit Codes

| Exit Code | Meaning |
| --------- | ------- |
| `0` | All checks passed. |
| `1` | Invalid command-line arguments, such as missing or malformed values or non-existent files. |
| `2` | SODB-to-PSDB compilation failed (full mode only). |
| `3` | Runtime cache hit rate is below 100%. |
| `4` | Runtime error, such as a device creation or file I/O failure. |

### Sample Output

The following is an example of a successful validate-mode JSON report:

```json
{
  "test": "SODBCompilerValidation",
  "version": "1.1.3.0",
  "mode": "validate",
  "adapter": "Example GPU",
  "shader_cache_abi_supported": true,
  "statistics_available": true,
  "app_identity": "SODB Compiler Validation",
  "default_psdb_registered": true,
  "validation": {
    "total_objects": 256,
    "create_failures": 0,
    "unsupported_skipped": 0,
    "cache_misses": 0,
    "hit_rate_check": "pass"
  },
  "result": "PASS"
}
```

## References

- D3D12 State Object Compiler Plugin NuGet Packages
- SODB Compiler Validation Test Specification
