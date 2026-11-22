

if !pcall(require,"pk_pills") then
    if SERVER then
        hook.Add("PlayerInitialSpawn","pk_pill_extfail_cl",function(ply)
            if game.SinglePlayer() || ply:IsListenServerHost() then
                ply:SendLua('notification.AddLegacy("One or more pill extensions failed to load. Did you forget to install Parakeet\'s Pill Pack?",NOTIFY_ERROR,30)')
            end
        end)
        hook.Add("Initialize","pk_pill_extfail_sv",function(ply)
            print("[ALERT] One or more pill extensions failed to load. Did you forget to install Enhanced Parakeet's Pill Base?")
        end)
    end
    return
end
AddCSLuaFile()
include("include/gent_scp096_noodle.lua")

-- scp096 CODING

if SERVER then
    util.AddNetworkString('gentoi_scp096_cam')
    util.AddNetworkString("Gentoi_scp096_CameraCode_n")

else

    surface.CreateFont("CreditsText_Large_scp", {
        font = "Arial",
        size = 70,
        weight = 700,
        antialias = true,
    })

    local preservedmats = {
        ["ShyGuy_bar"]     = Material("gentoi/scp096/ShyGuy_bar.png"),
        ["ShyGuySad"]     = Material("gentoi/scp096/ShyGuySad.png"),
        ["ShyGuyMiddle"]  = Material("gentoi/scp096/ShyGuyMiddle.png"),
        ["ShyGuyAngry1"]  = Material("gentoi/scp096/ShyGuyAngry1.png"),
        ["docile"]  = Material("gentoi/scp096/docile.png"),

        ["AngryShyGuy"]  = Material("gentoi/scp096/AngryShyGuy.png"),
        ["increaseShyGuy"]  = Material("gentoi/scp096/increaseShyGuy.png"),
        
        ["ShyGuyIcon1"]   = Material("gentoi/scp096/ShyGuyIcon1.png"),
        ["Rage1"]   = Material("gentoi/scp096/Rage1.png"),
        ["RedBorder"]  = Material("gentoi/scp096/RedBorder.png"),
    }

    local lastIconMat   = nil
    local iconKickAngle = 0
    local iconKickDir   = 1
    local iconKickEnd   = 0
    local KICK_DURATION = 0.2

    local angryAlpha    = 0
    local middleAlpha   = 0
    local angryOverlayA = 0
    local angryYOffset  = 0

    local increaseAlpha = 0

    local iconColorR = 255
    local iconColorG = 255
    local iconColorB = 255

    local FADE_SPEED  = 8
    local PULSE_SPEED = 2
    local PULSE_MIN   = 180
    local PULSE_MAX   = 255
    local barAlpha = 0
    local barAlpha2 = 0
    local targetRIcon, targetGIcon, targetBIcon = 0,0,0
    local rageColor = Color(255, 255, 255, 255)

    hook.Add("HUDPaint", "gent_scp096_hudpaint", function()
        if SherlockHNS then return end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local pillentity = ply.pk_pill_ent
        if not IsValid(pillentity) then return end
        if not pillentity.GetPuppet then return end
        if not IsValid(pillentity:GetPuppet()) then return end
        if not pillentity.formTable.Gentoi_scp96 then return end

        local screenW, screenH = ScrW(), ScrH()
        local iconize = ScreenScale(70)

        local barX, barY = iconize * 0.1, screenH * 0.5 - iconize

        surface.SetDrawColor(25,25,25,255)
        surface.SetMaterial(preservedmats["ShyGuy_bar"])
        surface.DrawTexturedRect(barX, barY, iconize*0.85, iconize*2.5)

        local frac = math.Clamp((pillentity:GetNWFloat("Bar_scp096_rage_ui") - CurTime()) / pillentity:GetNWFloat("Bar_scp096_rage_max"), 0, 1 )

        local barH, barY2, uvY

        if pillentity:GetNWFloat("Bar_scp096_rage_buildup") > CurTime() then
            barH  = Lerp(frac, iconize*2.5, 0) 
            barY2 = Lerp(frac, barY, barY + iconize*2.5) 
            uvY   = Lerp(frac, 0, 1)
        else
            barH = Lerp(frac, 0, iconize*2.5)
            barY2 = Lerp(frac, barY + iconize*2.5, barY)
            uvY = Lerp(frac, 1, 0)
        end

        surface.SetDrawColor(255,255,255,255)
        if pillentity:GetNWFloat("Bar_scp096_rage_cd") > CurTime() then
            surface.SetDrawColor(125,0,0,255)
        end
        surface.DrawTexturedRectUV(barX,barY2,iconize*0.85,barH,0,uvY,1,1)

        local iconMat
        if pillentity:GetNWFloat("Gentoi_scp96_counter") <= 0 then
            iconMat = preservedmats["ShyGuySad"]
        else
            if pillentity:GetNWFloat("Bar_scp096_rage_buildup") < CurTime()
            and pillentity:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
                iconMat = preservedmats["ShyGuyAngry1"]
            else
                iconMat = preservedmats["ShyGuyMiddle"]
            end
        end

        if iconMat ~= lastIconMat then
            iconKickDir = math.random(0,1) == 1 and 1 or -1
            iconKickEnd = CurTime() + KICK_DURATION
            lastIconMat = iconMat
        end

        if CurTime() < iconKickEnd then
            local t = 1 - ((iconKickEnd - CurTime()) / KICK_DURATION)
            iconKickAngle = Lerp(t, 25 * iconKickDir, 0)
        else
            iconKickAngle = Lerp(FrameTime() * 20, iconKickAngle, 0)
        end

        local isAngry  = iconMat == preservedmats["ShyGuyAngry1"]
        local isMiddle = iconMat == preservedmats["ShyGuyMiddle"]

        angryAlpha  = Lerp(FrameTime()*FADE_SPEED, angryAlpha,  isAngry  and 255 or 0)
        middleAlpha = Lerp(FrameTime()*FADE_SPEED, middleAlpha, isMiddle and 255 or 0)

        iconColorG = Lerp(FrameTime()*FADE_SPEED, iconColorG, isAngry and 170 or 255)
        iconColorB = Lerp(FrameTime()*FADE_SPEED, iconColorB, isAngry and 170 or 255)

        angryOverlayA = Lerp(FrameTime()*FADE_SPEED, angryOverlayA, isAngry and 255 or 0)
        angryYOffset  = Lerp(FrameTime()*FADE_SPEED, angryYOffset, isAngry and -12 or 0)

        local size = iconize * 0.90
        local cx = barX + size*0.5
        local cy = barY*1.02 + size*0.5

        if middleAlpha > 1 then
            surface.SetMaterial(preservedmats["ShyGuyMiddle"])
            surface.SetDrawColor(255,255,255,middleAlpha)
            surface.DrawTexturedRectRotated(cx, cy, size, size, iconKickAngle)
        end

        if angryAlpha > 1 then
            surface.SetMaterial(preservedmats["ShyGuyAngry1"])
            surface.SetDrawColor(255, iconColorG, iconColorB, angryAlpha)
            surface.DrawTexturedRectRotated(cx, cy, size, size, iconKickAngle)
        end

        if angryOverlayA > 1 then
            surface.SetMaterial(preservedmats["AngryShyGuy"])
            surface.SetDrawColor(255,255,255,angryOverlayA)
            surface.DrawTexturedRectRotated(
                cx,
                cy + angryYOffset,
                size,
                size,
                iconKickAngle
            )
        end

        if increaseAlpha > 1 then
            surface.SetMaterial(preservedmats["increaseShyGuy"])
            surface.SetDrawColor(pulse, pulse, pulse, increaseAlpha)
            surface.DrawTexturedRectRotated(cx, cy, size, size, iconKickAngle)
        end

        if iconMat == preservedmats["ShyGuySad"] then
            surface.SetMaterial(preservedmats["ShyGuySad"])
            surface.SetDrawColor(255,255,255,255)
            surface.DrawTexturedRectRotated(cx, cy, size, size, iconKickAngle)
        end

        local lx, ly = screenW/2 + screenW/3, screenH - ScreenScale(80)

        surface.SetDrawColor(255,255,255,255)
        surface.SetMaterial(preservedmats["ShyGuyIcon1"])
        surface.DrawTexturedRectRotated(lx + iconize/2,ly + iconize/2,iconize,iconize,0)

        draw.SimpleTextOutlined("SPACE","CreditsText_Large_scp",lx + ScreenScale(5),ly + ScreenScale(2),color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,6,color_black)

        if isAngry or isMiddle then
            if pillentity:GetNWFloat("Bar_scp096_rage_cd") > CurTime() then
                targetRIcon, targetGIcon, targetBIcon = 255, 125, 125
            else
                targetRIcon, targetGIcon, targetBIcon = 255, 255, 255
            end
        else
            targetRIcon, targetGIcon, targetBIcon = 145, 145, 145
        end

        local speed = FrameTime() * 10

        rageColor.r = Lerp(speed, rageColor.r, targetRIcon)
        rageColor.g = Lerp(speed, rageColor.g, targetGIcon)
        rageColor.b = Lerp(speed, rageColor.b, targetBIcon)

        surface.SetDrawColor(rageColor)
        local lx, ly = screenW/2 + screenW/5, screenH - ScreenScale(80)

        if isAngry or isMiddle then
            surface.SetMaterial(preservedmats["Rage1"])
        else
            surface.SetMaterial(preservedmats["docile"])
        end
        surface.DrawTexturedRectRotated(
            lx + iconize/2,
            ly + iconize/2,
            iconize,
            iconize,
            0
        )

        draw.SimpleTextOutlined(
            "1",
            "CreditsText_Large_scp",
            lx + ScreenScale(5),
            ly + ScreenScale(2),
            color_white,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER,
            6,
            color_black
        )



        local shouldShow = pillentity:GetNWFloat("gent_scp096_cutscenebar") > CurTime()

        local targetAlpha = shouldShow and 255 or 0
        barAlpha = Lerp(FrameTime() * 8, barAlpha, targetAlpha)

        surface.SetDrawColor(0, 0, 0, barAlpha)
        surface.DrawRect(0, 0, screenW, screenH / 13)
        surface.DrawRect(0, screenH - screenH / 13.1, screenW, screenH / 13)

        local shouldShow = pillentity:GetNWFloat("gent_scp096_cutscenebar_tre") > CurTime()

        local targetAlpha = shouldShow and 255 or 0
        barAlpha2 = Lerp(FrameTime() * 8, barAlpha2, targetAlpha)

        surface.SetDrawColor(255, 255, 255, barAlpha2)
        surface.SetMaterial(preservedmats["RedBorder"])
        surface.DrawTexturedRect(0, 0, screenW, screenH)
    end)

    local function scp096_returntablename( ply, ent )
        if !IsValid(ply) then return end
        return "Gentoi_scp96_".. ent:EntIndex().. "_".. ply:EntIndex()
    end

    net.Receive("Gentoi_scp096_CameraCode_n", function()
        local ply = LocalPlayer()
        local ent = net.ReadEntity()

        timer.Simple(0,function()
            if !IsValid(ent) then return end

            local savedCalcViewHooks = {}

            local calcViewHooks = hook.GetTable().CalcView or {}
            for k, v in pairs(calcViewHooks) do
                if k ~= hookID then
                    savedCalcViewHooks[k] = v
                    hook.Remove("CalcView", k)
                end
            end

            local name6 = "momo_calcview_".. ply:Nick()
            local name5 = "gentoi_remove_n_".. ply:Nick()
            hook.Add("EntityRemoved", name5, function(removedent)
                if removedent == ent then
                    hook.Remove('CalcView', name6)
                    hook.Remove("EntityRemoved", name5)
                    hook.Remove("Think", name5)
                    for savedID, func in pairs(savedCalcViewHooks) do
                        hook.Add("CalcView", savedID, func)
                    end
                    savedCalcViewHooks = {}

                    for _, v in ipairs(ents.GetAll()) do
                        if IsValid(v) then
                            local name = scp096_returntablename(ply, ent)
                            if v:GetNWBool(name) then
                                v:SetNoDraw(false)
                            else
                                v:SetNoDraw(false)
                            end

                        end
                    end

                end
            end)
            
            local lastID = nil
            local lastOrigin = nil
            local lastFOV = nil
            local transitionStart = 0
            local transitionTime = 0.25

            hook.Add("Think", name5, function()
                local allEntities = table.Add(player.GetAll(), ents.GetAll())
                for k, v in ipairs(allEntities) do
                    if IsValid(v) then
                        if v:IsPlayer() and v:Team() == TEAM_SPECTATOR then continue end
                        if (v:IsPlayer() or v:IsNextBot() or v:IsNPC()) and v:Health() >= 0.1 then
                            local name = scp096_returntablename(ply, ply.pk_pill_ent)
                            if v:GetNWBool(name) and ent:GetNWBool("Gentoi_scp96_rage_toggle") then
                                v:SetNoDraw(false)

                                local realWep = v:GetActiveWeapon()
                                if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                                    realWep:SetNoDraw(false)
                                end
                            else
                                if ent:GetNWBool("Gentoi_scp96_rage_toggle") then
                                    v:SetNoDraw(true)

                                    local realWep = v:GetActiveWeapon()
                                    if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                                        realWep:SetNoDraw(true)
                                    end
                                else
                                    v:SetNoDraw(false)


                                    local realWep = v:GetActiveWeapon()
                                    if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                                        realWep:SetNoDraw(false)
                                    end

                                end
                            end 

                        end
                    end
                end
            end)

            hook.Add("CalcView", name6, function(ply, pos, ang, fov)
                local ent = pk_pills.getMappedEnt(ply)
                if not IsValid(ent) or ply:GetViewEntity() ~= ply then return end

                local currentOMTable = ent.formTable.OM_cameratable(ply, ent)
                if not currentOMTable then return end

                if lastID ~= currentOMTable.id then
                    lastID = currentOMTable.id
                    transitionStart = CurTime()
                    lastOrigin = lastOrigin or pos
                    lastFOV = lastFOV or fov
                end

                if transitionTime ~= currentOMTable.transition then
                    transitionTime = currentOMTable.transition
                end

                local up = ang:Up() * currentOMTable.startoffset.z
                local right = ang:Right() * currentOMTable.startoffset.x
                local forward = ang:Forward() * currentOMTable.startoffset.y
                local startpos = ply:GetPos() + up + right + forward
                if currentOMTable.bonecenter then
                    local boneID = ent:GetPuppet():LookupBone(currentOMTable.bonecenter)
                    local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)
                    startpos = bonePos + up + right + forward
                end

                if pk_pills.convars.cl_thirdperson:GetBool() then
                    local dist = currentOMTable.dist
                    local offset = ang:Forward() * -dist

                    local tr = util.TraceHull({
                        start = startpos,
                        endpos = startpos + offset,
                        filter = ent.camTraceFilter,
                        mins = Vector(-5, -5, -5),
                        maxs = Vector(5, 5, 5),
                        mask = MASK_VISIBLE
                    })

                    local targetOrigin = tr.HitPos
                    local targetFOV = currentOMTable.fov

                    local t = math.Clamp((CurTime() - transitionStart) / transitionTime, 0, 1)

                    local smoothOrigin = LerpVector(t, lastOrigin, targetOrigin)
                    local smoothFOV = Lerp(t, lastFOV, targetFOV)

                    lastOrigin = smoothOrigin
                    lastFOV = smoothFOV

                    return {
                        origin = smoothOrigin,
                        angles = ang,
                        fov = smoothFOV,
                        drawviewer = true
                    }
                else

                    local up = ang:Up() * currentOMTable.startoffsetFirst.z
                    local right = ang:Right() * currentOMTable.startoffsetFirst.x
                    local forward = ang:Forward() * currentOMTable.startoffsetFirst.y
                    if currentOMTable.bonecenter then
                        local boneID = ent:GetPuppet():LookupBone(currentOMTable.bonecenter)
                        local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)
                        startpos = bonePos + up + right + forward
                    end

                    local tr = util.TraceHull({
                        start = startpos,
                        endpos = startpos,
                        filter = ent.camTraceFilter,
                        mins = Vector(-5, -5, -5),
                        maxs = Vector(5, 5, 5),
                        mask = MASK_VISIBLE
                    })

                    local targetOrigin = tr.HitPos
                    local targetFOV = currentOMTable.fov

                    local t = math.Clamp((CurTime() - transitionStart) / transitionTime, 0, 1)

                    local smoothOrigin = LerpVector(t, lastOrigin, targetOrigin)
                    local smoothFOV = Lerp(t, lastFOV, targetFOV)

                    lastOrigin = smoothOrigin
                    lastFOV = smoothFOV

                    return {
                        origin = smoothOrigin,
                        angles = ang,
                        fov = smoothFOV,
                        drawviewer = true
                    }
                end
            end)
        end)
    end)


    net.Receive('gentoi_scp096_cam', function()
        local ent = net.ReadEntity()
        local state = net.ReadBool()
        local startTime = CurTime()

        local hookID = "gentoi_scp096_cam_" .. LocalPlayer():SteamID()

        if not state then
            hook.Remove('CalcView', hookID)
        else
            hook.Add('CalcView', hookID, function(ply, pos, angles, fov)
                if not IsValid(ply) or not ply:Alive() or !IsValid(ent) then
                    hook.Remove('CalcView', hookID)
                    if IsValid(ply) then
                        ply:RemoveFlags(FL_NOTARGET)
                        ply:Freeze(false)
                        ply:DrawViewModel(true)
                    end
                    return
                end

                local cam = ent:GetAttachment(ent:LookupAttachment('camera'))

                ply:AddFlags(FL_NOTARGET)
                ply:Freeze(true)
                ply:DrawViewModel(false)

                local lerpFactor = math.Clamp((CurTime() - startTime) / (0.7/3), 0, 1)
                
                local targetFOV = 80 

                local orgiginlerpto = LerpVector(lerpFactor, pos, cam.Pos)
                local angleslerpto = LerpAngle(lerpFactor, angles, cam.Ang)
                local interpolatedFOV = Lerp(lerpFactor, fov, targetFOV)

                local view = {
                    origin = orgiginlerpto,
                    angles = angleslerpto,
                    fov = interpolatedFOV,
                    drawviewer = false
                }
                return view
            end)
        end
    end)
    
