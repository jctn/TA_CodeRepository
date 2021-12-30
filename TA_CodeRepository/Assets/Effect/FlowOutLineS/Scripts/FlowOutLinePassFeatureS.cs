using System.Collections;
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
            private RenderTargetIdentifier mColorActive; //当前pass进入时激活的colorbuffer
            private RenderTargetIdentifier mDepthActive; //当前pass进入时激活的depthbuffer

            private RenderTargetHandle mMaskTexture;
            private RenderTargetHandle mTemporaryColorTexture0;
            private RenderTargetHandle mTemporaryColorTexture1;

            private int mID_OutlineWidth;
            private int mID_MaxOutlineZOffset;
            private int mID_BlurParams;
            private string[] mBlurKeyWorld = { "MASKR", "MASKRG", "MASKRGB", "MASKRGBA" };

            Setting mSetting;

            public FlowOutLinePass()
            {
                mMaskTexture.Init("_MaskTex");
                mTemporaryColorTexture0.Init("_TemporaryRT0");
                mTemporaryColorTexture1.Init("_TemporaryRT1");

                mID_OutlineWidth = Shader.PropertyToID("_OutlineWidth");
                mID_MaxOutlineZOffset = Shader.PropertyToID("_MaxOutlineZOffset");
                mID_BlurParams = Shader.PropertyToID("_BlurParams");
            }

            public void SetupPass(RenderTargetIdentifier colorActive, RenderTargetIdentifier depthActive, Setting setting)
            {
                mColorActive = colorActive; //该pass未调用configure设置target，所以一定是ScriptableRenderer的cameraColorTarget
                mDepthActive = depthActive;
                mSetting = setting;
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                if (mSetting.BlurMat == null) return;

                CommandBuffer cmb = CommandBufferPool.Get("FlowOutLine Pass");

                int scW = renderingData.cameraData.cameraTargetDescriptor.width;
                int scH = renderingData.cameraData.cameraTargetDescriptor.height;

                //mask，mask需要高精度，而Silhouette分辨率不能太高，因为数量可能大，所以不能用Silhouette做mask
                int maskDown = 0;
                cmb.BeginSample("Render Mask");
                cmb.GetTemporaryRT(mMaskTexture.id, scW >> maskDown, scH >> maskDown, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
                RenderMask(cmb);
                cmb.EndSample("Render Mask");

                cmb.BeginSample("Blur");
                Matrix4x4 blurParams = new Matrix4x4();
                int row = 0;
                foreach (var f in FlowOutlineMgrS.Instance.FlowOutlineObjs)
                {
                    blurParams[row, 0] = f.BlurRadiusX;
                    blurParams[row, 1] = f.BlurRadiusY;
                    blurParams[row, 2] = f.IsUPBlur ? 1f : 0f;
                    row++;
                    if (row >= 4) break;
                }
                for(int i = 0; i < mBlurKeyWorld.Length; i++)
                {
                    cmb.DisableShaderKeyword(mBlurKeyWorld[i]);
                }
                cmb.EnableShaderKeyword(mBlurKeyWorld[row - 1]);

                int w = scW >> mSetting.BlurDownSample;
                int h = scH >> mSetting.BlurDownSample;
                cmb.GetTemporaryRT(mTemporaryColorTexture0.id, w, h, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);
                cmb.GetTemporaryRT(mTemporaryColorTexture1.id, w, h, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);
                cmb.Blit(mMaskTexture.id, mTemporaryColorTexture0.id);
                cmb.SetGlobalMatrix(mID_BlurParams, blurParams);
                for (int j = 0; j < mSetting.Iteration; j++)
                {
                    cmb.Blit(mTemporaryColorTexture0.id, mTemporaryColorTexture1.id, mSetting.BlurMat, 0);
                    cmb.Blit(mTemporaryColorTexture1.id, mTemporaryColorTexture0.id, mSetting.BlurMat, 1);
                }
                cmb.EndSample("Blur");

                //还原target buffer
                if (mDepthActive == BuiltinRenderTextureType.CameraTarget)
                {
                    cmb.SetRenderTarget(mColorActive, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store);
                }
                else
                {
                    cmb.SetRenderTarget(mColorActive, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store, mDepthActive, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store);
                }
                ExecuteCommandBuffer(context, cmb);
                CommandBufferPool.Release(cmb);
            }

            private void RenderMask(CommandBuffer buffer)
            {
                buffer.SetRenderTarget(mMaskTexture.id, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                buffer.ClearRenderTarget(false, true, Color.clear);
                foreach (FlowOutlineObjS outLineObj in FlowOutlineMgrS.Instance.FlowOutlineObjs)
                {
                    if(outLineObj.ShowOutline)
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
                        if(shaderPass != 0)
                        {
                            float w = renderer.sharedMaterials[i].GetFloat(mID_OutlineWidth);
                            float z = renderer.sharedMaterials[i].GetFloat(mID_MaxOutlineZOffset);
                            buffer.SetGlobalFloat(mID_OutlineWidth, w);
                            buffer.SetGlobalFloat(mID_MaxOutlineZOffset, z);
                        }
                        buffer.DrawRenderer(renderer, mat, i, shaderPass);
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

        public override void Create()
        {
            mFlowOutLinePass = new FlowOutLinePass();
            mFlowOutLinePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            bool notMainCamera = renderingData.cameraData.camera.cameraType == CameraType.Game && Camera.main != null && Camera.main != renderingData.cameraData.camera;
            if ((renderingData.cameraData.camera.cameraType != CameraType.Game && renderingData.cameraData.camera.cameraType != CameraType.SceneView) || notMainCamera || !FlowOutlineMgrS.Instance.NeedPassRender)
            {
                return;
            }
            mFlowOutLinePass.SetupPass(renderer.cameraColorTarget, renderer.cameraDepth, MSetting);
            renderer.EnqueuePass(mFlowOutLinePass);
        }
    }
}
