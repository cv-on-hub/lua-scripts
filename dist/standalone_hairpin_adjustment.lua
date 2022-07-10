local a,b,c,d=(function(e)local f={[{}]=true}local g;local h={}local require;local i={}g=function(j,k)if not h[j]then h[j]=k end end;require=function(j)local l=i[j]if l then if l==f then return nil end else if not h[j]then if not e then local m=type(j)=='string'and'\"'..j..'\"'or tostring(j)error('Tried to require '..m..', but no such module has been registered')else return e(j)end end;i[j]=f;l=h[j](require,i,g,h)i[j]=l end;return l end;return require,i,g,h end)(require)c("__root",function(require,n,c,d)function plugindef()finaleplugin.RequireSelection=true;finaleplugin.Author="CJ Garcia"finaleplugin.Copyright="© 2021 CJ Garcia Music"finaleplugin.Version="1.2"finaleplugin.Date="2/29/2021"return"Hairpin and Dynamic Adjustments","Hairpin and Dynamic Adjustments","Adjusts hairpins to remove collisions with dynamics and aligns hairpins with dynamics."end;local o=require("library.expression")local p=require("library.note_entry")local q=require("library.configuration")local r={left_dynamic_cushion=9,right_dynamic_cushion=-9,left_selection_cushion=0,right_selection_cushion=0,extend_to_end_of_right_entry=true,limit_to_hairpins_on_notes=true,vertical_adjustment_type="far",horizontal_adjustment_type="both",vertical_displacement_for_hairpins=12}q.get_parameters("standalone_hairpin_adjustment.config.txt",r)if finenv.IsRGPLua and finenv.QueryInvokedModifierKeys then if finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT)then if r.vertical_adjustment_type=="far"then r.vertical_adjustment_type="near"elseif r.vertical_adjustment_type=="near"then r.vertical_adjustment_type="far"end end end;function calc_cell_relative_vertical_position(s,t)local u=t;local v=s:CreateCellMetrics()if nil~=v then u=t-v.ReferenceLinePos;v:FreeMetrics()end;return u end;function expression_calc_relative_vertical_position(w)local x=finale.FCPoint(0,0)if not w:CalcMetricPos(x)then return false,0 end;local y=finale.FCCell(w.Measure,w.Staff)local z=calc_cell_relative_vertical_position(y,x:GetY())return true,z end;function smartshape_calc_relative_vertical_position(A)local x=finale.FCPoint(0,0)if not A:CalcLeftCellMetricPos(x)then return false,0 end;local B=A:GetTerminateSegmentLeft()local y=finale.FCCell(B.Measure,B.Staff)local z=calc_cell_relative_vertical_position(y,x:GetY())return true,z end;function vertical_dynamic_adjustment(C,D)local E={}local F={}local G=false;local H=false;local I=finale.FCExpressions()I:LoadAllForRegion(C)for J in each(I)do local K=J:CreateTextExpressionDef()local L=finale.FCCategoryDef()if L:Load(K:GetCategoryID())then if L:GetID()==finale.DEFAULTCATID_DYNAMICS or string.find(L:CreateName().LuaString,"Dynamic")then local M,N=expression_calc_relative_vertical_position(J)if M then G=true;table.insert(E,N)end end end end;local O=finale.FCSmartShapeMeasureMarks()O:LoadAllForRegion(C,true)for P in each(O)do local Q=P:CreateSmartShape()if Q:IsHairpin()then H=true;local M,N=smartshape_calc_relative_vertical_position(Q)if M then table.insert(E,N-r.vertical_displacement_for_hairpins)end end end;table.sort(E)if G then local I=finale.FCExpressions()I:LoadAllForRegion(C)for J in each(I)do local K=J:CreateTextExpressionDef()local L=finale.FCCategoryDef()if L:Load(K:GetCategoryID())then if L:GetID()==finale.DEFAULTCATID_DYNAMICS or string.find(L:CreateName().LuaString,"Dynamic")then local M,N=expression_calc_relative_vertical_position(J)if M then local R=N-E[1]if D=="near"then R=E[#E]-N end;local S=J:GetVerticalPos()if D=="far"then J:SetVerticalPos(S-R)else J:SetVerticalPos(S+R)end;J:Save()end end end end else for T in eachentry(C)do if T:IsNote()then for U in each(T)do table.insert(F,U:CalcStaffPosition())end end end;table.sort(F)if nil~=F[1]and"far"==D and#E>0 then local V=E[1]if F[1]>-7 then V=-160 else local W=45;V=F[1]*12-W end;if E[1]>V then E[1]=V end end end;if H then local O=finale.FCSmartShapeMeasureMarks()O:LoadAllForRegion(C,true)for P in each(O)do local Q=P:CreateSmartShape()if Q:IsHairpin()then local M,N=smartshape_calc_relative_vertical_position(Q)if M then local X=Q:GetTerminateSegmentLeft()local Y=Q:GetTerminateSegmentRight()local S=X:GetEndpointOffsetY()local R=N-E[1]if D=="near"then R=E[#E]-N end;if G then if D=="far"then X:SetEndpointOffsetY(S-R+r.vertical_displacement_for_hairpins)Y:SetEndpointOffsetY(S-R+r.vertical_displacement_for_hairpins)else X:SetEndpointOffsetY(S+R+r.vertical_displacement_for_hairpins)Y:SetEndpointOffsetY(S+R+r.vertical_displacement_for_hairpins)end else if"far"==D then X:SetEndpointOffsetY(E[1])Y:SetEndpointOffsetY(E[1])elseif"near"==D then X:SetEndpointOffsetY(E[#E])Y:SetEndpointOffsetY(E[#E])end end;Q:Save()end end end end end;function horizontal_hairpin_adjustment(Z,_,a0,a1,a2)local a3=_:GetTerminateSegmentLeft()if Z=="left"then a3=_:GetTerminateSegmentLeft()end;if Z=="right"then a3=_:GetTerminateSegmentRight()end;local C=finale.FCMusicRegion()C:SetStartStaff(a0[1])C:SetEndStaff(a0[1])if a2 or not r.limit_to_hairpins_on_notes then C:SetStartMeasure(a3:GetMeasure())C:SetStartMeasurePos(a3:GetMeasurePos())C:SetEndMeasure(a3:GetMeasure())C:SetEndMeasurePos(a3:GetMeasurePos())else C:SetStartMeasure(a0[2])C:SetEndMeasure(a0[2])C:SetStartMeasurePos(a0[3])C:SetEndMeasurePos(a0[3])a3:SetMeasurePos(a0[3])end;local I=finale.FCExpressions()I:LoadAllForRegion(C)local a4={}for J in each(I)do local K=J:CreateTextExpressionDef()local L=finale.FCCategoryDef()if L:Load(K:GetCategoryID())then if L:GetID()==finale.DEFAULTCATID_DYNAMICS or string.find(L:CreateName().LuaString,"Dynamic")then table.insert(a4,{o.calc_text_width(K),J,J:GetItemInci()})end end end;if#a4>0 then local a5=a4[1][2]local a6=a5:CreateTextExpressionDef()local a7=a4[1][1]if finale.EXPRJUSTIFY_CENTER==a6.HorizontalJustification then a7=a7/2 elseif finale.EXPRJUSTIFY_RIGHT==a6.HorizontalJustification then a7=0 end;local a8=o.calc_handle_offset_for_smart_shape(a5)if Z=="left"then local a9=a7+r.left_dynamic_cushion+a8;a3:SetEndpointOffsetX(a9)elseif Z=="right"then a1=false;local a9=0-a7+r.right_dynamic_cushion+a8;a3:SetEndpointOffsetX(a9)end end;if a1 then a3=_:GetTerminateSegmentRight()local aa=0;if r.extend_to_end_of_right_entry then C:SetStartMeasure(a3:GetMeasure())C:SetStartMeasurePos(a3:GetMeasurePos())C:SetEndMeasure(a3:GetMeasure())C:SetEndMeasurePos(a3:GetMeasurePos())for T in eachentry(C)do local ab=p.calc_right_of_all_noteheads(T)if ab>aa then aa=ab end end end;a3:SetEndpointOffsetX(r.right_selection_cushion+aa)end;_:Save()end;function hairpin_adjustments(ac)local ad=finale.FCMusicRegion()ad:SetCurrentSelection()ad:SetStartStaff(ac[1])ad:SetEndStaff(ac[1])local ae={}local O=finale.FCSmartShapeMeasureMarks()O:LoadAllForRegion(ad,true)for P in each(O)do local af=P:CreateSmartShape()if af:IsHairpin()then table.insert(ae,af)end end;function has_dynamic(C)local I=finale.FCExpressions()I:LoadAllForRegion(C)local a4={}for J in each(I)do local K=J:CreateTextExpressionDef()local L=finale.FCCategoryDef()if L:Load(K:GetCategoryID())then if L:GetID()==finale.DEFAULTCATID_DYNAMICS or string.find(L:CreateName().LuaString,"Dynamic")then table.insert(a4,J)end end end;if#a4>0 then return true else return false end end;local ag=ac[5]local ah=not r.limit_to_hairpins_on_notes;local ai={}for T in eachentry(ad)do if T:IsNote()then table.insert(ai,T)end end;if#ai>0 then ad:SetStartMeasure(ai[#ai]:GetMeasure())ad:SetEndMeasure(ai[#ai]:GetMeasure())ad:SetStartMeasurePos(ai[#ai]:GetMeasurePos())ad:SetEndMeasurePos(ai[#ai]:GetMeasurePos())if has_dynamic(ad)and#ai>1 then local aj=ai[#ai]ag=aj:GetMeasurePos()+aj:GetDuration()elseif has_dynamic(ad)and#ai==1 then ag=ac[5]else ah=true end else ah=true end;ad:SetStartStaff(ac[1])ad:SetEndStaff(ac[1])ad:SetStartMeasure(ac[2])ad:SetEndMeasure(ac[3])ad:SetStartMeasurePos(ac[4])ad:SetEndMeasurePos(ag)if"none"~=r.horizontal_adjustment_type then local ak=#ae>1;for al,am in pairs(ae)do if"both"==r.horizontal_adjustment_type or"left"==r.horizontal_adjustment_type then horizontal_hairpin_adjustment("left",am,{ac[1],ac[2],ac[4]},ah,ak)end;if"both"==r.horizontal_adjustment_type or"right"==r.horizontal_adjustment_type then horizontal_hairpin_adjustment("right",am,{ac[1],ac[3],ag},ah,ak)end end end;if"none"~=r.vertical_adjustment_type then if"both"==r.vertical_adjustment_type or"far"==r.vertical_adjustment_type then vertical_dynamic_adjustment(ad,"far")end;if"both"==r.vertical_adjustment_type or"near"==r.vertical_adjustment_type then vertical_dynamic_adjustment(ad,"near")end end end;function set_first_last_note_in_range(an)local ao=finale.FCMusicRegion()local ac={}ao:SetCurrentSelection()ao:SetStartStaff(an)ao:SetEndStaff(an)if not r.limit_to_hairpins_on_notes then local ap=ao.EndMeasurePos;local aq=finale.FCMeasure()aq:Load(ao.EndMeasure)if ap>aq:GetDuration()then ap=aq:GetDuration()end;return{an,ao.StartMeasure,ao.EndMeasure,ao.StartMeasurePos,ap}end;local ai={}for T in eachentry(ao)do if T:IsNote()then table.insert(ai,T)end end;if#ai>0 then local ar=ai[1]:GetMeasurePos()local ag=ai[#ai]:GetMeasurePos()local as=ai[1]:GetMeasure()local at=ai[#ai]:GetMeasure()if ai[#ai]:GetDuration()>=2048 then ag=ag+ai[#ai]:GetDuration()end;return{an,as,at,ar,ag}end;return nil end;function dynamics_align_hairpins_and_dynamics()local au=finale.FCStaves()au:LoadAll()for an in each(au)do local ao=finale.FCMusicRegion()ao:SetCurrentSelection()if ao:IsStaffIncluded(an:GetItemNo())then local ac=set_first_last_note_in_range(an:GetItemNo())if nil~=ac then hairpin_adjustments(ac)end end end end;dynamics_align_hairpins_and_dynamics()end)c("library.configuration",function(require,n,c,d)local av={}function av.finale_version(aw,ax,ay)local az=bit32.bor(bit32.lshift(math.floor(aw),24),bit32.lshift(math.floor(ax),20))if ay then az=bit32.bor(az,math.floor(ay))end;return az end;function av.group_overlaps_region(aA,C)if C:IsFullDocumentSpan()then return true end;local aB=false;local aC=finale.FCSystemStaves()aC:LoadAllForRegion(C)for aD in each(aC)do if aA:ContainsStaff(aD:GetStaff())then aB=true;break end end;if not aB then return false end;if aA.StartMeasure>C.EndMeasure or aA.EndMeasure<C.StartMeasure then return false end;return true end;function av.group_is_contained_in_region(aA,C)if not C:IsStaffIncluded(aA.StartStaff)then return false end;if not C:IsStaffIncluded(aA.EndStaff)then return false end;return true end;function av.staff_group_is_multistaff_instrument(aA)local aE=finale.FCMultiStaffInstruments()aE:LoadAll()for aF in each(aE)do if aF:ContainsStaff(aA.StartStaff)and aF.GroupID==aA:GetItemID()then return true end end;return false end;function av.get_selected_region_or_whole_doc()local aG=finenv.Region()if aG:IsEmpty()then aG:SetFullDocument()end;return aG end;function av.get_first_cell_on_or_after_page(aH)local aI=aH;local aJ=finale.FCPage()local aK=false;while aJ:Load(aI)do if aJ:GetFirstSystem()>0 then aK=true;break end;aI=aI+1 end;if aK then local aL=finale.FCStaffSystem()aL:Load(aJ:GetFirstSystem())return finale.FCCell(aL.FirstMeasure,aL.TopStaff)end;local aM=finale.FCMusicRegion()aM:SetFullDocument()return finale.FCCell(aM.EndMeasure,aM.EndStaff)end;function av.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local aN=finale.FCMusicRegion()aN:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),aN.StartStaff)end;return av.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function av.get_top_left_selected_or_visible_cell()local aG=finenv.Region()if not aG:IsEmpty()then return finale.FCCell(aG.StartMeasure,aG.StartStaff)end;return av.get_top_left_visible_cell()end;function av.is_default_measure_number_visible_on_cell(aO,y,aP,aQ)local an=finale.FCCurrentStaffSpec()if not an:LoadForCell(y,0)then return false end;if aO:GetShowOnTopStaff()and y.Staff==aP.TopStaff then return true end;if aO:GetShowOnBottomStaff()and y.Staff==aP:CalcBottomStaff()then return true end;if an.ShowMeasureNumbers then return not aO:GetExcludeOtherStaves(aQ)end;return false end;function av.is_default_number_visible_and_left_aligned(aO,y,aR,aQ,aS)if aO.UseScoreInfoForParts then aQ=false end;if aS and aO:GetShowOnMultiMeasureRests(aQ)then if finale.MNALIGN_LEFT~=aO:GetMultiMeasureAlignment(aQ)then return false end elseif y.Measure==aR.FirstMeasure then if not aO:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=aO:GetStartAlignment(aQ)then return false end else if not aO:GetShowMultiples(aQ)then return false end;if finale.MNALIGN_LEFT~=aO:GetMultipleAlignment(aQ)then return false end end;return av.is_default_measure_number_visible_on_cell(aO,y,aR,aQ)end;function av.update_layout(aT,aU)aT=aT or 1;aU=aU or false;local aV=finale.FCPage()if aV:Load(aT)then aV:UpdateLayout(aU)end end;function av.get_current_part()local aW=finale.FCParts()aW:LoadAll()return aW:GetCurrent()end;function av.get_page_format_prefs()local aX=av.get_current_part()local aY=finale.FCPageFormatPrefs()local M=false;if aX:IsScore()then M=aY:LoadScore()else M=aY:LoadParts()end;return aY,M end;function av.get_smufl_metadata_file(aZ)if not aZ then aZ=finale.FCFontInfo()aZ:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local a_=function(b0,aZ)local b1=b0 .."/SMuFL/Fonts/"..aZ.Name.."/"..aZ.Name..".json"return io.open(b1,"r")end;local b2=""if finenv.UI():IsOnWindows()then b2=os.getenv("LOCALAPPDATA")else b2=os.getenv("HOME").."/Library/Application Support"end;local b3=a_(b2,aZ)if nil~=b3 then return b3 end;local b4="/Library/Application Support"if finenv.UI():IsOnWindows()then b4=os.getenv("COMMONPROGRAMFILES")end;return a_(b4,aZ)end;function av.is_font_smufl_font(aZ)if not aZ then aZ=finale.FCFontInfo()aZ:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=av.finale_version(27,1)then if nil~=aZ.IsSMuFLFont then return aZ.IsSMuFLFont end end;local b5=av.get_smufl_metadata_file(aZ)if nil~=b5 then io.close(b5)return true end;return false end;function av.simple_input(b6,b7)local b8=finale.FCString()b8.LuaString=""local b9=finale.FCString()local ba=160;function format_ctrl(bb,bc,bd,be)bb:SetHeight(bc)bb:SetWidth(bd)b9.LuaString=be;bb:SetText(b9)end;title_width=string.len(b6)*6+54;if title_width>ba then ba=title_width end;text_width=string.len(b7)*6;if text_width>ba then ba=text_width end;b9.LuaString=b6;local bf=finale.FCCustomLuaWindow()bf:SetTitle(b9)local bg=bf:CreateStatic(0,0)format_ctrl(bg,16,ba,b7)local bh=bf:CreateEdit(0,20)format_ctrl(bh,20,ba,"")bf:CreateOkButton()bf:CreateCancelButton()function callback(bb)end;bf:RegisterHandleCommand(callback)if bf:ExecuteModal(nil)==finale.EXECMODAL_OK then b8.LuaString=bh:GetText(b8)return b8.LuaString end end;function av.is_finale_object(bi)return bi and type(bi)=="userdata"and bi.ClassName and bi.GetClassID and true or false end;function av.system_indent_set_to_prefs(aR,aY)aY=aY or av.get_page_format_prefs()local bj=finale.FCMeasure()local bk=aR.FirstMeasure==1;if not bk and bj:Load(aR.FirstMeasure)then if bj.ShowFullNames then bk=true end end;if bk and aY.UseFirstSystemMargins then aR.LeftMargin=aY.FirstSystemLeft else aR.LeftMargin=aY.SystemLeft end;return aR:Save()end;return av end)c("library.note_entry",function(require,n,c,d)local av={}function av.finale_version(aw,ax,ay)local az=bit32.bor(bit32.lshift(math.floor(aw),24),bit32.lshift(math.floor(ax),20))if ay then az=bit32.bor(az,math.floor(ay))end;return az end;function av.group_overlaps_region(aA,C)if C:IsFullDocumentSpan()then return true end;local aB=false;local aC=finale.FCSystemStaves()aC:LoadAllForRegion(C)for aD in each(aC)do if aA:ContainsStaff(aD:GetStaff())then aB=true;break end end;if not aB then return false end;if aA.StartMeasure>C.EndMeasure or aA.EndMeasure<C.StartMeasure then return false end;return true end;function av.group_is_contained_in_region(aA,C)if not C:IsStaffIncluded(aA.StartStaff)then return false end;if not C:IsStaffIncluded(aA.EndStaff)then return false end;return true end;function av.staff_group_is_multistaff_instrument(aA)local aE=finale.FCMultiStaffInstruments()aE:LoadAll()for aF in each(aE)do if aF:ContainsStaff(aA.StartStaff)and aF.GroupID==aA:GetItemID()then return true end end;return false end;function av.get_selected_region_or_whole_doc()local aG=finenv.Region()if aG:IsEmpty()then aG:SetFullDocument()end;return aG end;function av.get_first_cell_on_or_after_page(aH)local aI=aH;local aJ=finale.FCPage()local aK=false;while aJ:Load(aI)do if aJ:GetFirstSystem()>0 then aK=true;break end;aI=aI+1 end;if aK then local aL=finale.FCStaffSystem()aL:Load(aJ:GetFirstSystem())return finale.FCCell(aL.FirstMeasure,aL.TopStaff)end;local aM=finale.FCMusicRegion()aM:SetFullDocument()return finale.FCCell(aM.EndMeasure,aM.EndStaff)end;function av.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local aN=finale.FCMusicRegion()aN:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),aN.StartStaff)end;return av.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function av.get_top_left_selected_or_visible_cell()local aG=finenv.Region()if not aG:IsEmpty()then return finale.FCCell(aG.StartMeasure,aG.StartStaff)end;return av.get_top_left_visible_cell()end;function av.is_default_measure_number_visible_on_cell(aO,y,aP,aQ)local an=finale.FCCurrentStaffSpec()if not an:LoadForCell(y,0)then return false end;if aO:GetShowOnTopStaff()and y.Staff==aP.TopStaff then return true end;if aO:GetShowOnBottomStaff()and y.Staff==aP:CalcBottomStaff()then return true end;if an.ShowMeasureNumbers then return not aO:GetExcludeOtherStaves(aQ)end;return false end;function av.is_default_number_visible_and_left_aligned(aO,y,aR,aQ,aS)if aO.UseScoreInfoForParts then aQ=false end;if aS and aO:GetShowOnMultiMeasureRests(aQ)then if finale.MNALIGN_LEFT~=aO:GetMultiMeasureAlignment(aQ)then return false end elseif y.Measure==aR.FirstMeasure then if not aO:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=aO:GetStartAlignment(aQ)then return false end else if not aO:GetShowMultiples(aQ)then return false end;if finale.MNALIGN_LEFT~=aO:GetMultipleAlignment(aQ)then return false end end;return av.is_default_measure_number_visible_on_cell(aO,y,aR,aQ)end;function av.update_layout(aT,aU)aT=aT or 1;aU=aU or false;local aV=finale.FCPage()if aV:Load(aT)then aV:UpdateLayout(aU)end end;function av.get_current_part()local aW=finale.FCParts()aW:LoadAll()return aW:GetCurrent()end;function av.get_page_format_prefs()local aX=av.get_current_part()local aY=finale.FCPageFormatPrefs()local M=false;if aX:IsScore()then M=aY:LoadScore()else M=aY:LoadParts()end;return aY,M end;function av.get_smufl_metadata_file(aZ)if not aZ then aZ=finale.FCFontInfo()aZ:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local a_=function(b0,aZ)local b1=b0 .."/SMuFL/Fonts/"..aZ.Name.."/"..aZ.Name..".json"return io.open(b1,"r")end;local b2=""if finenv.UI():IsOnWindows()then b2=os.getenv("LOCALAPPDATA")else b2=os.getenv("HOME").."/Library/Application Support"end;local b3=a_(b2,aZ)if nil~=b3 then return b3 end;local b4="/Library/Application Support"if finenv.UI():IsOnWindows()then b4=os.getenv("COMMONPROGRAMFILES")end;return a_(b4,aZ)end;function av.is_font_smufl_font(aZ)if not aZ then aZ=finale.FCFontInfo()aZ:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=av.finale_version(27,1)then if nil~=aZ.IsSMuFLFont then return aZ.IsSMuFLFont end end;local b5=av.get_smufl_metadata_file(aZ)if nil~=b5 then io.close(b5)return true end;return false end;function av.simple_input(b6,b7)local b8=finale.FCString()b8.LuaString=""local b9=finale.FCString()local ba=160;function format_ctrl(bb,bc,bd,be)bb:SetHeight(bc)bb:SetWidth(bd)b9.LuaString=be;bb:SetText(b9)end;title_width=string.len(b6)*6+54;if title_width>ba then ba=title_width end;text_width=string.len(b7)*6;if text_width>ba then ba=text_width end;b9.LuaString=b6;local bf=finale.FCCustomLuaWindow()bf:SetTitle(b9)local bg=bf:CreateStatic(0,0)format_ctrl(bg,16,ba,b7)local bh=bf:CreateEdit(0,20)format_ctrl(bh,20,ba,"")bf:CreateOkButton()bf:CreateCancelButton()function callback(bb)end;bf:RegisterHandleCommand(callback)if bf:ExecuteModal(nil)==finale.EXECMODAL_OK then b8.LuaString=bh:GetText(b8)return b8.LuaString end end;function av.is_finale_object(bi)return bi and type(bi)=="userdata"and bi.ClassName and bi.GetClassID and true or false end;function av.system_indent_set_to_prefs(aR,aY)aY=aY or av.get_page_format_prefs()local bj=finale.FCMeasure()local bk=aR.FirstMeasure==1;if not bk and bj:Load(aR.FirstMeasure)then if bj.ShowFullNames then bk=true end end;if bk and aY.UseFirstSystemMargins then aR.LeftMargin=aY.FirstSystemLeft else aR.LeftMargin=aY.SystemLeft end;return aR:Save()end;return av end)c("library.expression",function(require,n,c,d)local av={}function av.finale_version(aw,ax,ay)local az=bit32.bor(bit32.lshift(math.floor(aw),24),bit32.lshift(math.floor(ax),20))if ay then az=bit32.bor(az,math.floor(ay))end;return az end;function av.group_overlaps_region(aA,C)if C:IsFullDocumentSpan()then return true end;local aB=false;local aC=finale.FCSystemStaves()aC:LoadAllForRegion(C)for aD in each(aC)do if aA:ContainsStaff(aD:GetStaff())then aB=true;break end end;if not aB then return false end;if aA.StartMeasure>C.EndMeasure or aA.EndMeasure<C.StartMeasure then return false end;return true end;function av.group_is_contained_in_region(aA,C)if not C:IsStaffIncluded(aA.StartStaff)then return false end;if not C:IsStaffIncluded(aA.EndStaff)then return false end;return true end;function av.staff_group_is_multistaff_instrument(aA)local aE=finale.FCMultiStaffInstruments()aE:LoadAll()for aF in each(aE)do if aF:ContainsStaff(aA.StartStaff)and aF.GroupID==aA:GetItemID()then return true end end;return false end;function av.get_selected_region_or_whole_doc()local aG=finenv.Region()if aG:IsEmpty()then aG:SetFullDocument()end;return aG end;function av.get_first_cell_on_or_after_page(aH)local aI=aH;local aJ=finale.FCPage()local aK=false;while aJ:Load(aI)do if aJ:GetFirstSystem()>0 then aK=true;break end;aI=aI+1 end;if aK then local aL=finale.FCStaffSystem()aL:Load(aJ:GetFirstSystem())return finale.FCCell(aL.FirstMeasure,aL.TopStaff)end;local aM=finale.FCMusicRegion()aM:SetFullDocument()return finale.FCCell(aM.EndMeasure,aM.EndStaff)end;function av.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local aN=finale.FCMusicRegion()aN:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),aN.StartStaff)end;return av.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function av.get_top_left_selected_or_visible_cell()local aG=finenv.Region()if not aG:IsEmpty()then return finale.FCCell(aG.StartMeasure,aG.StartStaff)end;return av.get_top_left_visible_cell()end;function av.is_default_measure_number_visible_on_cell(aO,y,aP,aQ)local an=finale.FCCurrentStaffSpec()if not an:LoadForCell(y,0)then return false end;if aO:GetShowOnTopStaff()and y.Staff==aP.TopStaff then return true end;if aO:GetShowOnBottomStaff()and y.Staff==aP:CalcBottomStaff()then return true end;if an.ShowMeasureNumbers then return not aO:GetExcludeOtherStaves(aQ)end;return false end;function av.is_default_number_visible_and_left_aligned(aO,y,aR,aQ,aS)if aO.UseScoreInfoForParts then aQ=false end;if aS and aO:GetShowOnMultiMeasureRests(aQ)then if finale.MNALIGN_LEFT~=aO:GetMultiMeasureAlignment(aQ)then return false end elseif y.Measure==aR.FirstMeasure then if not aO:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=aO:GetStartAlignment(aQ)then return false end else if not aO:GetShowMultiples(aQ)then return false end;if finale.MNALIGN_LEFT~=aO:GetMultipleAlignment(aQ)then return false end end;return av.is_default_measure_number_visible_on_cell(aO,y,aR,aQ)end;function av.update_layout(aT,aU)aT=aT or 1;aU=aU or false;local aV=finale.FCPage()if aV:Load(aT)then aV:UpdateLayout(aU)end end;function av.get_current_part()local aW=finale.FCParts()aW:LoadAll()return aW:GetCurrent()end;function av.get_page_format_prefs()local aX=av.get_current_part()local aY=finale.FCPageFormatPrefs()local M=false;if aX:IsScore()then M=aY:LoadScore()else M=aY:LoadParts()end;return aY,M end;function av.get_smufl_metadata_file(aZ)if not aZ then aZ=finale.FCFontInfo()aZ:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local a_=function(b0,aZ)local b1=b0 .."/SMuFL/Fonts/"..aZ.Name.."/"..aZ.Name..".json"return io.open(b1,"r")end;local b2=""if finenv.UI():IsOnWindows()then b2=os.getenv("LOCALAPPDATA")else b2=os.getenv("HOME").."/Library/Application Support"end;local b3=a_(b2,aZ)if nil~=b3 then return b3 end;local b4="/Library/Application Support"if finenv.UI():IsOnWindows()then b4=os.getenv("COMMONPROGRAMFILES")end;return a_(b4,aZ)end;function av.is_font_smufl_font(aZ)if not aZ then aZ=finale.FCFontInfo()aZ:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=av.finale_version(27,1)then if nil~=aZ.IsSMuFLFont then return aZ.IsSMuFLFont end end;local b5=av.get_smufl_metadata_file(aZ)if nil~=b5 then io.close(b5)return true end;return false end;function av.simple_input(b6,b7)local b8=finale.FCString()b8.LuaString=""local b9=finale.FCString()local ba=160;function format_ctrl(bb,bc,bd,be)bb:SetHeight(bc)bb:SetWidth(bd)b9.LuaString=be;bb:SetText(b9)end;title_width=string.len(b6)*6+54;if title_width>ba then ba=title_width end;text_width=string.len(b7)*6;if text_width>ba then ba=text_width end;b9.LuaString=b6;local bf=finale.FCCustomLuaWindow()bf:SetTitle(b9)local bg=bf:CreateStatic(0,0)format_ctrl(bg,16,ba,b7)local bh=bf:CreateEdit(0,20)format_ctrl(bh,20,ba,"")bf:CreateOkButton()bf:CreateCancelButton()function callback(bb)end;bf:RegisterHandleCommand(callback)if bf:ExecuteModal(nil)==finale.EXECMODAL_OK then b8.LuaString=bh:GetText(b8)return b8.LuaString end end;function av.is_finale_object(bi)return bi and type(bi)=="userdata"and bi.ClassName and bi.GetClassID and true or false end;function av.system_indent_set_to_prefs(aR,aY)aY=aY or av.get_page_format_prefs()local bj=finale.FCMeasure()local bk=aR.FirstMeasure==1;if not bk and bj:Load(aR.FirstMeasure)then if bj.ShowFullNames then bk=true end end;if bk and aY.UseFirstSystemMargins then aR.LeftMargin=aY.FirstSystemLeft else aR.LeftMargin=aY.SystemLeft end;return aR:Save()end;return av end)return a("__root")