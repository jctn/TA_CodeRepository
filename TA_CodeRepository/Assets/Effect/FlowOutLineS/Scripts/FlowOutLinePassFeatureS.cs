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

            private int mID_Offsets;
            private int mID_isUp;
            private int mID_OutlineWidth;
            private int mID_MaxOutlineZOffset;
            public FlowOutLinePass()
            {
                mMaskTexture.Init("_MaskTex");
                mTemporaryColorTexture0.Init("_TemporaryRT0");

                mID_Offsets = Shader.PropertyToID("_offsets");
                mID_isUp = Shader.PropertyToID("_isUp");
                mID_OutlineWidth = Shader.PropertyToID("_OutlineWidth");
                mID_MaxOutlineZOffset = Shader.PropertyToID("_MaxOutlineZOffset");
            }

            public void SetupPass(RenderTargetIdentifier colorActive, RenderTargetIdentifier depthActive)
            {
                mColorActive = colorActive; //该pass未调用configure设置target，所以一定是ScriptableRenderer的cameraColorTarget
                mDepthActive = depthActive;
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmb = CommandBufferPool.Get("FlowOutLine Pass");

                int scW = renderingData.cameraData.cameraTargetDescriptor.width;
                int scH = renderingData.cameraData.cameraTargetDescriptor.height;

                //mask，mask需要高精度，而Silhouette分辨率不能太高，因为数量可能大，所以不能用Silhouette做mask
                int maskDown = 0;
                cmb.BeginSample("Render Mask");
                cmb.GetTemporaryRT(mMaskTexture.id, scW >> maskDown, scH >> maskDown, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
                RenderMask(cmb);
                cmb.EndSample("Render Mask");

                //Silhouette
                cmb.BeginSample("Render Silhouette");
                RenderSilhouette(cmb);
                cmb.EndSample("Render Silhouette");

                cmb.BeginSample("Blur");
                int w = scW >> FlowOutlineMgrS.Instance.BlurDownSample;
                int h = scH >> FlowOutlineMgrS.Instance.BlurDownSample;
                cmb.GetTemporaryRT(mTemporaryColorTexture0.id, w, h, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);
                foreach(var f in FlowOutlineMgrS.Instance.FlowOutlineObjs)
                {
                    cmb.SetGlobalInt(mID_isUp, f.IsUPBlur ? 1 : 0);
                    for (int j = 0; j < f.Iteration; j++)
                    {
                        //竖向模糊
                        cmb.SetGlobalVector(mID_Offsets, new Vector4(0, f.BlurRadiusY, 0, 0));
                        cmb.Blit(f.SilhouetteTex, mTemporaryColorTexture0.Identifier(), f.BlurMat, 0);
                        //横向模糊
                        cmb.SetGlobalVector(mID_Offsets, new Vector4(f.BlurRadiusX, 0, 0, 0));
                        cmb.Blit(mTemporaryColorTexture0.Identifier(), f.SilhouetteTex, f.BlurMat, 0);
                    }
                }
                cmb.EndSample("Blur");
                //还原target buffer
                if(mDepthActive == BuiltinRenderTextureType.CameraTarget)
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

            private void RenderSilhouette(CommandBuffer buffer)
            {
                foreach (FlowOutlineObjS outLineObj in FlowOutlineMgrS.Instance.FlowOutlineObjs)
                {
                    buffer.SetRenderTarget(outLineObj.SilhouetteTex, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                    buffer.ClearRenderTarget(false, true, Color.clear);
                    if(outLineObj.ShowOutline)
                    {
                        foreach (Renderer renderer in outLineObj.Renderers)
                        {
                            DrawByCmb(buffer, renderer, outLineObj.SilhouetteMat, 1);
                        }
                    }
                    else
                    {
                        foreach (Renderer renderer in outLineObj.Renderers)
                        {
                            DrawByCmb(buffer, renderer, outLineObj.SilhouetteMat);
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
            }
        }

        private FlowOutLinePass mFlowOutLinePass;

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
            mFlowOutLinePass.SetupPass(renderer.cameraColorTarget, renderer.cameraDepth);
            renderer.EnqueuePass(mFlowOutLinePass);
        }
    }
}
