<a id="video-encoding-codecs"></a>

# Video encoding codec contracts

<!-- d3d12-review-legend:begin -->

> [!NOTE]
> **Draft provenance annotations.**
> Underlining marks pending replacement wording or authored list items. Warning boxes
> mark authored, mixed or reopened passages awaiting editorial review.
> Editorial adoption does not establish factual or hardware verification. Exact approved factual
> corrections do not trigger a marker. Unmarked text elsewhere, declarations
> and structural Markdown are not assertions of approval.
> [Annotation scope and approvals](../../spec-maintenance/d3d12/prose-annotations.md).

<!-- d3d12-review-legend:end -->

<!-- d3d12-review-alert:begin:video-encoding-codecs:entry:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Qualified draft.** This supporting reference covers H.264, HEVC and AV1
> capabilities, bitstream-header responsibilities, picture controls and reference
> management, including the distinct legacy and HEVC2 list contracts.
> [Video encoding](video-encoding.md) owns the API and object/recording contracts;
> shared released declarations belong to the [type reference](video-encoding-types.md).
> Unresolved codec and numerical requirements are qualified locally.

<!-- d3d12-review-alert:end:video-encoding-codecs:entry:0 -->

<a id="family-h264-hevc"></a>

## H.264 and legacy HEVC headers and picture controls

<!-- d3d12-review-alert:begin:video-encoding-codecs:qualification-H264_HEVC:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Codec-contract qualification.** The detailed codec syntax, reference-management,
> intra-refresh, precision and quality requirements in this reference are retained
> from the published encoding specification. They are source-only except for
> released declarations and the narrowly scoped object/recording observations in
> the main reference. In particular, the source's GOP prose permits
> `pic_order_cnt_type` 0–2 while its H.264 SPS table only permits 0 and 2; no support
> for type 1 is established here. Temporal-layer reference restrictions and the
> strict-versus-inclusive slice-count boundary need codec-specialist confirmation.
> The baseline HEVC VPS/SPS/PPS tables describe Main/Main10 4:2:0 and the legacy
> reference-list path, not the higher-profile or HEVC2 path. Their enum-to-header
> arithmetic must not be extended to higher profiles. The higher-profile and HEVC2
> sections retain their separate requirements. These tables are header-coding
> expectations, not an instruction to treat API enum ordinals as codec syntax.
> In header formulas, `minCuSize`, `maxCuSize`, `minTuSize` and `maxTuSize` denote
> the pixel dimensions represented by the selected CU/TU enums, not their ordinal
> values. Duplicated source table rows are consolidated; the source does not
> independently establish omitted chroma-depth or intra-transform table entries,
> H.264 cropping-direction details, or the HEVC loop-filter-flag polarity.
> Those source-specific header details remain subject to codec review.

<!-- d3d12-review-alert:end:video-encoding-codecs:qualification-H264_HEVC:0 -->

<a id="source-s01-102"></a>

### Level_idc mappings for H264

<!-- d3d12-review-alert:begin:video-encoding-codecs:S01-102:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | D3D12 Level | Expected level_idc | Notes |
> |--------|------------|------------|
> | D3D12_VIDEO_ENCODER_LEVELS_H264_1 | 10 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_1b | 11 | SPS.constraint_set3 must be 1 |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_11 | 11 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_12 | 12 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_13 | 13 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_2 | 20 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_21 | 21 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_22 | 22 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_3 | 30 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_31 | 31 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_32 | 32 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_4 | 40 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_41 | 41 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_42 | 42 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_5 | 50 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_51 | 51 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_52 | 52 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_6 | 60 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_61 | 61 | None |
> | D3D12_VIDEO_ENCODER_LEVELS_H264_62 | 62 | None |

<!-- d3d12-review-alert:end:video-encoding-codecs:S01-102:0 -->

---

<a id="source-s01-103"></a>

### H264 Sequence Parameter Set expected values

<!-- d3d12-review-alert:begin:video-encoding-codecs:S01-103:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Syntax element | Expected default value | Notes |
> |--------|------------|------------|
> | profile_idc | 77 (Main), 100 (High), or 110 (High 10), not the API enum ordinal | None |
> | constraint_set0_flag | 0 | None |
> | constraint_set1_flag | 0 | None |
> | constraint_set2_flag | 0 | None |
> | constraint_set3_flag | 0 | 1 if using D3D12_VIDEO_ENCODER_LEVELS_H264_1b |
> | constraint_set4_flag | 0 | None |
> | constraint_set5_flag | 0 | None |
> | reserved_zero_2bits | 0 | None |
> | level_idc | Please see table above for H264 levels | None |
> | seq_parameter_set_id | User specific | None |
> | chroma_format_idc | 1 | For usage with P010 or NV12 YUV 4.2.0 formats only |
> | bit_depth_luma_minus8 | 0 for NV12, 2 for P010 | None |
> | qpprime_y_zero_transform_bypass_flag | 0 | None |
> | seq_scaling_matrix_present_flag | 0 | None |
> | log2_max_frame_num_minus4 | Same as in D3D12_VIDEO_ENCODER_SEQUENCE_GOP_STRUCTURE_H264 | None |
> | pic_order_cnt_type | Same as in D3D12_VIDEO_ENCODER_SEQUENCE_GOP_STRUCTURE_H264 | Only modes 0 and 2 supported in this API |
> | log2_max_pic_order_cnt_lsb_minus4 | Same as in D3D12_VIDEO_ENCODER_SEQUENCE_GOP_STRUCTURE_H264 | Only if pic_order_cnt_type == 0 |
> | max_num_ref_frames | Max number of reference pictures used in encode session | None |
> | gaps_in_frame_num_value_allowed_flag | 0 | Unless app coding headers for multiple temporal layers. |
> | pic_width_in_mbs_minus1 | `std::ceil(sequenceTargetResolution.Width / 16.0) - 1;` | None |
> | pic_height_in_map_units_minus1 | `std::ceil(sequenceTargetResolution.Height / 16.0) - 1;` | None |
> | frame_mbs_only_flag | 1 | No interlace support |
> | direct_8x8_inference_flag | 1 | None |
> | frame_cropping_flag | 0 or 1 depending on encode resolution being 16 aligned or not | None |
> | frame_cropping_rect_left_offset | 0 | Only if frame_cropping_flag = 1 |
> | frame_cropping_rect_right_offset | ((pic_width_in_mbs_minus1+1) * 16 - sequenceTargetResolution.Width) / 2 | Only if frame_cropping_flag = 1 |
> | frame_cropping_rect_top_offset | ((pic_height_in_map_units_minus1+1) * 16 - sequenceTargetResolution.Height) / 2 | Only if frame_cropping_flag = 1 |
> | frame_cropping_rect_bottom_offset | 0 | Only if frame_cropping_flag = 1 |
> | vui_paramenters_present_flag | 0 | None |

<!-- d3d12-review-alert:end:video-encoding-codecs:S01-103:0 -->

<a id="source-s01-104"></a>

### H264 Picture Parameter Set expected values

<!-- d3d12-review-alert:begin:video-encoding-codecs:S01-104:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Syntax element | Expected default value | Notes |
> |--------|------------|------------|
> | pic_parameter_set_id | User specific | None |
> | seq_parameter_set_id | User specific | None |
> | entropy_coding_mode_flag | Based on D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_H264_FLAG_ENABLE_CABAC_ENCODING | None |
> | pic_order_present_flag | 0 | Only support for pic_cnt_type = 0, 2 |
> | num_slice_groups_minus1 | 0 | None |
> | num_ref_idx_l0_active_minus1 | `std::max(static_cast<INT>(pictureControl.List0ReferenceFramesCount) - 1, 0)` | None |
> | num_ref_idx_l1_active_minus1 | `std::max(static_cast<INT>(pictureControl.List1ReferenceFramesCount) - 1, 0)` | None |
> | weighted_pred_flag | 0 | None |
> | weighted_bipred_idc | 0 | None |
> | pic_init_qp_minus26 | 0 | None |
> | pic_init_qs_minus26 | 0 | None |
> | chroma_qp_index_offset | 0 | None |
> | deblocking_filter_control_present_flag | 1 | None |
> | constrained_intra_pred_flag | Based on D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_H264_FLAG_USE_CONSTRAINED_INTRAPREDICTION | None |
> | redundant_pic_cnt_present_flag | 0 | None |
> | transform_8x8_mode_flag | Based on D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_H264_FLAG_USE_ADAPTIVE_8x8_TRANSFORM | Only if using High profiles |
> | pic_scaling_matrix_present_flag | 0 | None |
> | second_chroma_qp_index_offset | 0 | None |

<!-- d3d12-review-alert:end:video-encoding-codecs:S01-104:0 -->

---

<a id="source-s01-106"></a>

### Level_idc mappings for HEVC

<!-- d3d12-review-alert:begin:video-encoding-codecs:S01-106:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | D3D12 Level | Expected general_level_idc | Notes |
> |--------|------------|------------|
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_1 | 30 | Corresponds to 3 * enum level 2 digit suffix (10) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_2 | 60 | Corresponds to 3 * enum level 2 digit suffix (20) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_21 | 63 | Corresponds to 3 * enum level 2 digit suffix (21) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_3 | 90 | Corresponds to 3 * enum level 2 digit suffix (30) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_31 | 93 | Corresponds to 3 * enum level 2 digit suffix (31) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_4 | 120 | Corresponds to 3 * enum level 2 digit suffix (40) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_41 | 123 | Corresponds to 3 * enum level 2 digit suffix (41) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_5 | 150 | Corresponds to 3 * enum level 2 digit suffix (50) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_51 | 153 | Corresponds to 3 * enum level 2 digit suffix (51) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_52 | 156 | Corresponds to 3 * enum level 2 digit suffix (52) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_6 | 180 | Corresponds to 3 * enum level 2 digit suffix (60) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_61 | 183 | Corresponds to 3 * enum level 2 digit suffix (61) |
> | D3D12_VIDEO_ENCODER_LEVELS_HEVC_62 | 186 | Corresponds to 3 * enum level 2 digit suffix (62) |

<!-- d3d12-review-alert:end:video-encoding-codecs:S01-106:0 -->

<a id="source-s01-107"></a>

### HEVC Video Parameter Set expected values

<!-- d3d12-review-alert:begin:video-encoding-codecs:S01-107:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Syntax element | Expected default value | Notes |
> |--------|------------|------------|
> | vps_video_parameter_set_id | User specific | None |
> | vps_base_layer_internal_flag | 1 | None |
> | vps_base_layer_available_flag | 1 | None |
> | vps_max_layers_minus1 | 0 | None |
> | vps_max_sub_layers_minus1 | 0 | None |
> | vps_temporal_id_nesting_flag | 1 | None |
> | vps_reserved_ffff_16bits | 0xFFFF | None |
> | general_profile_space | 0 | None |
> | general_tier_flag | 1 for High tier, 0 for Main tier | None |
> | general_profile_idc | D3D12_VIDEO_ENCODER_PROFILE_HEVC enum value + 1 | None |
> | general_profile_compatibility_flag[general_profile_space] | 1 | None |
> | general_progressive_source_flag |1 | None |
> | general_interlaced_source_flag | 0 | None |
> | general_non_packed_constraint_flag | 1 | None |
> | general_frame_only_constraint_flag | 1 | None |
> | general_reserved_zero_44bits | 44 bit zeroes | None |
> | general_level_idc | Please see table above | None |
> | vps_sub_layer_ordering_info_present_flag | 0 | None |
> | vps_max_dec_pic_buffering_minus1[0] | `(MaxReferenceFramesInDPB/*previous reference frames*/ + 1 /*additional current frame recon pic*/) - 1/**minus1 for header*/;` | None |
> | vps_max_num_reorder_pics[0] | 0 if no B frames. vps_max_dec_pic_buffering_minus1 otherwise. | None |
> | vps_max_latency_increase_plus1[0] | 1 | None |
> | vps_max_layer_id | 0 | None |
> | vps_num_layer_sets_minus1 | 0 | None |
> | vps_timing_info_present_flag | 0 | None |
> | vps_extension_flag | 0 | None |

<!-- d3d12-review-alert:end:video-encoding-codecs:S01-107:0 -->

---

<a id="source-s01-108"></a>

### HEVC Sequence Parameter Set expected values

<!-- d3d12-review-context:begin:video-encoding-codecs:S01-108:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

| Syntax element | Expected default value | Notes |
|--------|------------|------------|
| sps_video_parameter_set_id | User specific | None |
| sps_max_sub_layers_minus1 | Same as in associated VPS | None |
| sps_temporal_id_nesting_flag | Same as in associated VPS | None |
| general_profile_space | 0 | None |
| general_tier_flag | 1 for High tier, 0 for Main tier | None |
| general_profile_idc | D3D12_VIDEO_ENCODER_PROFILE_HEVC enum value + 1 | None |
| general_profile_compatibility_flag[general_profile_space] | 1 | None |
| general_progressive_source_flag |1 | None |
| general_interlaced_source_flag | 0 | None |
| general_non_packed_constraint_flag | 1 | None |
| general_frame_only_constraint_flag | 1 | None |
| general_reserved_zero_44bits | 44 bit zeroes | None |
| general_level_idc | Please see table above | None |
| chroma_format_idc | 1 | 4.2.0 for NV12 and P010 |
| pic_width_in_luma_samples | `std::ceil(sequenceTargetResolution.Width / SubregionBlockPixelsSize) * SubregionBlockPixelsSize` | Use current frame resolution for D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.SubregionBlockPixelsSize  |
| pic_height_in_luma_samples | `std::ceil(sequenceTargetResolution.Height / SubregionBlockPixelsSize) * SubregionBlockPixelsSize` | Use current frame resolution for D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.SubregionBlockPixelsSize |
| conformance_window_flag | 0 if resolution is aligned to SubregionBlockPixelsSize, 1 otherwise | None |
| conf_win_left_offset | 0 | Only if conformance_windows_flag = 1 |
| conf_win_right_offset | (sps.pic_width_in_luma_samples - encodeResolution.Width) >> 1 | Only if conformance_windows_flag = 1 |
| conf_win_top_offset | 0 | Only if conformance_windows_flag = 1 |
| conf_win_bottom_offset | (sps.pic_height_in_luma_samples - encodeResolution.Height) >> 1 | Only if conformance_windows_flag = 1 |
| bit_depth_luma_minus8 | 0 for NV12, 2 for P010 | None |
| log2_max_pic_order_cnt_lsb_minus4 | Based on D3D12_VIDEO_ENCODER_SEQUENCE_GOP_STRUCTURE_HEVC | None |
| sps_sub_layer_ordering_info_present_flag | Same as in associated VPS | None |
| sps_max_dec_pic_buffering_minus1 | Same as in associated VPS | None |
| sps_max_num_reorder_pics | Same as in associated VPS | None |
| sps_max_latency_increase_plus1 | Same as in associated VPS | None |
| log2_min_luma_coding_block_size_minus3 | `std::log2(minCuSize) - 3` | For example MinCUSize=8 for D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_CUSIZE_8x8 |
| log2_diff_max_min_luma_coding_block_size | `std::log2(maxCuSize) - std::log2(minCuSize)` | For example MaxCUSize=16 for D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_CUSIZE_16x16 |
| log2_min_transform_block_size_minus2 | `std::log2(minTuSize) - 2` |  For example MinTuSize=4 for D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_TUSIZE_4x4 |
| log2_diff_max_min_transform_block_size | `std::log2(maxTuSize) - std::log2(minTuSize)` | For example MaxTuSize=16 for D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_TUSIZE_16x16 |
| max_transform_hierarchy_depth_inter | Based on D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC | None |
| scaling_list_enabled_flag | 0 | None |
| amp_enabled_flag | Based on D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_USE_ASYMETRIC_MOTION_PARTITION | None |
| sample_adaptive_offset_enabled_flag | Based on D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_ENABLE_SAO_FILTER | None |
| pcm_enabled_flag | 0 | None |
| num_short_term_ref_pic_sets | 0 | None |
| long_term_ref_pics_present_flag | Based on D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_ENABLE_LONG_TERM_REFERENCES | None |
| num_long_term_ref_pics_sps | 0 | None |
| sps_temporal_mvp_enabled_flag | 0 | None |
| strong_intra_smoothing_enabled_flag | 0 | None |
| vui_parameters_present_flag | 0 | None |
| sps_extension_flag | 0 | None |

