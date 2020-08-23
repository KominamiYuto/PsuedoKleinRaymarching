using System;
using JetBrains.Annotations;
using Unity.Mathematics;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using Zenject;

[ExecuteInEditMode, RequireComponent(typeof(Camera))]
public class RendertestScr : MonoBehaviour
{
    private Camera cam;
    private CommandBuffer command;
    private RenderTexture colorBuff;
    private RenderTexture depthBuff;
    [SerializeField] private Material echoMat;
    [CanBeNull] private Mesh quad;
    private Vector2 sphereRad = Vector2.zero;
    public bool Quality;

    Mesh Quad()
    {
        var mesh = new Mesh();
        mesh.vertices = new[]
        {
            new Vector3(1, 1, 0),
            new Vector3(-1, 1, 0),
            new Vector3(-1, -1, 0),
            new Vector3(1, -1, 0)
        };
        mesh.triangles = new int[6] {0, 1, 2, 0, 2, 3};
        return mesh;
    }
    private void Start()
    {
    }

    private void Update()
    {
        if (Quality)
        {
            Shader.globalMaximumLOD = 300;
        }
        else
        {
            Shader.globalMaximumLOD = 150;
        }
        float mouseAcceleration = 0.03f;
        Vector2 mouseDelta = new Vector2(Input.GetAxis("Mouse X")*mouseAcceleration,Input.GetAxis("Mouse Y")*mouseAcceleration);
        
        sphereRad = new Vector2(mouseDelta.x + sphereRad.x,Mathf.Clamp(-mouseDelta.y + sphereRad.y,-0.5f,0.5f));
        Quaternion Rotate = new Quaternion(0,Mathf.Sin(sphereRad.x),0,Mathf.Cos(sphereRad.x)) * new Quaternion(Mathf.Sin(sphereRad.y),0,0,Mathf.Cos(sphereRad.y));
        Quaternion targetRotate = quaternion.identity * Rotate;
        this.gameObject.transform.rotation = Quaternion.Slerp(this.gameObject.transform.rotation, targetRotate, 0.1f);
        //Debug.Log($"Forward : {(Vector3.up*0.8f-this.gameObject.transform.localPosition).sqrMagnitude}");
        this.gameObject.transform.position = this.gameObject.transform.parent.position + Vector3.up*0.7f-this.gameObject.transform.forward * 2;
        
    }

    private void OnPreRender()
    {
        if(cam != null)
            return;
        
        quad = quad ?? Quad();
        cam = GetComponent<Camera>();

        var com = new CommandBuffer();
        com.name = "Raymarching";
        com.DrawMesh(quad, Matrix4x4.identity, echoMat, 0, 0);
        cam.AddCommandBuffer(CameraEvent.AfterImageEffectsOpaque, com);
        
        var com2 = new CommandBuffer();
        com2.name = "RaymarchingShadow";
        com2.DrawMesh(quad, Matrix4x4.identity, echoMat, 0, 1);
        cam.AddCommandBuffer(CameraEvent.BeforeDepthTexture, com2);
        //cam.SetTargetBuffers(colorBuff.colorBuffer,depthBuff.depthBuffer);
    }
}
#if UNITY_EDITOR
public class Editorexp : EditorWindow

{
    private RendertestScr RTS;
    //https://docs.unity3d.com/ja/current/Manual/editor-EditorWindows.html
    private void OnGUI()
    {
        RTS.Quality = EditorGUILayout.Toggle ("高画質", RTS.Quality);
    }
}
#endif