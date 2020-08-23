using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using Random = UnityEngine.Random;

[RequireComponent(typeof(Renderer))]
public class MetaBollScr : MonoBehaviour
{
    // Start is called before the first frame update
    private Material metabollMat;
    private ComputeBuffer _computeBuffer;
    private float3 scale;
    [SerializeField] private float Gravity = 9.8f;
    [SerializeField] private float Feather = 1.0f;

    private struct metabollinfo
    {
        public float3 pos;
        public float size;
        public float3 addForce;
        public float time;
    }

    private metabollinfo[] metabollArr;

    void Start()
    {
        metabollMat = GetComponent<Renderer>().material;
        _computeBuffer = new ComputeBuffer(100, Marshal.SizeOf(typeof(metabollinfo)));
        metabollArr = new metabollinfo[100].Select(e => e = new metabollinfo()
        {
            pos = new float3(0, 0, 0),
            size = 0.01f,
            addForce = Random.insideUnitSphere * Feather,
            time = 0
        }).ToArray();
        _computeBuffer.SetData(metabollArr);
        metabollMat.SetBuffer("_metabollinfo", _computeBuffer);
        metabollMat.SetInt("_arraycount", metabollArr.Length);
        scale = this.gameObject.transform.lossyScale;
    }

    // Update is called once per frame
    void Update()
    {
        for (int i = 0; i < metabollArr.Length; i++)
        {
            if (metabollArr[i].size <= 0)
            {
                metabollArr[i].pos = new float3(0, 0, 0);
                metabollArr[i].time = 0;
                metabollArr[i].addForce = Random.insideUnitSphere * Feather * Random.value;
                metabollArr[i].size = Random.Range(0.01f, 0.75f);
            }
            else
            {
                metabollArr[i].pos += metabollArr[i].addForce - new float3(0, Gravity, 0) * metabollArr[i].time;
                metabollArr[i].time += Time.deltaTime;
                metabollArr[i].size -= 0.001f;
            }
        }

        _computeBuffer.SetData(metabollArr);
        metabollMat.SetBuffer("_metabollinfo", _computeBuffer);
        metabollMat.SetInt("_arraycount", metabollArr.Length);
    }
}