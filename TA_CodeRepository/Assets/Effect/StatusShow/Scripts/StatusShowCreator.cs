using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum StatusShowType
{
    None,
    //PuppetizationStatus,
    //StonedStatus,
    //StreamlightStatus,
    //RimcolorStatus,
    //TransparentStatus,
    HitStatus,
    //IceStatus,
}

public class StatusShowCreator
{
    private static StatusShowCreator mInstance;
    public static StatusShowCreator Instance
    {
        get
        {
            if(mInstance == null)
            {
                mInstance = new StatusShowCreator();
            }
            return mInstance;
        }
    }

    private StatusShowSetting mStatusShowSetting;
    private List<StatusShowContainer> mStatusShowContainers = new List<StatusShowContainer>();

    public StatusShowCreator()
    {
        LoadSettingData();
    }

    public void LoadSettingData()
    {
        mStatusShowSetting = Resources.Load<StatusShowSetting>("StatusShowSetting");
    }

    /// <summary>
    /// 创建角色状态显示
    /// </summary>
    /// <param name="type">状态类型</param>
    /// <param name="roleShowRoot">角色显示节点，需能向下找到render组件</param>
    /// <param name="argus">额外参数</param>
    public BaseStatusShow CreateStatusShow(StatusShowType type, Transform roleShowRoot, params object[] argus)
    {
        if (roleShowRoot == null || mStatusShowSetting == null) return null;

        StatusShowContainer statusContainer = roleShowRoot.GetComponent<StatusShowContainer>();
        if (statusContainer == null)
        {
            statusContainer = roleShowRoot.gameObject.AddComponent<StatusShowContainer>();
            statusContainer.Init();
        }
        if(!mStatusShowContainers.Contains(statusContainer))
        {
            mStatusShowContainers.Add(statusContainer);
        }

        BaseStatusShow statusShow = null;
        switch (type)
        {
            case StatusShowType.HitStatus:
                statusShow = mStatusShowSetting.HitStatusShowData.CreateInstance();
                break;
        }
        statusContainer.SetStatus(statusShow);
        return statusShow;
    }

    /// <summary>
    /// 强制刷新显示，用于更改了配置文件后更新显示效果
    /// </summary>
    public void ForceUpdateStatus()
    {
        foreach(var s in mStatusShowContainers)
        {
            if(s != null)
            {
                s.ForceUpdate();
            }
        }
    }

    public void RemoveShowContainer(StatusShowContainer showContainer)
    {
       if(showContainer != null)
       {
            mStatusShowContainers.Remove(showContainer);
       }
    }
}
