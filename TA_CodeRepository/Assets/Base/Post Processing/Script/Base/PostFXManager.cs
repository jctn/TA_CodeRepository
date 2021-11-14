using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PostFXManager
{
    static PostFXManager mInstance;
    public static PostFXManager Instance
    {
        get
        {
            if (mInstance == null)
            {
                mInstance = new PostFXManager();
            }
            return mInstance;
        }
    }

    List<PostFXBase> mPostFXes = new List<PostFXBase>();

    public void AddPostFX(PostFXBase postFX)
    {
        if(!mPostFXes.Contains(postFX))
        {
            mPostFXes.Add(postFX);
        }
    }

    public void RemovePostFX(PostFXBase postFX)
    {
        mPostFXes.Remove(postFX);
    }

    public int PostFXCount
    {
        get { return mPostFXes.Count; }
    }

    public void RenderPostFX(ScriptableRenderContext context, CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetHandle dest, ref RenderingData renderingData)
    {
        foreach(var postFX in mPostFXes)
        {
            if(postFX != null)
            {
                postFX.Render(context, cmd, source, dest, ref renderingData);
            }
        }
    }
}
