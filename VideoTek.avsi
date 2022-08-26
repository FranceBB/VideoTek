Function VideoTek(clip clp, String "Mode") {
    clp
    nChannels=(HasAudio)?AudioChannels:0                        # HasAudio = audio_samples_per_second!=0

    #Errors checking                                            # ssS: Might as well do at beginning (after errchk, known Planar YUV & < 9 channels)
    Assert(nChannels<9,"VideoTek: sources with more than 8 audio channels are not supported")
    
    #Mode
    Mode = Default(Mode, "SDR")

    #Getting info
    #Resolution
    x=Width()
    y=Height()
    #Framerate
    fps=FrameRate()
    #ColorSpace
    colorspace=PixelType()

    #Taking care of High bit Depth
    Bpc = BitsPerComponent

    ConvertToYUV444
    (HasAlpha) ? RemoveAlphaPlane : NOP          # ssS: Avoid eg YUVA444 error in VirtualDub2 (OK in PotPlayer but grey screen in VD2 if YUVA)
    ConvertBits(bits=8)                          # ssS: Convert To YUV444, 8 bit, NO ALPHA, support all colorspace input

    #Main
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
    chroma    = Histogram("color2").Crop(Width, 0, 0,256).BilinearResize(CSZ,CSZ)
    Audio     = myBlack.Crop(0,0,A_W,A_H).Histogram(Mode="audiolevels")
    lissajous = StereoClip.Histogram(mode="StereoOverlay").BicubicResize(L_W,A_H)

    #Putting the 4 blocks together with a black background
    MyBlack
    Overlay(Picture,   x=0,                   y=0)
    Overlay(luma,      x=704+6,               y=0)
    Overlay(chroma,    x=(704-chroma.Width)/2,y=396 + (920-396-chroma.height)/2)
    Overlay(Audio,     x=704-4,               y=396 + (920-396-audio.height) /2)
    Overlay(lissajous, x=700+Audio.Width,     y=396 + (920-396-lissajous.height)  /2)

    
    if (Mode == "HLG") {
    
    #Reference White 75%
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=65.0, size=15, text_color=$0E7F84, utf8=true)
    Text("0.52V", x=1430.0, y=69.0, size=18)
    }

    
    #Displaying Values for Luma (top right)
    Text("0.00V", x=1430.0, y=362.0, size=18)
    Text("0.70V", x=1430.0, y=20.0, size=18)
    Text("0.35V", x=1430.0, y=192.0, size=18)

    #Displaying TimeCode (bottom right), BitDepth and ColorSpace (bottom left)
    Subtitle("TC:", size=18, x=1309, y=896)
    ShowSMPTE(size=18, x=1383, y=910)
    Subtitle(String(x) + "x" + String(y) + " " + String(fps) + "fps" + " " + String(colorspace) + " " + String(Bpc) + "Bit", size=18, x=11, y=896)

    return Last
}
