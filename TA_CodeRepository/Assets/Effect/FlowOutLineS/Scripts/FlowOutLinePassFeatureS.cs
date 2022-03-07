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

            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
                int scW = cameraTextureDescriptor.width;
                int scH = cameraTextureDescriptor.height;

                int maskDown = 0;
                cmd.GetTemporaryRT(mMaskTexture.id, scW >> maskDown, scH >> maskDown, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

                int w = scW >> FlowOutlineMgrS.Instance.BlurDownSample;
                int h = scH >> FlowOutlineMgrS.Instance.BlurDownSample;
                cmd.GetTemporaryRT(mTemporaryColorTexture0.id, w, h, 0, FilterMode.Bilinear, RenderTextureFormat.ARGBHalf);

                //保证后面的pass能正确设置自身的rt
                ConfigureTarget(mMaskTexture.id);
                ConfigureClear(ClearFlag.Color, Color.clear);
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                try
                {
                    CommandBuffer cmb = CommandBufferPool.Get("FlowOutLine Pass");

                    cmb.BeginSample("Render Mask");
                    RenderMask(cmb);
                    cmb.EndSample("Render Mask");

                    //Silhouette
                    cmb.BeginSample("Render Silhouette");
                    RenderSilhouette(cmb);
                    cmb.EndSample("Render Silhouette");

                    cmb.BeginSample("Blur");
                    foreach (var f in FlowOutlineMgrS.Instance.FlowOutlineObjs)
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
                //buffer.SetRenderTarget(mMaskTexture.id, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                //buffer.ClearRenderTarget(false, true, Color.clear);
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
            renderer.EnqueuePass(mFlowOutLinePass);
        }
    }
}
