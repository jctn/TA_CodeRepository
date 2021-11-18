using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public abstract class PostFXBase : MonoBehaviour
{
    public virtual void OnEnable()
    {
        PostFXManager.Instance.AddPostFX(this);
    }

    public virtual void OnDisable()
    {
        PostFXManager.Instance.RemovePostFX(this);
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

    public abstract void Render(ScriptableRenderContext context, CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetHandle dest, ref RenderingData renderingData);
}
