using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GlobalFogFeature : ScriptableRendererFeature
{
    class GlobalFogPass : ScriptableRenderPass
    {
        const string CMDSTR = "GlobalFog";
        RenderTargetHandle mTemporaryColorTexture;
        RenderTargetIdentifier mSource;
        Material mGlobalFogMat;
        int ID_Fog_MATRIX_I_V = Shader.PropertyToID("_Fog_MATRIX_I_V");

        public GlobalFogPass()
        {
            mTemporaryColorTexture.Init("_TemporaryColorTexture");
        }

        public void Setup(RenderTargetIdentifier source, Material mat)
        {
            mSource = source;
            mGlobalFogMat = mat;
        }

        protected RenderTextureDescriptor GetDescriptor(RenderTextureDescriptor descriptor, int width, int height)
        {
            RenderTextureDescriptor desc = descriptor;
            desc.msaaSamples = 1;
            desc.depthBufferBits = 0;
            desc.width = width;
            desc.height = height;
            return desc;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (mGlobalFogMat == null) return;
            CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
            RenderTextureDescriptor camDesc = renderingData.cameraData.cameraTargetDescriptor;
            RenderTextureDescriptor desc = GetDescriptor(camDesc, camDesc.width, camDesc.height);
            cmd.GetTemporaryRT(mTemporaryColorTexture.id, desc, FilterMode.Bilinear);
            cmd.SetGlobalMatrix(ID_Fog_MATRIX_I_V, renderingData.cameraData.camera.cameraToWorldMatrix);
            cmd.Blit(mSource, mTemporaryColorTexture.Identifier(), mGlobalFogMat, 0);
            cmd.Blit(mTemporaryColorTexture.Identifier(), mSource);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(mTemporaryColorTexture.id);
        }
    }

    GlobalFogPass mGlobalFogPass;
    Material mGlobalFogMat;

    public override void Create()
    {
        mGlobalFogPass = new GlobalFogPass();
        mGlobalFogPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!GlobalFogSetting.EnableGlobalFog) return;
        bool mainGameCam = renderingData.cameraData.camera.cameraType == CameraType.Game && renderingData.cameraData.camera == Camera.main;
        if (mainGameCam || renderingData.cameraData.camera.cameraType == CameraType.SceneView)
        {
            if(mGlobalFogMat == null)
            {
                Shader s = Shader.Find("Code Repository/Scene/GlobalFog");
                if(s != null)
                {
                    mGlobalFogMat = new Material(s);
                }           
            }
            mGlobalFogPass.Setup(renderer.cameraColorTarget, mGlobalFogMat);
            renderer.EnqueuePass(mGlobalFogPass);
        }
    }
}