> Note: When operating with temporal SVC layers the VPS/SPS must be authored by the app so that VPS fields (e.g `vps_max_layers_minus1`, `vps_max_layer_id`, etc) and SPS fields (e.g `sps_max_sub_layers_minus1`, etc) reflect the configured temporal layer count and layer ids. The VPS/SPS expectations above apply to a single base layer case; for multi‑layer temporal SVC the VPS/SPS coded by the app must be consistent with the requested temporal layer configuration.

<!-- d3d12-review-context:end:video-encoding-codecs:S01-108:0 -->

<a id="source-s01-109"></a>

### HEVC Picture Parameter Set expected values

<!-- d3d12-review-alert:begin:video-encoding-codecs:S01-109:0 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Syntax element | Expected default value | Notes |
> |--------|------------|------------|
> | pps_pic_parameter_set_id | User specific | None |
> | pps_seq_parameter_set_id | User specific | None |
> | dependent_slice_segments_enabled_flag | 0 | None |
> | output_flag_present_flag | 0 | None |
> | num_extra_slice_header_bits | 0 | None |
> | sign_data_hiding_enabled_flag | 0 | None |
> | cabac_init_present_flag | 1 | None |
> | num_ref_idx_lx_default_active_minus1[0] | `std::max(static_cast<INT>(pictureControl.List0ReferenceFramesCount) - 1, 0)` | None |
> | num_ref_idx_lx_default_active_minus1[1] | `std::max(static_cast<INT>(pictureControl.List1ReferenceFramesCount) - 1, 0)` | None |
> | init_qp_minus26 | 0 | None |
> | constrained_intra_pred_flag | Based on D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_USE_CONSTRAINED_INTRAPREDICTION | None |
> | transform_skip_enabled_flag | Based on D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_ENABLE_TRANSFORM_SKIPPING | None |
> | cu_qp_delta_enabled_flag | 1 | None |
> | diff_cu_qp_delta_depth | 0 | None |
> | pps_cb_qp_offset | 0 | None |
> | pps_cr_qp_offset | 0 | None |
> | pps_slice_chroma_qp_offsets_present_flag | 1 | None |
> | weighted_pred_flag | 0 | No support for weighted prediction in the API |
> | weighted_bipred_flag | 0 | No support for weighted prediction in the API |
> | transquant_bypass_enabled_flag | 0 | None |
> | tiles_enabled_flag | 0 | None |
> | entropy_coding_sync_enabled_flag | 0 | None |
> | pps_loop_filter_across_slices_enabled_flag  | Based on D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAG_DISABLE_LOOP_FILTER_ACROSS_SLICES | None |
> | deblocking_filter_control_present_flag | 1 | None |
> | deblocking_filter_override_enabled_flag | 0 | None |
> | pps_deblocking_filter_disabled_flag | 0 | None |
> | pps_beta_offset_div2 | 0 | None |
> | pps_tc_offset_div2 | 0 | None |
> | pps_scaling_list_data_present_flag | 0 | None |
> | lists_modification_present_flag | 1 if sending down D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC lists modifications. Otherwise set as 0. | None |
> | log2_parallel_merge_level_minus2 | 0 | None |
> | slice_segment_header_extension_present_flag | 0 | None |
> | pps_extension_flag | 0 | None |

<!-- d3d12-review-alert:end:video-encoding-codecs:S01-109:0 -->

<a id="source-s01-111"></a>

### D3D12_VIDEO_ENCODER_FRAME_TYPE_H264

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-111:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_FRAME_TYPE_H264`](video-encoding-types.md#d3d12-video-encoder-frame-type-h264).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-111:0 --></ins>

**Constants**

*D3D12_VIDEO_ENCODER_FRAME_TYPE_H264_I_FRAME*

I-Frame. Completely intra-coded frame.

*D3D12_VIDEO_ENCODER_FRAME_TYPE_H264_P_FRAME*

P-Frame. Allows references to past frames.

*D3D12_VIDEO_ENCODER_FRAME_TYPE_H264_B_FRAME*

B-Frame. Allows references to both past and future (in display order) frames.

*D3D12_VIDEO_ENCODER_FRAME_TYPE_H264_IDR_FRAME*

Instanteneous decode refresh frame. Special type of I-frame where no frame after it can reference any frame before it.

<a id="source-s01-112"></a>

### D3D12_VIDEO_ENCODER_REFERENCE_PICTURE_DESCRIPTOR_H264

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-112:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_REFERENCE_PICTURE_DESCRIPTOR_H264`](video-encoding-types.md#d3d12-video-encoder-reference-picture-descriptor-h264).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-112:0 --></ins>

**Members**

*ReconstructedPictureResourceIndex*

Maps the current reference picture described by this structure to a resource in the D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames array.

*IsLongTermReference*

Set when the described reference frame is being used as a long-term reference picture.

*LongTermPictureIdx*

If used as a long term reference, indicates the long term reference index number.

*PictureOrderCountNumber*

Indicates the described reference frame display order.

*FrameDecodingOrderNumber*

Frame *decode* order **with semantic as indicated by the slice header *frame_num* syntax element** associated with the encoded reference picture.

*TemporalLayerIndex*

Picture layer number in temporal hierarchy. The maximum number of temporal layers is currently 3.

<a id="source-s01-113"></a>

### D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264_FLAGS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-113:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264_FLAGS`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data-h264-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-113:0 --></ins>

Defines the set of flags for the codec-specific picture control properties.

**Constants**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-113:3 -->*D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264_FLAG_NONE*<!-- d3d12-review-inline:end:video-encoding-codecs:S01-113:3 --></ins>

No flags

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-113:5 -->*D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264_FLAG_REQUEST_INTRA_CONSTRAINED_SLICES*<!-- d3d12-review-inline:end:video-encoding-codecs:S01-113:5 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-113:6 -->Requests slice constrained encoding for this frame, in which every slice in a frame is encoded independently from other slices in the same frame. Please check for support in
D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_H264_FLAG_INTRA_SLICE_CONSTRAINED_ENCODING_SUPPORT. This mode restricts the motion vector search range to the region box of the current slice (eg. can’t use motion vectors outside the slice boundary).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-113:6 --></ins>

*D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264_FLAG_REQUEST_NUM_REF_IDX_ACTIVE_OVERRIDE_FLAG_SLICE*

If bit set, requests for the driver to write `num_ref_idx_active_override_flag` and the related `num_ref_idx_l0_active_minus1` and `num_ref_idx_l1_active_minus1` in the slice header, overriding the active PPS values for these codec params. Requires `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_H264_FLAG_NUM_REF_IDX_ACTIVE_OVERRIDE_FLAG_SLICE_SUPPORT` supported.

In this case the app can reuse the PPS coded for previous frames and avoid a new PPS per frame, as long as the slice override params are enough to specify the bitstream changes, if any.

<a id="source-s01-114"></a>

### D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264_REFERENCE_PICTURE_MARKING_OPERATION

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-114:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264_REFERENCE_PICTURE_MARKING_OPERATION`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data-h264-reference-picture-marking-operation).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-114:0 --></ins>

Describes changes in the reference pictures as memory operations as a tuple of an operation identificator and associated parameters needed for the operation.

Please refer to H264 specification for more details: section 8.2.5.4 "Adaptive memory control decoded reference picture marking process".

**Members**

*memory_management_control_operation*

Specifies a control operation to be applied to affect the reference picture marking state.

<!-- d3d12-review-alert:begin:video-encoding-codecs:S01-114:6 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | memory_management_control_operation | Operation description |
> |--------|------------|
> | 0 | End memory_management_control_operation syntax element loop |
> | 1 | Mark a short-term reference picture as "unused for reference" |
> | 2 | Mark a long-term reference picture as "unused for reference" |
> | 3 | Mark a short-term reference picture as "used for long-term reference" and assign a long-term frame index to it |
> | 4 | Specify the maximum long-term frame index and mark all long-term reference pictures having long-term frame indices greater than the maximum value as "unused for reference" |
> | 5 | Mark all reference pictures as "unused for reference" and set the MaxLongTermFrameIdx variable to "no long-term frame indices" |
> | 6 | Mark the current picture as "used for long-term reference" and assign a long-term frame index to it |

<!-- d3d12-review-alert:end:video-encoding-codecs:S01-114:6 -->

*difference_of_pic_nums_minus1*

**Is used with memory_management_control_operation equal to 3 or 1** to assign a long-term frame index to a short-term reference picture or to mark a short-term reference picture as "unused for reference". When the associated memory_management_control_operation is processed by the decoding process, the resulting picture number derived from difference_of_pic_nums_minus1 shall be a picture number assigned to one of the reference pictures marked as "used for reference" and not previously assigned to a long-term frame index.

*long_term_pic_num*

**Is used with memory_management_control_operation equal to 2** to mark a long-term reference picture as "unused for reference". When the associated memory_management_control_operation is processed by the decoding process, long_term_pic_num shall be equal to a long-term picture number assigned to one of the reference pictures that is currently marked as "used for long-term reference".

*long_term_frame_idx*

**Is used with memory_management_control_operation equal to 3 or 6** to assign a long-term frame index to a picture. When the associated memory_management_control_operation is processed by the decoding process, the value of long_term_frame_idx shall be in the range of 0 to MaxLongTermFrameIdx, inclusive.

*max_long_term_frame_idx_plus1*

The value minus 1 specifies the maximum value of long-term frame index allowed for long-term reference pictures (until receipt of another value of max_long_term_frame_idx_plus1). The value of max_long_term_frame_idx_plus1 shall be in the range of 0 to max_num_ref_frames, inclusive.

**Notes**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-114:16 -->The variable MaxLongTermFrameIdx is derived as follows:<!-- d3d12-review-inline:end:video-encoding-codecs:S01-114:16 --></ins>

        – If max_long_term_frame_idx_plus1 is equal to 0, MaxLongTermFrameIdx is set equal to "no long-term frame indices".
        – Otherwise (max_long_term_frame_idx_plus1 is greater than 0), MaxLongTermFrameIdx is set equal to max_long_term_frame_idx_plus1 − 1.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-114:18 -->The operation of marking the current frame as a **short** term reference is given by a flag present in the *D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264_FLAGS* structure with its corresponding PictureOrderCountNumber and FrameDecodingOrderNumber values indicated in the associated picture control structure.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-114:18 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-114:19 -->The variable max_num_ref_frames is indicated in this API by the maximum DPB capacity reported.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-114:19 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-114:20 -->Note that for marking an IDR frame as long term reference, the explicit mechanism is to mark it as short term reference first, by setting D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_USED_AS_REFERENCE_PICTURE when calling EncodeFrame for such IDR frame, and later promoting it to be a long term reference frame using memory management operation '3' Mark a short-term reference picture as "used for long-term reference" and assign a long-term frame index to it.
Alternatively, if encoding an IDR frame and setting adaptive_ref_pic_marking_mode_flag = 1, the driver will assume that the client is attempting to set the H264 slice header long_term_reference_flag and will do so in the output bitstream for such EncodeFrame call.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-114:20 --></ins>

<a id="source-s01-115"></a>

### D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264_REFERENCE_PICTURE_LIST_MODIFICATION_OPERATION

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-115:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264_REFERENCE_PICTURE_LIST_MODIFICATION_OPERATION`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data-h264-reference-picture-list-modification-operation).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-115:0 --></ins>

**Members**

*modification_of_pic_nums_idc*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-115:3 -->Together with abs_diff_pic_num_minus1 or long_term_pic_num specifies which of the reference pictures are re-mapped. The values of modification_of_pic_nums_idc are specified in Table 7-7. In Rec. ITU-T H.264 (06/2019), the first modification_of_pic_nums_idc that follows immediately after ref_pic_list_modification_flag_l0 or ref_pic_list_modification_flag_l1 shall not be equal to 3.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-115:3 --></ins>

*abs_diff_pic_num_minus1*

Plus 1 specifies the absolute difference between the picture number of the picture being moved to the current index in the list and the picture number prediction value. abs_diff_pic_num_minus1 shall be in the range of 0 to MaxPicNum − 1. The allowed values of abs_diff_pic_num_minus1 are further restricted as specified in clause 8.2.4.3.1.

*long_term_pic_num*

Specifies the long-term picture number of the picture being moved to the current index in the list. When decoding a coded frame, long_term_pic_num shall be equal to a LongTermPicNum assigned to one of the reference frames or complementary reference field pairs marked as "used for long-term reference". When decoding a coded field, long_term_pic_num shall be equal to a LongTermPicNum assigned to one of the reference fields marked as "used for long-term reference".

<a id="source-s01-116"></a>

### D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-116:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_H264`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data-h264).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-116:0 --></ins>

Describes the picture level control elements for the associated *EncodeFrame* command.

Please note that if the current frame is marked as a reference picture, the output must contain the reconstructed picture along with the bitstream for the host to place it in future commands in the reconstructed pictures reference list. Please note that there might be limitations for some frame types to be marked as references, please check support before setting those values.

**Members**

*Flags*

Configuration flags for this frame to be encoded. The flags can be combined.

*FrameType*

Sets the picture type. See D3D12_VIDEO_ENCODER_FRAME_TYPE_H264 values. Please check that the codec specific flags support the type (eg. B-Frames) before selecting a value.

**This selection needs to be kept in sync with the GOP structure configuration set by the host. Please beware that the GOP is defined in display order and this pic type selection must follow such GOP but in encode order**.

*pic_parameter_set_id*

Value to be used in the slice headers of the current frame to reference the PPS.

*idr_pic_id*

When frame is of type *D3D12_VIDEO_ENCODER_FRAME_TYPE_H264_IDR_FRAME*, this indicates the identifier of such IDR frame to be used in all the slices headers present in the frame.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-116:13 -->The H.264 deblocking setting is `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_H264.DisableDeblockingFilterConfig`, with allowed modes reported in `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_H264.DisableDeblockingFilterSupportedModes`. It is not a separate member of the released H.264 picture-control structure.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-116:13 --></ins>

*PictureOrderCountNumber*

Current frame display order.

*FrameDecodingOrderNumber*

Frame *decode* order **with semantic as indicated by the slice header *frame_num* syntax element** that increments after each reference picture.

*TemporalLayerIndex*

Picture layer number in temporal hierarchy. The maximum number of temporal layers is currently 3.

<!-- d3d12-review-context:begin:video-encoding-codecs:S01-116:20 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

> Note: For H264 the driver **will not** write the prefix NAL indicating the *temporal_id* for the slices coded for this frame when using temporal scalability. The responsibility of coding the prefix NAL units falls on the user along with the rest of the bitstream headers such as PPS, SPS, etc.

<!-- d3d12-review-context:end:video-encoding-codecs:S01-116:20 -->

*List0ReferenceFramesCount*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-116:22 -->Number of past frame references to be used for this frame. This value should be coherent with what was exposed in D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_H264.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-116:22 --></ins>

*pList0ReferenceFrames*

List of past frame reference frames to be used for this frame. Each integer value in this array indices into pReferenceFramesReconPictureDescriptors to reference pictures kept in the DPB.

*List1ReferenceFramesCount*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-116:26 -->Number of future frame references to be used for this frame. This value should be coherent with what was exposed in D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_H264.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-116:26 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-116:27 -->*pList1ReferenceFrames*<!-- d3d12-review-inline:end:video-encoding-codecs:S01-116:27 --></ins>

List of future frame reference frames to be used for this frame. Each integer value in this array indices into pReferenceFramesReconPictureDescriptors to reference pictures kept in the DPB.

*ReferenceFramesReconPictureDescriptorsCount*

Number of entries in pReferenceFramesReconPictureDescriptors.

*pReferenceFramesReconPictureDescriptors*

Describes the current state of the DPB buffer kept in D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames. The L0/L1 lists indices map from past/future references into this descriptors array.

This array of descriptors, in turn, maps a reference picture for this frame into a resource index in the reconstructed pictures array D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames. Aditionally, for each reference picture it indicates the encode and display order number and whether it is a long term reference.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-116:34 -->The size of this array always matches D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames.NumTexture2Ds for the associated EncodeFrame command.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-116:34 --></ins>

*adaptive_ref_pic_marking_mode_flag*

