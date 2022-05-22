using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RainSceneDepthRender : ScriptableRenderer
{
    RainSceneDepthPass rainSceneDepthPass;

    public RainSceneDepthRender(RainSceneDepthRenderData data) : base(data)
    {
        rainSceneDepthPass = new RainSceneDepthPass(RenderPassEvent.BeforeRenderingOpaques, RenderQueueRange.opaque, data.opaqueLayerMask);
    }

    public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        ConfigureCameraTarget(BuiltinRenderTextureType.CameraTarget, BuiltinRenderTextureType.CameraTarget);
        AddRenderPasses(ref renderingData);
        EnqueuePass(rainSceneDepthPass);
    }
}
