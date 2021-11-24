using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

//[ExecuteInEditMode]
[DisallowMultipleComponent]
public class StatusShowContainer : MonoBehaviour
{
    Material[][] mOriMats;
    public Material[][] OriMats
    {
        get
        {
            return mOriMats;
        }
    }

    Dictionary<Material, Material> mTempMats;
    public Dictionary<Material, Material> TempMats
    {
        get { return mTempMats; }
    }

    Renderer[] mRenderers;
    public Renderer[] Renderers
    {
        get
        {
            return mRenderers;
        }
    }

    BaseStatusShow mBaseStatus;

    public void Init()
    {
        mRenderers = GetComponentsInChildren<Renderer>();
        if (mRenderers != null)
        {
            mOriMats = new Material[mRenderers.Length][];
            for (int i = 0; i < mRenderers.Length; i++)
            {
                Material[] mats = mRenderers[i].sharedMaterials;
                mOriMats[i] = mats;
            }
        }
        CreateTempMats();
    }

    /// <summary>
    /// 设置当前状态
    /// </summary>
    /// <param name="status">null，恢复状态</param>
    public void SetStatus(BaseStatusShow status)
    {
        if(mBaseStatus != null)
        {
            mBaseStatus.StatusExit();
        }
        mBaseStatus = status;
        if (mBaseStatus != null)
        {
            mBaseStatus.MStatusShowContainer = this;
            mBaseStatus.StatusEnter();
        }
    }

    /// <summary>
    /// 创建替换材质
    /// </summary>
    private void CreateTempMats()
    {
        mTempMats = new Dictionary<Material, Material>();
        if (mOriMats != null)
        {
            for (int i = 0; i < mOriMats.Length; i++)
            {
                Material[] mMats = mOriMats[i];
                if (mMats != null)
                {
                    for (int j = 0; j < mMats.Length; j++)
                    {
                        Material mat = mMats[j];
                        if (!mTempMats.ContainsKey(mat))
                        {
                            Material tempMat = new Material(mat);
                            mTempMats.Add(mat, tempMat);
                        }
                    }
                }
            }
        }
    }

    private void Update()
    {
        if(mBaseStatus != null)
        {
            mBaseStatus.StatusUpdate();
        }
    }

    public void ForceUpdate()
    {
        if (mBaseStatus != null)
        {
            mBaseStatus.StatusExit();
            mBaseStatus.StatusEnter();
        }
    }

    /// <summary>
    /// 释放临时替换材质
    /// </summary>
    private void DisposeTempMats()
    {
        if (mTempMats != null)
        {
            foreach (var mat in mTempMats.Values)
            {
                CoreUtils.Destroy(mat);
            }
            mTempMats.Clear();
            mTempMats = null;
        }
    }

    private void OnDestroy()
    {
        if (mBaseStatus != null)
        {
            mBaseStatus.StatusExit();
        }
        StatusShowCreator.Instance.RemoveShowContainer(this);
        DisposeTempMats();
    }
}