Defines a semantic mode for the frame reference handling.

<!-- d3d12-review-alert:begin:video-encoding-codecs:S01-116:37 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | adaptive_ref_pic_marking_mode_flag | Reference picture marking mode specified |
> |--------|------------|
> | 0 | Sliding window reference picture marking mode: A marking mode providing a first-in first-out mechanism for short-term reference pictures. |
> | 1 | Adaptive reference picture marking mode: A reference picture marking mode providing syntax elements to specify marking of reference pictures as "unused for reference" and to assign long-term frame indices. |

<!-- d3d12-review-alert:end:video-encoding-codecs:S01-116:37 -->

*RefPicMarkingOperationsCommandsCount*

Requires that **adaptive_ref_pic_marking_mode_flag** is set to 1.

Number of reference pictures marking operations associated with the current frame.

*pRefPicMarkingOperationsCommands*

Requires that **adaptive_ref_pic_marking_mode_flag** is set to 1.

List of *RefPicMarkingOperationsCommandsCount* reference pictures marking operations associated with the current frame.

**Remarks**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-116:45 -->The operations described by this list need to be reflected in the DPB descriptors accordingly during the encoding session.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-116:45 --></ins>

*List0RefPicModificationsCount*

Number of list modifications for L0 list.

*pList0RefPicModifications*

Contains List0RefPicModificationsCount modification commands for L0 list.

*List1RefPicModificationsCount*

Number of list modifications for L1 list.

*pList1RefPicModifications*

Contains List1RefPicModificationsCount modification commands for L1 list.

*QPMapValuesCount*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-116:55 -->Contains the number of elements in `pRateControlQPMap`. This should match the number of coding blocks in the frame, rounding up the frame resolution to the closest aligned values.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-116:55 --></ins>

*pRateControlQPMap*

Array containing in row/column scan order, the QP map values to use on each squared region for this frame.
The QP map dimensions can be calculated using the current resolution and D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.QPMapRegionPixelsSize conveying the squared region sizes.

> For any codecs/configurations where the QP ranges can be negative, the ranges used by `pRateControlQPMap` as absolute map parameter are kept in that native signed range.

<a id="source-s01-117"></a>

### D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-117:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC`](video-encoding-types.md#d3d12-video-encoder-frame-type-hevc).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-117:0 --></ins>

**Constants**

*D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC_I_FRAME*

I-Frame. Completely intra-coded frame.

*D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC_P_FRAME*

P-Frame. Allows references to past frames.

*D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC_B_FRAME*

B-Frame. Allows references to both past and future (in display order) frames.

*D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC_IDR_FRAME*

Instanteneous decode refresh frame. Special type of I-frame where no frame after it can reference any frame before it.

> Note: Please see below the expected HEVC header frame type for each of the defined frames.

<!-- d3d12-review-context:begin:video-encoding-codecs:S01-117:11 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

| Syntax element | Expected default value |
|--------|------------|
| D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC_I_FRAME | nal_unit_type = CRA_NUT   |
| D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC_P_FRAME | nal_unit_type = TRAIL_R |
| D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC_B_FRAME |  nal_unit_type = TRAIL_R |
| D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC_IDR_FRAME | nal_unit_type = IDR_W_RADL   |

> Note for D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_P_FRAMES_IMPLEMENTED_AS_LOW_DELAY_B_FRAMES:
If bit set, informs the user that when encoding frames with type D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC_P_FRAME, they will be written as low delay B-Frames in the compressed bitstream. If bit off, informs P frames will be written in the compressed bitstream.
> Note: When operating under this mode, is the user responsibility to code the correct frame type in _AUD_NUT_ and other parts of the HEVC bitstream, taking into account that P frames will be treated as generalized B frames with only references to past frames in POC order.

<!-- d3d12-review-context:end:video-encoding-codecs:S01-117:11 -->

<a id="source-s01-118"></a>

### D3D12_VIDEO_ENCODER_REFERENCE_PICTURE_DESCRIPTOR_HEVC

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-118:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_REFERENCE_PICTURE_DESCRIPTOR_HEVC`](video-encoding-types.md#d3d12-video-encoder-reference-picture-descriptor-hevc).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-118:0 --></ins>

**Members**

*ReconstructedPictureResourceIndex*

Maps the current reference picture described by this structure to a resource in the D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames array.

*IsRefUsedByCurrentPic*

Indicates whether this descriptor entry is being used by the current picture by being indexed from either L0 and/or L1 lists.

*IsLongTermReference*

Set when the described reference frame is being used as a long-term reference picture.

*PictureOrderCountNumber*

Indicates the described reference frame display order.

*TemporalLayerIndex*

Picture layer number in temporal hierarchy. The maximum number of temporal layers is currently 3.

<a id="source-s01-119"></a>

### D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAGS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-119:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAGS`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data-hevc-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-119:0 --></ins>

Defines the set of flags for the codec-specific picture control properties.

**Constants**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-119:3 -->*D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAG_NONE*<!-- d3d12-review-inline:end:video-encoding-codecs:S01-119:3 --></ins>

No flags

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-119:5 -->*D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAG_REQUEST_INTRA_CONSTRAINED_SLICES*<!-- d3d12-review-inline:end:video-encoding-codecs:S01-119:5 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-119:6 -->Requests slice constrained encoding for this frame, in which every slice in a frame is encoded independently from other slices in the same frame. Please check for support in
D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_INTRA_SLICE_CONSTRAINED_ENCODING_SUPPORT. This mode restricts the motion vector search range to the region box of the current slice (eg. can’t use motion vectors outside the slice boundary).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-119:6 --></ins>

*D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAG_REQUEST_NUM_REF_IDX_ACTIVE_OVERRIDE_FLAG_SLICE*

If bit set, requests for the driver to write `num_ref_idx_active_override_flag` and the related `num_ref_idx_l0_active_minus1` and `num_ref_idx_l1_active_minus1` in the slice header, overriding the active PPS values for these codec params. Requires `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAG_NUM_REF_IDX_ACTIVE_OVERRIDE_FLAG_SLICE_SUPPORT` supported.

In this case the app can reuse the PPS coded for previous frames and avoid a new PPS per frame, as long as the slice override params are enough to specify the bitstream changes, if any.

<a id="source-s01-120"></a>

### D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-120:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data-hevc).<!-- d3d12-review-inline:end:video-encoding-codecs:S01-120:0 --></ins>

**Members**

*Flags*

Configuration flags for this frame to be encoded. The flags can be combined.

*FrameType*

Sets the picture type. See D3D12_VIDEO_ENCODER_FRAME_TYPE_HEVC values. Please check that the codec specific flags support the type (eg. B-Frames) before selecting a value.

**This selection needs to be kept in sync with the GOP structure configuration set by the host. Please beware that the GOP is defined in display order and this pic type selection must follow such GOP but in encode order**.

*slice_pic_parameter_set_id*

Value to be used in the slice headers of the current frame to reference the PPS.

*PictureOrderCountNumber*

Current frame display order.

*TemporalLayerIndex*

Picture layer number in temporal hierarchy. The maximum number of temporal layers is currently 3.

*List0ReferenceFramesCount*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-120:14 -->Number of past frame references to be used for this frame. This value should be coherent with what was exposed in D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_HEVC.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-120:14 --></ins>

*pList0ReferenceFrames*

List of past frame reference frames to be used for this frame. Each integer value in this array indices into pReferenceFramesReconPictureDescriptors to reference pictures kept in the DPB.

*List1ReferenceFramesCount*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-120:18 -->Number of future frame references to be used for this frame. This value should be coherent with what was exposed in D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_HEVC.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-120:18 --></ins>

*pList1ReferenceFrames*

List of future frame reference frames to be used for this frame. Each integer value in this array indices into pReferenceFramesReconPictureDescriptors to reference pictures kept in the DPB.

*ReferenceFramesReconPictureDescriptorsCount*

Number of entries in pReferenceFramesReconPictureDescriptors.

*pReferenceFramesReconPictureDescriptors*

Describes the current state of the DPB buffer kept in D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames. The L0/L1 lists indices map from past/future references into this descriptors array.

This array of descriptors, in turn, maps a reference picture for this frame into a resource index in the reconstructed pictures array D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames. Aditionally, for each reference picture it indicates the encode and display order number and whether it is a long term reference.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-120:26 -->The size of this array always matches D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames.NumTexture2Ds for the associated EncodeFrame command.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-120:26 --></ins>

*List0RefPicModificationsCount*

Number of list modifications for L0 list.

*pList0RefPicModifications*

Contains List0RefPicModificationsCount modification commands for L0 list.

*List1RefPicModificationsCount*

Number of list modifications for L1 list.

*pList1RefPicModifications*

Contains List1RefPicModificationsCount modification commands for L1 list.

*QPMapValuesCount*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-120:36 -->Contains the number of elements in `pRateControlQPMap`. This should match the number of coding blocks in the frame, rounding up the frame resolution to the closest aligned values.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-120:36 --></ins>

*pRateControlQPMap*

Array containing in row/column scan order, the QP map values to use on each squared region for this frame.
The QP map dimensions can be calculated using the current resolution and D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.QPMapRegionPixelsSize conveying the squared region sizes.

<!-- d3d12-review-context:begin:video-encoding-codecs:S01-120:39 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

> For any codecs/configurations where the QP ranges can be negative, the ranges used by `pRateControlQPMap` as absolute map parameter are kept in that native signed range. For example for HEVC `[0, 51]` range for 8 bit pixel depth, the range for 10 bits `[-12, 51]`, and similar for higher bit depths are all considered as-is from the contract.

<!-- d3d12-review-context:end:video-encoding-codecs:S01-120:39 -->

<a id="source-s01-121"></a>

### D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-121:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data).
**Remarks**<!-- d3d12-review-inline:end:video-encoding-codecs:S01-121:0 --></ins>

1. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S01-121:1 -->There is no support for slice level picture reference lists reordering.<!-- d3d12-review-inline:end:video-encoding-codecs:S01-121:1 --></ins>
2. There is no support for weighted inter-prediction.

<a id="family-hevc-422-444"></a>

## HEVC higher-profile configuration

<!-- d3d12-review-alert:begin:video-encoding-codecs:qualification-HEVC_422_444:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **Higher-profile qualification.** The format lists and codec numeric
> restrictions below are published requirements, not independently tested
> hardware capabilities. Availability remains conditional on codec/profile/format
> and combined-configuration support. The legacy Main/Main10 header tables do not
> define the higher-profile header syntax. Bitmask expressions are shown with
> explicit parentheses around the bitwise operation; no additional allowed values
> or codec tools are inferred.

<!-- d3d12-review-alert:end:video-encoding-codecs:qualification-HEVC_422_444:0 -->

<a id="source-s03-004"></a>

