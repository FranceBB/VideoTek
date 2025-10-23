Function VideoTek(clip clp, String "Mode", String "Type", Bool "Detailed") {
    
    #Check if frame properties are there
    my_frame_properties = propGetAll(clp)
    
    #Getting info
    #Resolution
    x=Width(clp)
    y=Height(clp)
    #Framerate
    fps=FrameRate(clp)
    #ColorSpace
    colorspace=PixelType(clp)
    
    #If there are no frame properties, let's do what we can
        if (Int(my_frame_properties.ArraySize()) == 0) {
        
            #Check Frame Size to set matrix
            if (clp.Height() <= 576) {
                    clp = ConvertToYUV444(clp, matrix="PC.601")           
            }

            else {
                    clp = ConvertToYUV444(clp, matrix="PC.709")             
                }
        }
                
        #If there are SOME frame properties, let's try
        else if (Int(my_frame_properties.ArraySize()) > 0) {
         
                #Check if we have Matrix
                try {
                        if (propGetInt(clp, "_Matrix") >= 0) {
        
                        my_matrix = propGetInt(clp, "_Matrix")
                        }
                }
        
                catch (property) {
                       my_matrix = Undefined()
                       }

                #If we have matrix, we're good
                if (Defined(my_matrix) == true) {
             
                          #BT601 PAL  or BT601 NTSC 
                          if (my_matrix == 5 || my_matrix == 6) {
            
                              clp = ConvertToYUV444(clp, matrix="PC.601")
                              }
                          #BT2020   
                          else if (my_matrix == 9) {
                          
                              clp = ConvertToYUV444(clp, matrix="PC.2020")
                              }
                              
                          #if none of the above, we assume BT709
                          else {
                              clp = ConvertToYUV444(clp, matrix="PC.709")
                              }      
                }                              

                #If we have no matrix
                else if (Defined(my_matrix) == false) {

                          #Check Frame Size to set matrix
                          #If SD - BT601
                          if (clp.Height() <= 576) {
                                clp = ConvertToYUV444(clp, matrix="PC.601")           
                              }
                              
                          #Otherwise we assume BT709
                           else if (clp.Height() > 576) {
                               clp = ConvertToYUV444(clp, matrix="PC.709")             
                              }
                }
          }
    
    clp
    nChannels=(HasAudio)?AudioChannels:0                        # HasAudio = audio_samples_per_second!=0
    
    #Mode
    Mode = Default(Mode, "SDR")
    #Type
    Type = Default(Type, "volts")
    #Detailed
    Detailed = Default(Detailed, false)

    #Errors checking                                            # ssS: Might as well do at beginning (after errchk, known Planar YUV & < 13 channels)
    Assert(nChannels<13,"VideoTek: sources with more than 12 audio channels are not supported")
    
    
    #Taking care of High bit Depth
    Bpc = BitsPerComponent
    
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
    Stereoclip = Last.BlankClip(width=16,height=16).AudioDub(Stereo)  # Histogram(mode="StereoOverlay") requires 2 channel only clp.
    Picture   = BicubicResize(704, 396)
    chroma    = Histogram("color2").Crop(Width, 0, 0,256).BilinearResize(CSZ,CSZ)
    Audio     = myBlack.Crop(0,0,A_W,A_H).Histogram(Mode="audiolevels")
    lissajous = Stereoclip.Histogram(mode="StereoOverlay").BicubicResize(L_W,A_H)
    
    #Check whether we should put markers on or not
    if (Mode=="HLG" && Type=="nits" || Mode=="PQ" && Type=="nits") {
    
    luma      = TurnRight.Histogram(mode="classic", markers=false).TurnLeft.Crop(0,0,0,256).BiCubicResize(704, 396)
    
    }
    else {
    
    luma      = TurnRight.Histogram(mode="classic", markers=true).TurnLeft.Crop(0,0,0,256).BiCubicResize(704, 396)
    }
    

    #Putting the 4 blocks together with a black background
    MyBlack
    Overlay(Picture,   x=0,                   y=0)
    Overlay(luma,      x=704+6,               y=0)
    Overlay(chroma,    x=(704-chroma.Width)/2,y=396 + (920-396-chroma.height)/2)
    Overlay(Audio,     x=704-4,               y=396 + (920-396-audio.height) /2)
    Overlay(lissajous, x=700+Audio.Width,     y=396 + (920-396-lissajous.height)  /2)


    if (Mode=="HLG" && Type=="nits") {
    
    #Displaying Values for Luma (top right)
    #0 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=359.0, size=15, text_color=$0E7F84, utf8=true)
    Text("0 nits", x=1415.0, y=365.0, size=17)
    #100 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=166.0, size=15, text_color=$0E7F84, utf8=true)
    Text("100 nits", x=1415.0, y=173.0, size=17)
    #200 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=103.0, size=15, text_color=$0E7F84, utf8=true)
    Text("200 nits", x=1415.0, y=110.0, size=17)
    #400 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=77.0, size=15, text_color=$0E7F84, utf8=true)
    Text("400 nits", x=1415.0, y=84.0, size=17)
    #600 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=51.0, size=15, text_color=$0E7F84, utf8=true)
    Text("600 nits", x=1415.0, y=58.0, size=17)
    #1000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=15.0, size=15, text_color=$0E7F84, utf8=true)
    Text("1000nits", x=1415.0, y=21.0, size=17)
  
    }
    else if (Mode=="HLG" && Type=="volts") {
    
    #Displaying Values for Luma (top right)
    #Reference bottom 0%
    Text("0.00V", x=1430.0, y=362.0, size=18)
    #Reference middle 50%
    Text("0.35V", x=1430.0, y=192.0, size=18)
    #Reference White 75%
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=103.0, size=15, text_color=$0E7F84, utf8=true)
    Text("0.52V", x=1430.0, y=107.0, size=18)
    #Reference top 100%
    Text("0.70V", x=1430.0, y=20.0, size=18)
    
    }
    else if (Mode=="PQ" && Type=="nits" && Detailed==false) {
    
    #Displaying Values for Luma (top right)
    #0 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=359.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("0        nits", x=1415.0, y=366.0, size=14)
    #203 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=159.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("203     nits", x=1415.0, y=166.0, size=14)
    #1000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=101.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("1000   nits", x=1415.0, y=107.0, size=14)
    #5000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=42.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("5000   nits", x=1415.0, y=49.0, size=14)
    #10000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=15.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("10000 nits", x=1415.0, y=22.0, size=14)
    
    }
    else if (Mode=="PQ" && Type=="nits" && Detailed==true) {
    
    #Displaying Values for Luma (top right)
    #0 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=359.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("0     nits", x=1415.0, y=369.0, size=8)
    #203 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=159.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("203    nits", x=1415.0, y=169.0, size=8)
    #1000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=101.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("1000   nits", x=1415.0, y=111.0, size=8)
    #2000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=76.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("2000   nits", x=1415.0, y=86.0, size=8)
    #3000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=61.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("3000   nits", x=1415.0, y=71.0, size=8)
    #4000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=50.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("4000   nits", x=1415.0, y=60.0, size=8)
    #5000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=42.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("5000   nits", x=1415.0, y=52.0, size=8)
    #6000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=36.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("6000   nits", x=1415.0, y=46.0, size=8)
    #7000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=30.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("7000   nits", x=1415.0, y=40.0, size=8)
    #8000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=25.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("8000   nits", x=1415.0, y=34.0, size=8)
    #9000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=20.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("9000   nits", x=1415.0, y=28.0, size=8)
    #10000 nits
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=15.0, size=15, text_color=$0E7F84, utf8=true)
    Subtitle("10000 nits", x=1415.0, y=22.0, size=8)
    
    }
    
    else if (Mode=="PQ" && Type=="volts") {
    
    #Displaying Values for Luma (top right)
    #Reference bottom 0%
    Text("0.00V", x=1430.0, y=362.0, size=18)
    #Reference middle 50%
    Text("0.35V", x=1430.0, y=192.0, size=18)
    #Reference White 58%
    Subtitle("_________________________________________________________________________________________________", x=710.0, y=159.0, size=15, text_color=$0E7F84, utf8=true)
    Text("0.40V", x=1430.0, y=159.0, size=18)
    #Reference top 100%
    Text("0.70V", x=1430.0, y=20.0, size=18)
    
    }
    
    else if (Mode=="SDR" && Type=="volts") {
    
    #Displaying Values for Luma (top right)
    #Reference bottom 0%
    Text("0.00V", x=1430.0, y=362.0, size=18)
    #Reference top 50%
    Text("0.35V", x=1430.0, y=192.0, size=18)
    #Reference middle 100%
    Text("0.70V", x=1430.0, y=20.0, size=18)
    
    }
    
    else if (Mode=="SDR" && Type=="nits") {
    
    #Displaying Values for Luma (top right)
    #Reference bottom 0%
    Text("0 nits", x=1415.0, y=365.0, size=17)
    #Reference middle 50%
    Text("50 nits", x=1415.0, y=195.0, size=17)
    #Reference top 100%
    Text("100 nits", x=1415.0, y=23.0, size=17)
    
    }

    #Displaying TimeCode (bottom right), BitDepth and ColorSpace (bottom left)
    Subtitle("TC:", size=18, x=1309, y=896)
    #Adding workaround for fractional framerates
    Try{
    ShowSMPTE(size=18, x=1383, y=910)
    my_tc=last
    }
    catch(my_tc) {
    ShowTime(size=18, x=1383, y=910)
    }
    
    Subtitle(String(x) + "x" + String(y) + " " + String(fps) + "fps" + " " + String(colorspace) + " " + String(Bpc) + "Bit", size=18, x=11, y=896)

    return Last
}

