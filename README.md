# VideoTek
VideoTek is a Tektronix-like waveform monitor for Avisynth written by Francesco Bucciantini (aka FranceBB).
<br>
Special thanks to Stainless and magiblot
<br>
<br>
<br>
**Usage Example 1 (SDR)**
>#Indexing a video
>
>video=LWLibavVideoSource("test_shooting.mxf")
>
>audio=LWLibavAudioSource("test_shooting.mxf")
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
<br>
**Usage Example 2 (HDR HLG)**
>#Indexing a video
>
>video=LWLibavVideoSource("test_shooting.mxf")
>
>audio=LWLibavAudioSource("test_shooting.mxf")
>
>AudioDub(video, audio)
>
>
>#Calling VideoTek with HLG Mode
>
>VideoTek(Mode="HLG")


![New File (17)000266](https://user-images.githubusercontent.com/18946343/186958373-6f20978f-766d-45bd-841c-5ca0ba177b59.png)
<br>
<br>
The HLG Mode will enable the 75% Reference White marker at 0.525V
<br>
<br>
![LEO - SULLA CRESTA DELL ONDA_V4000413](https://user-images.githubusercontent.com/18946343/233964818-8bfc4ec9-f09d-41f8-bd37-34155f846ab0.png)

**Usage Example 3 (HDR PQ)**
>#Indexing a video
>
>video=LWLibavVideoSource("test_shooting_PQ.mxf")
>
>audio=LWLibavAudioSource("test_shooting_PQ.mxf")
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