### D3D12_VIDEO_ENCODER_PROFILE_HEVC

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-004:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PROFILE_HEVC`](video-encoding-types.md#d3d12-video-encoder-profile-hevc).<!-- d3d12-review-inline:end:video-encoding-codecs:S03-004:0 --></ins>

**Remarks**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-004:2 -->Driver uses `D3D12_FEATURE_VIDEO_ENCODER_PROFILE_LEVEL` to report support for a given codec/profile configuration for these profiles. This cap must be used by the app to ensure runtime/driver support before using the associated higher-profile structures.<!-- d3d12-review-inline:end:video-encoding-codecs:S03-004:2 --></ins>

Driver uses `D3D12_FEATURE_DATA_VIDEO_ENCODER_INPUT_FORMAT` to report optionally supported formats for a given input `D3D12_VIDEO_ENCODER_PROFILE_HEVC` to the query. For consistency with DXVA decode spec, driver should also report lower subsampling/bitdepth formats as supported other than the maximum allowed by the profile (e.g 8 bit 4:2:0 and others can also be supported when using higher profiles like Main10, etc).

The `DXGI_FORMAT`s are consistent with the HEVC DXVA decode counterpart spec. These are the formats expected for higher subsampling/bit depth content:

- `DXGI_FORMAT_NV12` for 8-bit 4:2:0
- `DXGI_FORMAT_P010` for 10-bit 4:2:0
- `DXGI_FORMAT_P016` for 12-bit 4:2:0
- `DXGI_FORMAT_YUY2` for 8-bit 4:2:2
- `DXGI_FORMAT_Y210` for 10-bit 4:2:2
- `DXGI_FORMAT_Y216` for 12-bit 4:2:2
- `DXGI_FORMAT_AYUV` for 8-bit 4:4:4
- `DXGI_FORMAT_Y410` for 10-bit 4:4:4
- `DXGI_FORMAT_Y416` for 12-bit 4:4:4
- `DXGI_FORMAT_Y416` for 16-bit 4:4:4

<a id="source-s03-006"></a>

### D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-006:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1`](video-encoding-types.md#d3d12-video-encoder-codec-configuration-support-hevc-flags1).<!-- d3d12-review-inline:end:video-encoding-codecs:S03-006:0 --></ins>

Reports HW capabilities for HEVC.

Flags ending in `_SUPPORT` indicate the driver optionally supports setting this flag in the bitstream headers and encoder params.
Flags ending in `_REQUIRED` indicate the driver requires setting this flag in the bitstream headers and encoder params as mandatory. Note that required flags implies the support flag is also reported.

<a id="source-s03-007"></a>

### D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-007:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1`](video-encoding-types.md#d3d12-video-encoder-codec-configuration-support-hevc1).<!-- d3d12-review-inline:end:video-encoding-codecs:S03-007:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-007:1 -->`D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC` expects `MinLumaCodingUnitSize`, `MaxLumaCodingUnitSize`, `MinLumaTransformUnitSize`, `MaxLumaTransformUnitSize`, `max_transform_hierarchy_depth_inter`, `max_transform_hierarchy_depth_intra` as inputs from the app to the driver, which will then return the result in `SupportFlags` and `D3D12_FEATURE_DATA_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT.IsSupported`<!-- d3d12-review-inline:end:video-encoding-codecs:S03-007:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-007:2 -->The additional flags in `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS` and `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1` are outputs from the driver.
When the driver indicated support or requirement for a given coding tool flag, the following additional parameters, also driver outputs, indicate the configuration restrictions for using the associated flag coding feature when encoding a frame.<!-- d3d12-review-inline:end:video-encoding-codecs:S03-007:2 --></ins>

*allowed_diff_cu_chroma_qp_offset_depth_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `diff_cu_chroma_qp_offset_depth`.

Codec valid range for support for `diff_cu_chroma_qp_offset_depth` is [0, 3].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_diff_cu_chroma_qp_offset_depth_values |= (1 << value)

Apps wanting to set `value` in `diff_cu_chroma_qp_offset_depth`, must validate support by checking:

    ((allowed_diff_cu_chroma_qp_offset_depth_values & (1 << value)) != 0)

*allowed_log2_sao_offset_scale_luma_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `log2_sao_offset_scale_luma`.

Codec valid range for support for `log2_sao_offset_scale_luma` is [0, 6].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_log2_sao_offset_scale_luma_values |= (1 << value)

Apps wanting to set `value` in `log2_sao_offset_scale_luma`, must validate support by checking:

    ((allowed_log2_sao_offset_scale_luma_values & (1 << value)) != 0)

*allowed_log2_sao_offset_scale_chroma_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `log2_sao_offset_scale_chroma`.

Codec valid range for support for `log2_sao_offset_scale_chroma` is [0, 6].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_log2_sao_offset_scale_chroma_values |= (1 << value)

Apps wanting to set `value` in `log2_sao_offset_scale_chroma`, must validate support by checking:

    ((allowed_log2_sao_offset_scale_chroma_values & (1 << value)) != 0)

*allowed_log2_max_transform_skip_block_size_minus2_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `log2_max_transform_skip_block_size_minus2`.

Codec valid range for support for `log2_max_transform_skip_block_size_minus2` is [0, 3].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_log2_max_transform_skip_block_size_minus2_values |= (1 << value)

Apps wanting to set `value` in `log2_max_transform_skip_block_size_minus2`, must validate support by checking:

    ((allowed_log2_max_transform_skip_block_size_minus2_values & (1 << value)) != 0)

*allowed_chroma_qp_offset_list_len_minus1_values*

Driver output. A bitmask indicating which values are allowed to be configured when encoding with `chroma_qp_offset_list_len_minus1`.

Codec valid range for support for `chroma_qp_offset_list_len_minus1` is [0, 5].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_chroma_qp_offset_list_len_minus1_values |= (1 << value)

Apps wanting to set `value` in `chroma_qp_offset_list_len_minus1`, must validate support by checking:

    ((allowed_chroma_qp_offset_list_len_minus1_values & (1 << value)) != 0)

*allowed_cb_qp_offset_list_values*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-007:39 -->Driver output. A bitmask indicating which values are allowed to be configured when encoding with `cb_qp_offset_list`.
The array has six entries. For an entry selected by the codec's chroma-QP list configuration, the driver reports the allowed signed values. The source's test for deriving array indices from the allowed-length mask is withheld pending codec-specialist reconciliation:<!-- d3d12-review-inline:end:video-encoding-codecs:S03-007:39 --></ins>

Codec valid range for support for `cb_qp_offset_list[index]` is [-12, 12].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_cb_qp_offset_list_values[index] |= (1 << (value + 12))

Apps wanting to set `value` in `cb_qp_offset_list[index]`, must validate support by checking:

    ((allowed_cb_qp_offset_list_values[index] & (1 << (value + 12))) != 0)

*allowed_cr_qp_offset_list_values*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-007:46 -->Driver output. A bitmask indicating which values are allowed to be configured when encoding with `cr_qp_offset_list`.
The array has six entries. For an entry selected by the codec's chroma-QP list configuration, the driver reports the allowed signed values. The source's test for deriving array indices from the allowed-length mask is withheld pending codec-specialist reconciliation:<!-- d3d12-review-inline:end:video-encoding-codecs:S03-007:46 --></ins>

Codec valid range for support for `cr_qp_offset_list[index]` is [-12, 12].

For driver to indicate that `value` is supported, it must set the following in the reported bitmask.

    allowed_cr_qp_offset_list_values[index] |= (1 << (value + 12))

Apps wanting to set `value` in `cr_qp_offset_list[index]`, must validate support by checking:

    ((allowed_cr_qp_offset_list_values[index] & (1 << (value + 12))) != 0)

<a id="source-s03-008"></a>

### D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-008:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT`](video-encoding-types.md#d3d12-video-encoder-codec-configuration-support).<!-- d3d12-review-inline:end:video-encoding-codecs:S03-008:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-008:1 -->For the higher HEVC profiles, the app must ensure support by calling `D3D12_FEATURE_VIDEO_ENCODER_PROFILE_LEVEL` first and then use `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1` which contains the additional parameters to report the associated profile features.<!-- d3d12-review-inline:end:video-encoding-codecs:S03-008:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-008:2 -->Main/Main10 continue to use `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC`; the higher profiles use HEVC1. The legacy query payload remains supported on runtimes/drivers without HEVC1.<!-- d3d12-review-inline:end:video-encoding-codecs:S03-008:2 --></ins>

<a id="source-s03-009"></a>

### D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAGS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-009:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_HEVC_FLAGS`](video-encoding-types.md#d3d12-video-encoder-codec-configuration-hevc-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S03-009:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-009:1 -->Defines the set of flags for the codec-specific encoder configuration properties and SPS syntax. These flags set by the client must conform to the caps reported in `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS` and `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1`.
Also, the coded bitstream headers for the current frame where the associated syntax with these flags is used must match with the ones set when recording EncodeFrame for the current frame.<!-- d3d12-review-inline:end:video-encoding-codecs:S03-009:1 --></ins>

<a id="source-s03-010"></a>

### D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAGS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-010:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAGS`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data-hevc-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S03-010:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-010:1 -->Defines the set of flags for the codec-specific picture control properties and PPS syntax. These flags set by the client must conform to the caps reported in `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS` and `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1`.
Also, the coded bitstream headers for the current frame where the associated syntax with these flags is used must match with the ones set when recording EncodeFrame for the current frame.<!-- d3d12-review-inline:end:video-encoding-codecs:S03-010:1 --></ins>

<a id="source-s03-011"></a>

### D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-011:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data-hevc1).<!-- d3d12-review-inline:end:video-encoding-codecs:S03-011:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-011:1 -->The additional parameters must conform the codec spec, the flags in `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS` and `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC_FLAGS1` as well as any driver cap limitations exposed by `D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION_SUPPORT_HEVC1`.<!-- d3d12-review-inline:end:video-encoding-codecs:S03-011:1 --></ins>

<!-- d3d12-review-context:begin:video-encoding-codecs:S03-011:2 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

> For any codecs/configurations where the QP ranges can be negative, the ranges used by `pRateControlQPMap` as absolute map parameter are kept in that native signed range. For example for HEVC `[0, 51]` range for 8 bit pixel depth, the range for 10 bits `[-12, 51]`, and similar for higher bit depths such as `[-24, 51]` for 12 bits or `[-48, 51]` for 16 bits are all considered as-is signed from the contract.

<!-- d3d12-review-context:end:video-encoding-codecs:S03-011:2 -->

<a id="source-s03-012"></a>

### D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-012:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data).<!-- d3d12-review-inline:end:video-encoding-codecs:S03-012:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-012:1 -->For the higher HEVC profiles, the app must ensure support by calling `D3D12_FEATURE_VIDEO_ENCODER_PROFILE_LEVEL` first and then use `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1` which contains the additional parameters to use the associated profile features.<!-- d3d12-review-inline:end:video-encoding-codecs:S03-012:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-012:2 -->On the original picture-control path, Main/Main10 use `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC`; the higher profiles use HEVC1. The version-1 picture-control union selects HEVC2 for HEVC, including both 4:2:0 and 4:2:2/4:4:4 profiles.<!-- d3d12-review-inline:end:video-encoding-codecs:S03-012:2 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S03-012:3 -->The `ID3D12VideoEncodeCommandList4::EncodeFrame1` path uses HEVC2; the original `EncodeFrame` picture-control path remains supported and unchanged.<!-- d3d12-review-inline:end:video-encoding-codecs:S03-012:3 --></ins>

<a id="family-hevc-referencelistextension"></a>

## HEVC2 complete temporary reference lists

<!-- d3d12-review-alert:begin:video-encoding-codecs:qualification-HEVC_ReferenceListExtension:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **HEVC2 qualification.** This section applies only to HEVC2 through the
> version-1 picture-control path. Older HEVC/HEVC1 and H.264 retain their
> previous list-count interpretation. Published complete-list construction and
> validation requirements are retained; the bounded recording wrapper shows a
> legacy-driver conversion, not universal hardware support for every HEVC2 list.
> The limits on active reference lists apply to `num_ref_idx_lx_active_minus1 + 1`,
> not to the length of the complete `RefPicListTempX` list.

<!-- d3d12-review-alert:end:video-encoding-codecs:qualification-HEVC_ReferenceListExtension:0 -->

<a id="source-s09-000"></a>

### D3D12 Video Encoding HEVC Reference List Extension

**Overview**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-000:1 -->In some complex reference picture usage scenarios, the legacy HEVC/HEVC1 [D3D12_Video_Encoding_H264_HEVC](video-encoding-codecs.md#family-h264-hevc) API doesn't expose the necessary information to the driver to code reference information in the bitstream accurately. On that legacy path, the application sends `pList0ReferenceFrames` and `pList1ReferenceFrames` corresponding to `RefPicListTemp0` and `RefPicListTemp1` from the HEVC standard, but capping the `List0ReferenceFramesCount` and `List1ReferenceFramesCount` corresponding array lengths to the driver reported limits `MaxLXReferencesForY` in `D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_HEVC`. There is also an assumption that `num_ref_idx_l0_active_minus1 + 1` and `num_ref_idx_l1_active_minus1 + 1` correspond to `List0ReferenceFramesCount` and `List1ReferenceFramesCount` respectively.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-000:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-000:2 -->The HEVC2 picture parameters extend the existing HEVC picture parameters `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC` and `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC1` from [D3D12_Video_Encoding_H264_HEVC](video-encoding-codecs.md#family-h264-hevc) and [D3D12_Video_Encoding_HEVC_422_444](video-encoding-codecs.md#family-hevc-422-444) to extend the information the app passes the driver to solve this limitation. The structure `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2` can be used for 420 profiles as well as for 422/444 HEVC profiles.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-000:2 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-000:3 -->Please note that similar rules that apply to H264 are **not** changed by this contract. The changes here only apply to HEVC, and only apply when using the version-1 picture-control path with `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2`. Previously existing retail API/DDI interfaces are kept unmodified for app back compat and driver should keep the prevailing HEVC rules from previous specs on that legacy path.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-000:3 --></ins>

<a id="source-s09-004"></a>

### HEVC2 picture-control payload

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-004:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA1`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data1).<!-- d3d12-review-inline:end:video-encoding-codecs:S09-004:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-004:1 -->Released declaration: [`D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2`](video-encoding-types.md#d3d12-video-encoder-picture-control-codec-data-hevc2).<!-- d3d12-review-inline:end:video-encoding-codecs:S09-004:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-004:2 -->Unlike HEVC1, HEVC2 carries explicit `num_ref_idx_l0_active_minus1` and `num_ref_idx_l1_active_minus1` values for the active-list counts.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-004:2 --></ins>

**Remarks**

1. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-004:4 -->`pReferenceFramesReconPictureDescriptors` remains as defined in [D3D12_Video_Encoding_H264_HEVC](video-encoding-codecs.md#family-h264-hevc). This still includes the complete DPB snapshot from the app to the driver as usual, including frames not used in current frame, etc. The app can send up to 16 entries here (up to 15 refs + curr pic). The current picture entry can be ignored by the driver if not needed.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-004:4 --></ins>

2.	<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-004:4 -->`pList0ReferenceFrames` corresponds to `RefPicListTemp0` (as per HEVC codec standard). The app must build and pass the *complete* list built as per HEVC codec standard by extracting `RefPicSetStCurrBefore`, `RefPicSetStCurrAfter` and `RefPicSetLtCurr` from `pReferenceFramesReconPictureDescriptors`. Previously defined in [D3D12_Video_Encoding_H264_HEVC](video-encoding-codecs.md#family-h264-hevc), this list was already generated from the RPS like `RefPicListTemp0` but capped to `D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_HEVC.MaxL0ReferencesForP/B` length before passing in the picture params to the driver.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-004:4 --></ins>

    > Note that `pps_curr_pic_ref_enabled_flag` will always be false (since `pps_scc_extension` is not supported in D3D12), so `RefPicListTemp0` will not have the current pic.

3.	<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-004:4 -->`pList1ReferenceFrames` corresponds to `RefPicListTemp1` (as per HEVC codec standard). The app must build and pass the *complete* list built as per HEVC codec standard by extracting `RefPicSetStCurrAfter`, `RefPicSetStCurrBefore` and `RefPicSetLtCurr` from `pReferenceFramesReconPictureDescriptors`. Previously defined in [D3D12_Video_Encoding_H264_HEVC](video-encoding-codecs.md#family-h264-hevc), this list was already generated from the RPS like `RefPicListTemp1` but capped to `D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_HEVC.MaxL1ReferencesForB` length before passing in the picture params to the driver.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-004:4 --></ins>

    > Note that `pps_curr_pic_ref_enabled_flag` will always be false (since `pps_scc_extension` is not supported in D3D12), so `RefPicListTemp0` will not have the current pic.

4. `pList0RefPicModifications`/`pList1RefPicModifications`/`List0RefPicModificationsCount`/`List1RefPicModificationsCount` do not change.

5. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-004:4 -->The parameter `num_ref_idx_l0_active_minus1` (+1 on the minus1) corresponds to the final `RefPicList0` (as per HEVC codec standard) length.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-004:4 --></ins>
    > The previously existing assumption that `num_ref_idx_l0_active_minus1 + 1` and `num_ref_idx_lx_default_active_minus1 + 1` was given by `List0ReferenceFramesCount` is replaced by this explicit parameter.

6. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-004:4 -->The parameter `num_ref_idx_l1_active_minus1` (+1 on the minus1) corresponds to the final `RefPicList1` (as per HEVC codec standard) length.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-004:4 --></ins>
    > The previously existing assumption that `num_ref_idx_l1_active_minus1 + 1` and `num_ref_idx_lx_default_active_minus1 + 1` was given by `List1ReferenceFramesCount` is replaced by this explicit parameter.

7. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-004:4 -->Using `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC_FLAG_REQUEST_NUM_REF_IDX_ACTIVE_OVERRIDE_FLAG_SLICE` uses the `num_ref_idx_l0_active_minus1` and `num_ref_idx_l1_active_minus1` params instead of `List0ReferenceFramesCount`/`List1ReferenceFramesCount` respectively.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-004:4 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-004:5 -->The rest of the `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2` does not change respect to [D3D12_Video_Encoding_H264_HEVC](video-encoding-codecs.md#family-h264-hevc) and [D3D12_Video_Encoding_HEVC_422_444](video-encoding-codecs.md#family-hevc-422-444).<!-- d3d12-review-inline:end:video-encoding-codecs:S09-004:5 --></ins>

<a id="source-s09-006"></a>

### Interpretation of D3D12_VIDEO_ENCODER_CODEC_PICTURE_CONTROL_SUPPORT_HEVC

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-006:0 -->The following changes only apply when using version-1 picture-control path with `D3D12_VIDEO_ENCODER_PICTURE_CONTROL_CODEC_DATA_HEVC2`. Previously existing interfaces are kept unmodified for app back compat and driver should keep the prevailing HEVC rules from previous specs on that legacy path.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-006:0 --></ins>

<!-- d3d12-review-context:begin:video-encoding-codecs:S09-006:1 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**

> The previously existing assumption that `MaxLXReferencesForY` limits `ListXReferenceFramesCount` for `Y` frame types is now replaced by `MaxLXReferencesForY` limiting `num_ref_idx_lx_active_minus1 + 1` for `Y` frame types.

<!-- d3d12-review-context:end:video-encoding-codecs:S09-006:1 -->

*MaxL0ReferencesForP*

MaxL0ReferencesForP corresponds to the maximum value allowed in the slice headers and picture control parameters for (`num_ref_idx_l0_active_minus1` +1) when encoding P frames – This is equivalent to the maximum size of the final `RefPicList0` (as per HEVC codec standard) for a P frame supported.

*MaxL0ReferencesForB*

MaxL0ReferencesForB corresponds to the maximum value allowed in the slice headers and picture control parameters for (`num_ref_idx_l0_active_minus1` +1) when encoding B frames – This is equivalent to the maximum size of the final `RefPicList0` (as per HEVC codec standard) for a B frame supported.

*MaxL1ReferencesForB*

MaxL1ReferencesForB corresponds to the maximum value allowed in the slice headers and picture control parameters for (`num_ref_idx_l1_active_minus1` +1) when encoding B frames – This is equivalent to the maximum size of the final `RefPicList1` (as per HEVC codec standard) for a B frame supported.

*MaxDPBCapacity*

MaxDPBCapacity should be the maximum number of unique pictures that can be used from the DPB the user manages (number of unique indices in final `RefPicList0` union final `RefPicList1`) for a given EncodeFrame command on the underlying HW.

<a id="source-s09-007"></a>

### D3D12 runtime validations

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-007:0 -->**Source-only validation requirements:** the published HEVC2 requirements follow; the retained wrapper trace does not establish every validation or error-timing path. For the older interfaces, where `ListXReferenceFramesCount` matches `num_ref_idx_lX_active_minus1 + 1`, the legacy validation rules are unchanged.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-007:0 --></ins>

1. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-007:1 -->For HEVC2, `Count(Distinct(UnionSet(RefPicList0, RefPicList1))) <= MaxDPBCapacity`, using the final active lists built from the complete `pListXReferenceFrames` temporary lists and explicit `num_ref_idx_lX_active_minus1` values. On legacy HEVC/HEVC1, the capacity check instead uses the union of `pList0ReferenceFrames` and `pList1ReferenceFrames`, whose lengths supply the active counts. The HEVC2 active-list capacity limit is not a limit on complete temporary-list lengths.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-007:1 --></ins>

2. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-007:1 -->The D3D12 runtime currently also validates that `Count(Distinct(UnionSet(pList0ReferenceFrames, pList1ReferenceFrames)))` is equal to the number of elements in `pReferenceFramesReconPictureDescriptors` with `IsRefUsedByCurrentPic = true`. This snapshot/list consistency requirement ensures that the count of DPB snapshot entries with `IsRefUsedByCurrentPic = true` matches the `RefPicSetStCurrBefore`, `RefPicSetStCurrAfter`, `RefPicSetLtCurr` from which the `RefPicListTempX` (passed as `pListXReferenceFrames`) were generated.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-007:1 --></ins>

3. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-007:1 -->`num_ref_idx_l0_active_minus1 >= 0` for P frames. `num_ref_idx_l0_active_minus1 >= 0` and `num_ref_idx_l1_active_minus1 >= 0` for B frames.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-007:1 --></ins>

4. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-007:1 -->`num_ref_idx_l0_active_minus1 + 1 <= pCurCommandPicCtrlHEVC->List0ReferenceFramesCount`.<!-- d3d12-review-inline:end:video-encoding-codecs:S09-007:1 --></ins>

5. `num_ref_idx_l1_active_minus1 + 1 <= pCurCommandPicCtrlHEVC->List1ReferenceFramesCount`.

6. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-007:1 -->When `List0RefPicModificationsCount > 0`,  `List0RefPicModificationsCount` must equal `num_ref_idx_l0_active_minus1 + 1`<!-- d3d12-review-inline:end:video-encoding-codecs:S09-007:1 --></ins>

6. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S09-007:1 -->When `List1RefPicModificationsCount > 0`, `List1RefPicModificationsCount` must equal `num_ref_idx_l1_active_minus1 + 1`<!-- d3d12-review-inline:end:video-encoding-codecs:S09-007:1 --></ins>

<a id="family-av1"></a>

## AV1 capabilities, picture controls and post-encode records

<!-- d3d12-review-alert:begin:video-encoding-codecs:qualification-AV1:0 -->

> [!WARNING]
> **Authored synthesis - human review pending.**
>
> **AV1 qualification.** Published AV1 syntax, segmentation, reference-slot,
> tile and rate-control details below remain source-only. Several source
> expressions are not promoted to independently verified codec guarantees:
> the `obu_extension_flag` inference, the Altref/Altref2 ordering tables, the
> refresh-slot example's one-based-versus-zero-based labels, and the original
> eight-slot DPB versus compact resource-count wording need codec-specialist
> reconciliation. `ReferenceIndices` has exactly seven elements; the DPB descriptor
> array has exactly eight. The seven reference-type entries use indices [0..6];
> their values select DPB slots [0..7]. There are no released
> public API macros for the source's unused-DPB sentinel or super-resolution
> minimum: the source values 255 and 9 are written as literals here.
> Fields absent from the released picture structure are not independent inputs.

<!-- d3d12-review-alert:end:video-encoding-codecs:qualification-AV1:0 -->

<a id="source-s02-009"></a>

### D3D12_FEATURE_VIDEO

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-009:0 -->Encoding feature selectors and fixed query payloads are listed in the [encoding query reference](video-encoding-controls.md#encoding-query-selectors).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-009:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-009:1 -->**Members**<!-- d3d12-review-inline:end:video-encoding-codecs:S02-009:1 --></ins>

*D3D12_FEATURE_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG*

Used with struct D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG.

*D3D12_FEATURE_VIDEO_ENCODER_SUPPORT1*

Used with struct D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1.

<a id="source-s02-011"></a>

### D3D12_VIDEO_ENCODER_AV1_PROFILE

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-011:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_PROFILE`](video-encoding-types.md#d3d12-video-encoder-av1-profile).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-011:0 --></ins>

**Remarks**

Driver uses `D3D12_FEATURE_DATA_VIDEO_ENCODER_INPUT_FORMAT` to report optionally supported formats for a given input `D3D12_VIDEO_ENCODER_AV1_PROFILE` to the query.

When a format is supported, the API Client sets accordingly the related AV1 syntax elements based on the `DXGI_FORMAT` used: `color_config()`, `high_bitdepth`, `twelve_bit`, `mono_chrome`, `subsampling_x`, `subsampling_y`, etc.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-011:4 -->The `DXGI_FORMAT`s are consistent with the AV1 DXVA decode counterpart spec.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-011:4 --></ins>

- `D3D12_VIDEO_ENCODER_AV1_PROFILE_MAIN` allows driver reporting support for:
    - `DXGI_FORMAT_NV12` for 8-bit YUV 4:2:0
    - `DXGI_FORMAT_P010` for 10-bit YUV 4:2:0
    - `DXGI_FORMAT_R8_UNORM` for 8-bit monochrome
    - `DXGI_FORMAT_R16_UNORM` for 10-bit monochrome
- `D3D12_VIDEO_ENCODER_AV1_PROFILE_HIGH` also allows:
    - `DXGI_FORMAT_AYUV` for 8-bit YUV 4:4:4
    - `DXGI_FORMAT_Y410` for 10-bit YUV 4:4:4
- `D3D12_VIDEO_ENCODER_AV1_PROFILE_PROFESSIONAL` also allows:
    - `DXGI_FORMAT_YUY2` for 8-bit YUV 4:2:2
    - `DXGI_FORMAT_Y210` for 10-bit YUV 4:2:2
    - `DXGI_FORMAT_Y216` for 12-bit YUV 4:2:2
    - `DXGI_FORMAT_Y416` for 12-bit YUV 4:4:4
    - `DXGI_FORMAT_R16_UNORM` for 12-bit monochrome
    - `DXGI_FORMAT_R16_UNORM` for 12-bit monochrome
    - `DXGI_FORMAT_P016` for 12-bit YUV 4:2:0

<a id="source-s02-012"></a>

### D3D12_VIDEO_ENCODER_PROFILE_DESC

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-012:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_PROFILE_DESC`](video-encoding-types.md#d3d12-video-encoder-profile-desc).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-012:0 --></ins>

Generic structure for codec profiles.

<a id="source-s02-017"></a>

### D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-017:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE`](video-encoding-types.md#d3d12-video-encoder-frame-subregion-layout-mode).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-017:0 --></ins>

**Constants**

*D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_UNIFORM_GRID_PARTITION*

Allows the driver to *uniformly* partition the frame into a grid with only input from the API Client being number of rows and columns. Driver will return the heights and widths of each cell in the partitioned grid after the execution of the EncodeFrame command in resolved metadata buffer.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-017:4 -->For the AV1 codec, This corresponds to the AV1 spec syntax uniform_tile_spacing_flag equal to 1, when using D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_UNIFORM_GRID_PARTITION, tiles are uniformly partitioned except the right and bottom edges. When the dimensions cannot be partitioned exactly, the last tile can have smaller size.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-017:4 --></ins>

*D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_CONFIGURABLE_GRID_PARTITION*

Allows the API Client to *fully* customize a grid partition of the frame. API Client will pass a list of rows and columns along with the heights and widths of each cell in the partitioned grid in the EncodeFrame command and they have to be honored exactly.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-017:7 -->For the AV1 codec, this corresponds to uniform_tile_spacing_flag equal to 0 means that the tile sizes are coded.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-017:7 --></ins>

**Remarks**

For further tile support details, please check the associated tile details support cap D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG.

<a id="source-s02-019"></a>

### D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAGS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-019:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAGS`](video-encoding-types.md#d3d12-video-encoder-av1-feature-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-019:0 --></ins>

Reports encoding capabilities for AV1.

**Constants**

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_128x128_SUPERBLOCK*

Indicates if support is available for 128x128 Superblocks.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_FILTER_INTRA*

Indicates if support is available for Intra prediction filter.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_INTRA_EDGE_FILTER*

Indicates if support is available for intra edge filtering process.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_INTERINTRA_COMPOUND*

Indicates if support is available for interintra, where the mode info for inter blocks may contain the syntax element interintra. Equal to 0 specifies that the syntax element interintra will not be present.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_MASKED_COMPOUND*

Indicates if support is available for masked compound, where the mode info for inter blocks may contain the syntax element compound_type. Equal to 0 specifies that the syntax element compound_type will not be present.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_WARPED_MOTION*

Equal to 1 indicates that the syntax element motion_mode may be present. If equal to 0 indicates that the syntax element motion_mode will not be present (this means that LOCALWARP cannot be signaled if this flag is equal to 0).

Related to AV1 syntax enable_warped_motion in the sequence header.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_DUAL_FILTER*

Indicates if support is available for dual filter mode, where the inter prediction filter type may be specified independently in the horizontal and vertical directions. If the flag is equal to 0, only one filter type may be specified, which is then used in both directions.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_JNT_COMP*

Indicates if support is available for the scenario where distance weights process may be used for inter prediction.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_FORCED_INTEGER_MOTION_VECTORS*

Indicates if support is available for using the syntax element force_integer_mv.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_SUPER_RESOLUTION*

Indicates if support is available for super resolution.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_LOOP_RESTORATION_FILTER*

Indicates if support is available for loop restoration filtering.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_PALETTE_ENCODING*

Indicates if support is available for frame level control on palette encoding; Equal to 0 indicates that palette encoding is never used.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_CDEF_FILTERING*

Indicates if support is available for constrained directional enhancement filtering.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_INTRA_BLOCK_COPY*

Indicates if intra block copy is supported or not at frame level. Same syntax as AV1 spec.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_FRAME_REFERENCE_MOTION_VECTORS*

Indicates if support is available for use_ref_frame_mvs to be configured on a per frame basis. Equal to 0 specifies that use_ref_frame_mvs syntax element will not be used.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_ORDER_HINT_TOOLS*

Indicates if support is available for usage of tools based on the values of order hints. Equal to 0 indicates that tools based on order hints are not supported and can't be enabled.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_AUTO_SEGMENTATION*

Indicates if the driver can perform segmentation without API Client input and return segmentation_params() information in D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES.
Driver will write the segment map in the compressed bitstream.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_CUSTOM_SEGMENTATION*

Indicates if the driver supports the API Client passing customized segmentation segmentation_params() as well as the segment map and driver will honor exactly.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_LOOP_FILTER_DELTAS*

Indicates if the driver supports use of loop filter deltas. Related to _loop_filter_delta_enabled_ AV1 syntax in loop_filter_params().

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_QUANTIZATION_DELTAS*

Indicates if the driver supports use of quantization delta syntax.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_QUANTIZATION_MATRIX*

Indicates if the driver supports use of quantization matrix syntax.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_REDUCED_TX_SET*

Indicates if driver supports setting _reduced_tx_set_ in the frame header or must be always set to zero.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_MOTION_MODE_SWITCHABLE*

Indicates if driver supports setting _is_motion_mode_switchable_ in the frame header or must be always set to zero.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_ALLOW_HIGH_PRECISION_MV*

Indicates if driver supports setting _allow_high_precision_mv_ in the frame header or must be always set to zero.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_SKIP_MODE_PRESENT*

Indicates if driver supports setting _skip_mode_present_ in the frame header or must be always set to zero.

*D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_DELTA_LF_PARAMS*

Indicates if the driver supports use of loop filter delta params syntax. Related to _delta_lf_params()_ AV1 syntax.

<a id="source-s02-028"></a>

### D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-028:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE`](video-encoding-types.md#d3d12-video-encoder-av1-restoration-tilesize).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-028:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-028:1 -->Corresponds to the size of loop restoration units in units of samples in the current plane. The enum values are based on lr_unit_shift and lr_uv_shift in lr_params() AV1 syntax and the RESTORATION_TILESIZE_MAX(256) AV1 spec constant.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-028:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-028:2 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAGS`](video-encoding-types.md#d3d12-video-encoder-av1-restoration-support-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-028:2 --></ins>

<a id="source-s02-029"></a>

### D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-029:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION`](video-encoding-types.md#d3d12-video-encoder-av1-reference-warped-motion-transformation).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-029:0 --></ins>

**Constants**

*D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_IDENTITY*

Identity transformation. 0 parameters in D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO.

*D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_TRANSLATION*

Translational motion. 2 parameters in D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO.

*D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_ROTZOOM*

Simplified affine with rotation with zoom. 4 parameters in D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO.

*D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_AFFINE*

Affine transform. 6 parameters in D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO.

<a id="source-s02-030"></a>

### D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAGS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-030:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAGS`](video-encoding-types.md#d3d12-video-encoder-av1-reference-warped-motion-transformation-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-030:0 --></ins>

**Remarks**

If only D3D12_VIDEO_ENCODER_AV1_REFERENCE_WARPED_MOTION_TRANSFORMATION_FLAG_NONE is supported, reference warp motion arguments are ignored and AV1 _is_global_ syntax is false for all references.

<a id="source-s02-031"></a>

### D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAGS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-031:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAGS`](video-encoding-types.md#d3d12-video-encoder-av1-post-encode-values-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-031:0 --></ins>

Specifies for which AV1 encoding features, the underlying encoder is able to override (partially or totally) the associated AV1 syntax values or honor API Client exact configuration input otherwise.

When the bitflag is **SET** for a given feature, the driver receives the related API Client input and is able to override all or certain parameters of the associated structure with the given reported flag, which will then write back in D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES with the final values for the API Client to re-pack the AV1 headers accordingly. API Client can compare this to the associated input structure to determine the driver changes (if any).

When the bitflag is **NOT SET** for a given feature, the driver honors the related API Client input exactly and **copies** the input values in D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES. This way the client can always copy the post encode values to pack the headers directly.

**Constants**

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_QUANTIZATION*

Related to D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_CONFIG values. Used to code _quantization_params()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_QUANTIZATION_DELTA*

Related to D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_DELTA_CONFIG values. Used to code _delta_q_params()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_LOOP_FILTER*

Related to D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_CONFIG values. Used to code AV1 syntax _loop_filter_params()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_LOOP_FILTER_DELTA*

Related to D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_DELTA_CONFIG values. Used to code AV1 syntax _delta_lf_params()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_CDEF_DATA*

Related to D3D12_VIDEO_ENCODER_AV1_CDEF_CONFIG values. Used to code AV1 syntax _cdef_params()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_CONTEXT_UPDATE_TILE_ID*

Related to *ContextUpdateTileId* element in D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES.
Used to code AV1 element syntax _context_update_tile_id_ in _tile_info()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_COMPOUND_PREDICTION_MODE*

Related to D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE values.

**Remarks**

* When API Client selects D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_COMPOUND_REFERENCE and this flag is set, the driver will return D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE in post encode values. The returned value must be used to code reference_select = 0 (SINGLE) or reference_select = 1 (COMPOUND) syntax accordingly.
* <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-031:20 -->When API Client selects D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_SINGLE_REFERENCE and this flag is set, the driver will return D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_SINGLE_REFERENCE and reference_select must be coded as 0 (SINGLE).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-031:20 --></ins>

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_PRIMARY_REF_FRAME*

Related to *PrimaryRefFrame* element in D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.
Used to code AV1 element syntax _primary_ref_frame_ in _uncompressed_header()_.

*D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_REFERENCE_INDICES*

When the flag is reported by the driver, the driver may reorder/remap (but not change the number of references) of the D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES.ReferenceIndices array output, based on the user input D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceIndices. Otherwise, driver must copy each array entry of this post encode output parameter as-is from D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceIndices.

API Client will write the picture header *ref_frame_idx* AV1 syntax from this output parameter.

<a id="source-s02-032"></a>

### D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-032:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT`](video-encoding-types.md#d3d12-video-encoder-av1-codec-configuration-support).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-032:0 --></ins>

**Members**

*SupportedFeatureFlags*

Output param. Indicates which features are supported for the codec. Supported features can be set or not by the API Client.

*RequiredFeatureFlags*

Output param. Indicates which features the driver **requires** to be set.

*SupportedInterpolationFilters*

Output parameter. Indicates which values can be selected on input parameters of type D3D12_VIDEO_ENCODER_AV1_INTERPOLATION_FILTERS.

*SupportedRestorationParams*

Output parameter. Indicates which values can be selected as input parameters for *FrameRestorationType* and *LoopRestorationPixelSize* in *D3D12_VIDEO_ENCODER_AV1_RESTORATION_CONFIG*.

The first array indexing corresponds to the restoration filter type:
| Index i in SupportedRestorationParams[i][j] | Filter type |
|--------------|-------------|
| 0 | SWITCHABLE |
| 1 | WIENER     |
| 2 | SGRPROJ    |

*Note the indexing of the filter types corresponds to D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE **minus 1** (skipping D3D12_VIDEO_ENCODER_AV1_RESTORATION_TYPE_DISABLED)*.

The second array indexing corresponds to the planes:
| Index j in SupportedRestorationParams[i][j] | Plane |
|--------------|-------------|
| 0 | Y plane |
| 1 | U plane |
| 2 | V plane |

The value returned in SupportedRestorationParams[i][j] is a bitflag mask indicating whether the i-th filter in the j-th plane is either:

1. Not supported indicated by SupportedRestorationParams[i][j] = D3D12_VIDEO_ENCODER_AV1_RESTORATION_SUPPORT_FLAG_NOT_SUPPORTED.
2. Supported with any of the D3D12_VIDEO_ENCODER_AV1_RESTORATION_TILESIZE as indicated by the combinable bit flags in SupportedRestorationParams[i][j].

*SupportedSegmentationModes*

Output parameter. Indicates which segmentation modes can be selected in D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_CONFIG.

*SupportedTxModes*

Output parameter. Indicates which values can be selected on input parameters of type D3D12_VIDEO_ENCODER_AV1_TX_MODE for different D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE.

**Note**: Driver must support at least 1 mode for each frame type (ie. mask value cannot be 0).

*SegmentationBlockSize*

Output parameter. Indicates the block size for the segment map.
This is both the for input blocks in D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MAP for custom segmentation or the block size of the segment map written in the compressed bitstream by the driver in auto segmentation.

*PostEncodeValuesFlags*

Specifies for which AV1 encoding features, the underlying encoder is able to override the associated AV1 syntax values or accept API Client configurable input exactly.

*MaxTemporalLayers*

Specifies the maximum number of temporal layers that can be supported.
The reported values must be in the range [1..MaxTemporalIdSupported + 1]. A reported value 1, there is no temporal scalability support.

*MaxSpatialLayers*

Specifies the maximum number of spatial layers that can be supported.
The reported values must be in the range [1..MaxSpatialIdSupported + 1]. A reported value 1, there is no spatial scalability support.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-032:28 -->`MaxTemporalIdSupported` and `MaxSpatialIdSupported` denote the corresponding codec-standard layer-ID limits, not API fields or public constants.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-032:28 --></ins>

<a id="source-s02-036"></a>

### D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-036:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE`](video-encoding-types.md#d3d12-video-encoder-av1-comp-prediction-type).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-036:0 --></ins>

**Constants**

*D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_SINGLE_REFERENCE*

Indicates that all inter blocks will use single prediction. Equivalent to AV1 syntax _reference_select_ equal to 0.

*D3D12_VIDEO_ENCODER_AV1_COMP_PREDICTION_TYPE_COMPOUND_REFERENCE*

Indicates that the mode info for inter blocks contains the syntax element comp_mode that indicates whether to use single or compound reference prediction. Equivalent to AV1 syntax _reference_select_ equal to 1.

<a id="source-s02-037"></a>

### D3D12_VIDEO_ENCODER_CODEC_AV1_PICTURE_CONTROL_SUPPORT

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-037:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_CODEC_AV1_PICTURE_CONTROL_SUPPORT`](video-encoding-types.md#d3d12-video-encoder-codec-av1-picture-control-support).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-037:0 --></ins>

**Members**

*PredictionMode*

Input param. The requested prediction mode to be used. The driver must return the output parameters below assuming a frame will be encoded using this prediction mode in the picture params structure.

*MaxUniqueReferencesPerFrame*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-037:5 -->Output param. Indicates how many unique reference frames in the DPB can be selected at the same time for a given frame from any of the reference types (LAST, ..., ALTREF, etc) in the picture control parameters from the DPB that the API Client manages. In other words, the maximum number distinct (and with ReconstructedPictureResourceIndex != 0xFF) entries in D3D12_VIDEO_ENCODE_REFERENCE_FRAMES.ppTexture2Ds[ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]].ReconstructedPictureResourceIndex] for i in [0..6].<!-- d3d12-review-inline:end:video-encoding-codecs:S02-037:5 --></ins>

*SupportedFrameTypes*

Output param. Indicates the supported frame types to be used in D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE.

*SupportedReferenceWarpedMotionFlags*

Output param. Indicates the supported types to be used in D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO.TransformationType.

<a id="source-s02-039"></a>

### D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-039:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION`](video-encoding-types.md#d3d12-video-encoder-av1-codec-configuration).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-039:0 --></ins>

**Members**

*FeatureFlags*

Defines the set of enabled features. Flags can be combined based on the reported capabilities/requirements by the driver.

<a id="source-s02-040"></a>

### D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAGS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-040:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAGS`](video-encoding-types.md#d3d12-video-encoder-av1-frame-subregion-layout-config-validation-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-040:0 --></ins>

**Constants**

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_NONE*

No flags.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_NOT_SPECIFIED*

When this flag is set, indicates that the requested tiles configuration is not supported due to a reason not specified by any of the other flag categories.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_CODEC_CONSTRAINT*

When this flag is set, indicates that the requested tiles configuration is not supported due to codec constraints. An example on this for AV1 would be D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG.Level.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_HARDWARE_CONSTRAINT*

When this flag is set, indicates that the requested tiles configuration is not supported due to hardware constraints.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_ROWS_COUNT*

When this flag is set, indicates that the number of tile rows requested is not supported.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_COLS_COUNT*

When this flag is set, indicates that the number of tile columns requested is not supported.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_WIDTH*

When this flag is set, indicates that one or more tiles widths in the requested configuration is not supported.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_AREA*

When this flag is set, indicates that one or more tiles areas in the requested configuration is not supported.

*D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_VALIDATION_FLAG_TOTAL_TILES*

When this flag is set, indicates that the total number of tiles in the requested partition exceeds the total supported tiles count. Please see D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.MaxSubregionsNumber.

<a id="source-s02-041"></a>

### D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-041:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT`](video-encoding-types.md#d3d12-video-encoder-av1-frame-subregion-layout-config-support).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-041:0 --></ins>

**Members**

*Use128SuperBlocks*

Input parameter. Indicates if the returned values by the driver in superblock units need to be expressed as 128x128 superblocks.
Otherwise the superblock default size 64x64 must be used.

*TilesConfiguration*

Input parameter. Desired tile configuration to check support for.

*ValidationFlags*

Output parameter. Indicates more details when D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG.IsSupported is false.

*MinTileRows*

Output parameter. Minimum number of horizontal partitions.

*MaxTileRows*

Output parameter. Maximum number of horizontal partitions.

*MinTileCols*

Output parameter. Minimum number of vertical partitions.

*MaxTileCols*

Output parameter. Maximum number of vertical partitions.

*MinTileWidth*

Output parameter. Minimum width of any tile, in superblock units.

*MaxTileWidth*

Output parameter. Maximum width of any tile, in superblock units.

*MinTileArea*

Output parameter. Minimum dimension of any tile, in superblock units.

*MaxTileArea*

Output parameter. Maximum dimension of any tile, in superblock units.

*TileSizeBytesMinus1*

Output parameter. Specifies the number of bytes needed to code each tile size. Related to the driver writing the D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA.bSize elements in the resolved metadata.
The API Client will write **tile_size_bytes_minus_1 = (TileSizeBytesMinus1)** in frame_header_obu/uncompressed_header/tile_info when writing the frame header OBU, and when writing *le(TileSizeBytes)* **tile_size_minus_1** in **tile_group_obu()**.

<a id="source-s02-043"></a>

### D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-043:0 -->Released declaration: [`D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG`](video-encoding-types.md#d3d12-feature-data-video-encoder-frame-subregion-layout-config).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-043:0 --></ins>

**Remarks**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-043:2 -->At the moment, this support query is only supported for input Codec == D3D12_VIDEO_ENCODER_CODEC_AV1, as it can only be compiled with CodecSupport.pAV1Support pointer of type D3D12_VIDEO_ENCODER_AV1_FRAME_SUBREGION_LAYOUT_CONFIG_SUPPORT.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-043:2 --></ins>

**Members**

*NodeIndex*

Input parameter. in multi-adapter operation, this indicates which physical adapter of the device this operation applies to.

*Codec*

Input parameter. Desired codec to check support for.

*Profile*

Input parameter, desired profile to check support for.

*Level*

Input parameter, desired level to check support for.

*SubregionMode*

Input parameter. Desired subregion mode to check support for.

*FrameResolution*

Input parameter. Indicates the resolution to check support for.

*CodecSupport*

Input/Output parameter. Indicates the codec specific input/output arguments for this cap.

*IsSupported*

Output parameter. Indicates if the driver supports this subregion layout configuration based on the input values, including the codec, profile, level, resolution and any other codec specific parameters.

<a id="source-s02-045"></a>

### D3D12_VIDEO_ENCODER_VALIDATION_FLAGS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-045:0 -->`D3D12_VIDEO_ENCODER_VALIDATION_FLAG_SUBREGION_LAYOUT_DATA_NOT_SUPPORTED` reports invalid subregion configuration in SUPPORT1 and SUPPORT2.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-045:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-045:1 -->Released declaration: [`D3D12_VIDEO_ENCODER_VALIDATION_FLAGS`](video-encoding-types.md#d3d12-video-encoder-validation-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-045:1 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-045:2 -->*Constants*<!-- d3d12-review-inline:end:video-encoding-codecs:S02-045:2 --></ins>

*D3D12_VIDEO_ENCODER_VALIDATION_FLAG_SUBREGION_LAYOUT_DATA_NOT_SUPPORTED*

When using D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1, indicates the subregions configuration passed was not valid. Please use D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG for more information. D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.MaxSubregionsNumber and D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.SubregionBlockPixelsSize still must be reported when driver issues no support result in D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1.

<a id="source-s02-046"></a>

### D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-046:0 -->Extends on the previous D3D12_FEATURE_VIDEO_ENCODER_SUPPORT query, adding additional parameters at the bottom of the associated data structure. This query can be used with all H264, HEVC and AV1 codecs and must behave exactly as D3D12_FEATURE_VIDEO_ENCODER_SUPPORT semantics.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-046:0 --></ins>

Please note the previous D3D12_FEATURE_VIDEO_ENCODER_SUPPORT **will not work for AV1 codec** as *Codec* input, and attempting to call it for AV1 will still return S_OK with **ValidationFlags=D3D12_VIDEO_ENCODER_VALIDATION_FLAG_CODEC_NOT_SUPPORTED** and print a debug layer message indicating to instead use the new D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1 instead.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-046:2 -->Released declaration: [`D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1`](video-encoding-types.md#d3d12-feature-data-video-encoder-support1).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-046:2 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-046:3 -->*Members*<!-- d3d12-review-inline:end:video-encoding-codecs:S02-046:3 --></ins>

*SubregionFrameEncodingData*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-046:5 -->Used to calculate D3D12_FEATURE_DATA_VIDEO_ENCODER_SUPPORT1.SuggestedLevel in codecs that have subregions constraints per level and used for related validation with D3D12_VIDEO_ENCODER_VALIDATION_FLAG_SUBREGION_LAYOUT_DATA_NOT_SUPPORTED.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-046:5 --></ins>

*MaxQualityVsSpeed*

Reported by driver. Used as the maximum value allowed for the `QualityVsSpeed` parameter in the rate control structures. When `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_QUALITY_VS_SPEED_AVAILABLE` is not reported, this value must be reported as zero.

<a id="source-s02-047"></a>

### D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-047:0 -->Released declaration: [`D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS`](video-encoding-types.md#d3d12-feature-data-video-encoder-resolution-support-limits).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-047:0 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-047:1 -->The following member semantics apply to AV1.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-047:1 --></ins>

*Members*

*MaxSubregionsNumber*

Indicates the maximum number of tiles supported by the hardware for the associated resolution.

*SubregionBlockPixelsSize*

Indicates the tiles block sizes in pixels for the associated resolution. This value must be equal or a multiple of the superblock size, which is passed in the input D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION parameter.

*QPMapRegionPixelsSize*

Indicates for the associated resolution, the size in pixels of the squared regions that will be affected by each of the values in the QP map buffer in absolute or delta QP modes. The resolution of the frame will be rounded up to be aligned to this value when it's partitioned in blocks for QP maps and the number of QP values in those maps will be the number of blocks of these indicated pixel size that comprise a full frame. This value must be equal or a multiple of the superblock size, which is passed in the input D3D12_VIDEO_ENCODER_CODEC_CONFIGURATION parameter.

<a id="source-s02-048"></a>

### D3D12_VIDEO_ENCODER_AV1_SEQUENCE_STRUCTURE

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-048:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_SEQUENCE_STRUCTURE`](video-encoding-types.md#d3d12-video-encoder-av1-sequence-structure).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-048:0 --></ins>

This is a hint to the driver of the GOP being used for rate control purposes only.

**Members**

*IntraDistance*

Indicates the distance between intra-only frames (or key frames) in the video sequence, or the number of pictures on a sequence of inter-frame pictures. If set to 0, only the first frame will be an key-frame.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-048:5 -->*InterFramePeriod*<!-- d3d12-review-inline:end:video-encoding-codecs:S02-048:5 --></ins>

Indicates the period for inter-frames to be inserted within the inter frame structure. Note that if *IntraDistance* is set to 0 for infinite inter frame structure, this value must be greater than zero.

<a id="source-s02-053"></a>

### Driver/host header coding responsibilities

Given an encoded frame with K tiles, the driver will write the K **decode_tile()** AV1 syntax elements in the compressed bitstream, corresponding to the requested tiles in EncodeFrame arguments.

The API Client then builds the tile_group_obu() AV1 syntax elements with tile_start_and_end_present_flag/tg_start/tg_end elements to arrange the tiles into tile groups as desired with the condition that the tiles are placed sequentially. The tile_size_minus_1 element is coded from the related tile D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA information and decode_tile() elements are copied from the compressed bitstream buffer. Finally, each tile_group_obu() is wrapped around open_bitstream_unit() elements of type OBU_TILE_GROUP and prepended with an OBU_FRAME_HEADER, or in case of a single tile group an OBU_FRAME type can be used.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-053:2 -->The application codes OBU extension and temporal/spatial layer syntax consistently with the configured layers. The source's boolean inference for `obu_extension_flag` is withheld pending codec-specialist reconciliation.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-053:2 --></ins>

The EncodeFrame submissions are in encode order, like the other codecs implemented in D3D12 Encode API.

<a id="source-s02-054"></a>

### Resolution changes and spatial scalability

If D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RESOLUTION_RECONFIGURATION_AVAILABLE is reported by the driver, this still only applies to resolution changes **on a key frame**.

The active sequence header must have the max_frame_*_minus_1
syntax set to the max resolution present in the associated *ID3D12VideoEncoderHeap* being used, and different frames using resolutions also present in the associated *ID3D12VideoEncoderHeap* can use th AV1 syntax _frame_size_override_flag_ in frame_size() to convey change of resolution.

If D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_FLAG_SWITCH_FRAME is supported, the reference frames must point to higher or equal resolution than the current switch frame being encoded and the different resolutions must be all present in the associated *ID3D12VideoEncoderHeap* being used.

Similarly, if spatial scalability is supported, the different resolutions of the reference frames must be all present in the associated *ID3D12VideoEncoderHeap* being used.

<a id="source-s02-055"></a>

### Rate control notes

The accepted range for D3D12_VIDEO_ENCODER_RATE_CONTROL_QVBR.ConstantQualityTarget is [0..63]. The lowest the value, the highest the quality.

In general, `D3D12_VIDEO_ENCODER_SUPPORT_FLAG_RATE_CONTROL_RECONFIGURATION_AVAILABLE` applies to the quality vs speed tweaking and the following RC parameters of the different RC modes: QP in constant QP, bitrates and quality levels in CBR, VBR and QVBR. Driver can return `D3D12_VIDEO_ENCODER_ENCODE_ERROR_FLAG_RECONFIGURATION_REQUEST_NOT_SUPPORTED` in `D3D12_VIDEO_ENCODER_OUTPUT_METADATA.EncodeErrorFlags` for other unsupported RC params reconfiguration.

<a id="source-s02-057"></a>

### D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-057:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_WARPED_MOTION_INFO`](video-encoding-types.md#d3d12-video-encoder-av1-reference-picture-warped-motion-info).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-057:0 --></ins>

**Remarks**

Related to warped motion transformation/global motion type. Transform to be applied to motion vectors.

<a id="source-s02-058"></a>

### D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_DESCRIPTOR

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-058:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_REFERENCE_PICTURE_DESCRIPTOR`](video-encoding-types.md#d3d12-video-encoder-av1-reference-picture-descriptor).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-058:0 --></ins>

**Members**

*ReconstructedPictureResourceIndex*

Maps the current reference picture described by this structure to a resource in the D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames array.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-058:4 -->If the associated slot in ReferenceFramesReconPictureDescriptors containing this structure has a valid *ReconstructedPictureResourceIndex* reference to the D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames array then the allowed range of values is [0..254]. Otherwise, if it corresponds to an empty/unused slot in the DPB, then the value must be set to 255.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-058:4 --></ins>

*TemporalLayerIndexPlus1*

Picture temporal layer index plus one of the previously encoded frame now used as reference.

*SpatialLayerIndexPlus1*

Picture spatial layer index plus one of the previously encoded frame now used as reference.

*FrameType*

The type of frame used to encode the described reference frame associated to this entry.

*WarpedMotionInfo*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-058:12 -->Global-motion parameters. Used only when the associated transformation is supported as reported by `D3D12_VIDEO_ENCODER_CODEC_AV1_PICTURE_CONTROL_SUPPORT.SupportedReferenceWarpedMotionFlags`; see the [API picture-control capability owner](#source-s02-037).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-058:12 --></ins>

*OrderHint*

The reference _ref_order_hint_ AV1 syntax. Even when reference order hints are not coded in the AV1 bitstream, *OrderHint* here must be set to the value used in D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.OrderHint for the previously encoded frame that is now being held as reference by this descriptor.
This information will hint the driver, in a frame type that allows frame references, which are from past frames and which are from future frames (in display order) when comparing against the current frame value of D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.OrderHint.

*PictureIndex*

The unique picture index of the previously encoded frame that is stored in this entry as a reference. This parameter is not related in any way to the AV1 standard syntax, but merely used for API client implementation tracking instead.

<a id="source-s02-059"></a>

### D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAGS

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-059:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAGS`](video-encoding-types.md#d3d12-video-encoder-av1-picture-control-flags).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-059:0 --></ins>

Defines the set of flags for the codec-specific picture control properties.

**Constants**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-059:3 -->*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_NONE*<!-- d3d12-review-inline:end:video-encoding-codecs:S02-059:3 --></ins>

No flags

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_ERROR_RESILIENT_MODE*

Related to error_resilient_mode AV1 syntax in frame header.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_DISABLE_CDF_UPDATE*

Related to AV1 syntax for disable_cdf_update.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_PALETTE_ENCODING*

Enables the usage of palette encoding for this frame.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_SKIP_MODE*

Related to AV1 syntax skip_mode_present. skip_mode element will be present for this frame if this flag is set. Please check support in AV1 query caps before enabling this feature.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_FRAME_REFERENCE_MOTION_VECTORS*

Related to AV1 syntax use_ref_frame_mvs. Equal to 1 specifies that motion vector information from a previous frame can be used when encoding the current frame. use_ref_frame_mvs equal to 0 specifies that this information will not be used.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_FORCE_INTEGER_MOTION_VECTORS*

Equal to 1 specifies that force_integer_mv may be enabled on a per frame basis. Equal to 0 specifies that force_integer_mv syntax element will not be used. Please check support in AV1 query caps before enabling this feature.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ALLOW_INTRA_BLOCK_COPY*

Indicates if intra block copy is supported or not at per frame basis. Related to allow_intrabc syntax in AV1 spec.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_USE_SUPER_RESOLUTION*

Related to AV1 syntax use_superres.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_DISABLE_FRAME_END_UPDATE_CDF*

Related to AV1 syntax disable_frame_end_update_cdf.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_AUTO*

Enables automatic (performed by driver without API Client input) segmentation for the current frame.
Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_AUTO_SEGMENTATION.
This flag must *not* be combined with D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM*

Enables customized segmentation with the API Client sending the driver segmentation config and segment map.
Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_CUSTOM_SEGMENTATION.
This flag must *not* be combined with D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_AUTO.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_WARPED_MOTION*

Related to AV1 syntax _allow_warped_motion_ to be coded in the frame header. Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_WARPED_MOTION.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_REDUCED_TX_SET*

Related to AV1 syntax _reduced_tx_set_. Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_REDUCED_TX_SET.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_MOTION_MODE_SWITCHABLE*

Related to AV1 syntax _is_motion_mode_switchable_. Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_MOTION_MODE_SWITCHABLE.

*D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ALLOW_HIGH_PRECISION_MV*

Related to AV1 syntax _allow_high_precision_mv_. Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_ALLOW_HIGH_PRECISION_MV.

<a id="source-s02-060"></a>

### D3D12_VIDEO_ENCODER_AV1_RESTORATION_CONFIG

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-060:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_RESTORATION_CONFIG`](video-encoding-types.md#d3d12-video-encoder-av1-restoration-config).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-060:0 --></ins>

**Remarks**

Related to AV1 syntax lr_params(). The array entries correspond to Y, U, V planes.

<a id="source-s02-061"></a>

### D3D12_VIDEO_ENCODER_AV1_SEGMENT_DATA

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-061:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_SEGMENT_DATA`](video-encoding-types.md#d3d12-video-encoder-av1-segment-data).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-061:0 --></ins>

**Members**

*EnabledFeatures*

Accepts a bit mask combination of values from D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE_FLAGS.

*FeatureValue*

For the enabled bit flags features in EnabledFeatures, the array FeatureValue is indexed by D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MODE - 1 for it's associated feature value.

<a id="source-s02-062"></a>

### D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_CONFIG

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-062:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_CONFIG`](video-encoding-types.md#d3d12-video-encoder-av1-segmentation-config).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-062:0 --></ins>

Related to AV1 syntax segmentation_params()

*NumSegments*

When using D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_AUTO and the driver writes it back on post encode values, NumSegments = 0 indicated that segmentation_enabled must be 0 in the frame header. Otherwise, the API client codes segmentation_params() in the frame header accordingly with the other parameters in this structure.

When using D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM, indicates the input number of segments.

<a id="source-s02-063"></a>

### D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MAP

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-063:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_SEGMENTATION_MAP`](video-encoding-types.md#d3d12-video-encoder-av1-segmentation-map).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-063:0 --></ins>

**Members**

*SegmentsMapByteSize*

Byte size of pSegmentsMap buffer.

*pSegmentsMap*

In raster order, contains the AV1 syntax segment_id between [0..7] for each block in the frame.
The block size is SegmentationBlockSize as reported by driver in D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT.

<a id="source-s02-064"></a>

### D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_CONFIG

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-064:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_CONFIG`](video-encoding-types.md#d3d12-video-encoder-codec-av1-loop-filter-config).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-064:0 --></ins>

Related to AV1 syntax loop_filter_params().

**Remarks**

AV1 syntax loop_filter_delta_update is derived from members as (UpdateRefDelta || UpdateModeDelta).

**Members**

*LoopFilterLevel*

Related to AV1 syntax loop_filter_level[0], loop_filter_level[1]

*LoopFilterLevelU*

Related to AV1 syntax loop_filter_level[2]

*LoopFilterLevelV*

Related to AV1 syntax loop_filter_level[3]

*LoopFilterSharpnessLevel*

Related to AV1 syntax loop_filter_sharpness

*LoopFilterDeltaEnabled*

Related to AV1 syntax loop_filter_delta_enabled. Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_LOOP_FILTER_DELTAS supported/enabled.

*UpdateRefDelta*

Bitmask related to AV1 syntax update_ref_delta. The i-th bit is associated with the `RefDeltas[i]` entry with i in range [0..7].

*RefDeltas*

Related to AV1 syntax loop_filter_ref_deltas.

*UpdateModeDelta*

Bitmask related to AV1 syntax update_mode_delta. The i-th bit is associated with the `ModeDeltas[i]` entry with i in range [0..1].

*ModeDeltas*

Related to AV1 syntax loop_filter_mode_deltas

<a id="source-s02-065"></a>

### D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_DELTA_CONFIG

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-065:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_CODEC_AV1_LOOP_FILTER_DELTA_CONFIG`](video-encoding-types.md#d3d12-video-encoder-codec-av1-loop-filter-delta-config).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-065:0 --></ins>

Related to AV1 syntax delta_lf_params().

**Members**

*DeltaLFPresent*

Related to AV1 syntax delta_lf_params(). Requires D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_DELTA_LF_PARAMS supported/enabled.

*DeltaLFMulti*

Related to AV1 syntax delta_lf_params()

*DeltaLFRes*

Related to AV1 syntax delta_lf_params()

<a id="source-s02-066"></a>

### D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_CONFIG

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-066:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_CONFIG`](video-encoding-types.md#d3d12-video-encoder-codec-av1-quantization-config).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-066:0 --></ins>

**Remarks**

* AV1 syntax separate_uv_delta_q will be coded as 1 always
* AV1 syntax diff_uv_delta can be inferred from below if U and V AC/DC components are the same.

**Members**

*BaseQIndex*

Related to AV1 syntax in quantization_params().

*YDCDeltaQ*

Related to AV1 syntax in quantization_params().

*UDCDeltaQ*

Related to AV1 syntax in quantization_params().

*UACDeltaQ*

Related to AV1 syntax in quantization_params().

*VDCDeltaQ*

Related to AV1 syntax in quantization_params().

*VACDeltaQ*

Related to AV1 syntax in quantization_params().

*UsingQMatrix*

Related to AV1 syntax in quantization_params().

*QMY*

Related to AV1 syntax in quantization_params().

*QMU*

Related to AV1 syntax in quantization_params().

*QMV*

Related to AV1 syntax in quantization_params().

<a id="source-s02-067"></a>

### D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_DELTA_CONFIG

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-067:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_CODEC_AV1_QUANTIZATION_DELTA_CONFIG`](video-encoding-types.md#d3d12-video-encoder-codec-av1-quantization-delta-config).
**Members**<!-- d3d12-review-inline:end:video-encoding-codecs:S02-067:0 --></ins>

*DeltaQPresent*

Related to AV1 syntax in delta_q_params().

*DeltaQRes*

Related to AV1 syntax in delta_q_params().

<a id="source-s02-068"></a>

### D3D12_VIDEO_ENCODER_AV1_CDEF_CONFIG

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-068:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_CDEF_CONFIG`](video-encoding-types.md#d3d12-video-encoder-av1-cdef-config).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-068:0 --></ins>

**Members**

*CdefBits*

Related to AV1 syntax in cdef_params().

*CdefDampingMinus3*

Related to AV1 syntax in cdef_params().

*CdefYPriStrength*

Related to AV1 syntax in cdef_params().

*CdefUVPriStrength*

Related to AV1 syntax in cdef_params().

*CdefYSecStrength*

Related to AV1 syntax in cdef_params().

*CdefUVSecStrength*

Related to AV1 syntax in cdef_params().

<a id="source-s02-069"></a>

### D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-069:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA`](video-encoding-types.md#d3d12-video-encoder-av1-picture-control-codec-data).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-069:0 --></ins>

**Constants**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-069:2 -->*Minimum enabled super-resolution denominator (9)*<!-- d3d12-review-inline:end:video-encoding-codecs:S02-069:2 --></ins>

As defined by the AV1 codec standard. Associated to SuperResDenominator param below.

**Members**

*Flags*

Configuration flags for this frame to be encoded.

*FrameType*

Sets the picture type. See D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE values.

*CompoundPredictionType*

Specifies whether single or compound prediction is used for the given frame.
Related to AV1 syntax _reference_select_.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-069:11 -->*TxMode*<!-- d3d12-review-inline:end:video-encoding-codecs:S02-069:11 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-069:12 -->Selects a transform mode reported in `SupportedTxModes` for the current `FrameType`.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-069:12 --></ins>

*InterpolationFilter*

InterpolationFilter to be used for inter prediction on the current frame, related to syntax interpolation_filter.

*FrameRestorationConfig*

Indicates the restoration config to be used.

*SuperResDenominator*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-069:18 -->Indicates the configuration for super resolution. Has to be greater or equal than 9 when super resolution is enabled.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-069:18 --></ins>

*OrderHint*

Current frame _order_hint_ AV1 syntax. For this API purposes, *OrderHint* must be always passed even when not coding the order hint in the AV1 bitstream, and it must reflect the display order of the frame.

*PictureIndex*

The unique picture index for this frame that will be used to uniquely identify it as a reference for future frames. This parameter is not related in any way to the AV1 standard syntax, but merely used for API client implementation tracking instead.

API Client should initialize this value at 0 for the first *D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_KEY_FRAME* and increment it by one on each subsequent frame until the next *D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_KEY_FRAME*, when it should be reset to zero and follow the same process.

Note: OrderHint cannot be used for this purpose as it has a max range of [0..2^(OrderHintBitsMinus1+1)], which can wrap around and not work as unique identifier of the frames and their references.

*TemporalLayerIndexPlus1*

Picture temporal layer index plus one. A value of zero indicates temporal scalability not used.
This value must be within the range [0..D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT.MaxTemporalLayers].

*SpatialLayerIndexPlus1*

Picture spatial layer index plus one. A value of zero indicates spatial scalability not used.
This value must be within the range [0..D3D12_VIDEO_ENCODER_AV1_CODEC_CONFIGURATION_SUPPORT.MaxSpatialLayers].

*ReferenceFramesReconPictureDescriptors*

Describes the current state snapshot of the **complete** (ie. including frames that are not used by current frame but used by future frames, etc) DPB buffer kept in D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames. The reference indices (ie. last, altref, etc) map from past/future references into this descriptors array. The AV1 codec allows up to 8 references in the DPB.

This array of descriptors, in turn, maps a reference picture for this frame into a resource index in the reconstructed pictures array D3D12_VIDEO_ENCODER_PICTURE_CONTROL_DESC.ReferenceFrames.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-069:32 -->The descriptor array has eight slots. The compact resource array's `NumTexture2Ds` follows the complete-DPB management rules; it is not the fixed descriptor-array length.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-069:32 --></ins>

*ReferenceIndices*

Corresponds to the *ref_frame_idx[i]* AV1 syntax. For a reference type *i*, ReferenceIndices[i] indicates an index between [0..7] into *ReferenceFramesReconPictureDescriptors* where the current frame i-th reference type is stored in the DPB. In other words *ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]]* contains the DPB descriptor for the i-th reference type.

The i-th entry of ReferenceIndices[] corresponds to each reference type as follows:

<!-- d3d12-review-alert:begin:video-encoding-codecs:S02-069:36 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | Index i | Reference type | ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]] |
> |-----------|------------|------------|
> | 0 | Last | DPB Descriptor for Last |
> | 1 | Last2 | DPB Descriptor for Last2 |
> | 2 | Last3 | DPB Descriptor for Last3 |
> | 3 | Golden | DPB Descriptor for Golden |
> | 4 | Bwdref | DPB Descriptor for Bwdref |
> | 5 | Source mapping withheld pending codec review | Source mapping withheld pending codec review |
> | 6 | Source mapping withheld pending codec review | Source mapping withheld pending codec review |

