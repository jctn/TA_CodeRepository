using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering.Universal;
#if UNITY_EDITOR
using UnityEditor;
#endif

public static class PipelineUtilities
{
    private const string renderDataListFieldName = "m_RendererDataList";

#if UNITY_EDITOR
    /// <summary>
    /// 根据文件名寻找项目内ForwardRendererData文件
    /// </summary>
    /// <param name="assetName"></param>
    /// <returns></returns>
    public static ForwardRendererData GetRenderer(string assetName)
    {

        string[] GUIDs = AssetDatabase.FindAssets(assetName + " t:ForwardRendererData");

        if (GUIDs.Length == 0)
        {
            Debug.LogError("The <i>" + assetName + "</i> 无法找到！");
            return null;
        }

        string assetPath = AssetDatabase.GUIDToAssetPath(GUIDs[0]);

        ForwardRendererData data = (ForwardRendererData)AssetDatabase.LoadAssetAtPath(assetPath, typeof(ForwardRendererData));

        return data;
    }
#endif

    /// <summary>
    /// 检测给定的renderer是否加入了pipeline asset, 如果没有则加入
    /// </summary>
    /// <param name="render"></param>
    public static void ValidatePipelineRenderers(ScriptableRendererData render)
    {
        if (render == null)
        {
            Debug.LogError("render is null");
            return;
        }

        BindingFlags bindings = BindingFlags.NonPublic | BindingFlags.Instance;

        ScriptableRendererData[] m_rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).GetValue(UniversalRenderPipeline.asset);
        bool exist = false;

        for (int i = 0; i < m_rendererDataList.Length; i++)
        {
            if (m_rendererDataList[i] == render) exist = true;
        }

        if (!exist)
        {
            AddRendererToPipeline(render);
        }
    }

    private static void AddRendererToPipeline(ScriptableRendererData render)
    {
        if (render == null) return;

        BindingFlags bindings = BindingFlags.NonPublic | BindingFlags.Instance;

        ScriptableRendererData[] m_rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).GetValue(UniversalRenderPipeline.asset);
        List<ScriptableRendererData> rendererDataList = new List<ScriptableRendererData>(m_rendererDataList);
        rendererDataList.Add(render);

        typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).SetValue(UniversalRenderPipeline.asset, rendererDataList.ToArray());
    }

    /// <summary>
    /// 从pipeline asset移除给定的render
    /// </summary>
    /// <param name="render"></param>
    public static void RemoveRendererFromPipeline(ScriptableRendererData render)
    {
        if (render == null) return;

        BindingFlags bindings = BindingFlags.NonPublic | BindingFlags.Instance;

        ScriptableRendererData[] m_rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).GetValue(UniversalRenderPipeline.asset);
        List<ScriptableRendererData> rendererDataList = new List<ScriptableRendererData>(m_rendererDataList);

        if (rendererDataList.Contains(render)) rendererDataList.Remove((render));

        typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).SetValue(UniversalRenderPipeline.asset, rendererDataList.ToArray());
    }

    /// <summary>
    /// 给指定相机分配render
    /// </summary>
    /// <param name="camData"></param>
    /// <param name="render"></param>
    public static void AssignRendererToCamera(UniversalAdditionalCameraData camData, ScriptableRendererData render)
    {
        if (UniversalRenderPipeline.asset)
        {
            if (render)
            {
                BindingFlags bindings = BindingFlags.NonPublic | BindingFlags.Instance;
                ScriptableRendererData[] rendererDataList = (ScriptableRendererData[])typeof(UniversalRenderPipelineAsset).GetField(renderDataListFieldName, bindings).GetValue(UniversalRenderPipeline.asset);

                for (int i = 0; i < rendererDataList.Length; i++)
                {
                    if (rendererDataList[i] == render) camData.SetRenderer(i);
                }
            }
        }
    }
}