end

hook.Add("PlayerButtonDown", "ActivateKeybind_scp096_gent_pills_noodles", function(ply, button)
    local pillentity = ply.pk_pill_ent
    
    if IsValid(pillentity) then
        if pillentity.formTable.noodles_gent_scp096_keybinds_activate then
            pillentity.formTable.noodles_gent_scp096_keybinds_activate(ply, pillentity, button)
        end
    end
end)

hook.Add("PlayerButtonUp", "DeactivateKeybind_scp096_gent_pills_noodles", function(ply, button)
    local pillentity = ply.pk_pill_ent
    
    if IsValid(pillentity) then
        if pillentity.formTable.noodles_gent_scp096_keybinds_deactivate then
            pillentity.formTable.noodles_gent_scp096_keybinds_deactivate(ply, pillentity, button)
        end
    end
end)


hook.Add("OnEntityCreated", "scp096_gent_noodles_initialize", function(ent)
    timer.Simple(0.00, function()
        if !IsValid(ent) then return end
        if ent:GetClass() == "pill_ent_costume" then
            if not ent then return end
            if ent.formTable then
                local PuppetEntity = ent:GetPuppet()
                local entityply = ent:GetPillUser()

                local hookName = "ThinkHookForEntity_scp096pill_" .. ent:EntIndex()

                if ent.formTable.noodles_gent_scp096_think then
                    hook.Add("Think", hookName, function()
                        if not IsValid(ent) then
                            hook.Remove("Think", hookName)
                            return
                        end

                        local ply = ent:GetPillUser()
                        local puppet = ent:GetPuppet()

                        if not IsValid(puppet) or not IsValid(ply) then
                            hook.Remove("Think", hookName)
                            return
                        end

                        ent.formTable.noodles_gent_scp096_think(ply, ent)
                    end)
                end

                if ent.formTable.noodles_gent_scp096_initialize then

                    local tablevarable = {["player"] = entityply, ["entity"] = ent, ["puppet"] = PuppetEntity}
                    if ent.formTable.noodles_gent_scp096_onremove then
                        ent:CallOnRemove("RemoveHook_OM"..ent:EntIndex(), function()

                            ent.formTable:noodles_gent_scp096_onremove(tablevarable,tablevarable,tablevarable)
                        end)
                    end

                    timer.Simple(0.1, function()
                        if !IsValid(ent) then return end
                        ent.formTable:noodles_gent_scp096_initialize(tablevarable,tablevarable,tablevarable)


                        local self = ent
                        self.formTable = pk_pills.getPillTable(self:GetPillForm())
                        local ply = self:GetPillUser()

                        if not self.formTable or not IsValid(ply) then
                            self:Remove()

                            return
                        end

                        local hull = self.formTable.hull or Vector(32, 32, 72)
                        local duckBy = self.formTable.duckBy or (self.formTable.hull and 0 or 36)
                        ply:SetHull(-Vector(hull.x / 2, hull.y / 2, 0), Vector(hull.x / 2, hull.y / 2, hull.z))
                        ply:SetHullDuck(-Vector(hull.x / 2, hull.y / 2, 0), Vector(hull.x / 2, hull.y / 2, hull.z - duckBy or 0))--
                        ply:SetRenderMode(RENDERMODE_NONE)
                        pk_pills.mapEnt(ply, nil)

                        if SERVER then
                            if ply:FlashlightIsOn() then
                                ply:Flashlight(false)
                            end

                            ply:Freeze(false)
                            ply:SetNotSolid(false)
                            ply:DrawViewModel(false)

                            local camOffset = Vector(0, 0, 100) --
                            --clside this?
                            ply:SetStepSize(hull.z / 4)
                            ply:SetViewOffset(camOffset)
                            ply:SetViewOffsetDucked(camOffset - Vector(0, 0, duckBy*1.75) )
                            
                            self:ApplyMoveSpeed()
                            
                        end
                        pk_pills.mapEnt(ply, self)
                    end)

                    local self = ent
                    ent.Think = function()
                        local currentanim = 'idle'
                        local ply = self:GetPillUser()
                        local puppet = self:GetPuppet()
                        if not IsValid(puppet) or not IsValid(ply) then return end
                        local vel = ply:GetVelocity():Length()

                        if SERVER then
                            --Anims
                            local anims = table.Copy(self.formTable.anims.default or {})
                            table.Merge(anims, (IsValid(ply:GetActiveWeapon()) and self.formTable.anims[ply:GetActiveWeapon():GetHoldType()]) or (self.forceAnimSet and self.formTable.anims[self.forceAnimSet]) or {})
                            local anim
                            --local useSeqVel=true
                            local overrideRate

                            if (not self.anim or not anims[self.anim]) then
                                self.animFreeze = nil
                                self.animStart = nil
                            end

                            if self.animFreeze and not self.plyFrozen then
                                self:ApplyMoveSpeed()
                                self.plyFrozen = true
                            elseif not self.animFreeze and self.plyFrozen then
                                self:ApplyMoveSpeed()
                                self.plyFrozen = nil
                            end

                            if self.anim and anims[self.anim] then
                                anim = anims[self.anim]
                                overrideRate = anims[self.anim .. "_rate"] or 1
                                local cycle = puppet:GetCycle()

                                if not self.animStart then
                                    if cycle == 1 or (self.animCycle and self.animCycle > cycle) or (string.lower(anim) ~= string.lower(puppet:GetSequenceName(puppet:GetSequence()))) then
                                        self.anim = nil
                                        self.animCycle = nil

                                        if self.animFreeze then
                                            self.animFreeze = nil
                                        end
                                    elseif self.animCycle then
                                        self.animCycle = cycle
                                    end
                                end
                            elseif self.tickAnim and anims[self.tickAnim] then
                                anim = anims[self.tickAnim]
                                overrideRate = anims[self.tickAnim .. "_rate"] or 1
                                self.tickAnim = nil
                            elseif self.burrowed then
                                anim = anims["burrow_loop"]
                            elseif ply:WaterLevel() > 2 then
                                anim = anims["swim"] or anims["glide"] or anims["idle"]
                            elseif ply:IsOnGround() then
                                if ply:Crouching() then
                                    if vel > ply:GetCrouchedWalkSpeed() / 4 then
                                        anim = anims["crouch_walk"] or anims["crouch"] or anims["walk"] or anims["idle"]
                                    else
                                        anim = anims["crouch"] or anims["idle"]
                                    end
                                else
                                    if vel > (ply:GetWalkSpeed() + ply:GetRunSpeed()) / 2 then
                                        anim = anims["run"] or anims["walk"] or anims["idle"]
                                    elseif vel > ply:GetWalkSpeed() / 4 then
                                        anim = anims["walk"] or anims["idle"]
                                    else
                                        anim = anims["idle"]
                                    end
                                end
                            else
                                anim = anims["glide"] or anims["idle"]
                            end

                            if anim == anims["idle"] or anim == anims["crouch"] then
                                overrideRate = 1
                            end
                            self:SetNWString("Animlastplayed", anim)

                            local ShouldAlternate = table.Copy(self.formTable.anims.ShouldAlternate or {})
                            if type(ShouldAlternate[anim]) == "function" and ShouldAlternate[anim](self) then
                                if ShouldAlternate[anim](self) ~= nil and isstring(ShouldAlternate[anim](self)) then
                                    
                                    anim = ShouldAlternate[anim](self)
                                end
                            end

                            if (anim and puppet:GetSequence() ~= puppet:LookupSequence(anim)) or self.animStart or (self.formTable.autoRestartAnims and puppet:GetCycle() == 1) then
                                puppet:ResetSequence(puppet:LookupSequence(anim))
                                puppet:SetCycle(0)
                                self.animCycle = 0
                            end

                            self.animStart = nil
                            local seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                            --if true then
                            if self.formTable.movePoseMode ~= "xy" and self.formTable.movePoseMode ~= "xy-bot" and not overrideRate then
                                local rate = overrideRate or vel / seq_vel

                                --goofy limitation (floods console with errors if above 12!)
                                if rate > 12 then
                                    rate = 12
                                end

                                puppet:SetPlaybackRate(rate)
                            else
                                --puppet:SetPlaybackRate(1)
                            end

                            --print(puppet:GetCycle())
                            if self.formTable.movePoseMode then
                                --
                                if self.formTable.movePoseMode == "yaw" then
                                    local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                    puppet:SetPoseParameter("move_yaw", move_dir.y)
                                elseif self.formTable.movePoseMode == "xy" then
                                    if not overrideRate then
                                        local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                        local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                        local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                        puppet:SetPoseParameter("move_x", clampedvel.x)
                                        puppet:SetPoseParameter("move_y", -clampedvel.y)
                                        seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                        if seq_vel ~= 0 then
                                            puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                            puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                        end
                                        --print(puppet:GetPlaybackRate())
                                    else
                                        puppet:SetPoseParameter("move_x", 0)
                                        puppet:SetPoseParameter("move_y", 0)
                                    end
                                elseif self.formTable.movePoseMode == "xy-bot" then
                                    if not overrideRate then
                                        local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                        local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                        local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                        local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                        puppet:SetPoseParameter("move_x", clampedvel.x)
                                        puppet:SetPoseParameter("move_y", -clampedvel.y)
                                        puppet:SetPoseParameter("move_yaw", move_dir.y)
                                        puppet:SetPoseParameter("move_scale", 1)
                                        seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                        if seq_vel ~= 0 then
                                            puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                            puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                            puppet:SetPoseParameter("move_scale", math.Clamp(localvel:Length() / seq_vel, -.99, .99))
                                        end
                                        --print(puppet:GetPlaybackRate())
                                    else
                                        puppet:SetPoseParameter("move_x", 0)
                                        puppet:SetPoseParameter("move_y", 0)
                                        puppet:SetPoseParameter("move_yaw", 0)
                                        puppet:SetPoseParameter("move_scale", 0)
                                    end
                                end
                            end

                            --Aimage
                            if self.formTable.aim then
                                if self.formTable.aim.xPose then
                                    local yaw = math.AngleDifference(ply:EyeAngles().y, puppet:GetAngles().y)

                                    if self.formTable.aim.xInvert then
                                        yaw = -yaw
                                    end

                                    puppet:SetPoseParameter(self.formTable.aim.xPose, yaw)
                                end

                                if self.formTable.aim.yPose then
                                    local pitch = math.AngleDifference(ply:EyeAngles().p, puppet:GetAngles().p)

                                    if self.formTable.aim.yInvert then
                                        pitch = -pitch
                                    end

                                    puppet:SetPoseParameter(self.formTable.aim.yPose, pitch)
                                end
                            end

                            if not ply:IsOnGround() and not self.touchingWater and ply:WaterLevel() > 0 and self.formTable.land then
                                self.formTable.land(ply, self)
                            end

                            --tick attack
                            if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "tick" then
                                self.formTable.attack.func(ply, self, self.formTable.attack)
                            end

                            if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "tick" then
                                self.formTable.attack2.func(ply, self, self.formTable.attack2)
                            end

                            --auto attack
                            if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "auto" then
                                if not self.formTable.aim then
                                    self:PillLoopSound("attack")
                                else
                                    self:PillLoopStop("attack")
                                end

                                if (not self.lastAttack or (self.formTable.attack.interval or self.formTable.attack.delay) < CurTime() - self.lastAttack) then
                                    self.formTable.attack.func(ply, self, self.formTable.attack)
                                    self.lastAttack = CurTime()
                                end
                            else
                                self:PillLoopStop("attack")
                            end

                            if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "auto" then
                                if not self.formTable.aim then
                                    self:PillLoopSound("attack2")
                                else
                                    self:PillLoopStop("attack2")
                                end

                                if not self.lastAttack2 or (self.formTable.attack2.interval or self.formTable.attack2.delay) < CurTime() - self.lastAttack2 then
                                    self.formTable.attack2.func(ply, self, self.formTable.attack2)
                                    self.lastAttack2 = CurTime()
                                end
                            else
                                self:PillLoopStop("attack2")
                            end

                            --if !IsValid(ply) then self:NextThink(CurTime()) return true end
                            --wepon-no longer SO hackey
                            if not self.formTable.hideWeapons then
                                local realWep = self:GetPillUser():GetActiveWeapon()

                                --&&self:GetPillUser()!=ply or pk_pills.var_thirdperson:GetBool()) then
                                if IsValid(realWep) and realWep:GetModel() ~= "" then
                                    --hiding the real thing [BROKEN]
                                    --[[if realWep:GetRenderMode()!=RENDERMODE_NONE then
                                        realWep:SetRenderMode(RENDERMODE_NONE)
                                    end]]
                                    if realWep.pill_attachment then
                                        if IsValid(self.wepmdl) then
                                            self.wepmdl:Remove()
                                        end

                                        self.wepmdl = ents.Create("pill_attachment_wep")
                                        self.wepmdl:SetParent(self:GetPuppet())
                                        self.wepmdl:SetModel(realWep:GetModel())
                                        self.wepmdl.attachment = realWep.pill_attachment
                                        self.wepmdl:Spawn()

                                        if realWep.pill_offset then
                                            self.wepmdl:SetWepOffset(realWep.pill_offset)
                                        end

                                        if realWep.pill_angle then
                                            self.wepmdl:SetWepAng(realWep.pill_angle)
                                        end

                                        realWep.pill_proxy = self.wepmdl
                                    elseif not IsValid(self.wepmdl) then
                                        self.wepmdl = ents.Create("pill_attachment_wep")
                                        self.wepmdl:SetParent(self:GetPuppet())
                                        self.wepmdl:SetModel(realWep:GetModel())
                                        self.wepmdl:Spawn()
                                        realWep.pill_proxy = self.wepmdl
                                    elseif self.wepmdl:GetModel() ~= realWep:GetModel() then
                                        self.wepmdl:SetModel(realWep:GetModel())
                                    end
                                elseif IsValid(self.wepmdl) then
                                    self.wepmdl:Remove()
                                end
                            end
                        else
                            if self:GetPillUser() ~= LocalPlayer() or pk_pills.convars.cl_thirdperson:GetBool() then
                                --puppet:SetNoDraw(false)
                            else
                                --puppet:SetNoDraw(true)
                            end

                            local realWep = self:GetPillUser():GetActiveWeapon()

                            if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                                realWep:SetNoDraw(true)
                            end
                        end

                        --Align pos and angles with player
                        if SERVER then
                            puppet:SetPos(ply:GetPos())
                        else
                            puppet:SetRenderOrigin(ply:GetPos())
                        end
                        
                        currentanim = self:GetNWString("Animlastplayed")

                        --if vel > 0 or math.abs(math.AngleDifference(puppet:GetAngles().y, ply:EyeAngles().y)) > 350 then

                        local animsshouldspn = table.Copy(self.formTable.anims.ShouldMoveRotate or {})
                        if animsshouldspn[currentanim] or (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) then
                            
                            local typeofitem = (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) or animsshouldspn[currentanim]
                            local function SetTargetAngle(ang)
                                ang.p = 0
                                puppet:SetNW2Vector("SyncAng", ang:Forward())
                            end

                            local function GetTargetAngle()
                                local dir = puppet:GetNW2Vector("SyncAng")
                                if not dir or dir == vector_origin then return nil end
                                local ang = dir:Angle()
                                if not ang then return nil end
                                ang.p = 0
                                return ang
                            end

                            if typeofitem == "notshftlock" then
                                local dir = ply:GetVelocity():GetNormalized()
                                local aheadPos = ply:GetPos() + dir * 5
                                local ang = (aheadPos - ply:GetPos()):Angle()
                                ang.p = 0
                                if ply:GetVelocity().x == 0 and ply:GetVelocity().y == 0 then
                                else
                                    if SERVER then
                                        SetTargetAngle(ang)
                                        puppet:SetAngles(ang)
                                    end

                                    if CLIENT then
                                        local targetAng = GetTargetAngle()
                                        if targetAng then
                                            local curAng = puppet:GetRenderAngles()
                                            if not curAng then curAng = targetAng end
                                            if not curAng.p then curAng = Angle(0,0,0) end
                                            local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                            puppet:SetRenderAngles(smoothAng)
                                        end
                                    end
                                end

                            elseif typeofitem == "assignedagnles_instant" then
                                local targetAng = self:GetNWAngle("pill_assignedangle")

                                if SERVER then
                                    SetTargetAngle(targetAng)
                                    puppet:SetAngles(targetAng)
                                end

                                if CLIENT then
                                    if targetAng then
                                        puppet:SetRenderAngles(targetAng)
                                    end
                                end

                            elseif typeofitem == "shiftlock" then
                                local angs = ply:EyeAngles()
                                angs.p = 0

                                if SERVER then
                                    SetTargetAngle(angs)
                                    puppet:SetAngles(angs)
                                end

                                if CLIENT then
                                    local targetAng = GetTargetAngle()
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end

                            elseif typeofitem == "Playerangles" then
                                local angs = ply:GetAngles()
                                angs.p = 0

                                if SERVER then
                                    SetTargetAngle(angs)
                                    puppet:SetAngles(angs)
                                end

                                if CLIENT then
                                    local targetAng = GetTargetAngle()
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end

                            elseif typeofitem == "assignedagnles" then
                                local targetAng = self:GetNWAngle("pill_assignedangle")

                                if SERVER then
                                    SetTargetAngle(targetAng)
                                    puppet:SetAngles(targetAng)
                                end

                                if CLIENT then
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end

                            elseif typeofitem == "notanything" then
                            end
                        end

                        self:NextThink(CurTime())

                        return true
                    end
                end
                if ent.formTable.HandleAnimEvent_Noodles_shyguy096_pill then
                    local PuppetEntity = ent:GetPuppet()
                    local entityply = ent:GetPillUser()

                    if IsValid(PuppetEntity) then
                        function PuppetEntity:AcceptInput(inputName, activator, caller, data)
                            ent.formTable.HandleAnimEvent_Noodles_shyguy096_pill(entityply, ent, inputName)
                            return true
                        end
                    end
                end
            end
        end
    end)
end)