<!-- d3d12-review-alert:end:video-encoding-codecs:S02-069:36 -->

*PrimaryRefFrame*

Corresponds to the AV1 element syntax _primary_ref_frame_ in _uncompressed_header()_. Specifies which reference frame contains the CDF values and other state that must be loaded at the start of the frame. The allowed range is [0..7] and the values corresponds as follows:

<!-- d3d12-review-alert:begin:video-encoding-codecs:S02-069:39 -->

> [!WARNING]
> **Mixed source and authored adaptation - human review pending.**
>
> | PrimaryRefFrame value | AV1 syntax value (primary_ref_frame) | Reference frame selected |
> |--------|------------|------------|
> | 0 | 0 | Last |
> | 1 | 1 | Last2 |
> | 2 | 2 | Last3 |
> | 3 | 3 | Golden |
> | 4 | 4 | Bwdref |
> | 5 | Source mapping withheld pending codec review | Source mapping withheld pending codec review |
> | 6 | Source mapping withheld pending codec review | Source mapping withheld pending codec review |
> | 7 | 7 (PRIMARY_REF_NONE) | None |

<!-- d3d12-review-alert:end:video-encoding-codecs:S02-069:39 -->

*RefreshFrameFlags*

Corresponds to the *refresh_frame_flags* AV1 syntax element.

