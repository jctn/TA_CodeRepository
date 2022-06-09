using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class SphereAO : MonoBehaviour
{
    public float SphereRadius = 1f;

    private void OnEnable()
    {
        CapsuleAOMgr.Instance?.AddSphere(this);
    }
    private void Start()
    {
        CapsuleAOMgr.Instance?.AddSphere(this);
    }

    private void OnDisable()
    {
        CapsuleAOMgr.Instance?.RemoveSphere(this);
    }

    private void OnDrawGizmos()
    {
        Gizmos.DrawWireSphere(transform.position, SphereRadius);
    }
}
