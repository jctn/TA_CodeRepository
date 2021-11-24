using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Rendering;

public abstract class BaseStatusShow
{
    public StatusShowContainer MStatusShowContainer;
    public StatusShowBaseData MStatusShowBaseData;

    protected Material[][] Mats
    {
        get
        {
            if(MStatusShowContainer != null)
            {
                return MStatusShowContainer.OriMats;
            }
            else
            {
                return null;
            }
        }
    }

    /// <summary>
    /// 更改了该数组内材质需置IsSetTempMat=true
    /// </summary>
    protected Dictionary<Material, Material> TempMats
    {
        get
        {
            if (MStatusShowContainer != null)
            {
                return MStatusShowContainer.TempMats;
            }
            else
            {
                return null;
            }
        }
    }

    protected Renderer[] Renderers
    {
        get
        {
            if (MStatusShowContainer != null)
            {
                return MStatusShowContainer.Renderers;
            }
            else
            {
                return null;
            }
        }
    }

    protected bool IsSetTempMat = false;
    bool mIsSetReplaceMat = false;
    bool mIsSetMPB = false;

    /// <summary>
    /// 设置替换材质
    /// </summary>
    protected void SetTempReplaceMat()
    {
        if (Renderers == null) return;

        mIsSetReplaceMat = true;
        for(int i = 0; i < Renderers.Length; i++)
        {
            Renderer render = Renderers[i];
            render.sharedMaterials = GetTempMats(render);
        }
    }

    /// <summary>
    /// 设置替换材质
    /// </summary>
    protected void SetReplaceMat(Material mat)
    {
        if (mat == null || Renderers == null) return;

        mIsSetReplaceMat = true;
        for (int i = 0; i < Renderers.Length; i++)
        {
            Renderer render = Renderers[i];
            render.sharedMaterials = GetTempMats(render, mat);
        }
    }

    private Material[] GetTempMats(Renderer render)
    {
        if (render == null) return null;
        Material[] mats = new Material[render.sharedMaterials.Length];
        for(int i = 0; i < mats.Length; i++)
        {
            mats[i] = TempMats[render.sharedMaterials[i]];
        }
        return mats;
    }

    private Material[] GetTempMats(Renderer render, Material mat)
    {
        if (render == null) return null;
        Material[] mats = new Material[render.sharedMaterials.Length];
        for (int i = 0; i < mats.Length; i++)
        {
            mats[i] = mat;
        }
        return mats;
    }

    /// <summary>
    /// 恢复原材质
    /// </summary>
    protected void ResetMats()
    {
        if (Renderers != null && mIsSetReplaceMat)
        {
            mIsSetReplaceMat = false;
            for (int i = 0; i < Renderers.Length; i++)
            {
               Renderers[i].sharedMaterials = Mats[i];
            }
        }
    }

    /// <summary>
    /// 设置MaterialPropertyBlock
    /// </summary>
    /// <param name="mpb"></param>
    protected void SetMPB(MaterialPropertyBlock mpb)
    {
        if (Renderers != null)
        {
            mIsSetMPB = mpb != null;
            for (int i = 0; i < Renderers.Length; i++)
            {
                Renderers[i].SetPropertyBlock(mpb);
            }
        }
    }

    /// <summary>
    /// 恢复临时材质,在StatusExit调用。
    /// </summary>
    protected virtual void ResetTempMat() 
    {
        if (!IsSetTempMat || TempMats == null) return;

        foreach (var pair in TempMats)
        {
            Material ori = pair.Key;
            Material val = pair.Value;
            if(ori != null && val != null)
            {
                val.CopyPropertiesFromMaterial(ori);
            }
        }
    }

    public virtual void StatusEnter() { }
    public virtual void StatusUpdate() { }
    public virtual void StatusExit() 
    {
        ResetMats();
        if(mIsSetMPB)
        {
            SetMPB(null);
        }
        ResetTempMat();
    }
}