*QPMapValuesCount*

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-069:43 -->Contains the number of elements in `pRateControlQPMap`. This must match the number of coding blocks in the frame, rounding up the frame resolution to the closest aligned values.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-069:43 --></ins>

*LoopFilter*

Specifies the loop filter parameters.

*LoopFilterDelta*

Specifies the loop filter delta parameters. Related to _delta_lf_params_ AV1 syntax.

*Quantization*

Specifies the quantization parameters.

*QuantizationDelta*

Specifies the quantization delta parameters.

*CDEF*

Specifies the constrained directional enhancement filtering parameters.

*pRateControlQPMap*

Array containing in row/column scan order, the QP map values to use on each squared region for this frame.
The QP map dimensions can be calculated using the current resolution and D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.QPMapRegionPixelsSize conveying the squared region sizes.
The range for Delta QP values is [-255;255].

*CustomSegmentation*

Only used when D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM is set for current frame.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-069:58 -->*CustomSegmentsMap*<!-- d3d12-review-inline:end:video-encoding-codecs:S02-069:58 --></ins>

Only used when D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM is set for current frame.
Segment map to be used if CustomSegmentation.UpdateMap is set. Otherwise, the segment map is inherited from ref frame.

**Remarks**

*DPB Management expectations*

The following is the contract the API client and the driver must conform to when using this API:

