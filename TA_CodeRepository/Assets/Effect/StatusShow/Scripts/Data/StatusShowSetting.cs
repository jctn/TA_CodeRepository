using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "StatusShowSetting", menuName = "Code Repository/Effect/StatusShowSetting")]
public class StatusShowSetting : ScriptableObject
{
    [Header("Hit")]
    public HitStatusShowData HitStatusShowData;

    private void OnValidate()
    {
        StatusShowCreator.Instance.ForceUpdateStatus();
    }
}
