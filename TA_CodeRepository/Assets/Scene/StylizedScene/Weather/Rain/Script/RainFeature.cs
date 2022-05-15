using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RainFeature : ScriptableRendererFeature
{
    class RainPass : ScriptableRenderPass
    {
        const string CMDSTR = "Rain";
        RenderTargetHandle mTemporaryColorTexture;
        RenderTargetIdentifier mSource;
        RainCtrl rainCtrl;

        public RainPass()
        {
            mTemporaryColorTexture.Init("_RainTemporaryColorTexture");
        }

        public void Setup(RenderTargetIdentifier source)
        {
            mSource = source;
            rainCtrl = RainMgr.Instance.RainCtrls[0];
        }

        RenderTextureDescriptor GetDescriptor(RenderTextureDescriptor descriptor, int width, int height)
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
            if (rainCtrl.RainMaterial == null) return;
            CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
            RenderTextureDescriptor camDesc = renderingData.cameraData.cameraTargetDescriptor;
            RenderTextureDescriptor desc = GetDescriptor(camDesc, camDesc.width, camDesc.height);
            cmd.GetTemporaryRT(mTemporaryColorTexture.id, desc, FilterMode.Bilinear);
            cmd.Blit(mSource, mTemporaryColorTexture.Identifier(), rainCtrl.RainMaterial, 0); //有load操作，后续优化
            cmd.Blit(mTemporaryColorTexture.Identifier(), mSource);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(mTemporaryColorTexture.id);
        }
    }

    RainPass mRainPass;

    public override void Create()
    {
        mRainPass = new RainPass();
        mRainPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (RainMgr.Instance.RainCtrls.Count <= 0) return;
        if (renderingData.cameraData.camera.cameraType == CameraType.Game || renderingData.cameraData.camera.cameraType == CameraType.SceneView)
        {
            mRainPass.Setup(renderer.cameraColorTarget);
            renderer.EnqueuePass(mRainPass);
        }
    }
}
