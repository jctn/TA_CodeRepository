using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class PlanarReflection : MonoBehaviour
{
    private Camera reflectionCamera = null;
    private RenderTexture reflectionRT = null;
    private Material reflectionMaterial = null;

    private void OnEnable()
    {
        RenderPipelineManager.beginCameraRendering += RenderPipelineManager_beginCameraRendering;
    }

    private void OnDisable()
    {
        RenderPipelineManager.endCameraRendering -= RenderPipelineManager_beginCameraRendering;
    }

    private void RenderPipelineManager_beginCameraRendering(ScriptableRenderContext arg1, Camera arg2)
    {
        if(arg2 == Camera.main)
        {
            RenderReflection(arg1);
        }
    }

    private void RenderReflection(ScriptableRenderContext context)
    {
        if (reflectionCamera == null)
        {
            var go = new GameObject("Reflection Camera");
            reflectionCamera = go.AddComponent<Camera>();
            reflectionCamera.CopyFrom(Camera.main);
        }
        if (reflectionRT == null)
        {
            reflectionRT = RenderTexture.GetTemporary(1024, 1024, 24);
        }
        //需要实时同步相机的参数，比如编辑器下滚动滚轮，Editor相机的远近裁剪面就会变化
        UpdateCamearaParams(Camera.main, reflectionCamera);
        reflectionCamera.targetTexture = reflectionRT;
        reflectionCamera.enabled = false;

        //根据上文平面定义，需要平面法向量和平面上任意点，此处使用transform.up为法向量，transform.position为平面上的点
        //即需要保证平面模型的原点在平面上，否则可以尝试增加offset偏移
        var reflectM = CaculateReflectMatrix(transform.up, transform.position);

        reflectionCamera.worldToCameraMatrix = Camera.main.worldToCameraMatrix * reflectM;

        //需要将背面裁剪反过来，因为仅改变了顶点，没有改变法向量，绕序反向，裁剪会不对
        GL.invertCulling = true;
        UniversalRenderPipeline.RenderSingleCamera(context, reflectionCamera);
        GL.invertCulling = false;

        if (reflectionMaterial == null)
        {
            var renderer = GetComponent<Renderer>();
            reflectionMaterial = renderer.sharedMaterial;
        }
        reflectionMaterial.SetTexture("_ReflectionTex", reflectionRT);
    }

    Matrix4x4 CaculateReflectMatrix(Vector3 normal, Vector3 positionOnPlane)
    {
        var d = -Vector3.Dot(normal, positionOnPlane);
        var reflectM = new Matrix4x4();
        reflectM.m00 = 1 - 2 * normal.x * normal.x;
        reflectM.m01 = -2 * normal.x * normal.y;
        reflectM.m02 = -2 * normal.x * normal.z;
        reflectM.m03 = -2 * d * normal.x;

        reflectM.m10 = -2 * normal.x * normal.y;
        reflectM.m11 = 1 - 2 * normal.y * normal.y;
        reflectM.m12 = -2 * normal.y * normal.z;
        reflectM.m13 = -2 * d * normal.y;

        reflectM.m20 = -2 * normal.x * normal.z;
        reflectM.m21 = -2 * normal.y * normal.z;
        reflectM.m22 = 1 - 2 * normal.z * normal.z;
        reflectM.m23 = -2 * d * normal.z;

        reflectM.m30 = 0;
        reflectM.m31 = 0;
        reflectM.m32 = 0;
        reflectM.m33 = 1;
        return reflectM;
    }

    private void UpdateCamearaParams(Camera srcCamera, Camera destCamera)
    {
        if (destCamera == null || srcCamera == null)
            return;

        destCamera.clearFlags = srcCamera.clearFlags;
        destCamera.backgroundColor = srcCamera.backgroundColor;
        destCamera.farClipPlane = srcCamera.farClipPlane;
        destCamera.nearClipPlane = srcCamera.nearClipPlane;
        destCamera.orthographic = srcCamera.orthographic;
        destCamera.fieldOfView = srcCamera.fieldOfView;
        destCamera.aspect = srcCamera.aspect;
        destCamera.orthographicSize = srcCamera.orthographicSize;

        UniversalAdditionalCameraData destAdditionalData = destCamera.GetUniversalAdditionalCameraData();
        if(destAdditionalData != null)
        {
            destAdditionalData.requiresColorOption = CameraOverrideOption.Off;
            destAdditionalData.requiresDepthOption = CameraOverrideOption.Off;
        }
    }
}
