using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ActorTracing : MonoBehaviour
{
    public float MaxDistance = 5f;
    public float MaxAngle = 60f;
    public Transform ForwardNode;
    public float MoveSpeed = 8f;
    public float RecoverSpeed = 5f;
    public float TargetHeightCorrection = 0f;

    #region head
    [Header("Head")]
    public Transform HeadNode; //头部节点

    Quaternion hLastFrameRotation;
    #endregion

    [Header("Eye")]
    public Transform LeftEyeNode;
    public Transform RightEyeNode;

    Quaternion elLastFrameRotation;
    Quaternion erLastFrameRotation;
    [Header("Waist")]
    #region waist
    public Transform WaistNode;
    [Range(0f, 1f)]
    public float WaistWeight = 0.4f;

    Quaternion wLastFrameRotation;
    #endregion

    bool haveTarget = false;
    [SerializeField]
    Transform targetT;
    Vector3 targetH;
    Vector3 mCorrectionAngle = new Vector3(180f, 90f, 90f);
    Quaternion mCorrectionQ;
    Vector3 mLEyeCorrectionAngle = new Vector3(0f, 90f, 0f);
    Quaternion mLEyeCorrectionQ;
    Vector3 mREyeCorrectionAngle = new Vector3(0f, -90f, 180f);
    Quaternion mREyeCorrectionQ;

    float mMaxAngeleRange = 1f; //[MaxAngle - mMaxAngeleRange, MaxAngle - mMaxAngeleRange]为缓冲区，在该区域内，状态不变。
    float mMaxDisRange = 0.1f;

    #region state
    public class TracingBaseState
    {
        public virtual void OnEnter(ActorTracing m) { }
        public virtual void OnUpdate(ActorTracing m) { }
        public virtual void OnExit(ActorTracing m) { }
    }

    public class IdleState : TracingBaseState
    {
        public override void OnUpdate(ActorTracing m)
        {
            if (m.HeadNode == null || m.ForwardNode == null || !m.haveTarget)
            {
                return;
            }
            Vector3 headCurrentDirection = m.targetH - m.HeadNode.position;
            float hAngle = Vector3.Angle(m.ForwardNode.up, headCurrentDirection);
            if (hAngle <= m.MaxAngle - m.mMaxAngeleRange && headCurrentDirection.magnitude <= m.MaxDistance - m.mMaxDisRange)
            {
                m.SteState(m.mTracingState);
            }
        }

        public override void OnExit(ActorTracing m)
        {
            if (m.HeadNode) m.hLastFrameRotation = m.HeadNode.rotation;
            if (m.WaistNode) m.wLastFrameRotation = m.WaistNode.rotation;
            if (m.LeftEyeNode) m.elLastFrameRotation = m.LeftEyeNode.rotation;
            if (m.RightEyeNode) m.erLastFrameRotation = m.RightEyeNode.rotation;
        }
    }

    public class TracingState : TracingBaseState
    {
        public override void OnEnter(ActorTracing m)
        {
            UpdateNode(m);
        }

        public override void OnUpdate(ActorTracing m)
        {
            if (m.HeadNode == null || m.ForwardNode == null || !m.haveTarget)
            {
                m.SteState(m.mTracingBackState);
                return;
            }

            Vector3 headCurrentDirection = m.targetH - m.HeadNode.position;
            float hAngle = Vector3.Angle(m.ForwardNode.up, headCurrentDirection);
            if (hAngle > m.MaxAngle + m.mMaxAngeleRange || headCurrentDirection.magnitude > m.MaxDistance + m.mMaxDisRange)
            {
                m.SteState(m.mTracingBackState);
                return;
            }
            UpdateNode(m);
        }

        void UpdateNode(ActorTracing m)
        {
            Vector3 headCurrentDirection = m.targetH - m.HeadNode.position;
            Vector3 orientation = Vector3.Slerp(m.ForwardNode.up, headCurrentDirection, 0.85f);
            //waist
            if (m.WaistNode != null)
            {
                //Vector3 waistCurrentDirection = Vector3.Slerp(m.ForwardNode.up, orientation, m.WaistWeight);
                Vector3 waistCurrentDirection = Vector3.Slerp(m.WaistNode.up, orientation, m.WaistWeight);
                Quaternion waistRotation = Quaternion.LookRotation(waistCurrentDirection, Vector3.up) * m.mCorrectionQ;
                m.WaistNode.rotation = Quaternion.Slerp(m.wLastFrameRotation, waistRotation, Time.deltaTime * m.MoveSpeed);
                m.wLastFrameRotation = m.WaistNode.rotation;
            }

            //head
            if (m.HeadNode != null)
            {
                Quaternion headRotation = Quaternion.LookRotation(orientation, Vector3.up) * m.mCorrectionQ;
                m.HeadNode.rotation = Quaternion.Slerp(m.hLastFrameRotation, headRotation, Time.deltaTime * m.MoveSpeed);
                m.hLastFrameRotation = m.HeadNode.rotation;
            }

            //eye
            if (m.LeftEyeNode != null)
            {
                Vector3 leftEyeDir = headCurrentDirection;
                Quaternion leyeRotation = Quaternion.LookRotation(leftEyeDir, Vector3.up) * m.mLEyeCorrectionQ;
                m.LeftEyeNode.rotation = Quaternion.Slerp(m.elLastFrameRotation, leyeRotation, Time.deltaTime * m.MoveSpeed * 1.5f);
                m.elLastFrameRotation = m.LeftEyeNode.rotation;
            }

            if (m.RightEyeNode != null)
            {
                Vector3 rightEyeDir = headCurrentDirection;
                Quaternion reyeRotation = Quaternion.LookRotation(rightEyeDir, Vector3.up) * m.mREyeCorrectionQ;
                m.RightEyeNode.rotation = Quaternion.Slerp(m.erLastFrameRotation, reyeRotation, Time.deltaTime * m.MoveSpeed * 1.5f);
                m.erLastFrameRotation = m.RightEyeNode.rotation;
            }
        }
    }

    public class TracingBackState : TracingBaseState
    {
        public override void OnEnter(ActorTracing m)
        {
            UpdateNode(m);
        }

        public override void OnUpdate(ActorTracing m)
        {
            if (m.HeadNode != null && m.ForwardNode != null && m.haveTarget)
            {
                Vector3 headCurrentDirection = m.targetH - m.HeadNode.position;
                float hAngle = Vector3.Angle(m.ForwardNode.up, headCurrentDirection);
                if (hAngle <= m.MaxAngle - m.mMaxAngeleRange && headCurrentDirection.magnitude <= m.MaxDistance - m.mMaxDisRange)
                {
                    m.SteState(m.mTracingState);
                    return;
                }
            }

            if (Quaternion.Angle(m.hLastFrameRotation, m.HeadNode.rotation) < 0.1f)
            {
                m.SteState(m.mIdleState);
                return;
            }

            UpdateNode(m);
        }

        void UpdateNode(ActorTracing m)
        {
            if (m.WaistNode != null)
            {
                Quaternion rotation = Quaternion.Slerp(m.wLastFrameRotation, m.WaistNode.rotation, m.RecoverSpeed * Time.deltaTime);
                m.WaistNode.rotation = rotation;
                m.wLastFrameRotation = rotation;
            }

            if (m.HeadNode != null)
            {
                Quaternion rotation = Quaternion.Slerp(m.hLastFrameRotation, m.HeadNode.rotation, m.RecoverSpeed * Time.deltaTime);
                m.HeadNode.rotation = rotation;
                m.hLastFrameRotation = rotation;
            }

            //eye
            if (m.LeftEyeNode != null)
            {
                Quaternion rotation = Quaternion.Slerp(m.elLastFrameRotation, m.LeftEyeNode.rotation, m.RecoverSpeed * Time.deltaTime * 2f);
                m.LeftEyeNode.rotation = rotation;
                m.elLastFrameRotation = rotation;
            }

            if (m.RightEyeNode != null)
            {
                Quaternion rotation = Quaternion.Slerp(m.erLastFrameRotation, m.RightEyeNode.rotation, m.RecoverSpeed * Time.deltaTime * 2f);
                m.RightEyeNode.rotation = rotation;
                m.erLastFrameRotation = rotation;
            }
        }
    }
    #endregion

    TracingBaseState mCurTracingState;
    public TracingBaseState CurTracingState
    {
        get
        {
            return mCurTracingState;
        }
    }

    public TracingBaseState mIdleState = new IdleState();
    public TracingBaseState mTracingState = new TracingState();
    public TracingBaseState mTracingBackState = new TracingBackState();

    public void SteState(TracingBaseState state)
    {
        if (mCurTracingState != null)
        {
            mCurTracingState.OnExit(this);
        }
        mCurTracingState = state;
        mCurTracingState.OnEnter(this);
        //mCurTracingState.OnUpdate(this);
    }

    private void Start()
    {
        OnValidate();
        mCurTracingState = mIdleState;
        mCorrectionQ = Quaternion.Euler(mCorrectionAngle);
        mLEyeCorrectionQ = Quaternion.Euler(mLEyeCorrectionAngle);
        mREyeCorrectionQ = Quaternion.Euler(mREyeCorrectionAngle);
    }

    private void LateUpdate()
    {
        if (mCurTracingState != null)
        {
            UpdateTarget();
            mCurTracingState.OnUpdate(this);
        }
    }

    /// <summary>
    /// 添加注视对象
    /// </summary>
    /// <param name="target"></param>
    public void SetTargetPos(Vector3 target)
    {
        RemoveTarget();
        haveTarget = true;
        targetH = target;
        targetH.y += TargetHeightCorrection;
    }

    /// <summary>
    /// 添加注视对象
    /// </summary>
    /// <param name="target"></param>
    public void SetTargetPos(Transform target)
    {
        RemoveTarget();
        haveTarget = true;
        targetT = target;
    }

    /// <summary>
    ///取消注视
    /// </summary>
    public void RemoveTarget()
    {
        haveTarget = false;
        targetT = null;
    }

    private void UpdateTarget()
    {
        if (targetT)
        {
            Vector3 target = targetT.position;
            target.y += TargetHeightCorrection;
            targetH = target;
        }
    }

    private void OnValidate()
    {
        haveTarget = targetT != null;
    }
}
