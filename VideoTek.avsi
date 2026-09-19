Function VideoTek(clip clp, String "Mode", String "Type", Bool "Detailed", Bool "ExtraInfo", 
	\ Bool "HiConWave", Bool "ChromaTargets", Bool "LegalChroma", Bool "KeepRange", Bool "IgnoreMatrix") {

    #Mode: SDR, HLG, PQ
    Mode = Default(Mode, "SDR")
    #Type: volts, nits
    Type = Default(Type, "volts")
    #Detailed nits (for PQ only)
    Detailed = Default(Detailed, false)
	#Showcolor matrix and range information (detected or assumed) 
    ExtraInfo = Default(ExtraInfo, false)
	#Higher contrast waveform display
    HiConWave = Default(HiConWave, false)
	#Display 75% chroma targets (supports limited range Rec.601, Rec.709, Rec.2020)
    ChromaTargets = Default(ChromaTargets, false)
	#Legalize full-range chroma to 16-240
    LegalChroma = Default(LegalChroma, false)
	#Output range = input range, otherwise output full range
    KeepRange = Default(KeepRange, false)
	#Ignore supplied color matrix metadata, assume matrix from the resolution
    IgnoreMatrix = Default(IgnoreMatrix, false)

	#------------------------------------------------------------

    #Getting info
    #Resolution
    x = Width(clp)
    y = Height(clp)
    #Framerate
    fps = FrameRate(clp)
    #ColorSpace
    colorSpace = PixelType(clp)
    #Bit Depth
    Bpc = BitsPerComponent(clp)

	#Check if we have Matrix
	try {
		if (propGetInt(clp, "_Matrix") >= 0) {
			colorMatrix = propGetInt(clp, "_Matrix")
		}
	}
	catch (property) {
		colorMatrix = 2
	}
	assumedRange = ""
	#Check if we have ColorRange
	try {
		if (propGetInt(clp, "_ColorRange") >= 0) {
			colorRange = propGetInt(clp, "_ColorRange")
		}
	}
	catch (property) {
		colorRange = 1
		#colorRange = (colorMatrix == 0) ? 0 : 1
		assumedRange = "(assumed)"
	}

	clp = clp.propClearAll()

	assumedMatrix = ""
	#If matrix is unspecified (also ignore 'rgb' matrix)
	if (IgnoreMatrix || colorMatrix == 0 || colorMatrix == 2 || colorMatrix == 3 || colorMatrix > 10) {
		#Check Frame Size to set matrix
		#If SD - BT601
		if (y <= 576) {
			clp = ConvertToYUV444(clp, matrix="PC.601")
			colorMatrix = 5
			if (y == 240 || (y >= 480 && y <= 486)) {
				colorMatrix = 6
			}
		}
		#If HDR & UHD - BT2020
		else if (Bpc >= 10 && (x >= 3840 || y >= 2160)) {
			clp = ConvertToYUV444(clp, matrix="PC.2020")   
			colorMatrix = 9
		}
		#Otherwise we assume BT709
		else {
			clp = ConvertToYUV444(clp, matrix="PC.709")   
			colorMatrix = 1
		}
		assumedMatrix = "(assumed)"
	}
	else {
		matrix = ["rgb","709","unspec","unspec","fcc","470bg","170m","240m","ycgco","2020","2020cl"]
		clp = ConvertToYUV444(clp, matrix=matrix[colorMatrix]+":f")
	}
	
	clp
    
	(HasAlpha) ? RemoveAlphaPlane : NOP          # ssS: Avoid eg YUVA444 error in VirtualDub2 (OK in PotPlayer but grey screen in VD2 if YUVA) 
	
	ConvertBits(8)                          # ssS: Convert To YUV444, 8 bit, NO ALPHA, support all colorspace input
    clplq = last

    nChannels = (HasAudio) ? AudioChannels : 0                        # HasAudio = audio_samples_per_second!=0  
	#Errors checking
    Assert(nChannels < 13, "VideoTek: sources with more than 12 audio channels are not supported") 

    #Main
    CSZ = 480                 # Chroma Size box (W & H)
    A_W = 320                 # Audio Box Width
    A_H = 460                 # Audio Box Height (Audio & Lissajoua)
    L_W = (704+704+6)-700-A_W # Lissajous Width
       
	#Chroma targets
	target = Blackness(width = 4, height = 4)
	target = StackVertical(StackHorizontal(
	\target.AddBorders(1, 1, 0, 0, $FFFFFF), 
	\target.AddBorders(1, 1, 1, 0, $FFFFFF)), StackHorizontal(
	\target.AddBorders(1, 1, 0, 1, $FFFFFF), 
	\target.AddBorders(1, 1, 1, 1, $FFFFFF))).AddBorders(1, 0, 0, 0)
	
	targets601 = Blackness(width = 256, height = 256)
	\.Overlay(target, 66, 53, mode = "Add", pc_range=true)
	\.Overlay(target, 150, 39, mode = "Add", pc_range=true)
	\.Overlay(target, 38, 137, mode = "Add", pc_range=true)
	\.Overlay(target, 94, 207, mode = "Add", pc_range=true)
	\.Overlay(target, 178, 193, mode = "Add", pc_range=true)
	\.Overlay(target, 206, 109, mode = "Add", pc_range=true)
	
	targets709 = Blackness(width = 256, height = 256)
	\.Overlay(target, 57, 47, mode = "Add", pc_range=true)
	\.Overlay(target, 141, 39, mode = "Add", pc_range=true)
	\.Overlay(target, 38, 131, mode = "Add", pc_range=true)
	\.Overlay(target, 103, 207, mode = "Add", pc_range=true)
	\.Overlay(target, 187, 199, mode = "Add", pc_range=true)
	\.Overlay(target, 206, 115, mode = "Add", pc_range=true)

	targets2020 = Blackness(width = 256, height = 256)
	\.Overlay(target, 61, 46, mode = "Add", pc_range=true)
	\.Overlay(target, 145, 39, mode = "Add", pc_range=true)
	\.Overlay(target, 38, 130, mode = "Add", pc_range=true)
	\.Overlay(target, 98, 207, mode = "Add", pc_range=true)
	\.Overlay(target, 183, 200, mode = "Add", pc_range=true)
	\.Overlay(target, 206, 116, mode = "Add", pc_range=true)

	SilentStereo = Last.BlankClip(width=1480, height=920, audio_rate=48000, channels=2, sample_type="Float")
    myBlack = (nChannels > 0) ? SilentStereo.AudioDubEx(Last) : SilentStereo.Killaudio
    Stereo = (nChannels >= 2) ? clplq.GetChannels(1, 2) : (nChannels==1) ? MergeChannels(GetChannels(1), GetChannels(1)) : SilentStereo
    Stereoclip = clplq.BlankClip(width=16, height=16).AudioDub(Stereo)  # Histogram(mode="StereoOverlay") requires 2 channel only clp.
    Picture = BicubicResize(704, 396)	
	if(colorRange == 0 && LegalChroma) {
		legal = MergeChroma(Last, Last.ColorYUV(Levels="PC->TV"), 1.0)
		legal
	}
	chroma = Histogram("color2").Crop(Width, 0, 0, 256)
	if (ChromaTargets && (colorRange == 1 || LegalChroma)) {
		if (colorMatrix == 1) {
			chroma = chroma.Overlay(targets709, mode="Add", opacity = 0.5, pc_range=true).Text("Rec.709 75%", size=12, text_color=$FFFFFF)
		}
		else if (colorMatrix == 5 || colormatrix == 6) {
			chroma = chroma.Overlay(targets601, mode="Add", opacity = 0.5, pc_range=true).Text("Rec.601 75%", size=12, text_color=$FFFFFF)
		}
		else if (colorMatrix == 9 || colormatrix == 10) {
			chroma = chroma.Overlay(targets2020, mode="Add", opacity = 0.5, pc_range=true).Text("Rec.2020 75%", size=12, text_color=$FFFFFF)
		}
	}
	if(colorRange == 0 && LegalChroma) {
		chroma = chroma.Text("Legalized", x=190, size=12, text_color=$FFFFFF)
	}
	chroma = chroma.BicubicResize(CSZ, CSZ)
    Audio = myBlack.Crop(0, 0, A_W, A_H).Histogram(Mode="audiolevels")
    lissajous = Stereoclip.Histogram(mode="StereoOverlay").BicubicResize(L_W, A_H)
    
    #Check whether we should put markers on or not
    if (Mode=="HLG" && Type=="nits" || Mode=="PQ" && Type=="nits") {    
		luma = clplq.TurnRight.Histogram(mode="classic", markers=false).TurnLeft.Crop(0, 0, 0, 256)
    }
    else {    
		luma = clplq.TurnRight.Histogram(mode="classic", markers=true).TurnLeft.Crop(0, 0, 0, 256)
    }
    
    
	if (HiConWave) {
		hcluma = luma.Crop(0,20,0,220).Levels(16, 2.0, 128, 0, 255, coring=false)
		luma = Overlay(luma, hcluma, 0, 20)
	}
	

	luma = luma.BiCubicResize(704, 396)

    #Putting the 4 blocks together with a black background
    MyBlack
    Overlay(Picture,   x=0,                   y=0)
    Overlay(luma,      x=704+6,               y=0)
    Overlay(chroma,    x=(704-chroma.Width)/2,y=396 + (920-396-chroma.height)/2)
    Overlay(Audio,     x=704-4,               y=396 + (920-396-audio.height)/2)
    Overlay(lissajous, x=700+Audio.Width,     y=396 + (920-396-lissajous.height)/2)


    if (Mode=="HLG" && Type=="nits" && HiConWave==false) {    
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
    else if (Mode=="HLG" && Type=="nits" && HiConWave==true) {    
		#Displaying Values for Luma (top right)
		#0 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=359.0, size=15, text_color=$00E1FF, utf8=true)
		Text("0 nits", x=1415.0, y=365.0, size=17)
		#100 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=166.0, size=15, text_color=$00E1FF, utf8=true)
		Text("100 nits", x=1415.0, y=173.0, size=17)
		#200 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=103.0, size=15, text_color=$00E1FF, utf8=true)
		Text("200 nits", x=1415.0, y=110.0, size=17)
		#400 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=77.0, size=15, text_color=$00E1FF, utf8=true)
		Text("400 nits", x=1415.0, y=84.0, size=17)
		#600 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=51.0, size=15, text_color=$00E1FF, utf8=true)
		Text("600 nits", x=1415.0, y=58.0, size=17)
		#1000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=15.0, size=15, text_color=$00E1FF, utf8=true)
		Text("1000nits", x=1415.0, y=21.0, size=17)  
    }
    else if (Mode=="HLG" && Type=="volts" && HiConWave==false) {    
		#Displaying Values for Luma (top right)
		#Reference bottom 0%
		Text("0.00V", x=1422.0, y=362.0, size=18)
		#Reference middle 50%
		Text("0.35V", x=1422.0, y=192.0, size=18)
		#Reference White 75%
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=103.0, size=15, text_color=$0E7F84, utf8=true)
		Text("0.52V", x=1422.0, y=107.0, size=18)
		#Reference top 100%
		Text("0.70V", x=1422.0, y=20.0, size=18)    
    }
    else if (Mode=="HLG" && Type=="volts" && HiConWave==true) {    
		#Displaying Values for Luma (top right)
		#Reference bottom 0%
		Text("0.00V", x=1422.0, y=362.0, size=18)
		#Reference middle 50%
		Text("0.35V", x=1422.0, y=192.0, size=18)
		#Reference White 75%
		Subtitle("_________________________________________________________________________", x=710.0, y=103.0, size=20, text_color=$00E1FF, utf8=true)
		Text("0.52V", x=1422.0, y=107.0, size=18)
		#Reference top 100%
		Text("0.70V", x=1422.0, y=20.0, size=18)    
    }
    else if (Mode=="PQ" && Type=="nits" && Detailed==false && HiConWave==false) {    
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
    else if (Mode=="PQ" && Type=="nits" && Detailed==false && HiConWave==true) {    
		#Displaying Values for Luma (top right)
		#0 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=359.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("0        nits", x=1415.0, y=366.0, size=14)
		#203 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=159.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("203     nits", x=1415.0, y=166.0, size=14)
		#1000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=101.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("1000   nits", x=1415.0, y=107.0, size=14)
		#5000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=42.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("5000   nits", x=1415.0, y=49.0, size=14)
		#10000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=15.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("10000 nits", x=1415.0, y=22.0, size=14)    
    }
    else if (Mode=="PQ" && Type=="nits" && Detailed==true && HiConWave==false) {    
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
    else if (Mode=="PQ" && Type=="nits" && Detailed==true && HiConWave==true) {    
		#Displaying Values for Luma (top right)
		#0 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=359.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("0     nits", x=1415.0, y=369.0, size=8)
		#203 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=159.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("203    nits", x=1415.0, y=169.0, size=8)
		#1000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=101.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("1000   nits", x=1415.0, y=111.0, size=8)
		#2000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=76.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("2000   nits", x=1415.0, y=86.0, size=8)
		#3000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=61.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("3000   nits", x=1415.0, y=71.0, size=8)
		#4000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=50.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("4000   nits", x=1415.0, y=60.0, size=8)
		#5000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=42.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("5000   nits", x=1415.0, y=52.0, size=8)
		#6000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=36.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("6000   nits", x=1415.0, y=46.0, size=8)
		#7000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=30.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("7000   nits", x=1415.0, y=40.0, size=8)
		#8000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=25.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("8000   nits", x=1415.0, y=34.0, size=8)
		#9000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=20.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("9000   nits", x=1415.0, y=28.0, size=8)
		#10000 nits
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=15.0, size=15, text_color=$00E1FF, utf8=true)
		Subtitle("10000 nits", x=1415.0, y=22.0, size=8)
    }
    else if (Mode=="PQ" && Type=="volts" && HiConWave==false) {    
		#Displaying Values for Luma (top right)
		#Reference bottom 0%
		Text("0.00V", x=1422.0, y=362.0, size=18)
		#Reference middle 50%
		Text("0.35V", x=1422.0, y=192.0, size=18)
		#Reference White 58%
		Subtitle("_________________________________________________________________________________________________", x=710.0, y=159.0, size=15, text_color=$0E7F84, utf8=true)
		Text("0.40V", x=1422.0, y=159.0, size=18)
		#Reference top 100%
		Text("0.70V", x=1422.0, y=20.0, size=18)    
    }
    else if (Mode=="PQ" && Type=="volts" && HiConWave==true) {    
		#Displaying Values for Luma (top right)
		#Reference bottom 0%
		Text("0.00V", x=1422.0, y=362.0, size=18)
		#Reference middle 50%
		Text("0.35V", x=1422.0, y=192.0, size=18)
		#Reference White 58%
		Subtitle("_________________________________________________________________________", x=710.0, y=159.0, size=20, text_color=$00E1FF, utf8=true)
		Text("0.40V", x=1422.0, y=159.0, size=18)
		#Reference top 100%
		Text("0.70V", x=1422.0, y=20.0, size=18)    
    }    
    else if (Mode=="SDR" && Type=="volts") {    
		#Displaying Values for Luma (top right)
		#Reference bottom 0%
		Text("0.00V", x=1422.0, y=362.0, size=18)
		#Reference middle 50%
		Text("0.35V", x=1422.0, y=192.0, size=18)
		#Reference top 100%
		Text("0.70V", x=1422.0, y=20.0, size=18)    
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
    Try {
		ShowSMPTE(size=18, x=1383, y=910)
		my_tc=last
    }
    catch(my_tc) {
		ShowTime(size=18, x=1383, y=910)
    }

	extraString = ""
	if (ExtraInfo) {
		matrixNames = ["RGB","Rec.709","Unspecified matrix","","FCC","Rec.601/BT.470BG",
			\ "Rec.601/SMPTE170M","SMPTE240M","YCgCo","Rec.2020ncl","Rec.2020cl"]
		rangeNames = ["Full range","Limited range"]
		extraString = matrixNames[colorMatrix] + assumedMatrix + " " + rangeNames[colorRange] + assumedRange
	}

    Subtitle(String(x) + "x" + String(y) + " " + String(fps) + "fps " + String(colorSpace) + " " + 
		\ String(Bpc) + "bit " + extraString, size=18, x=11, y=896)

	propSet("_Matrix", colorMatrix)
	if (KeepRange==false) {
		propSet("_ColorRange", 0)
	}

    return Last
}
