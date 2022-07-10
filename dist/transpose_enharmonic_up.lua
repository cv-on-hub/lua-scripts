local a,b,c,d=(function(e)local f={[{}]=true}local g;local h={}local require;local i={}g=function(j,k)if not h[j]then h[j]=k end end;require=function(j)local l=i[j]if l then if l==f then return nil end else if not h[j]then if not e then local m=type(j)=='string'and'\"'..j..'\"'or tostring(j)error('Tried to require '..m..', but no such module has been registered')else return e(j)end end;i[j]=f;l=h[j](require,i,g,h)i[j]=l end;return l end;return require,i,g,h end)(require)c("__root",function(require,n,c,d)function plugindef()finaleplugin.RequireSelection=true;finaleplugin.Author="Robert Patterson"finaleplugin.Copyright="CC0 https://creativecommons.org/publicdomain/zero/1.0/"finaleplugin.Version="1.0"finaleplugin.Date="March 25, 2021"finaleplugin.CategoryTags="Pitch"finaleplugin.Notes=[[
        In normal 12-note music, enharmonically transposing is the same as transposing by a diminished 2nd.
        However, in some microtone systems (specifically 19-EDO and 31-EDO), enharmonic transposition produces a different result
        than chromatic transposition. As an example, C is equivalent to Dbb in 12-tone systems. But in 31-EDO, C is five microsteps
        lower than D whereas Dbb is four microsteps lower than D. Transposing C up a diminished 2nd gives Dbb in either system, but
        in 31-EDO, Dbb is not the same pitch as C.
        
        If you are using custom key signatures with JW Lua or an early version of RGP Lua, you must create
        a `custom_key_sig.config.txt` file in a folder called `script_settings` within the same folder as the script.
        It should contains the following two lines that define the custom key signature you are using. Unfortunately,
        the JW Lua and early versions of RGP Lua do not allow scripts to read this information from the Finale document.
        
        (This example is for 31-EDO.)
        
        ```
        number_of_steps = 31
        diatonic_steps = {0, 5, 10, 13, 18, 23, 28}
        ```
        Later versions of RGP Lua (0.58 or higher) ignore this configuration file (if it exists) and read the correct
        information from the Finale document.
    ]]return"Enharmonic Transpose Up","Enharmonic Transpose Up","Transpose up enharmonically all notes in selected regions."end;local o=require("library.transposition")function transpose_enharmonic_up()local p=true;for q in eachentrysaved(finenv.Region())do for r in each(q)do if not o.enharmonic_transpose(r,1)then p=false end end end;if not p then finenv.UI():AlertError("Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.","Transposition Error")end end;transpose_enharmonic_up()end)c("library.transposition",function(require,n,c,d)local s={}function s.finale_version(t,u,v)local w=bit32.bor(bit32.lshift(math.floor(t),24),bit32.lshift(math.floor(u),20))if v then w=bit32.bor(w,math.floor(v))end;return w end;function s.group_overlaps_region(x,y)if y:IsFullDocumentSpan()then return true end;local z=false;local A=finale.FCSystemStaves()A:LoadAllForRegion(y)for B in each(A)do if x:ContainsStaff(B:GetStaff())then z=true;break end end;if not z then return false end;if x.StartMeasure>y.EndMeasure or x.EndMeasure<y.StartMeasure then return false end;return true end;function s.group_is_contained_in_region(x,y)if not y:IsStaffIncluded(x.StartStaff)then return false end;if not y:IsStaffIncluded(x.EndStaff)then return false end;return true end;function s.staff_group_is_multistaff_instrument(x)local C=finale.FCMultiStaffInstruments()C:LoadAll()for D in each(C)do if D:ContainsStaff(x.StartStaff)and D.GroupID==x:GetItemID()then return true end end;return false end;function s.get_selected_region_or_whole_doc()local E=finenv.Region()if E:IsEmpty()then E:SetFullDocument()end;return E end;function s.get_first_cell_on_or_after_page(F)local G=F;local H=finale.FCPage()local I=false;while H:Load(G)do if H:GetFirstSystem()>0 then I=true;break end;G=G+1 end;if I then local J=finale.FCStaffSystem()J:Load(H:GetFirstSystem())return finale.FCCell(J.FirstMeasure,J.TopStaff)end;local K=finale.FCMusicRegion()K:SetFullDocument()return finale.FCCell(K.EndMeasure,K.EndStaff)end;function s.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local L=finale.FCMusicRegion()L:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),L.StartStaff)end;return s.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function s.get_top_left_selected_or_visible_cell()local E=finenv.Region()if not E:IsEmpty()then return finale.FCCell(E.StartMeasure,E.StartStaff)end;return s.get_top_left_visible_cell()end;function s.is_default_measure_number_visible_on_cell(M,N,O,P)local Q=finale.FCCurrentStaffSpec()if not Q:LoadForCell(N,0)then return false end;if M:GetShowOnTopStaff()and N.Staff==O.TopStaff then return true end;if M:GetShowOnBottomStaff()and N.Staff==O:CalcBottomStaff()then return true end;if Q.ShowMeasureNumbers then return not M:GetExcludeOtherStaves(P)end;return false end;function s.is_default_number_visible_and_left_aligned(M,N,R,P,S)if M.UseScoreInfoForParts then P=false end;if S and M:GetShowOnMultiMeasureRests(P)then if finale.MNALIGN_LEFT~=M:GetMultiMeasureAlignment(P)then return false end elseif N.Measure==R.FirstMeasure then if not M:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=M:GetStartAlignment(P)then return false end else if not M:GetShowMultiples(P)then return false end;if finale.MNALIGN_LEFT~=M:GetMultipleAlignment(P)then return false end end;return s.is_default_measure_number_visible_on_cell(M,N,R,P)end;function s.update_layout(T,U)T=T or 1;U=U or false;local V=finale.FCPage()if V:Load(T)then V:UpdateLayout(U)end end;function s.get_current_part()local W=finale.FCParts()W:LoadAll()return W:GetCurrent()end;function s.get_page_format_prefs()local X=s.get_current_part()local Y=finale.FCPageFormatPrefs()local p=false;if X:IsScore()then p=Y:LoadScore()else p=Y:LoadParts()end;return Y,p end;function s.get_smufl_metadata_file(Z)if not Z then Z=finale.FCFontInfo()Z:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local _=function(a0,Z)local a1=a0 .."/SMuFL/Fonts/"..Z.Name.."/"..Z.Name..".json"return io.open(a1,"r")end;local a2=""if finenv.UI():IsOnWindows()then a2=os.getenv("LOCALAPPDATA")else a2=os.getenv("HOME").."/Library/Application Support"end;local a3=_(a2,Z)if nil~=a3 then return a3 end;local a4="/Library/Application Support"if finenv.UI():IsOnWindows()then a4=os.getenv("COMMONPROGRAMFILES")end;return _(a4,Z)end;function s.is_font_smufl_font(Z)if not Z then Z=finale.FCFontInfo()Z:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=s.finale_version(27,1)then if nil~=Z.IsSMuFLFont then return Z.IsSMuFLFont end end;local a5=s.get_smufl_metadata_file(Z)if nil~=a5 then io.close(a5)return true end;return false end;function s.simple_input(a6,a7)local a8=finale.FCString()a8.LuaString=""local a9=finale.FCString()local aa=160;function format_ctrl(ab,ac,ad,ae)ab:SetHeight(ac)ab:SetWidth(ad)a9.LuaString=ae;ab:SetText(a9)end;title_width=string.len(a6)*6+54;if title_width>aa then aa=title_width end;text_width=string.len(a7)*6;if text_width>aa then aa=text_width end;a9.LuaString=a6;local af=finale.FCCustomLuaWindow()af:SetTitle(a9)local ag=af:CreateStatic(0,0)format_ctrl(ag,16,aa,a7)local ah=af:CreateEdit(0,20)format_ctrl(ah,20,aa,"")af:CreateOkButton()af:CreateCancelButton()function callback(ab)end;af:RegisterHandleCommand(callback)if af:ExecuteModal(nil)==finale.EXECMODAL_OK then a8.LuaString=ah:GetText(a8)return a8.LuaString end end;function s.is_finale_object(ai)return ai and type(ai)=="userdata"and ai.ClassName and ai.GetClassID and true or false end;function s.system_indent_set_to_prefs(R,Y)Y=Y or s.get_page_format_prefs()local aj=finale.FCMeasure()local ak=R.FirstMeasure==1;if not ak and aj:Load(R.FirstMeasure)then if aj.ShowFullNames then ak=true end end;if ak and Y.UseFirstSystemMargins then R.LeftMargin=Y.FirstSystemLeft else R.LeftMargin=Y.SystemLeft end;return R:Save()end;return s end)return a("__root")