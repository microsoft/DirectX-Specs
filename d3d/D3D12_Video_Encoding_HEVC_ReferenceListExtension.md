# D3D12 Video Encoding HEVC Reference List Extension

**Overview**

In some complex reference picture usage scenarios, the current [D3D12_Video_Encoding_H264_HEVC](D3D12_Video_Encoding_H264_HEVC.md) API doesn't expose the necessary information to the driver to code reference information in the bitstream accurately. Particularly, currently the app sends `pList0ReferenceFrames` and `pList0ReferenceFrames` corresponding to `RefPicListTemp0` and `RefPicListTemp1` from the HEVC standard, but capping the `List0ReferenceFramesCount` and `List1ReferenceFramesCount` corresponding array lengths to the driver reported limits `MaxLXReferencesForY` in `D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_HEVC`. There is also an assumption that `num_ref_idx_l0_active_minus1` and `num_ref_idx_l1_active_minus1` correspond to `List0ReferenceFramesCount` and `List1ReferenceFramesCount` respectively.

The proposed changes in this spec, extend the existing HEVC picture parameters `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC` and `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1` from [D3D12_Video_Encoding_H264_HEVC](D3D12_Video_Encoding_H264_HEVC.md) and [D3D12_Video_Encoding_HEVC_422_444](D3D12_Video_Encoding_HEVC_422_444.md) to extend the information the app passes the driver to solve this limitation. This new structure `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2` can be used for 420 profiles as well as for 422/444 HEVC profiles.

Please note that similar rules that apply to H264 are **not** changed by this spec. The changes here only apply to HEVC, and only apply when using the new interfaces with `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2`. Previously existing retail API/DDI interfaces are kept unmodified for app back compat and driver should keep the prevailing HEVC rules from previous specs on that legacy path.

# General considerations

This spec focuses on the different points of extension where the existing D3D12 Video Encode API needs new structures to extend HEVC Encode picture reference structures. The rest of the D3D12 Encode API will remain unmodified for this feature unless explicited in this spec.

## API and DDI similarities

The next sections detail the API and DDI for video encoding. In many cases, the DDI is extremely similar to the API. The structures and enumerations which are basically the same (differing solely in name convention) are not repeated in the this specification. We include just the DDI structures/enumerations and functions that differ substantially from the API.

# Video Encoding API

## Extensions to picture control API

```C++
typedef struct D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA1
{
    UINT DataSize;
    union
    {
        D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264* pH264PicData;
        D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2* pHEVCPicData;
        D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA* pAV1PicData;
    };
} D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA1;
```

```C++
typedef struct D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2
{
    // Members from D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1
    D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAGS Flags;
    D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC FrameType;
    UINT slice_pic_parameter_set_id;
    UINT PictureOrderCountNumber;
    UINT TemporalLayerIndex;    
    UINT List0ReferenceFramesCount;
    [annotation("_Field_size_full_(List0ReferenceFramesCount)")] UINT* pList0ReferenceFrames;
    UINT List1ReferenceFramesCount;
    [annotation("_Field_size_full_(List1ReferenceFramesCount)")] UINT* pList1ReferenceFrames;
    UINT ReferenceFramesReconPictureDescriptorsCount;
    [annotation("_Field_size_full_(ReferenceFramesReconPictureDescriptorsCount)")] D3D12_VIDEO_ENCODER_REFERENCE_PICTURE_DESCRIPTOR_HEVC* pReferenceFramesReconPictureDescriptors;
    UINT List0RefPicModificationsCount;
    [annotation("_Field_size_full_(List0RefPicModificationsCount)")] UINT* pList0RefPicModifications;
    UINT List1RefPicModificationsCount;
    [annotation("_Field_size_full_(List1RefPicModificationsCount)")] UINT* pList1RefPicModifications;
    UINT QPMapValuesCount;
    [annotation("_Field_size_full_(QPMapValuesCount)")] INT8 *pRateControlQPMap;
    UCHAR diff_cu_chroma_qp_offset_depth;
    UCHAR log2_sao_offset_scale_luma;
    UCHAR log2_sao_offset_scale_chroma;
    UCHAR log2_max_transform_skip_block_size_minus2;
    UCHAR chroma_qp_offset_list_len_minus1;
    CHAR cb_qp_offset_list[6];
    CHAR cr_qp_offset_list[6];

    // New members below
    UINT num_ref_idx_l0_active_minus1;
    UINT num_ref_idx_l1_active_minus1;
} D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2;
```

