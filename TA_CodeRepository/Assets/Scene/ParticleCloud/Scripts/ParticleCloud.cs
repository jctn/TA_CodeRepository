using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ParticleCloud : MonoBehaviour
{
    private void OnEnable()
    {
        ParticleCloudMgr.Instance.AddParticleCloud(this);
    }

    private void OnDisable()
    {
        ParticleCloudMgr.Instance.RemoveParticleCloud(this);
    }
}
