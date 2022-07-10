function plugindef()finaleplugin.RequireSelection=true;finaleplugin.Author="Carl Vine"finaleplugin.AuthorURL="http://carlvine.com/?cv=lua"finaleplugin.Copyright="CC0 https://creativecommons.org/publicdomain/zero/1.0/"finaleplugin.Version="v1.2"finaleplugin.Date="2022/06/14"finaleplugin.CategoryTags="MIDI, Playback"finaleplugin.Notes=[[
    Change the playback Key Velocity for every note in the selected area in one or all layers. 
    "Key Velocities" must be enabled under "Playback/Record Options" to affect playback. 
    Note that key velocity will not affect every type of playback especially if Human Playback is active. 

    Side-note: selecting the MIDI tool, choosing "Velocity" then "Set to" is moderately convenient 
    but doesn't offer setting key velocity on a single chosen layer. 
    This script also remembers your choices between invocations.
]]return"MIDI Velocity","MIDI Velocity","Change MIDI Velocity"end;function show_error(a,b)local c={bad_velocity="Velocity must be an\ninteger between 0 and 127\n(not ",bad_layer_number="Layer number must be an\ninteger between zero and 4\n(not "}finenv.UI():AlertNeutral("script: "..plugindef(),c[a]..b..")")end;function get_user_choices(d)local e,f=10,25;local g=finenv.UI():IsOnMac()and 3 or 0;local h=120;local i=finale.FCCustomWindow()local j=finale.FCString()j.LuaString=plugindef()i:SetTitle(j)local k={}local l={{"Key Velocity (0-127):",key_velocity or d},{"Layer 1-4 (0 = all):",layer_number or 0}}for m,n in ipairs(l)do j.LuaString=n[1]local o=i:CreateStatic(0,e)o:SetText(j)o:SetWidth(h)k[m]=i:CreateEdit(h,e-g)k[m]:SetInteger(n[2])e=e+f end;i:CreateOkButton()i:CreateCancelButton()return i:ExecuteModal(nil)==finale.EXECMODAL_OK,k[1]:GetInteger(),k[2]:GetInteger()end;function change_velocity()local p=finale.FCPlaybackPrefs()p:Load(1)local d=p:GetBaseKeyVelocity()local q=false;q,key_velocity,layer_number=get_user_choices(d)if not q then return end;if key_velocity<0 or key_velocity>127 then show_error("bad_velocity",key_velocity)return end;if layer_number<0 or layer_number>4 then show_error("bad_layer_number",layer_number)return end;if finenv.RetainLuaState~=nil then finenv.RetainLuaState=true end;for r in eachentrysaved(finenv.Region(),layer_number)do local s=finale.FCPerformanceMod()if r:IsNote()then s:SetNoteEntry(r)for t in each(r)do s:LoadAt(t)s.VelocityDelta=key_velocity-d;s:SaveAt(t)end end end end;change_velocity()