Adds `num_ref_idx_l0_active_minus1` and `num_ref_idx_l1_active_minus1` respect to `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1`.

**Remarks**

1. `pReferenceFramesReconPictureDescriptors` remains as defined in [D3D12_Video_Encoding_H264_HEVC](D3D12_Video_Encoding_H264_HEVC.md). This still includes the complete DPB snapshot from the app to the driver as usual, including frames not used in current frame, etc. The app can send up to 16 entries here (up to 15 refs + curr pic). The current picture entry can be ignored by the driver if not needed.

2.	`pList0ReferenceFrames` will now correspond to `RefPicListTemp0` (as per HEVC codec standard). The app must build and pass the *complete* list built as per HEVC codec standard by extracting `RefPicSetStCurrBefore`, `RefPicSetStCurrAfter` and `RefPicSetLtCurr` from `pReferenceFramesReconPictureDescriptors`. Previously defined in [D3D12_Video_Encoding_H264_HEVC](D3D12_Video_Encoding_H264_HEVC.md), this list was already generated from the RPS like `RefPicListTemp0` but capped to `D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_HEVC.MaxL0ReferencesForP/B` length before passing in the picture params to the driver.

    > Note that `pps_curr_pic_ref_enabled_flag` will always be false (since `pps_scc_extension` is not supported in D3D12), so `RefPicListTemp0` will not have the current pic.

3.	`pList1ReferenceFrames` will now correspond to `RefPicListTemp1` (as per HEVC codec standard). The app must build and pass the *complete* list built as per HEVC codec standard by extracting `RefPicSetStCurrAfter`, `RefPicSetStCurrBefore` and `RefPicSetLtCurr` from `pReferenceFramesReconPictureDescriptors`. Previously defined in [D3D12_Video_Encoding_H264_HEVC](D3D12_Video_Encoding_H264_HEVC.md), this list was already generated from the RPS like `RefPicListTemp1` but capped to `D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_HEVC.MaxL0ReferencesForP/B` length before passing in the picture params to the driver.

    > Note that `pps_curr_pic_ref_enabled_flag` will always be false (since `pps_scc_extension` is not supported in D3D12), so `RefPicListTemp0` will not have the current pic.

4. `pList0RefPicModifications`/`pList1RefPicModifications`/`List0RefPicModificationsCount`/`List1RefPicModificationsCount` do not change.

5. The new param `num_ref_idx_l0_active_minus1` (+1 on the minus1) corresponds to the final `RefPicList0` (as per HEVC codec standard) length.
    > The previously existing assumption that `num_ref_idx_l0_active_minus1 + 1` and `num_ref_idx_lx_default_active_minus1 + 1` was given by `List0ReferenceFramesCount` is replaced by this explicit parameter.

6. The new param `num_ref_idx_l1_active_minus1` (+1 on the minus1) corresponds to the final `RefPicList1` (as per HEVC codec standard) length.
    > The previously existing assumption that `num_ref_idx_l1_active_minus1 + 1` and `num_ref_idx_lx_default_active_minus1 + 1` was given by `List1ReferenceFramesCount` is replaced by this explicit parameter.

7. Using `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAG_REQUEST_NUM_REF_IDX_ACTIVE_OVERRIDE_FLAG_SLICE` should now take the `num_ref_idx_l0_active_minus1` and `num_ref_idx_l1_active_minus1` params instead of `List0ReferenceFramesCount`/`List0ReferenceFramesCount` respectively.

