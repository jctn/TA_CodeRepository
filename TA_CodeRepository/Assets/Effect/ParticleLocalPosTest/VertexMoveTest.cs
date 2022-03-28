using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 为该粒子系统指定数量的粒子传递世界矩阵与世界矩阵的逆矩阵，以支持顶点动画，该功能只支持发射mesh，且RenderAlignment为local的粒子系统组件。
/// </summary>
[ExecuteInEditMode]
[RequireComponent(typeof(ParticleSystem))]
public class VertexMoveTest : MonoBehaviour
{
    [Range(1, 10)]
    public int MaxParticlesCount = 10;
    ParticleSystem mPS;
    ParticleSystem.Particle[] mParticles;
    ParticleSystemRenderer mPSR;
    List<Vector4> mCustomData = new List<Vector4>();

    Matrix4x4[] mMatrixArray;
    Matrix4x4[] mIMatrixArray;

    private void Update()
    {
        InitializeIfNeeded();
        int particleCount = mPS.GetParticles(mParticles);
        mPS.GetCustomParticleData(mCustomData, ParticleSystemCustomData.Custom1);

        if (mParticles.Length > 0)
        {
            for(int i = 0; i < particleCount; i++)
            {
                ParticleSystem.Particle p = mParticles[i];
                Vector3 s = p.GetCurrentSize3D(mPS);
                s.Scale(transform.lossyScale);
                Quaternion r = Quaternion.Euler(p.rotation3D);
                Vector3 t = p.position;
                if (mPS.main.simulationSpace == ParticleSystemSimulationSpace.Local)
                {
                    t += transform.position;
                }
                Matrix4x4 m = mPSR.alignment == ParticleSystemRenderSpace.Local ? Matrix4x4.Rotate(transform.rotation) * Matrix4x4.TRS(t, r, s) : Matrix4x4.TRS(t, r, s);
                mMatrixArray[i] = m;
                mIMatrixArray[i] = m.inverse;
                mCustomData[i] = new Vector4(i, 0, 0, 0);
            }

            Shader.SetGlobalMatrixArray("M", mMatrixArray);
            Shader.SetGlobalMatrixArray("IM", mIMatrixArray);
            mPS.SetCustomParticleData(mCustomData, ParticleSystemCustomData.Custom1);
        }
    }

    void InitializeIfNeeded()
    {
        if (mPS == null)
        {
            mPS = GetComponent<ParticleSystem>();
        }

        if(mPS.main.maxParticles != MaxParticlesCount)
        {
            ParticleSystem.MainModule m = mPS.main;
            m.maxParticles = MaxParticlesCount;
        }

        if (mParticles == null || mParticles.Length < mPS.main.maxParticles)
        {
            mParticles = new ParticleSystem.Particle[mPS.main.maxParticles];
        }

        if (mPSR == null)
        {
            mPSR = GetComponent<ParticleSystemRenderer>();
        }

        if (mMatrixArray == null || mMatrixArray.Length < MaxParticlesCount)
        {
            mMatrixArray = new Matrix4x4[MaxParticlesCount];
        }

        if (mIMatrixArray == null || mIMatrixArray.Length < MaxParticlesCount)
        {
            mIMatrixArray = new Matrix4x4[MaxParticlesCount];
        }
    }
}
