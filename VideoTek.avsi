#simple Videoscope by FranceBB
#special thanks to both magiblot and StainlessS
#it resembles Tektronix WVR 7020
#Accepts 8bit planar clip only.
#Accepts up to 8 audio channels

Function VideoTek(clip clp) {
    clp
    nChannels=(HasAudio)?AudioChannels:0                        # ssS, HasAudio = audio_samples_per_second!=0
    Assert(IsYV12 || isYV16 || isYV24,"VideoTek: source must be 8bit planar")
    Assert(nChannels<9,"VideoTek: sources with more than 8 audio channels are not supported")
    CSZ = 480                 # Chroma Size box (W & H)
    A_W = 320                 # Audio Box Width
    A_H = 460                 # Audio Box Height (Audio & Lissajoua)
    L_W = (704+704+6)-700-A_W # Lissajous Width
    SilentStereo=Last.BlankClip(width=1480, height=920,audio_rate=48000,channels=2,sample_type="Float")
    myBlack= (nChannels>0)  ? SilentStereo.AudioDubEx(Last) : SilentStereo.Killaudio
    Stereo = (nChannels>=2) ? Last.GetChannels(1,2) : (nChannels==1) ? MergeChannels(GetChannels(1),GetChannels(1)) : SilentStereo
    StereoClip = Last.BlankClip(width=16,height=16).AudioDub(Stereo)  # Histogram(mode="StereoOverlay") requires 2 channel only clip.
    Picture   = BicubicResize(704, 396)
    luma      = TurnRight.Histogram(mode="classic").TurnLeft.Crop(0,0,0,256).BiCubicResize(704, 396)
    chroma    = Histogram("color2").Crop(clp.Width, 0, 0,256).BilinearResize(CSZ,CSZ)
    Audio     = myBlack.Crop(0,0,A_W,A_H).Histogram(Mode="audiolevels")
    lissajous = StereoClip.Histogram(mode="StereoOverlay").BicubicResize(L_W,A_H)
    MyBlack
    Overlay(Picture,   x=0,                   y=0)
    Overlay(luma,      x=704+6,               y=0)
    Overlay(chroma,    x=(704-chroma.Width)/2,y=396 + (920-396-chroma.height)/2)
    Overlay(Audio,     x=704-4,               y=396 + (920-396-audio.height) /2)
    Overlay(lissajous, x=700+Audio.Width,     y=396 + (920-396-lissajous.height)  /2)
    return Last
}