1. <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-069:63 -->When encoding D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_KEY_FRAME:<!-- d3d12-review-inline:end:video-encoding-codecs:S02-069:63 --></ins>

    - PrimaryRefFrame must be 7 (PRIMARY_REF_NONE)

    - RefreshFrameFlags must be 0xFF (conforming to the AV1 codec standard bitstream syntax)

    - For all array entries in *ReferenceFramesReconPictureDescriptors*, *ReconstructedPictureResourceIndex* must be set to *Unused DPB resource index (255)*

    - The values in the seven *ReferenceIndices* entries (indices [0..6]) are indistinct as any value [0..7] will point to an unused DPB slot in *ReferenceFramesReconPictureDescriptors* as per the point above.

    - D3D12_VIDEO_ENCODE_REFERENCE_FRAMES will be filled as:

        - NumTexture2Ds = 0

        - ppTexture2Ds = NULL

        - pSubresources = NULL

2. When encoding a frame type with references (ie. SWITCH/INTER):

    - PrimaryRefFrame specifies which reference frame contains the CDF values and other state that must be loaded at the start of the frame.

    - RefreshFrameFlags must be set accordingly to indicate on which *ReferenceFramesReconPictureDescriptors* DPB slots the current encoded frame reconstructed picture will be placed after encoding execution. This value must match exactly what the API client will code for *refresh_frame_flags* AV1 syntax element in the associated picture header for the current frame.

    - The array entries in *ReferenceFramesReconPictureDescriptors* for the current frame will follow exactly what *RefreshFrameFlags* indicated for the previous frame.
    - The source's refresh-slot numbering example is withheld because its labels and array indices disagree; the complete-DPB and refresh-flag requirements remain applicable.
        - Note this includes considering RefreshFrameFlags=0xFF for *D3D12_VIDEO_ENCODER_AV1_FRAME_TYPE_KEY_FRAME* as well, by marking all ReferenceFramesReconPictureDescriptors entries pointing to the KEY frame reconstructed picture.
        - If a (non key frame) picture won't be marked with D3D12_VIDEO_ENCODER_PICTURE_CONTROL_FLAG_USED_AS_REFERENCE_PICTURE, their RefreshFrameFlags must be zero to indicate this.

    - The values in the seven *ReferenceIndices* entries (indices [0..6]) are within [0..7] and point to DPB slots in *ReferenceFramesReconPictureDescriptors*.
        - The values of the seven ReferenceIndices entries (indices [0..6]) must match exactly what the API client codes in the picture header for *ref_frame_idx*.
        - As per AV1 syntax definition of *ref_frame_idx* there is **no requirement** that the array entry values must be unique.
        - If ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]].
        ReconstructedPictureResourceIndex == 255
            - This indicates the reference picture i-th won't be used for the current frame and must be ignored.
        - Otherwise (Valid ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]].
        ReconstructedPictureResourceIndex)
            - This indicates the reference i-th will point to the DPB slot *ReferenceIndices[i]* and the reconstructed picture to be used is **D3D12_VIDEO_ENCODE_REFERENCE_FRAMES.ppTexture2Ds[ReferenceFramesReconPictureDescriptors[ReferenceIndices[i]].ReconstructedPictureResourceIndex]**

    - D3D12_VIDEO_ENCODE_REFERENCE_FRAMES will be filled as:

        - NumTexture2Ds = {number of **unique** values of *ReferenceFramesReconPictureDescriptors.ReconstructedPictureResourceIndex[j] != 255* for j in {0..7} }

        - ppTexture2Ds = { compact array (no null entries) containing the reconstructed picture from the previously encoded frames that will be used as references }

        - [Texture Array mode only] pSubresources = { compact array (no null entries) containing the subresource index of the texture array from the previously encoded frames that will be used as references }