The rest of the `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2` does not change respect to [D3D12_Video_Encoding_H264_HEVC](D3D12_Video_Encoding_H264_HEVC.md) and [D3D12_Video_Encoding_HEVC_422_444](D3D12_Video_Encoding_HEVC_422_444.md).

## HEVC Validation/rules changes

### Interpretation of D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_HEVC

The following changes only apply when using new interfaces with `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2`. Previously existing interfaces are kept unmodified for app back compat and driver should keep the prevailing HEVC rules from previous specs on that legacy path.

> The previously existing assumption that `MaxLXReferencesForY` limits `ListXReferenceFramesCount` for `Y` frame types is now replaced by `MaxLXReferencesForY` limiting `num_ref_idx_lx_active_minus1` for `Y` frame types.

*MaxL0ReferencesForP*

MaxL0ReferencesForP corresponds to the maximum value allowed in the slice headers and picture control parameters for (`num_ref_idx_l0_active_minus1` +1) when encoding P frames – This is equivalent to the maximum size of the final `RefPicList0` (as per HEVC codec standard) for a P frame supported.

*MaxL0ReferencesForB*

MaxL0ReferencesForB corresponds to the maximum value allowed in the slice headers and picture control parameters for (`num_ref_idx_l0_active_minus1` +1) when encoding B frames – This is equivalent to the maximum size of the final `RefPicList0` (as per HEVC codec standard) for a B frame supported.

*MaxL1ReferencesForB*

MaxL1ReferencesForB corresponds to the maximum value allowed in the slice headers and picture control parameters for (`num_ref_idx_l1_active_minus1` +1) when encoding B frames – This is equivalent to the maximum size of the final `RefPicList1` (as per HEVC codec standard) for a B frame supported.

*MaxDPBCapacity*

MaxDPBCapacity should be the maximum number of unique pictures that can be used from the DPB the user manages (number of unique indices in final `RefPicList0` union final `RefPicList1`) for a given EncodeFrame command on the underlying HW.

### D3D12 runtime validations

These will be the runtime validations for the HEVC picture params. For the older interfaces, where `ListXReferenceFramesCount` matches `num_ref_idx_lX_active_minus1`, no validations changes will be imposed.

1. `Count(Distinct(UnionSet(pList0ReferenceFrames, pList1ReferenceFrames)) <= MaxDPBCapacity`. This will be replaced by `Count(Distinct(UnionSet(RefPicList0, RefPicList1)) <= MaxDPBCapacity`, where `RefPicList0` and `RefPicList1` will be built from `pListXReferenceFrames` and `num_ref_idx_lX_active_minus1`.

2. The D3D12 runtime currently also validates that `Count(Distinct(UnionSet(pList0ReferenceFrames, pList1ReferenceFrames))` is equal to the number of elements in `pReferenceFramesReconPictureDescriptors` with `IsRefUsedByCurrentPic = true`. This validation will stay in place as-is, as it will ensure that the count of DPB snapshot entries with `IsRefUsedByCurrentPic = true` matches the `RefPicSetStCurrBefore`, `RefPicSetStCurrAfter`, `RefPicSetLtCurr` from which the `RefPicListTempX` (passed as `pListXReferenceFrames`) were generated.

3. New validation: `num_ref_idx_l0_active_minus1 >= 0` for P frames. `num_ref_idx_l0_active_minus1 >= 0` and `num_ref_idx_l1_active_minus1 >= 0` for B frames.

4. New validation: `num_ref_idx_l0_active_minus1 + 1 <= pCurCommandPicCtrlHEVC->List0ReferenceFramesCount`.

5. New validation: `num_ref_idx_l1_active_minus1 + 1 <= pCurCommandPicCtrlHEVC->List1ReferenceFramesCount`.

6. New validation: When `List0RefPicModificationsCount > 0`,  `List0RefPicModificationsCount must be equal to (num_ref_idx_l0_active_minus1 + 1)`

6. New validation: When `List1RefPicModificationsCount > 0`, `List1RefPicModificationsCount must be equal to (num_ref_idx_l1_active_minus1 + 1)`
