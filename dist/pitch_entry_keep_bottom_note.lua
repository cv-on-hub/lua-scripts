local a,b,c,d=(function(e)local f={[{}]=true}local g;local h={}local require;local i={}g=function(j,k)if not h[j]then h[j]=k end end;require=function(j)local l=i[j]if l then if l==f then return nil end else if not h[j]then if not e then local m=type(j)=='string'and'\"'..j..'\"'or tostring(j)error('Tried to require '..m..', but no such module has been registered')else return e(j)end end;i[j]=f;l=h[j](require,i,g,h)i[j]=l end;return l end;return require,i,g,h end)(require)c("__root",function(require,n,c,d)function plugindef()finaleplugin.RequireSelection=true;finaleplugin.Author="Nick Mazuk"finaleplugin.Copyright="CC0 https://creativecommons.org/publicdomain/zero/1.0/"finaleplugin.Version="1.0"finaleplugin.Date="June 7, 2020"finaleplugin.CategoryTags="Pitch"finaleplugin.AuthorURL="https://nickmazuk.com"return"Chord Line - Keep Bottom Note","Chord Line - Keep Bottom Note","Keeps the bottom note of every chord and deletes the rest"end;local o=require("library.note_entry")function pitch_entry_keep_bottom_note()for p in eachentrysaved(finenv.Region())do while p.Count>=2 do local q=p:CalcHighestNote(nil)o.delete_note(q)end end end;pitch_entry_keep_bottom_note()end)c("library.note_entry",function(require,n,c,d)local r={}function r.finale_version(s,t,u)local v=bit32.bor(bit32.lshift(math.floor(s),24),bit32.lshift(math.floor(t),20))if u then v=bit32.bor(v,math.floor(u))end;return v end;function r.group_overlaps_region(w,x)if x:IsFullDocumentSpan()then return true end;local y=false;local z=finale.FCSystemStaves()z:LoadAllForRegion(x)for A in each(z)do if w:ContainsStaff(A:GetStaff())then y=true;break end end;if not y then return false end;if w.StartMeasure>x.EndMeasure or w.EndMeasure<x.StartMeasure then return false end;return true end;function r.group_is_contained_in_region(w,x)if not x:IsStaffIncluded(w.StartStaff)then return false end;if not x:IsStaffIncluded(w.EndStaff)then return false end;return true end;function r.staff_group_is_multistaff_instrument(w)local B=finale.FCMultiStaffInstruments()B:LoadAll()for C in each(B)do if C:ContainsStaff(w.StartStaff)and C.GroupID==w:GetItemID()then return true end end;return false end;function r.get_selected_region_or_whole_doc()local D=finenv.Region()if D:IsEmpty()then D:SetFullDocument()end;return D end;function r.get_first_cell_on_or_after_page(E)local F=E;local G=finale.FCPage()local H=false;while G:Load(F)do if G:GetFirstSystem()>0 then H=true;break end;F=F+1 end;if H then local I=finale.FCStaffSystem()I:Load(G:GetFirstSystem())return finale.FCCell(I.FirstMeasure,I.TopStaff)end;local J=finale.FCMusicRegion()J:SetFullDocument()return finale.FCCell(J.EndMeasure,J.EndStaff)end;function r.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local K=finale.FCMusicRegion()K:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),K.StartStaff)end;return r.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function r.get_top_left_selected_or_visible_cell()local D=finenv.Region()if not D:IsEmpty()then return finale.FCCell(D.StartMeasure,D.StartStaff)end;return r.get_top_left_visible_cell()end;function r.is_default_measure_number_visible_on_cell(L,M,N,O)local P=finale.FCCurrentStaffSpec()if not P:LoadForCell(M,0)then return false end;if L:GetShowOnTopStaff()and M.Staff==N.TopStaff then return true end;if L:GetShowOnBottomStaff()and M.Staff==N:CalcBottomStaff()then return true end;if P.ShowMeasureNumbers then return not L:GetExcludeOtherStaves(O)end;return false end;function r.is_default_number_visible_and_left_aligned(L,M,Q,O,R)if L.UseScoreInfoForParts then O=false end;if R and L:GetShowOnMultiMeasureRests(O)then if finale.MNALIGN_LEFT~=L:GetMultiMeasureAlignment(O)then return false end elseif M.Measure==Q.FirstMeasure then if not L:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=L:GetStartAlignment(O)then return false end else if not L:GetShowMultiples(O)then return false end;if finale.MNALIGN_LEFT~=L:GetMultipleAlignment(O)then return false end end;return r.is_default_measure_number_visible_on_cell(L,M,Q,O)end;function r.update_layout(S,T)S=S or 1;T=T or false;local U=finale.FCPage()if U:Load(S)then U:UpdateLayout(T)end end;function r.get_current_part()local V=finale.FCParts()V:LoadAll()return V:GetCurrent()end;function r.get_page_format_prefs()local W=r.get_current_part()local X=finale.FCPageFormatPrefs()local Y=false;if W:IsScore()then Y=X:LoadScore()else Y=X:LoadParts()end;return X,Y end;function r.get_smufl_metadata_file(Z)if not Z then Z=finale.FCFontInfo()Z:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local _=function(a0,Z)local a1=a0 .."/SMuFL/Fonts/"..Z.Name.."/"..Z.Name..".json"return io.open(a1,"r")end;local a2=""if finenv.UI():IsOnWindows()then a2=os.getenv("LOCALAPPDATA")else a2=os.getenv("HOME").."/Library/Application Support"end;local a3=_(a2,Z)if nil~=a3 then return a3 end;local a4="/Library/Application Support"if finenv.UI():IsOnWindows()then a4=os.getenv("COMMONPROGRAMFILES")end;return _(a4,Z)end;function r.is_font_smufl_font(Z)if not Z then Z=finale.FCFontInfo()Z:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=r.finale_version(27,1)then if nil~=Z.IsSMuFLFont then return Z.IsSMuFLFont end end;local a5=r.get_smufl_metadata_file(Z)if nil~=a5 then io.close(a5)return true end;return false end;function r.simple_input(a6,a7)local a8=finale.FCString()a8.LuaString=""local a9=finale.FCString()local aa=160;function format_ctrl(ab,ac,ad,ae)ab:SetHeight(ac)ab:SetWidth(ad)a9.LuaString=ae;ab:SetText(a9)end;title_width=string.len(a6)*6+54;if title_width>aa then aa=title_width end;text_width=string.len(a7)*6;if text_width>aa then aa=text_width end;a9.LuaString=a6;local af=finale.FCCustomLuaWindow()af:SetTitle(a9)local ag=af:CreateStatic(0,0)format_ctrl(ag,16,aa,a7)local ah=af:CreateEdit(0,20)format_ctrl(ah,20,aa,"")af:CreateOkButton()af:CreateCancelButton()function callback(ab)end;af:RegisterHandleCommand(callback)if af:ExecuteModal(nil)==finale.EXECMODAL_OK then a8.LuaString=ah:GetText(a8)return a8.LuaString end end;function r.is_finale_object(ai)return ai and type(ai)=="userdata"and ai.ClassName and ai.GetClassID and true or false end;function r.system_indent_set_to_prefs(Q,X)X=X or r.get_page_format_prefs()local aj=finale.FCMeasure()local ak=Q.FirstMeasure==1;if not ak and aj:Load(Q.FirstMeasure)then if aj.ShowFullNames then ak=true end end;if ak and X.UseFirstSystemMargins then Q.LeftMargin=X.FirstSystemLeft else Q.LeftMargin=X.SystemLeft end;return Q:Save()end;return r end)return a("__root")