3. When encoding a frame type without references but without clearing the DPB (ie. INTRA_ONLY)

    - PrimaryRefFrame must be 7 (PRIMARY_REF_NONE)

    - RefreshFrameFlags must be set accordingly to indicate on which *ReferenceFramesReconPictureDescriptors* DPB slots the current encoded frame reconstructed picture will be placed after encoding execution. This value must match exactly what the API client will code for *refresh_frame_flags* AV1 syntax element in the associated picture header for the current frame.

    - The array entries in *ReferenceFramesReconPictureDescriptors* for the current frame will follow exactly what *RefreshFrameFlags* indicated for the previous frame.

    - The values in the seven *ReferenceIndices* entries (indices [0..6]) are ignored as the intra-only frame doesn't use any references.

    - D3D12_VIDEO_ENCODE_REFERENCE_FRAMES contains the DPB snapshot and will be filled as:

        - NumTexture2Ds = {number of **unique** values of *ReferenceFramesReconPictureDescriptors.ReconstructedPictureResourceIndex[j] != 255* for j in {0..7} }

        - ppTexture2Ds = { compact array (no null entries) containing the reconstructed picture from the previously encoded frames referred to by ReferenceFramesReconPictureDescriptors.ReconstructedPictureResourceIndex[j] for j in {0..7} }

        - [Texture Array mode only] pSubresources = { compact array (no null entries) containing the subresource index of the texture array from the previously encoded frames referred to by ReferenceFramesReconPictureDescriptors.ReconstructedPictureResourceIndex[j] for j in {0..7} }

<a id="source-s02-071"></a>

### D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-071:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES`](video-encoding-types.md#d3d12-video-encoder-av1-picture-control-subregions-layout-data-tiles).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-071:0 --></ins>

**Remarks**

This operates in different ways using different D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE configurations.

For D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_CONFIGURABLE_GRID_PARTITION,

* Input parameters: RowCount, ColCount, RowHeights, ColWidths within the reported tile caps. The integer values must match the AV1 codec standard expectations (ie. power of two, etc).
* Driver honors exactly and copies the exact same structure after EncodeFrame execution.

For D3D12_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_MODE_UNIFORM_GRID_PARTITION
* Input parameters: RowCount, ColCount. The integer values must match the AV1 codec standard expectations (ie. power of two, etc).
* Driver copies RowCount/ColCount as passed by API Client, and returns also RowHeights, ColWidths after EncodeFrame execution.

For ContextUpdateTileId, is an input parameter from the API Client corresponding to the frame header context_update_tile_id AV1 syntax and if D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_CONTEXT_UPDATE_TILE_ID was reported then the driver is able to overwrite the API client input after EncodeFrame execution, otherwise must be copied by the driver from the input to the post encode values.

**Constants**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-071:7 -->*D3D12_VIDEO_ENCODER_AV1_MAX_TILE_ROWS*<!-- d3d12-review-inline:end:video-encoding-codecs:S02-071:7 --></ins>

As defined in the AV1 codec standard.

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-071:9 -->*D3D12_VIDEO_ENCODER_AV1_MAX_TILE_COLS*<!-- d3d12-review-inline:end:video-encoding-codecs:S02-071:9 --></ins>

As defined in the AV1 codec standard.

**Members**

*RowCount*

Number of tile rows.

*ColCount*

Number of tile cols.

*RowHeights*

Heights of tile rows.

*ColWidths*

Widths of tile cols.

*ContextUpdateTileId*

Related to AV1 syntax context_update_tile_id.

**Remarks**

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-071:23 -->Please check the limitations for tile configuration returned in D3D12_FEATURE_DATA_VIDEO_ENCODER_FRAME_SUBREGION_LAYOUT_CONFIG for AV1 codec.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-071:23 --></ins>

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-071:24 -->For the width and height parameter lists, please make sure they fall under the codec standard defined dimension limitations specified above. The units of these arrays are measured in block of size D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.SubregionBlockPixelsSize. For example if RowHeights[0] = 2 and SubregionBlockPixelsSize = 64,
    then the RowHeightInPixels[0] = RowHeights[0] * SubregionBlockPixelsSize = 2 * 64 = 128.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-071:24 --></ins>

<a id="source-s02-073"></a>

### D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-073:0 -->Released declaration: [`D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES`](video-encoding-types.md#d3d12-video-encoder-av1-post-encode-values).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-073:0 --></ins>

**Remarks**

If D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAGS was reported for the respective structures, driver must write the values after EncodeFrame execution with or without modifications (copy API client input) done by the driver.
Otherwise, driver must copy the values from the associated API Client input when calling EncodeFrame.

**Members**

*CompoundPredictionType*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_COMPOUND_PREDICTION_MODE.

*LoopFilter*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_LOOP_FILTER.

*LoopFilterDelta*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_LOOP_FILTER_DELTA.

*Quantization*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_QUANTIZATION.

*QuantizationDelta*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_QUANTIZATION_DELTA.

*CDEF*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_CDEF_DATA.

*SegmentationConfig*

This operates in different modes depending the segmentation mode selected.

* D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_AUTO is on for current frame
    * Driver will calculate and write SegmentationConfig which will be used by the API Client to code the segmentation_params() syntax in the frame header.
    * Driver will calculate and write the read_segment_id() map information directly in the compressed bitstream
* D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_FLAG_ENABLE_FRAME_SEGMENTATION_CUSTOM is on for current frame
    * Driver will copy here the SegmentationConfig sent by the API Client in the encode frame parameters for API Client to code the segmentation_params() syntax in the frame header.
    * Driver will copy the read_segment_id() map sent by the API Client in the encode frame parameters directly in the compressed bitstream
* Otherwise (both segmentation modes are off)
    * Driver should write all zeroes
    * API Client will write segmentation_enabled = 0 accordingly in the segmentation_params() section of the frame header

*PrimaryRefFrame*

Associated flag is D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES_FLAG_PRIMARY_REF_FRAME. If the flag was set, the driver controls the selection of the primary reference frame from which the segment id map, CDF, etc are inherited from.

When used together with D3D12_VIDEO_ENCODER_AV1_FEATURE_FLAG_AUTO_SEGMENTATION, allows the driver to force a value **other than** _PRIMARY_REF_NONE_ when applicable, giving the driver full control of the AV1 syntax: _segmentation_update_map_, _segmentation_temporal_update_ and _segmentation_update_data_ in _segmentation_params()_.

*ReferenceIndices*

When the flag is reported, the driver may reorder/remap (but not change the number of references) the ReferenceIndices array, based on the user input D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceIndices. Otherwise, driver must copy each array entry of this parameter as-is from D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_CODEC_DATA.ReferenceIndices.

API Client will write the picture header *ref_frame_idx* AV1 syntax from this output parameter.

<a id="source-s02-074"></a>

### Metadata-resolution requirements

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-074:0 -->Declaring API: [`ID3D12VideoEncodeCommandList2::ResolveEncoderOutputMetadata`](video-encoding.md#id3d12videoencodecommandlist2--resolveencoderoutputmetadata).<!-- d3d12-review-inline:end:video-encoding-codecs:S02-074:0 --></ins>

Resolves the output metadata to a readable format.

**Remarks**

- <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-074:3 -->The API Client must interpret the contents of the resolved output buffer as a memory blob that contains the data as specified in the buffer layout defined for ResolveEncoderOutputMetadata below. All the information in the layout is positioned in memory contiguously. API Client will parse accordingly depending on the value of D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS.EncoderCodec.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-074:3 --></ins>
- <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-074:3 -->For D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS.EncoderCodec equal to H264/HEVC the resolved buffer memory layout will **not** be changed.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-074:3 --></ins>
- <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-074:3 -->For D3D12_VIDEO_ENCODER_RESOLVE_METADATA_INPUT_ARGUMENTS.EncoderCodec == D3D12_VIDEO_ENCODER_CODEC_AV1, the AV1 resolved buffer layout follows.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-074:3 --></ins>

<a id="source-s02-075"></a>

### Resolved buffer layouts for ResolveEncoderOutputMetadata

<ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-075:0 -->Please refer to [D3D12_Video_Encoding_Stats_Metadata](video-encoding-controls.md#family-stats-metadata) for additional resolved metadata layout data.<!-- d3d12-review-inline:end:video-encoding-codecs:S02-075:0 --></ins>

<a id="source-s02-076"></a>

### For H264/HEVC codecs

- <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-076:0 -->Same as existing ResolveEncoderOutputMetadata layout:<!-- d3d12-review-inline:end:video-encoding-codecs:S02-076:0 --></ins>
    - D3D12_VIDEO_ENCODER_OUTPUT_METADATA structure
    - WrittenSubregionsCount elements of type D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA indicating each tile in the same order they're written in the compressed output bitstream.

- The maximum size of the resolved metadata buffer can be inferred by the H264/HEVC layout for ResolveEncoderOutputMetadata.

```text
maxSliceNumber = D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.MaxSubregionsNumber (driver reported output);
MaxEncoderOutputMetadataResolvedBufferSize = sizeof(D3D12_VIDEO_ENCODER_OUTPUT_METADATA) +
            (maxSliceNumber * sizeof(D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA));
```

<a id="source-s02-077"></a>

### For AV1 codec

- <ins><!-- d3d12-review-inline:begin:video-encoding-codecs:S02-077:0 -->The AV1 memory layout is:<!-- d3d12-review-inline:end:video-encoding-codecs:S02-077:0 --></ins>
    - D3D12_VIDEO_ENCODER_OUTPUT_METADATA structure
    - WrittenSubregionsCount elements of type D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA indicating each tile in the same order they're written in the compressed output bitstream.
        - bSize = tile_size_minus_1 + 1 + bStartOffset
        - bStartOffset = Bytes to skip relative to this tile, the actual bitstream coded tile size is tile_size_minus_1 = (bSize - bStartOffset - 1).
        - bHeaderSize = 0
        - The i-th tile is read from the compressed_bitstream[offset] with  offset = D3D12_VIDEO_ENCODER_COMPRESSED_BITSTREAM.FrameStartOffset + [sum j = (0, (i-1)){ tile[j].bSize }] + tile[i].bStartOffset
    - D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES structure indicating the encoded frame tile grid structure
    - D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES indicating encoding metadata values that are only obtained post-execution of EncodeFrame on the GPU.

- The maximum size of the resolved metadata buffer can be inferred by the layout for AV1 in ResolveEncoderOutputMetadata.

```text
MaxTiles = D3D12_FEATURE_DATA_VIDEO_ENCODER_RESOLUTION_SUPPORT_LIMITS.MaxSubregionsNumber (driver reported output);
MaxEncoderOutputMetadataResolvedBufferSize =
        sizeof(D3D12_VIDEO_ENCODER_OUTPUT_METADATA) +
        (MaxTiles * sizeof(D3D12_VIDEO_ENCODER_FRAME_SUBREGION_METADATA))
        + sizeof(D3D12_VIDEO_ENCODER_AV1_PICTURE_CONTROL_SUBREGIONS_LAYOUT_DATA_TILES)
        + sizeof(D3D12_VIDEO_ENCODER_AV1_POST_ENCODE_VALUES)
```
