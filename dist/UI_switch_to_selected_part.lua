local a,b,c,d=(function(e)local f={[{}]=true}local g;local h={}local require;local i={}g=function(j,k)if not h[j]then h[j]=k end end;require=function(j)local l=i[j]if l then if l==f then return nil end else if not h[j]then if not e then local m=type(j)=='string'and'\"'..j..'\"'or tostring(j)error('Tried to require '..m..', but no such module has been registered')else return e(j)end end;i[j]=f;l=h[j](require,i,g,h)i[j]=l end;return l end;return require,i,g,h end)(require)c("__root",function(require,n,c,d)function plugindef()finaleplugin.NoStore=true;finaleplugin.Author="CJ Garcia"finaleplugin.Copyright="© 2020 CJ Garcia Music"finaleplugin.Version="1.2"finaleplugin.Date="June 12, 2020"finaleplugin.CategoryTags="UI"return"Switch To Selected Part","Switch To Selected Part","Switches to the first part of the top staff in a selected region in a score. Switches back to the score if viewing a part."end;local o=require("library.general_library")function ui_switch_to_selected_part()local p=finenv.Region()local q=not p:IsEmpty()local r=finenv.UI()local s=o.get_top_left_selected_or_visible_cell()local t=finale.FCParts()t:LoadAll()local u=t:GetCurrent()if u:IsScore()then local v=nil;t:SortByOrderID()for w in each(t)do if not w:IsScore()and w:IsStaffIncluded(s.Staff)then v=w:GetID()break end end;if v~=nil then local w=finale.FCPart(v)w:ViewInDocument()if q then p:SetInstrumentList(0)p:SetStartStaff(s.Staff)p:SetEndStaff(s.Staff)p:SetInDocument()end;r:MoveToMeasure(s.Measure,p.StartStaff)else finenv.UI():AlertInfo("Hmm, this part doesn't seem to be generated.\nTry generating parts and try again","No Part Detected")end else local x=t:GetScore()local w=finale.FCPart(x:GetID())w:ViewInDocument()r:MoveToMeasure(s.Measure,s.Staff)end end;ui_switch_to_selected_part()end)c("library.general_library",function(require,n,c,d)local o={}function o.finale_version(y,z,A)local B=bit32.bor(bit32.lshift(math.floor(y),24),bit32.lshift(math.floor(z),20))if A then B=bit32.bor(B,math.floor(A))end;return B end;function o.group_overlaps_region(C,D)if D:IsFullDocumentSpan()then return true end;local E=false;local F=finale.FCSystemStaves()F:LoadAllForRegion(D)for G in each(F)do if C:ContainsStaff(G:GetStaff())then E=true;break end end;if not E then return false end;if C.StartMeasure>D.EndMeasure or C.EndMeasure<D.StartMeasure then return false end;return true end;function o.group_is_contained_in_region(C,D)if not D:IsStaffIncluded(C.StartStaff)then return false end;if not D:IsStaffIncluded(C.EndStaff)then return false end;return true end;function o.staff_group_is_multistaff_instrument(C)local H=finale.FCMultiStaffInstruments()H:LoadAll()for I in each(H)do if I:ContainsStaff(C.StartStaff)and I.GroupID==C:GetItemID()then return true end end;return false end;function o.get_selected_region_or_whole_doc()local J=finenv.Region()if J:IsEmpty()then J:SetFullDocument()end;return J end;function o.get_first_cell_on_or_after_page(K)local L=K;local M=finale.FCPage()local N=false;while M:Load(L)do if M:GetFirstSystem()>0 then N=true;break end;L=L+1 end;if N then local O=finale.FCStaffSystem()O:Load(M:GetFirstSystem())return finale.FCCell(O.FirstMeasure,O.TopStaff)end;local P=finale.FCMusicRegion()P:SetFullDocument()return finale.FCCell(P.EndMeasure,P.EndStaff)end;function o.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local Q=finale.FCMusicRegion()Q:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),Q.StartStaff)end;return o.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function o.get_top_left_selected_or_visible_cell()local J=finenv.Region()if not J:IsEmpty()then return finale.FCCell(J.StartMeasure,J.StartStaff)end;return o.get_top_left_visible_cell()end;function o.is_default_measure_number_visible_on_cell(R,S,T,U)local V=finale.FCCurrentStaffSpec()if not V:LoadForCell(S,0)then return false end;if R:GetShowOnTopStaff()and S.Staff==T.TopStaff then return true end;if R:GetShowOnBottomStaff()and S.Staff==T:CalcBottomStaff()then return true end;if V.ShowMeasureNumbers then return not R:GetExcludeOtherStaves(U)end;return false end;function o.is_default_number_visible_and_left_aligned(R,S,W,U,X)if R.UseScoreInfoForParts then U=false end;if X and R:GetShowOnMultiMeasureRests(U)then if finale.MNALIGN_LEFT~=R:GetMultiMeasureAlignment(U)then return false end elseif S.Measure==W.FirstMeasure then if not R:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=R:GetStartAlignment(U)then return false end else if not R:GetShowMultiples(U)then return false end;if finale.MNALIGN_LEFT~=R:GetMultipleAlignment(U)then return false end end;return o.is_default_measure_number_visible_on_cell(R,S,W,U)end;function o.update_layout(Y,Z)Y=Y or 1;Z=Z or false;local _=finale.FCPage()if _:Load(Y)then _:UpdateLayout(Z)end end;function o.get_current_part()local t=finale.FCParts()t:LoadAll()return t:GetCurrent()end;function o.get_page_format_prefs()local u=o.get_current_part()local a0=finale.FCPageFormatPrefs()local a1=false;if u:IsScore()then a1=a0:LoadScore()else a1=a0:LoadParts()end;return a0,a1 end;function o.get_smufl_metadata_file(a2)if not a2 then a2=finale.FCFontInfo()a2:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local a3=function(a4,a2)local a5=a4 .."/SMuFL/Fonts/"..a2.Name.."/"..a2.Name..".json"return io.open(a5,"r")end;local a6=""if finenv.UI():IsOnWindows()then a6=os.getenv("LOCALAPPDATA")else a6=os.getenv("HOME").."/Library/Application Support"end;local a7=a3(a6,a2)if nil~=a7 then return a7 end;local a8="/Library/Application Support"if finenv.UI():IsOnWindows()then a8=os.getenv("COMMONPROGRAMFILES")end;return a3(a8,a2)end;function o.is_font_smufl_font(a2)if not a2 then a2=finale.FCFontInfo()a2:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=o.finale_version(27,1)then if nil~=a2.IsSMuFLFont then return a2.IsSMuFLFont end end;local a9=o.get_smufl_metadata_file(a2)if nil~=a9 then io.close(a9)return true end;return false end;function o.simple_input(aa,ab)local ac=finale.FCString()ac.LuaString=""local ad=finale.FCString()local ae=160;function format_ctrl(af,ag,ah,ai)af:SetHeight(ag)af:SetWidth(ah)ad.LuaString=ai;af:SetText(ad)end;title_width=string.len(aa)*6+54;if title_width>ae then ae=title_width end;text_width=string.len(ab)*6;if text_width>ae then ae=text_width end;ad.LuaString=aa;local aj=finale.FCCustomLuaWindow()aj:SetTitle(ad)local ak=aj:CreateStatic(0,0)format_ctrl(ak,16,ae,ab)local al=aj:CreateEdit(0,20)format_ctrl(al,20,ae,"")aj:CreateOkButton()aj:CreateCancelButton()function callback(af)end;aj:RegisterHandleCommand(callback)if aj:ExecuteModal(nil)==finale.EXECMODAL_OK then ac.LuaString=al:GetText(ac)return ac.LuaString end end;function o.is_finale_object(am)return am and type(am)=="userdata"and am.ClassName and am.GetClassID and true or false end;function o.system_indent_set_to_prefs(W,a0)a0=a0 or o.get_page_format_prefs()local an=finale.FCMeasure()local ao=W.FirstMeasure==1;if not ao and an:Load(W.FirstMeasure)then if an.ShowFullNames then ao=true end end;if ao and a0.UseFirstSystemMargins then W.LeftMargin=a0.FirstSystemLeft else W.LeftMargin=a0.SystemLeft end;return W:Save()end;return o end)return a("__root")