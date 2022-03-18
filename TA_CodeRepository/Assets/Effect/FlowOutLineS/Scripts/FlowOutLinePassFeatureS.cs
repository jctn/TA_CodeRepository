using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace FlowOutline
{
    public class FlowOutLinePassFeatureS : ScriptableRendererFeature
    {
        class FlowOutLinePass : ScriptableRenderPass
        {
            private RenderTargetHandle mMaskTexture;
            private RenderTargetHandle mTemporaryColorTexture0;
            private RenderTargetHandle mTemporaryColorTexture1;

            private int mID_OutlineWidth;
            private int mID_MaxOutlineZOffset;
            private int mID_BlurParams;
            private int mID_MsakTexMasks;
            private string[] mBlurKeyWorld = { "MASKR", "MASKRG", "MASKRGB", "MASKRGBA" };

            Setting mSetting;
            List<FlowOutlineObjS> mFlowOutlineObjS;
            Vector4[] mMsakTexMasks = new Vector4[FlowOutlineMgrS.MAX_FLOWITEM_COUNT];

            public FlowOutLinePass()
            {
                mMaskTexture.Init("_MaskTex");
                mTemporaryColorTexture0.Init("_TemporaryRT0");
                mTemporaryColorTexture1.Init("_TemporaryRT1");

                mID_OutlineWidth = Shader.PropertyToID("_OutlineWidth");
                mID_MaxOutlineZOffset = Shader.PropertyToID("_MaxOutlineZOffset");
                mID_BlurParams = Shader.PropertyToID("_BlurParams");
                mID_MsakTexMasks = Shader.PropertyToID("_MsakTexMasks");
            }

            public void SetupPass(Setting setting, List<FlowOutlineObjS> flowOutlineObjS)
            {
                mSetting = setting;
                mFlowOutlineObjS = flowOutlineObjS;
            }

            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
                int scW = cameraTextureDescriptor.width;
                int scH = cameraTextureDescriptor.height;

                int maskDown = 0;
                cmd.GetTemporaryRT(mMaskTexture.id, scW >> maskDown, scH >> maskDown, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);

                int w, h;
                if (mSetting != null)
                {
                    w = scW >> mSetting.BlurDownSample;
                    h = scH >> mSetting.BlurDownSample;
                }
                else
                {
                    w = scW;
                    h = scH;
                }
                cmd.GetTemporaryRT(mTemporaryColorTexture0.id, w, h, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
                cmd.GetTemporaryRT(mTemporaryColorTexture1.id, w, h, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);

                //保证后面的pass能正确设置自身的rt
                ConfigureTarget(mTemporaryColorTexture0.id); //该pass执行到最后的rt为mTemporaryColorTexture0
                ConfigureClear(ClearFlag.Color, Color.clear);
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                try
                {
                    if (mSetting.BlurMat == null) return;

                    CommandBuffer cmb = CommandBufferPool.Get("FlowOutLine Pass");

                    cmb.BeginSample("Render Mask");
                    RenderMask(cmb);
                    cmb.EndSample("Render Mask");

                    cmb.BeginSample("Blur");
                    Matrix4x4 blurParams = new Matrix4x4();
                    int row = 0;
                    foreach (var f in mFlowOutlineObjS)
                    {
                        blurParams[row, 0] = f.BlurRadiusX;
                        blurParams[row, 1] = f.BlurRadiusY;
                        blurParams[row, 2] = f.BlurDirByDistortRange ? f.DistortRangeX * f.DistortStrengthX : 0f;
                        blurParams[row, 3] = f.BlurDirByDistortRange ? f.DistortRangeY * f.DistortStrengthY : 0f;
                        row++;
                        if (row >= FlowOutlineMgrS.MAX_CHANNEL_COUNT) break;
                    }

                    for (int i = 0; i < mBlurKeyWorld.Length; i++)
                    {
                        cmb.DisableShaderKeyword(mBlurKeyWorld[i]);
                    }
                    if (row - 1 >= 0)
                    {
                        cmb.EnableShaderKeyword(mBlurKeyWorld[row - 1]);
                    }

                    cmb.Blit(mMaskTexture.id, mTemporaryColorTexture0.id);
                    cmb.SetGlobalMatrix(mID_BlurParams, blurParams);
                    for (int j = 0; j < mSetting.Iteration; j++)
                    {
                        cmb.Blit(mTemporaryColorTexture0.id, mTemporaryColorTexture1.id, mSetting.BlurMat, 0);
                        cmb.Blit(mTemporaryColorTexture1.id, mTemporaryColorTexture0.id, mSetting.BlurMat, 1);
                    }
                    cmb.EndSample("Blur");

                    //Billboard遮罩因子
                    for (int i = 0; i < mMsakTexMasks.Length; i++)
                    {
                        mMsakTexMasks[i] = Vector4.zero;
                    }
                    for (int i = 0; i < mFlowOutlineObjS.Count; i++)
                    {
                        FlowOutlineObjS f = mFlowOutlineObjS[i];
                        mMsakTexMasks[f.SceneIndex] = f.MsakTexMask;
                    }
                    cmb.SetGlobalVectorArray(mID_MsakTexMasks, mMsakTexMasks);

                    ExecuteCommandBuffer(context, cmb);
                    CommandBufferPool.Release(cmb);
                }
                catch (Exception ex)
                {
                    Debug.LogException(ex); //管线代码出错会导致画面黑屏
                }
            }

            private void RenderMask(CommandBuffer buffer)
            {
                buffer.SetRenderTarget(mMaskTexture.id, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                buffer.ClearRenderTarget(false, true, Color.clear);
                for (int i = 0; i < mFlowOutlineObjS.Count; i++)
                {
                    FlowOutlineObjS outLineObj = mFlowOutlineObjS[i];
                    outLineObj.UpdateMaskMat(i);
                    if (outLineObj.ShowOutline)
                    {
                        foreach (Renderer renderer in outLineObj.Renderers)
                        {
                            DrawByCmb(buffer, renderer, outLineObj.MaskMat, 1);
                        }
                    }
                    else
                    {
                        foreach (Renderer renderer in outLineObj.Renderers)
                        {
                            DrawByCmb(buffer, renderer, outLineObj.MaskMat);
                        }
                    }
                }
            }

            private void DrawByCmb(CommandBuffer buffer, Renderer renderer, Material mat, int shaderPass = 0)
            {
                if (renderer != null && mat != null && buffer != null)
                {
                    //int subMeshCount = renderer.sharedMesh.subMeshCount;
                    int subMeshCount = renderer.sharedMaterials.Length;
                    for (int i = 0; i < subMeshCount; i++)
                    {
                        if (shaderPass != 0)
                        {
                            int tempPass = shaderPass;
                            if (renderer.sharedMaterials[i].HasProperty(mID_OutlineWidth) && renderer.sharedMaterials[i].HasProperty(mID_MaxOutlineZOffset))
                            {
                                float w = renderer.sharedMaterials[i].GetFloat(mID_OutlineWidth);
                                float z = renderer.sharedMaterials[i].GetFloat(mID_MaxOutlineZOffset);
                                buffer.SetGlobalFloat(mID_OutlineWidth, w);
                                buffer.SetGlobalFloat(mID_MaxOutlineZOffset, z);
                            }
                            else
                            {
                                tempPass = 0;
                            }
                            buffer.DrawRenderer(renderer, mat, i, tempPass);
                        }
                        else
                        {
                            buffer.DrawRenderer(renderer, mat, i, shaderPass);
                        }
                    }
                }
            }

            private void ExecuteCommandBuffer(ScriptableRenderContext context, CommandBuffer buffer)
            {
                if (buffer != null)
                {
                    context.ExecuteCommandBuffer(buffer);
                    buffer.Clear();
                }
            }
            public override void FrameCleanup(CommandBuffer cmd)
            {
                cmd.ReleaseTemporaryRT(mMaskTexture.id);
                cmd.ReleaseTemporaryRT(mTemporaryColorTexture0.id);
                cmd.ReleaseTemporaryRT(mTemporaryColorTexture1.id);
            }
        }

        private FlowOutLinePass mFlowOutLinePass;

        [System.Serializable]
        public class Setting
        {
            public Material BlurMat;
            [Min(0)]
            public int BlurDownSample = 3;
            [Min(1)]
            public int Iteration = 2;
        }

        public Setting MSetting;

        List<FlowOutlineObjS> mFlowOutlineObjS = new List<FlowOutlineObjS>();

        public override void Create()
        {
            mFlowOutLinePass = new FlowOutLinePass();
            mFlowOutLinePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            Camera cam = renderingData.cameraData.camera;
            FlowOutlineMgrS.Instance.GetRenderFlowOutlineObjs(mFlowOutlineObjS, cam);

            bool sceneNeedPass = cam.cameraType == CameraType.SceneView && mFlowOutlineObjS.Count > 0;
            bool gameNeedPass = cam.cameraType == CameraType.Game && mFlowOutlineObjS.Count > 0;

            if (sceneNeedPass || gameNeedPass)
            {
                mFlowOutLinePass.SetupPass(MSetting, mFlowOutlineObjS);
                renderer.EnqueuePass(mFlowOutLinePass);
            }
        }
    }
}
