using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteAlways]
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

    public abstract void Render(ScriptableRenderContext context, CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetHandle dest, ref RenderingData renderingData);
}
