using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[ExecuteInEditMode]
public class StatusPreview : MonoBehaviour
{
    public Transform Root;
    public StatusShowType StatusShowType = StatusShowType.None;

    StatusShowType preStatusShowType = StatusShowType.None;

    private void Update()
    {
        if (Root != null)
        {
            if (preStatusShowType != StatusShowType)
            {
                preStatusShowType = StatusShowType;
                StatusShowCreator.Instance.CreateStatusShow(StatusShowType, Root);
            }
        }
    }
}
