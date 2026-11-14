<a id="state-object-database-format"></a>

# State object database published format

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

<ins><!-- d3d12-review-inline:begin:sodb-input-format:format-boundary:0:authored:migration-004bb9e79bbc6edb-0 -->This is the published SQLite format associated with the
[state object database input contract](state-object-databases-and-identity.md).
The format below has `user_version` 2 and application ID `0x0D3D50DB`.
These are format identifiers, not application versions or per-object versions.<!-- d3d12-review-inline:end:sodb-input-format:format-boundary:0:authored:migration-004bb9e79bbc6edb-0 --></ins>

<a id="published-sql-schema"></a>

## Published SQL schema

The State Object Database is a [SQLite](https://sqlite.org/) database with the following schema.  The schema is versioned to facilitate future additions and bug fixes.

```sql
PRAGMA user_version = 2;
PRAGMA application_id = 0xD3D50DB;

CREATE TABLE root_signatures (Key BLOB NOT NULL PRIMARY KEY , value BLOB NOT NULL );
CREATE TABLE input_element_descs (Key BLOB NOT NULL PRIMARY KEY , SemanticName TEXT NOT NULL ,SemanticIndex INTEGER NOT NULL ,Format INTEGER NOT NULL ,InputSlot INTEGER NOT NULL ,AlignedByteOffset INTEGER NOT NULL ,InputSlotClass INTEGER NOT NULL ,InstanceDataStepRate INTEGER NOT NULL );
CREATE TABLE state_objects (Key BLOB NOT NULL PRIMARY KEY , Type INTEGER  ,NodeMask INTEGER  ,Flags INTEGER  ,AddToStateObjectParent BLOB  ,FOREIGN KEY(AddToStateObjectParent) REFERENCES state_objects(Key));
CREATE TABLE shader_bytecode (Key BLOB NOT NULL PRIMARY KEY , Type TEXT  ,Bytecode BLOB  );
CREATE TABLE exports (Key BLOB NOT NULL PRIMARY KEY , Name TEXT NOT NULL ,ExportToRename TEXT  ,Flags INTEGER NOT NULL );
CREATE TABLE depth_stencil_op_descs (Key BLOB NOT NULL PRIMARY KEY , StencilFailOp INTEGER NOT NULL ,StencilDepthFailOp INTEGER NOT NULL ,StencilPassOp INTEGER NOT NULL ,StencilFunc INTEGER NOT NULL ,StencilReadMask INTEGER NOT NULL ,StencilWriteMask INTEGER NOT NULL );
CREATE TABLE depth_stencil_descs (Key BLOB NOT NULL PRIMARY KEY , DepthEnable INTEGER NOT NULL ,DepthWriteMask INTEGER NOT NULL ,DepthFunc INTEGER NOT NULL ,StencilEnable INTEGER NOT NULL ,FrontFace BLOB NOT NULL ,BackFace BLOB NOT NULL ,DepthBoundsTestEnable INTEGER NOT NULL ,FOREIGN KEY(FrontFace) REFERENCES depth_stencil_op_descs(Key),FOREIGN KEY(BackFace) REFERENCES depth_stencil_op_descs(Key));
CREATE TABLE render_target_formats (Key BLOB NOT NULL PRIMARY KEY , RTFormat0 INTEGER NOT NULL ,RTFormat1 INTEGER NOT NULL ,RTFormat2 INTEGER NOT NULL ,RTFormat3 INTEGER NOT NULL ,RTFormat4 INTEGER NOT NULL ,RTFormat5 INTEGER NOT NULL ,RTFormat6 INTEGER NOT NULL ,RTFormat7 INTEGER NOT NULL ,NumRenderTargets INTEGER NOT NULL );
CREATE TABLE render_target_blend_descs (Key BLOB NOT NULL PRIMARY KEY , BlendEnable INTEGER NOT NULL ,LogicOpEnable INTEGER NOT NULL ,SrcBlend INTEGER NOT NULL ,DestBlend INTEGER NOT NULL ,BlendOp INTEGER NOT NULL ,SrcBlendAlpha INTEGER NOT NULL ,DestBlendAlpha INTEGER NOT NULL ,BlendOpAlpha INTEGER NOT NULL ,LogicOp INTEGER NOT NULL ,RenderTargetWriteMask INTEGER NOT NULL );
CREATE TABLE blend_descs (Key BLOB NOT NULL PRIMARY KEY , AlphaToCoverageEnable INTEGER NOT NULL ,IndependentBlendEnable INTEGER NOT NULL ,RenderTarget0 BLOB  ,RenderTarget1 BLOB  ,RenderTarget2 BLOB  ,RenderTarget3 BLOB  ,RenderTarget4 BLOB  ,RenderTarget5 BLOB  ,RenderTarget6 BLOB  ,RenderTarget7 BLOB  ,FOREIGN KEY(RenderTarget0) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget1) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget2) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget3) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget4) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget5) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget6) REFERENCES render_target_blend_descs(Key),FOREIGN KEY(RenderTarget7) REFERENCES render_target_blend_descs(Key));
CREATE TABLE rasterizer_descs (Key BLOB NOT NULL PRIMARY KEY , FillMode INTEGER NOT NULL ,CullMode INTEGER NOT NULL ,FrontCounterClockwise INTEGER NOT NULL ,DepthBias REAL NOT NULL ,DepthBiasClamp REAL NOT NULL ,SlopeScaledDepthBias REAL NOT NULL ,DepthClipEnable INTEGER NOT NULL ,LineRasterizationMode INTEGER NOT NULL ,ForcedSampleCount INTEGER NOT NULL ,ConservativeRaster INTEGER NOT NULL );
CREATE TABLE view_instancing_descs (Key BLOB NOT NULL PRIMARY KEY , ViewInstanceCount INTEGER NOT NULL ,RenderFlags INTEGER NOT NULL ,ViewportArrayIndex0 INTEGER  ,RenderTargetArrayIndex0 INTEGER  ,ViewportArrayIndex1 INTEGER  ,RenderTargetArrayIndex1 INTEGER  ,ViewportArrayIndex2 INTEGER  ,RenderTargetArrayIndex2 INTEGER  ,ViewportArrayIndex3 INTEGER  ,RenderTargetArrayIndex3 INTEGER  );
CREATE TABLE so_declarations (Key BLOB NOT NULL PRIMARY KEY , Stream INTEGER NOT NULL ,SemanticName TEXT NOT NULL ,SemanticIndex INTEGER NOT NULL ,StartComponent INTEGER NOT NULL ,ComponentCount INTEGER NOT NULL ,OutputSlot INTEGER NOT NULL );
CREATE TABLE stream_out_descs (Key BLOB NOT NULL PRIMARY KEY , BufferStride0 INTEGER NOT NULL ,BufferStride1 INTEGER NOT NULL ,BufferStride2 INTEGER NOT NULL ,BufferStride3 INTEGER NOT NULL ,NumStrides INTEGER NOT NULL ,RasterizedStream INTEGER NOT NULL );
CREATE TABLE rt_hit_groups (Key BLOB NOT NULL PRIMARY KEY , HitGroupExport TEXT NOT NULL ,Type INTEGER NOT NULL ,AnyHitShaderImport TEXT  ,ClosestHitShaderImport TEXT  ,IntersectionShaderImport TEXT  );
CREATE TABLE rt_shader_config (Key BLOB NOT NULL PRIMARY KEY , MaxPayloadSizeInBytes INTEGER NOT NULL ,MaxAttributeSizeInBytes INTEGER NOT NULL );
CREATE TABLE rt_pipeline_config (Key BLOB NOT NULL PRIMARY KEY , MaxTraceRecursionDepth INTEGER NOT NULL ,Flags INTEGER NOT NULL );
CREATE TABLE dxil_subobject_to_exports_associations (Key BLOB NOT NULL PRIMARY KEY , SubobjectToAssociate TEXT NOT NULL );
CREATE TABLE subobject_to_exports_associations (Key BLOB NOT NULL PRIMARY KEY , SubobjectType INTEGER NOT NULL ,SubobjectKey BLOB NOT NULL );
CREATE TABLE generic_programs (Key BLOB NOT NULL PRIMARY KEY , ProgramName TEXT  ,InputLayout BLOB  ,DepthStencilDesc BLOB  ,RenderTargetFormats BLOB  ,BlendDesc BLOB  ,RasterizerDesc BLOB  ,ViewInstancingDesc BLOB  ,StreamOutDesc BLOB  ,SampleDesc_Count INTEGER  ,SampleDesc_Quality INTEGER  ,SampleMask INTEGER  ,IBStripCutValue INTEGER  ,PrimitiveTopology INTEGER  ,DSVFormat INTEGER  ,NodeMask INTEGER  ,Flags INTEGER  ,FOREIGN KEY(DepthStencilDesc) REFERENCES depth_stencil_descs(Key),FOREIGN KEY(RenderTargetFormats) REFERENCES render_target_formats(Key),FOREIGN KEY(BlendDesc) REFERENCES blend_descs(Key),FOREIGN KEY(RasterizerDesc) REFERENCES rasterizer_descs(Key),FOREIGN KEY(ViewInstancingDesc) REFERENCES view_instancing_descs(Key),FOREIGN KEY(StreamOutDesc) REFERENCES stream_out_descs(Key));
CREATE TABLE pipeline_states (Key BLOB NOT NULL PRIMARY KEY , RootSignature BLOB  ,InputLayout BLOB  ,ByteCode_VS BLOB  ,ByteCode_PS BLOB  ,ByteCode_HS BLOB  ,ByteCode_DS BLOB  ,ByteCode_GS BLOB  ,ByteCode_AS BLOB  ,ByteCode_MS BLOB  ,ByteCode_CS BLOB  ,DepthStencilDesc BLOB  ,RenderTargetFormats BLOB  ,BlendDesc BLOB  ,RasterizerDesc BLOB  ,ViewInstancingDesc BLOB  ,StreamOutDesc BLOB  ,SampleDesc_Count INTEGER  ,SampleDesc_Quality INTEGER  ,SampleMask INTEGER  ,IBStripCutValue INTEGER  ,PrimitiveTopology INTEGER  ,DSVFormat INTEGER  ,NodeMask INTEGER  ,Flags INTEGER  ,FOREIGN KEY(RootSignature) REFERENCES root_signatures(Key),FOREIGN KEY(ByteCode_VS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_PS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_HS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_DS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_GS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_AS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_MS) REFERENCES shader_bytecode(Key),FOREIGN KEY(ByteCode_CS) REFERENCES shader_bytecode(Key),FOREIGN KEY(DepthStencilDesc) REFERENCES depth_stencil_descs(Key),FOREIGN KEY(RenderTargetFormats) REFERENCES render_target_formats(Key),FOREIGN KEY(BlendDesc) REFERENCES blend_descs(Key),FOREIGN KEY(RasterizerDesc) REFERENCES rasterizer_descs(Key),FOREIGN KEY(ViewInstancingDesc) REFERENCES view_instancing_descs(Key),FOREIGN KEY(StreamOutDesc) REFERENCES stream_out_descs(Key));
CREATE TABLE work_graphs (Key BLOB NOT NULL PRIMARY KEY , ProgramName TEXT NOT NULL ,Flags INTEGER NOT NULL );
CREATE TABLE node_ids (Key BLOB NOT NULL PRIMARY KEY , Name TEXT NOT NULL ,ArrayIndex INTEGER NOT NULL );
CREATE TABLE node_output_overrides (Key BLOB NOT NULL PRIMARY KEY , OutputIndex INTEGER NOT NULL ,NewName BLOB  ,AllowSparseNodes INTEGER  ,MaxRecords INTEGER  ,MaxRecordsSharedWithOutputIndex INTEGER  ,FOREIGN KEY(NewName) REFERENCES node_ids(Key));
CREATE TABLE shader_nodes (Key BLOB NOT NULL PRIMARY KEY , ShaderOrProgram TEXT NOT NULL ,NodeType INTEGER NOT NULL ,OverridesType INTEGER NOT NULL ,LocalRootArgumentsTableIndex INTEGER  ,ProgramEntry INTEGER  ,NewName BLOB  ,ShareInputOf BLOB  ,DispatchGridX INTEGER  ,DispatchGridY INTEGER  ,DispatchGridZ INTEGER  ,MaxDispatchGridX INTEGER  ,MaxDispatchGridY INTEGER  ,MaxDispatchGridZ INTEGER  ,MaxInputRecordsPerGraphEntryRecord_RecordCount INTEGER  ,MaxInputRecordsPerGraphEntryRecord_bCountSharedAcrossNodeArray INTEGER  ,FOREIGN KEY(NewName) REFERENCES node_ids(Key),FOREIGN KEY(ShareInputOf) REFERENCES node_ids(Key));
CREATE TABLE input_layout_to_input_element_associations (InputLayoutKey BLOB NOT NULL ,InputElementKey BLOB NOT NULL ,FOREIGN KEY(InputElementKey) REFERENCES input_element_descs(Key),UNIQUE(InputLayoutKey, InputElementKey));
CREATE TABLE stream_output_desc_to_stream_output_decl_associations (StreamOutDescKey BLOB NOT NULL ,StreamOutDeclKey BLOB NOT NULL ,FOREIGN KEY(StreamOutDescKey) REFERENCES stream_out_descs(Key),FOREIGN KEY(StreamOutDeclKey) REFERENCES so_declarations(Key),UNIQUE(StreamOutDescKey, StreamOutDeclKey));
CREATE TABLE so_to_global_rs_associations (StateObjectKey BLOB NOT NULL ,RootSignatureKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(RootSignatureKey) REFERENCES root_signatures(Key),UNIQUE(StateObjectKey, RootSignatureKey));
CREATE TABLE so_to_local_rs_associations (StateObjectKey BLOB NOT NULL ,RootSignatureKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(RootSignatureKey) REFERENCES root_signatures(Key),UNIQUE(StateObjectKey, RootSignatureKey));
CREATE TABLE so_to_dxil_lib_associations (StateObjectKey BLOB NOT NULL ,DxilLibKey BLOB NOT NULL ,ExportKey BLOB  ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(DxilLibKey) REFERENCES shader_bytecode(Key),FOREIGN KEY(ExportKey) REFERENCES exports(Key),UNIQUE(StateObjectKey, DxilLibKey, ExportKey));
CREATE UNIQUE INDEX so_to_dxil_lib_associations_partial_index ON so_to_dxil_lib_associations(StateObjectKey,DxilLibKey) WHERE ExportKey IS NULL;
CREATE TABLE so_to_existing_so_associations (StateObjectKey BLOB NOT NULL ,ExistingStateObjectKey BLOB NOT NULL ,ExportKey BLOB  ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(ExistingStateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(ExportKey) REFERENCES exports(Key),UNIQUE(StateObjectKey, ExistingStateObjectKey, ExportKey));
CREATE UNIQUE INDEX so_to_existing_so_associations_partial_index ON so_to_existing_so_associations(StateObjectKey,ExistingStateObjectKey) WHERE ExportKey IS NULL;
CREATE TABLE so_to_hit_group_associations (StateObjectKey BLOB NOT NULL ,HitGroupKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(HitGroupKey) REFERENCES rt_hit_groups(Key),UNIQUE(StateObjectKey, HitGroupKey));
CREATE TABLE so_to_rt_shader_config_associations (StateObjectKey BLOB NOT NULL ,ShaderConfigKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(ShaderConfigKey) REFERENCES rt_shader_config(Key),UNIQUE(StateObjectKey, ShaderConfigKey));
CREATE TABLE so_to_rt_pipeline_config_associations (StateObjectKey BLOB NOT NULL ,PipelineConfigKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(PipelineConfigKey) REFERENCES rt_pipeline_config(Key),UNIQUE(StateObjectKey, PipelineConfigKey));
CREATE TABLE so_to_dxil_subobject_to_exports_associations (StateObjectKey BLOB NOT NULL ,DxilSubobjectToExportsAssociationKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(DxilSubobjectToExportsAssociationKey) REFERENCES dxil_subobject_to_exports_associations(Key),UNIQUE(StateObjectKey, DxilSubobjectToExportsAssociationKey));
CREATE TABLE so_to_subobject_to_exports_associations (StateObjectKey BLOB NOT NULL ,SubobjectToExportsAssociationKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(SubobjectToExportsAssociationKey) REFERENCES subobject_to_exports_associations(Key),UNIQUE(StateObjectKey, SubobjectToExportsAssociationKey));
CREATE TABLE so_to_generic_program_associations (StateObjectKey BLOB NOT NULL ,GenericProgramKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(GenericProgramKey) REFERENCES generic_programs(Key),UNIQUE(StateObjectKey, GenericProgramKey));
CREATE TABLE so_to_work_graph_associations (StateObjectKey BLOB NOT NULL ,WorkGraphKey BLOB NOT NULL ,FOREIGN KEY(StateObjectKey) REFERENCES state_objects(Key),FOREIGN KEY(WorkGraphKey) REFERENCES work_graphs(Key),UNIQUE(StateObjectKey, WorkGraphKey));
CREATE TABLE work_graph_to_entrypoint_node_id_associations (WorkGraphKey BLOB NOT NULL ,NodeIDKey BLOB NOT NULL ,FOREIGN KEY(WorkGraphKey) REFERENCES work_graphs(Key),FOREIGN KEY(NodeIDKey) REFERENCES node_ids(Key),UNIQUE(WorkGraphKey, NodeIDKey));
CREATE TABLE workgraph_node_to_node_output_overrides_associations (WorkGraphNodeKey BLOB NOT NULL ,NodeOutputOverridesKey BLOB NOT NULL ,FOREIGN KEY(WorkGraphNodeKey) REFERENCES shader_nodes(Key),FOREIGN KEY(NodeOutputOverridesKey) REFERENCES node_output_overrides(Key),UNIQUE(WorkGraphNodeKey, NodeOutputOverridesKey));
CREATE TABLE work_graph_to_work_graph_node_associations (WorkGraphKey BLOB NOT NULL ,WorkGraphNodeKey BLOB NOT NULL ,FOREIGN KEY(WorkGraphKey) REFERENCES work_graphs(Key),FOREIGN KEY(WorkGraphNodeKey) REFERENCES shader_nodes(Key),UNIQUE(WorkGraphKey, WorkGraphNodeKey));
CREATE TABLE string_associations (OwningTableKey BLOB  ,Value TEXT NOT NULL ,UNIQUE(OwningTableKey, Value));
CREATE UNIQUE INDEX string_associations_partial_index ON string_associations(Value) WHERE OwningTableKey IS NULL;
CREATE TABLE groups (Key BLOB NOT NULL PRIMARY KEY , Version INTEGER NOT NULL ,PSOKey BLOB  ,SOKey BLOB  ,FOREIGN KEY(PSOKey) REFERENCES pipeline_states(Key),FOREIGN KEY(SOKey) REFERENCES state_objects(Key));
CREATE TABLE app_id (id INTEGER NOT NULL PRIMARY KEY , exe TEXT NOT NULL ,app_name TEXT NOT NULL ,engine_name TEXT  ,app_version INTEGER NOT NULL ,engine_version INTEGER NOT NULL )
```

<a id="tables-and-relationships"></a>

## Tables and relationships

<ins><!-- d3d12-review-inline:begin:sodb-input-format:schema-mapping:0:authored:migration-a4331bfaaf35a380-0 -->`groups` maps an application-selected object key to an object version and the
pipeline state (`PSOKey`) or state object (`SOKey`) record. The `Key` primary key
is shared across those object kinds. It is not a composite of key and version.
The API's single stored version is represented by the group's `Version`, not
by `PRAGMA user_version`.<!-- d3d12-review-inline:end:sodb-input-format:schema-mapping:0:authored:migration-a4331bfaaf35a380-0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input-format:schema-mapping:1:authored:migration-de4d0b45e5107d3b-0 -->Export selection and association records are part of the
[stored dependency graph](state-object-databases-and-identity.md#keys-and-versions),
not incidental ordering to be discarded.<!-- d3d12-review-inline:end:sodb-input-format:schema-mapping:1:authored:migration-de4d0b45e5107d3b-0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input-format:schema-mapping:2:authored:migration-922b0eaf17d927c8-0 -->`shader_bytecode.Bytecode` and `root_signatures.value` are
[opaque input blobs](state-object-databases-and-identity.md#database-inputs).<!-- d3d12-review-inline:end:sodb-input-format:schema-mapping:2:authored:migration-922b0eaf17d927c8-0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input-format:schema-mapping:3:authored:migration-3ecab7d77d826cfb-0 -->Application metadata is the `app_id` record used by `SetApplicationDesc` and
`GetApplicationDesc`. The API uses the single application row at `id = 0`.
`exe`, `app_name`, `engine_name`, `app_version` and `engine_version` correspond
to `D3D12_APPLICATION_DESC`. There is no application-GUID field in this
published schema. SQL `NOT NULL` does not mean that a string is nonempty, and
schema constraints alone do not replace owning-API validation.<!-- d3d12-review-inline:end:sodb-input-format:schema-mapping:3:authored:migration-3ecab7d77d826cfb-0 --></ins>

<ins><!-- d3d12-review-inline:begin:sodb-input-format:schema-mapping:4:authored:migration-fc7f26ab8cc1e5b8-0 -->The DDL declares primary/unique keys, partial unique indexes and foreign-key
relationships exactly as published. It does not issue `PRAGMA foreign_keys`;
declarations of foreign keys do not establish that SQLite foreign-key
enforcement is enabled. The API's typed keys and dependency requirements must
not be inferred solely from what an unconstrained SQL insert accepts.<!-- d3d12-review-inline:end:sodb-input-format:schema-mapping:4:authored:migration-fc7f26ab8cc1e5b8-0 --></ins>
