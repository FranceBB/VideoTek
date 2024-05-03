# VideoTek
VideoTek is a Tektronix-like waveform monitor for Avisynth written by Francesco Bucciantini (aka FranceBB).
<br>
Special thanks to Stainless, magiblot and erazortt.
<br>
<br>
<br>
**Parameters**
<br>
VideoTek(clip clp, String "Mode", String "Type")
<br>
<br>
clip = input clip
<br>
<br>
String Mode = SDR
<br>
sets the mode of the source
<br>
<br>
"SDR" - Standard Dynamic Range
<br>
"HLG" - Hybrid Log Gamma
<br>
"PQ" - Perceptual Quantizer
<br>
<br>
<br>
String Type = volts
<br>
sets the display mode for luma
<br>
<br>
"volts"
<br>
"nits"
<br>
<br>

**Usage Example 1 (SDR)**
>#Indexing a video
>
>video=LWLibavVideoSource("test1.mxf")
>
>audio=LWLibavAudioSource("test1.mxf")
>
>AudioDub(video, audio)
>
>
>#Calling VideoTek without parameters for SDR videos
>
>VideoTek()

<img src="https://i.imgur.com/sHsDioV.png">

**Menu**
<br>
picture (top left), luma (top right)
<br>
chroma (bottom left), audio channels and Lissajou (bottom right)
<br>
Resolution, framerate, BitDepth (bottom left), Timecode (bottom right)
<br>

**About the example**
<br>
In the example it's possible to see how the luma is out of range and soft-highlights rollback will need to be performed.
<br>
<br>
<br>
By default, it uses the volts representation, however it's possible to use the nits representation as well.
>#Indexing a video
>
>video=LWLibavVideoSource("test2.mxf")
>
>audio=LWLibavAudioSource("test2.mxf")
>
>AudioDub(video, audio)
>
>
>#Calling VideoTek SDR with nits representation
>
>VideoTek(Mode="SDR", Type="nits")
![New File (80)001886](https://github.com/FranceBB/VideoTek/assets/18946343/c061bbb0-a649-44a2-ba86-3910aeb12d0a)
<br>
<br>
<br>
<br>


**Usage Example 2 (HDR HLG)**
>#Indexing a video
>
>video=LWLibavVideoSource("test3.mxf")
>
>audio=LWLibavAudioSource("test3.mxf")
>
>AudioDub(video, audio)
>
>
>#Calling VideoTek with HLG Mode
>
>VideoTek(Mode="HLG")
![New File (80)070475](https://github.com/FranceBB/VideoTek/assets/18946343/2059c839-085c-4fd8-a480-cffa6fe760c8)
<br>
The HLG Mode will enable the 75% Reference White marker at 0.525V
<br>
<br>
<br>

**About the example**
<br>
In the example it's possible to see how the specular highlights of the stones in the background are slightly over the 75% reference white of 0.525V.
<br>
<br>
By default, it uses the volts representation, however it's possible to use the nits representation as well.
>#Indexing a video
>
>video=LWLibavVideoSource("test4.mxf")
>
>audio=LWLibavAudioSource("test4.mxf")
>
>AudioDub(video, audio)
>
>
>#Calling VideoTek with HLG Mode
>
>VideoTek(Mode="HLG", Type="nits")
![New File (73)003356](https://github.com/FranceBB/VideoTek/assets/18946343/16b2932b-c048-4537-ba43-206580f5db74)
<br>
<br>
The nits reference in HLG mode will enable the 0, 100, 200, 400, 600 and 1000 nits markers.
<br>
<br>
<br>

**Usage Example 3 (HDR PQ)**
>#Indexing a video
>
>video=LWLibavVideoSource("test5.mxf")
>
>audio=LWLibavAudioSource("test5.mxf")
>
>AudioDub(video, audio)
>
>
>#Calling VideoTek with PQ Mode
>
>VideoTek(Mode="PQ")


![New File (2)002441](https://github.com/FranceBB/VideoTek/assets/18946343/8879d890-6548-4f67-94bb-e70271802979)
<br>
<br>
The PQ Mode will enable the 58% Reference White marker at 0.406V
<br>
<br>
<br>

**About the example**
<br>
In the example it's possible to see how the reflected light on the leaves is totally preserved and some reflections exceed the 58% reference white of 0.406V.
<br>
<br>
By default, it uses the volts representation, however it's possible to use the nits representation as well.
>#Indexing a video
>
>video=LWLibavVideoSource("test5.mxf")
>
>audio=LWLibavAudioSource("test5.mxf")
>
>AudioDub(video, audio)
>
>
>#Calling VideoTek with PQ Mode
>
>VideoTek(Mode="PQ", type="nits")
![New File (80)029489](https://github.com/FranceBB/VideoTek/assets/18946343/e008e111-7fed-4c07-83cd-02792a751a4b)
<br>
<br>
<br>
The nits reference in PQ mode will enable the 0, 203, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000 and 10000 nits markers.
