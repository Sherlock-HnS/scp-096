--NoHealing_OM_Noodles
AddCSLuaFile()
if CLIENT then
    util.PrecacheSound("gentoi/scp096/Scream.wav")
end

local function AdvancedPillSound(SoundData, ent)
    if SERVER then
        if IsValid(ent) then
            SoundData = SoundData or {}
            SoundData.stringe = SoundData.stringe or {}
            SoundData.soundLevel = SoundData.soundLevel or 75
            SoundData.pitchPercent = SoundData.pitchPercent or 100
            SoundData.volume = SoundData.volume or 1
            SoundData.channel = SoundData.channel or CHAN_AUTO
            SoundData.soundFlags = SoundData.soundFlags or 0
            SoundData.dsp = SoundData.dsp or 0
            SoundData.filter = SoundData.filter or nil

            local chosenSound = SoundData.stringe

            if istable(SoundData.stringe) then
                local index = math.random(1, #SoundData.stringe)
                chosenSound = SoundData.stringe[index]
            end

            ent:EmitSound(
                chosenSound,
                SoundData.soundLevel,
                SoundData.pitchPercent,
                SoundData.volume,
                SoundData.channel,
                SoundData.soundFlags,
                SoundData.dsp,
                SoundData.filter
            )
        end
        return true
    end
end

hook.Add("SetupMove", "Gentoi_thescp96_moveset_e", function(ply, mv, cmd)



    if ply:GetNWFloat("DisablePlayerMovement_Gentoi_The_scp96") >= CurTime() or ply:GetNWFloat("Disable_Gentoi_The_scp96_stunned") >= CurTime() then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
        mv:SetButtons(0)
    end
    
    if mv:KeyDown(IN_JUMP) then
        if ply:GetNWFloat("nojump_Gentoi_The_scp96") >= CurTime() then
            mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
        end
    end
end)


local function scp096_returntablename( ply, ent )
    if !IsValid(ply) then return end
    return "Gentoi_scp96_".. ent:EntIndex().. "_".. ply:EntIndex()
end
local function tracefuntion(pilluser, functionth)
    if not SERVER then return end

    local enttable = {}
    local allEntities = table.Add(player.GetAll(), ents.GetAll())

    local puppet = pilluser.pk_pill_ent:GetPuppet()
    if not IsValid(puppet) then return end

    local bone = puppet:LookupBone("Head")
    if not bone then return end

    local headPos = puppet:GetBonePosition(bone)

    for _, v in ipairs(allEntities) do
        if not IsValid(v) then continue end
        if v:GetNWFloat("gentoi_scp096_jumpscare_kill") > 0 then continue end
        if v:IsPlayer() and v:Team() == TEAM_SPECTATOR then continue end

        if (v:IsPlayer() or v:IsNextBot() or v:IsNPC()) and v:Health() >= 0.1 then
            if v == pilluser then continue end
            if v:GetClass() == "pill_puppet" then continue end
            if not pilluser:Visible(v) then continue end

            local eyePos = v:EyePos()
            local eyeAng = v:EyeAngles()

            local dir = (headPos - eyePos):GetNormalized()
            local targetAng = dir:Angle()

            local yawDiff = math.AngleDifference(eyeAng.y, targetAng.y)
            local pitchDiff = math.AngleDifference(eyeAng.p, targetAng.p)

            local fov = v:IsPlayer() and v:GetFOV() or 90
 

            local sideBias = 1.5
            halfFOV_H = fov * 0.5 * sideBias
            local halfFOV_V = (fov * 0.5) * 0.6

            if math.abs(yawDiff) <= halfFOV_H and math.abs(pitchDiff) <= halfFOV_V then
                local name = scp096_returntablename(pilluser, pilluser.pk_pill_ent)
                if v:GetNWBool(name) then continue end

                table.insert(enttable, v)
            end
        end
    end

    functionth(enttable)
end

hook.Add("PlayerSpawn", "gentoi_scp096_jumpscare_kill", function(ply)
    if ply:GetNWFloat("gentoi_scp096_jumpscare_kill") > 0 then
        ply:SetNWFloat("gentoi_scp096_jumpscare_kill", 0)
    end
end)

local function scp096_removetable(ply, ent, target)
    if !IsValid(ent) or !IsValid(target) then return end

    local name = scp096_returntablename(ply, ent)
    if target:GetNWBool(name) then
        target:SetNWBool(name, false)

        ent:SetNWFloat("Gentoi_scp96_counter",math.max(0, ent:GetNWFloat("Gentoi_scp96_counter", 0) - 1))
        hook.Remove("PlayerDeath", name.." ".. target:EntIndex())
    end
end


local function scp096_addtotable(ply, ent, target)
    if !IsValid(ent) or !IsValid(target) then return end

    local name = scp096_returntablename(ply, ent)
    if target:GetNWBool(name) then return end

    target:SetNWBool(name, true)
    ent:SetNWFloat( "Gentoi_scp96_counter", ent:GetNWFloat("Gentoi_scp96_counter", 0) + 1)

    target:CallOnRemove("scp096_cleanup_" .. name, function()
        if !IsValid(ent) then return end
        ent:SetNWFloat("Gentoi_scp96_counter",math.max(0, ent:GetNWFloat("Gentoi_scp96_counter", 0) - 1))
    end)

    ent:CallOnRemove("scp096_cleanup_ent_" .. name, function()
        if !IsValid(target) then return end
        target:SetNWBool(name, false)
    end)

    hook.Add("PlayerDeath", name.." ".. target:EntIndex(), function(victim)
        if victim ~= target then return end
        scp096_removetable(ply, ent, target)
        hook.Remove("PlayerDeath", name.." ".. target:EntIndex())
    end)
end

if SERVER then
else

    local scp096_faceSprite = Material("models/gentoi/scp/scp096/black")
    hook.Add("PostDrawTranslucentRenderables", "gent_scp096_drawface_sprite", function()
        local eyePos = EyePos()

        for _, ent in ipairs(ents.GetAll()) do
            if not IsValid(ent) then continue end


            local boneCount = ent:GetBoneCount()
            if ent:GetNWEntity("JumpscareDeathThing_ent_scp096") == LocalPlayer() then
                local headBone = ent:LookupBone("ValveBiped.Bip01_Head1")
                if headBone then
                    local function IsChildOfHead(bone)
                        local parent = ent:GetBoneParent(bone)

                        while parent and parent ~= -1 do
                            if parent == headBone then
                                return true
                            end
                            parent = ent:GetBoneParent(parent)
                        end

                        return false
                    end

                    for i = 0, boneCount - 1 do
                        if i == headBone or IsChildOfHead(i) then
                            ent:ManipulateBoneScale(i, Vector(0, 0, 0))
                        end
                    end
                end
            end
            
            if ent:GetNWFloat("DrawBlackSqaure_scp096") <= CurTime() then
                continue 
            end

            if not boneCount or boneCount <= 0 then continue end
            local headBone = ent:LookupBone("ValveBiped.Bip01_Head1")
            local headPos

            if headBone then
                headPos = ent:GetBonePosition(headBone)
            end

            if not headPos or headPos == vector_origin then
                headPos = ent:EyePos()
            end

            local drawPos = headPos + LocalPlayer():EyeAngles():Forward()*-10

            render.SetMaterial(scp096_faceSprite)

            local size = 25

            render.DrawSprite(
                drawPos,
                size,
                size,
                color_black
            )
        end
    end)


    hook.Add("SetupPlayerVisibility", "gent_scp096_visible", function()
        local ply = LocalPlayer()
        local pillentity = LocalPlayer().pk_pill_ent

        if IsValid(pillentity) then
            if pillentity.formTable then
                if pillentity.formTable.Gentoi_scp96 then
                    for _, ent in ipairs(ents.GetAll()) do
                        if IsValid(ent) then
                            if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
                                local name = scp096_returntablename(ply, pillentity)
                                if ent:GetNWBool(name) then
                                    AddOriginToPVS(ent:GetPos())
                                end
                            end 
                        end
                    end
                end
            end
        end
    end)

    hook.Add( "PreDrawHalos", "gent_scp096_halo", function()
        local ply = LocalPlayer()
        local pillentity = LocalPlayer().pk_pill_ent

        if IsValid(pillentity) then
            if pillentity.formTable then
                if pillentity.formTable.Gentoi_scp96 then
                    local entities = {}

                    for _, ent in ipairs(ents.GetAll()) do
                        if IsValid(ent) then
                            if (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) and ent:Health()>0.1 then
                                local name = scp096_returntablename(ply, pillentity)
                                if ent:GetNWBool(name) then
                                    table.insert(entities, ent)
                                end
                                        
                            end
                        end
                    end

                    halo.Add(entities, Color(255,0,0), 0, 0, 2, true, true)
                    halo.Add(entities, Color(255,0,0), 6, 6, 2, true, true)
                end
            end
        end
    end )
end

local function racheljackietien_jumpscare(ply, ent, duration, customanimstuff)
    if SERVER then
        if not ent.IsInJumpscare then ent.IsInJumpscare = 0 end
        if ent.IsInJumpscare >= CurTime() then return end
        if not ent.IsInJumpscareCooldown then ent.IsInJumpscareCooldown = 0 end
        if ent.IsInJumpscareCooldown >= CurTime() then return end

        local jumpscare_entity = nil

        for _, ent2 in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 90)) do
            if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.1 then
                if ent2 == ply then continue end
                if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end

                if IsValid(ent2) then
                    jumpscare_entity = ent2
                    break
                end
            end
        end

        if SherlockHNS and IsValid(jumpscare_entity) and jumpscare_entity:IsPlayer() then
            return pk_pills.playHNSJumpscare(ply, ent, jumpscare_entity, duration, {
                camera = "gentoi_scp096_cam",
                onStart = customanimstuff,
            })
        end

        if jumpscare_entity ~= nil then
            
            ent.JuumpscareStart = CurTime()

            ent.jumpscare_entity = jumpscare_entity
            ent.entitylastpos = jumpscare_entity:GetPos()
            ent.entitylastang = jumpscare_entity:GetAngles()

            local targetAngle = (ply:GetPos() - jumpscare_entity:GetPos()):Angle()

            targetAngle.p = 0
            targetAngle.r = 0

            ply:SetNWInt("DisablePlayerMovement_Gentoi_The_scp96", duration+CurTime())
            jumpscare_entity:SetNWInt("DisablePlayerMovement_Gentoi_The_scp96", duration+CurTime())


            ent.IsInJumpscare = CurTime() + duration

            local puppet = ent:GetPuppet()

            if jumpscare_entity:IsPlayer() then

                net.Start('gentoi_scp096_cam')
                net.WriteEntity(puppet)
                net.WriteBool(true)
                net.Send(jumpscare_entity)
            else
                jumpscare_entity:NextThink(duration+0.1+CurTime())
            end
            
            jumpscare_entity:AddFlags(FL_NOTARGET)
            jumpscare_entity:SetNWFloat("gentoi_scp096_jumpscare_kill", 1)
            ent:CallOnRemove("RachelJumpscare"..ent:EntIndex(), function()
                if !IsValid(jumpscare_entity) then return end

                jumpscare_entity:RemoveFlags(FL_NOTARGET)
                ent.jumpscare_entity = nil

                if jumpscare_entity:IsPlayer() then
                    net.Start('gentoi_scp096_cam')
                    net.WriteEntity(puppet)
                    net.WriteBool(false)
                    net.Send(jumpscare_entity)
                else
                    jumpscare_entity:NextThink(CurTime())
                end
                jumpscare_entity:SetPos(ent.entitylastpos)
                jumpscare_entity:SetAngles(ent.entitylastang)
                jumpscare_entity:SetNWInt("DisablePlayerMovement_Gentoi_The_scp96", CurTime())
                jumpscare_entity:SetNWFloat("gentoi_scp096_jumpscare_kill", 0)
            end)

            customanimstuff()
        end
    end


end


pk_pills.packStart("SCP 096", "gentoi_noodles_SCP096", "pills/pill_gent_scp096.png")

pk_pills.register('pill_gent_scp096', {

    printName='SCP 096',
    Health = 3000,
    
    model="models/Gentoi/scp/scp096.mdl",
    
    modelScale='1',

    Gentoi_scp96 = true,
    noragdoll = false,
    muteSteps = true,
    type='ply',

    ---------------------------------- STATS STATS STATS
    Gentoi_scp096_stats = {
        moveSpeed = {
            walk =72,
            run = 600,
            ducked= 70,
            jumppower= 0,
        },
        rage = {
            wait = 30,
            dur = 60,
            cd = 30,
        },
    },
    
    anims={
        default={
            idle="idle",
            run="run",
            walk="walk",
            glide="idle",
            kill="Kill",
            rage='rage',
            intro='intro',
            ForceOpenDoor='ForceOpenDoor',
            crouch = "CrouchIdle",
            crouch_walk = "CrouchWalk",
        },
        ShouldMoveRotate={
            idle= function(ent) 
                if ent:GetNWFloat("nearwall_scp_096") > CurTime() then
                    return "assignedagnles"
                end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end

                if ent:GetPillUser():IsOnGround() then
                    return 'notanything'
                else
                    return 'notshftlock'
                end
            end,
            run= function(ent)
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'
            end,
            walk= function(ent)
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'
            end,
            CrouchIdle= function(ent) 
                if ent:GetNWFloat("nearwall_scp_096") > CurTime() then
                    return "assignedagnles"
                end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end

                if ent:GetPillUser():IsOnGround() then
                    return 'notanything'
                else
                    return 'notshftlock'
                end
            end,
            CrouchWalk= function(ent)
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'
            end,
        },

        ShouldAlternate={
            CrouchIdle= function(ent)
                if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
                    return "CrouchIdleRage"
                end
            end,
            CrouchWalk= function(ent)
                if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
                    return "CrouchWalkRage"
                end
            end,
            run= function(ent)
                if ent:GetNWFloat("Gentoi_scp96_ragedur") <= CurTime() then
                    return "walk"
                end
            end,

            walk= function(ent)
                if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
                    return "run"
                end
            end,

            idle= function(ent)
                if ent:GetNWFloat("nearwall_scp_096") > CurTime() then
                    return "HoldItIn"
                end
                if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
                    return "RageIdle"
                end
            end,
        },
    },


    OM_cameratable = function(ply,ent)
        local basetable =  {
            startoffset = Vector(22.5,0,0),  -- left-up, front-back, up-down
            startoffsetFirst = Vector(0,10,0),
            dist=100,
            fov = 80,
            id = 0,
            transition = 2,
            bonecenter = "Head",
        }

        if ent:GetNWFloat("StartTime") > CurTime() then
            basetable =  {
                startoffset = Vector(0,0,0),  -- left-up, front-back, up-down
                startoffsetFirst = Vector(0,10,0),
                dist=250,
                fov = 70,
                id = 1,
                transition = 0,
                bonecenter = "Head",
            }
        end

        if ent:GetNWFloat("Bar_scp096_rage_buildup") > CurTime() then
            basetable =  {
                startoffset = Vector(0,0,0),  -- left-up, front-back, up-down
                startoffsetFirst = Vector(0,10,0),
                dist=140,
                fov = 80,
                id = 2,
                transition = 1,
                bonecenter = "Head",
            }
        end

        if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
            basetable =  {
                startoffset = Vector(22.5,0,0),  -- left-up, front-back, up-down
                startoffsetFirst = Vector(0,10,0),
                dist=100,
                fov = 80,
                id = 3,
                transition = 1,
                bonecenter = "Head",
            }
        end
        return basetable
    end,

    movePoseMode="xy",

    aim={
        xPose="aim_yaw",
        yPose="aim_pitch",
        nocrosshair = true
    },
        
        
    --canAim=function(ply,ent) return ent.active end,     

    HandleAnimEvent_Noodles_shyguy096_pill = function(ply, ent, event)
        if event == "Step" then

            if not ply:OnGround() then return end
            local DefaultFootsteps = {
                [MAT_ANTLION] = { "physics/flesh/flesh_impact_hard1.wav", "physics/flesh/flesh_impact_hard2.wav", "physics/flesh/flesh_impact_hard3.wav", "physics/flesh/flesh_impact_hard4.wav", "physics/flesh/flesh_impact_hard5.wav", "physics/flesh/flesh_impact_hard6.wav" },
                [MAT_BLOODYFLESH] = { "physics/flesh/flesh_squishy_impact_hard1.wav", "physics/flesh/flesh_squishy_impact_hard2.wav", "physics/flesh/flesh_squishy_impact_hard3.wav", "physics/flesh/flesh_squishy_impact_hard4.wav" },
                [MAT_CONCRETE] = {"player/footsteps/concrete1.wav", "player/footsteps/concrete2.wav", "player/footsteps/concrete3.wav", "player/footsteps/concrete4.wav" },
                [MAT_DIRT] = { "player/footsteps/dirt1.wav", "player/footsteps/dirt2.wav", "player/footsteps/dirt3.wav", "player/footsteps/dirt4.wav" },
                [MAT_EGGSHELL] = {"physics/flesh/flesh_impact_hard1.wav", "physics/flesh/flesh_impact_hard2.wav", "physics/flesh/flesh_impact_hard3.wav", "physics/flesh/flesh_impact_hard4.wav", "physics/flesh/flesh_impact_hard5.wav", "physics/flesh/flesh_impact_hard6.wav" },
                [MAT_FLESH] = {"physics/flesh/flesh_impact_hard1.wav","physics/flesh/flesh_impact_hard2.wav","physics/flesh/flesh_impact_hard3.wav","physics/flesh/flesh_impact_hard4.wav","physics/flesh/flesh_impact_hard5.wav","physics/flesh/flesh_impact_hard6.wav"},
                [MAT_GRATE] = {"player/footsteps/chainlink1.wav","player/footsteps/chainlink2.wav","player/footsteps/chainlink3.wav","player/footsteps/chainlink4.wav"},
                [MAT_ALIENFLESH] = { "physics/flesh/flesh_impact_hard1.wav", "physics/flesh/flesh_impact_hard2.wav", "physics/flesh/flesh_impact_hard3.wav", "physics/flesh/flesh_impact_hard4.wav", "physics/flesh/flesh_impact_hard5.wav","physics/flesh/flesh_impact_hard6.wav"},
                [MAT_SNOW] = {"player/footsteps/grass1.wav", "player/footsteps/grass2.wav","player/footsteps/grass3.wav","player/footsteps/grass4.wav"},
                [MAT_PLASTIC] = {"physics/plastic/plastic_box_impact_soft1.wav","physics/plastic/plastic_box_impact_soft2.wav","physics/plastic/plastic_box_impact_soft3.wav","physics/plastic/plastic_box_impact_soft4.wav"},
                [MAT_METAL] = {"player/footsteps/metal1.wav","player/footsteps/metal2.wav","player/footsteps/metal3.wav","player/footsteps/metal4.wav"},
                [MAT_SAND] = {"player/footsteps/sand1.wav","player/footsteps/sand2.wav","player/footsteps/sand3.wav","player/footsteps/sand4.wav"},
                [MAT_FOLIAGE] = {"player/footsteps/grass1.wav","player/footsteps/grass2.wav","player/footsteps/grass3.wav","player/footsteps/grass4.wav"},
                [MAT_COMPUTER] = {"player/footsteps/metal1.wav","player/footsteps/metal2.wav","player/footsteps/metal3.wav","player/footsteps/metal4.wav"},
                [MAT_SLOSH] = {"player/footsteps/slosh1.wav","player/footsteps/slosh2.wav","player/footsteps/slosh3.wav","player/footsteps/slosh4.wav"},
                [MAT_TILE] = {"player/footsteps/tile1.wav","player/footsteps/tile2.wav","player/footsteps/tile3.wav","player/footsteps/tile4.wav"},
                [MAT_GRASS] = {"player/footsteps/grass1.wav","player/footsteps/grass2.wav","player/footsteps/grass3.wav","player/footsteps/grass4.wav"},
                [MAT_VENT] = {"player/footsteps/duct1.wav","player/footsteps/duct2.wav","player/footsteps/duct3.wav","player/footsteps/duct4.wav"},
                [MAT_WOOD] = {"player/footsteps/wood1.wav","player/footsteps/wood2.wav","player/footsteps/wood3.wav","player/footsteps/wood4.wav"},
                [MAT_DEFAULT] = {"player/footsteps/concrete1.wav","player/footsteps/concrete2.wav","player/footsteps/concrete3.wav","player/footsteps/concrete4.wav"},
                [MAT_GLASS] = {"physics/glass/glass_sheet_step1.wav","physics/glass/glass_sheet_step2.wav","physics/glass/glass_sheet_step3.wav","physics/glass/glass_sheet_step4.wav"},
                [MAT_WARPSHIELD] = {"physics/glass/glass_sheet_step1.wav","physics/glass/glass_sheet_step2.wav","physics/glass/glass_sheet_step3.wav","physics/glass/glass_sheet_step4.wav"}
            }
            local tr = util.TraceLine({
                start = ply:GetPos(),
                endpos = ply:GetPos() - ply:GetUp()*999,
                filter = {ply, ent, ent:GetPuppet()}
            })
            local sounds = DefaultFootsteps[tr.MatType]
            if not sounds then return end
            AdvancedPillSound({
                stringe = sounds[math.random(#sounds)],
                soundLevel = 79*0.85
            }, ent)
        end

        if event == "Scratch" then

            
            local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))

            for i=1,3 do
                local effectdata = EffectData()
                effectdata:SetOrigin(cam.Pos)
                effectdata:SetNormal(ent:GetAngles():Forward()*-1 + ent:GetAngles():Up()*0.25)
                effectdata:SetMagnitude(3)
                effectdata:SetScale(15)
                effectdata:SetColor(0)
                effectdata:SetFlags(3)
                util.Effect("bloodspray", effectdata)
            end
        end

        if event == "DieFromJumpscare" then
            if SERVER then
                timer.Simple(0,function()
                    if !IsValid(ent) then return end
                    local jumpscare_entity = ent.jumpscare_entity
                    if IsValid(jumpscare_entity) then
                        jumpscare_entity:SetNoDraw(false)

                        jumpscare_entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
                        jumpscare_entity:SetColor(Color(255, 255, 255, 255))
                    end
                    
                    if !(IsValid(jumpscare_entity)) or !IsValid(ent) then return end

                    if jumpscare_entity:IsPlayer() then

                        ent.jumpscare_entity = nil
                        jumpscare_entity:SetPos(ent.entitylastpos)
                        jumpscare_entity:SetAngles(ent.entitylastang)
                        net.WriteEntity(puppet)
                        net.WriteBool(false)
                        net.Send(jumpscare_entity)
                        jumpscare_entity:Kill(ply)

                    else
                        --[[
                        if ply:IsPlayer() then
                            hook.Run("PlayerDeath", ply, jumpscare_entity, ply)
                        else hook.Run("OnNPCKilled", ply, ply, jumpscare_entity) end
                        ]]
                        jumpscare_entity:Remove()
                    end

                    ent:RemoveCallOnRemove("RachelJumpscare"..ent:EntIndex())
                    if IsValid(ent:GetNWEntity("JumpscareDeathThing_ent")) then
                        ent:GetNWEntity("JumpscareDeathThing_ent"):SetNWInt("DrawBlackSqaure_scp096", 1e9+CurTime())
                    end
                end)
            end
        end
    end,

    noodles_gent_scp096_initialize=function(initializetable,initializetable2,initializetable3)
        if SERVER then
            hook.Add("PlayerFootstep", "DisableFootstepID_OM:".. tostring(initializetable2["entity"]:EntIndex()), function(ply)
                if entityply == ply then return true end
            end)
            if initializetable2["player"]:IsPlayer() then
                net.Start("Gentoi_scp096_CameraCode_n")
                net.WriteEntity(initializetable2["entity"])
                net.Send(initializetable2["player"])
            end
            if SERVER then
                timer.Simple(0.1,function()
                    if !IsValid(initializetable2["entity"]) then return end
                    initializetable2["entity"]:GetPuppet():SetViewOffset(Vector(0, 0, 120))
                end)
                
                initializetable2["entity"]:PillAnim('intro')
                local anim = initializetable2["entity"]:GetPuppet():LookupSequence("intro")
                local dur = initializetable2["entity"]:GetPuppet():SequenceDuration(anim)
                initializetable2["entity"]:SetNWFloat("StartTime", CurTime()+ dur)
                initializetable2["entity"]:SetNWBool("StartTime2",  true)
                initializetable2["player"]:SetNWFloat("Disable_Gentoi_The_scp96_stunned", CurTime()+ dur)
                initializetable2["player"]:SetNWFloat("DisablePlayerMovement_Gentoi_The_scp96", CurTime()+ dur)
                initializetable2["entity"]:SetNWFloat("gent_scp096_cutscenebar", CurTime()+ dur)

            end

            
                local ent = initializetable2["entity"]
                --[[
                if not ent.SCP096_Ambience then
                    ent.SCP096_Ambience = CreateSound(ent, "gentoi/scp096/Ambiance.wav")
                    ent.SCP096_Ambience:PlayEx(0, 100)
                    ent.SCP096_Ambience:SetSoundLevel(100)
                    ent.SCP096_Ambience:ChangeVolume(1, 1)
                end
                ]]
        end

        if CLIENT then
            local ent = initializetable2["entity"]
            local name = "gent_scp_096_"..ent:EntIndex()
            hook.Add("Think",  name, function()
                if !IsValid(ent) then 
                    hook.Remove("Think", name)
                    return end
                local ply = LocalPlayer()

                local dist = ply:GetPos():DistToSqr(ent:GetPos())
                local range = 4000 * 4000

                if dist <= range then
                    local stat1 = (ent:GetNWFloat("Gentoi_scp96_counter") > 0 and ent:GetNWFloat("Bar_scp096_rage_cd") < CurTime()) or ent:GetNWBool("increaseShyGuy")
                    if stat1 then
                        if ent:GetNWFloat("Bar_scp096_rage_buildup") > CurTime() then
                            if ent.SCP096_Scream then
                                ent.SCP096_Scream:Stop()
                                ent.SCP096_Scream = nil
                            end
                            if ent.SCP096_Ambience then
                                ent.SCP096_Ambience:Stop()
                                ent.SCP096_Ambience = nil
                            end
                        else
                            if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
                                if not ent.SCP096_Scream then
                                    ent.SCP096_Scream = CreateSound(ent, "gentoi/scp096/Scream.wav")
                                    ent.SCP096_Scream:SetSoundLevel(100)
                                end
                                if not ent.SCP096_Scream:IsPlaying() then
                                    ent.SCP096_Scream:Play()
                                end
                                if ent.SCP096_Ambience then
                                    ent.SCP096_Ambience:Stop()
                                    ent.SCP096_Ambience = nil
                                end
                            else
                                if ent.SCP096_Scream then
                                    ent.SCP096_Scream:Stop()
                                    ent.SCP096_Scream = nil
                                end
                            end
                        end

                    else
                        if ent:GetNWFloat("Bar_scp096_rage_buildup") > CurTime() then
                            if ent.SCP096_Scream then
                                ent.SCP096_Scream:Stop()
                                ent.SCP096_Scream = nil
                            end
                            if ent.SCP096_Ambience then
                                ent.SCP096_Ambience:Stop()
                                ent.SCP096_Ambience = nil
                            end
                        end
                        if ent.SCP096_Scream then
                            ent.SCP096_Scream:Stop()
                            ent.SCP096_Scream = nil
                        end
                        if not ent.SCP096_Ambience then
                            ent.SCP096_Ambience = CreateSound(ent, "gentoi/scp096/Ambiance.wav")
                            ent.SCP096_Ambience:PlayEx(0, 100)
                            ent.SCP096_Ambience:SetSoundLevel(100)
                            ent.SCP096_Ambience:ChangeVolume(1, 1)
                        else
                            if ent:GetNWFloat("nearwall_scp_096") > CurTime() then
                                ent.SCP096_Ambience:ChangeVolume(0.1, 1)
                            else
                                ent.SCP096_Ambience:ChangeVolume(1, 1)
                            end
                        end


                        if not ent.SCP096_Ambience:IsPlaying() then
                            ent.SCP096_Ambience:Play()
                        end
                    end
                else
                    if ent.SCP096_Scream then
                        ent.SCP096_Scream:Stop()
                        ent.SCP096_Scream = nil
                    end                        
                    if ent.SCP096_Ambience then
                        ent.SCP096_Ambience:Stop()
                        ent.SCP096_Ambience = nil
                    end
                end
            end)
        end
        if IsValid(initializetable2["player"]) then
            initializetable2["player"]:SetNWFloat("Disable_Gentoi_The_scp96_stunned", CurTime())
            for i, v in ipairs(ents.GetAll()) do
                local name = scp096_returntablename(initializetable2["player"], initializetable2["entity"])
                if v:GetNWBool(name) then
                    v:SetNWBool(name, false)
                end
            end
        end   
    end,

    noodles_gent_scp096_onremove=function(initializetable,initializetable2,initializetable3)
        if IsValid(initializetable2["player"]) then
            initializetable2["player"]:SetNWFloat("Disable_Gentoi_The_scp96_stunned", CurTime())
            for i, v in ipairs(ents.GetAll()) do
                local name = scp096_returntablename(initializetable2["player"], initializetable2["entity"])
                if v:GetNWBool(name) then
                    v:SetNWBool(name, false)
                end
            end
        end           
        initializetable2["entity"]:StopSound("gentoi/scp096/Triggered.wav")
        if initializetable2["entity"].SCP096_Ambience then
            initializetable2["entity"].SCP096_Ambience:Stop()
        end
        if initializetable2["entity"].SCP096_Scream then
            initializetable2["entity"].SCP096_Scream:Stop()
            initializetable2["entity"].SCP096_Scream = nil
        end

    end,

    noodles_gent_scp096_think = function(ply, ent)
        ply:SetNWFloat("nojump_Gentoi_The_scp96", CurTime()+0.1)
        if not ent:GetNWBool("StartTime2") then return end
        if ent:GetNWFloat("StartTime") > CurTime() then return end

        if ent:GetNWFloat("nearwall_scp_096") > CurTime() then
            if ent:GetNWBool("OnIntializeThink") then
                ent:SetNWBool("OnIntializeThink", false)
                if ent.SCP096_Ambience then ent.SCP096_Ambience:ChangeVolume(0.15, 1) end
            end
        else
            if not ent:GetNWBool("OnIntializeThink") then
                ent:SetNWBool("OnIntializeThink", true)
                if not ent:GetNWBool("Gentoi_scp96_rage_toggle") then
                    if ent.SCP096_Ambience then ent.SCP096_Ambience:ChangeVolume(1, 1) end
                end
            end

        end

        -- speed handeling
        local speed = {
            ['walk'] = ent.formTable.Gentoi_scp096_stats.moveSpeed.walk,
            ['run'] = ent.formTable.Gentoi_scp096_stats.moveSpeed.run,
            ['ducked'] = ent.formTable.Gentoi_scp096_stats.moveSpeed.ducked,
            ['jumppower'] = ent.formTable.Gentoi_scp096_stats.moveSpeed.jumppower
        }
        
        if ent:GetNWFloat("Gentoi_scp96_ragedur") < CurTime() then speed.run = speed.walk end
        if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then speed.walk = speed.run end

        local puppet = ent:GetPuppet()
        local currentsequence = puppet:GetSequence()
        if puppet:LookupSequence("CrouchWalk") == currentsequence or puppet:LookupSequence("CrouchWalkRage") == currentsequence then 
            if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
                speed.ducked = 200
            end
            speed.walk = speed.ducked
            speed.run = speed.ducked
        end

        --speed.walk = 700
        --speed.run = 900

        if IsValid(ply) and IsValid(ent) then
            pk_pills.setCostumeMoveSpeed(ent, speed.walk, speed.run, speed.ducked, speed.jumppower)
        end

        -- jumpscare handeling
        if SERVER then
            local puppet = ent:GetPuppet()
            if ent.jumpscare_entity then
                local entity = ent.jumpscare_entity
                if IsValid(entity) then

                    local lengthofentitybody = (entity:EyePos() - entity:GetPos()):Length() /2

                    local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))

                    if entity:Health() < 0.1 and entity:IsPlayer() then
                        ent.jumpscare_entity = nil
                    else
                        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                        local lengthofentitybody = ((maxs.z - mins.z)/2)*4

                        local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                        local newAngle = LerpAngle(lerpFactor, ent.entitylastang, cam.Ang)
                        local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos - entity:GetUp() * lengthofentitybody)
                        entity:SetPos(NewVector)
                        entity:SetAngles(newAngle)
                    end
                end
            end
        end

        --rage handeling
        tracefuntion(
            ply, 
            function(starelist)
                for k, v in ipairs(starelist) do
                    if ent:GetNWFloat("Bar_scp096_rage_cd") < CurTime() then
                        ent:SetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever", false)
                    end

                    if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
                        local duration = ent.formTable.Gentoi_scp096_stats.rage.dur
                        ent:SetNWFloat("Bar_scp096_rage_max", duration)
                        ent:SetNWFloat("Bar_scp096_rage_ui", CurTime()+ duration)
                        ent:SetNWFloat("Gentoi_scp96_ragedur", CurTime()+ duration)
                        ent:SetNWFloat("gent_scp096_cutscenebar_tre", CurTime()+ duration)
                    end

                    scp096_addtotable(ply, ent, v)
                end
            end
        )

        if (ent:GetNWFloat("Gentoi_scp96_counter") > 0 and ent:GetNWFloat("Bar_scp096_rage_cd") < CurTime()) or ent:GetNWBool("increaseShyGuy") then

            if not ent:GetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever") then
                if not ent:GetNWBool("Gentoi_scp96_rage_toggle") and not ent:GetNWBool("Gentoi_scp96_rage2_toggle") and not ent:GetNWBool("Gentoi_scp96_rage3_toggle") then 
                    if not ent:GetNWBool("Gentoi_scp96_rage_toggle") then ent:SetNWBool("Gentoi_scp96_rage_toggle", true) end

                    local duration = ent.formTable.Gentoi_scp096_stats.rage.wait
                    if ent:GetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever_forced") then
                        duration = 0.1
                    end
                    ent:SetNWFloat("Bar_scp096_rage_max", duration)
                    ent:SetNWFloat("Bar_scp096_rage_ui", CurTime()+ duration)
                    ent:SetNWFloat("Bar_scp096_rage_buildup", CurTime()+ duration)
                    ply:SetNWFloat("Disable_Gentoi_The_scp96_stunned", CurTime()+ duration)
                    ent:SetNWFloat("gent_scp096_cutscenebar", CurTime()+ duration)
                    ent:SetNWBool("increaseShyGuy", true)

                    if duration == 30 then
                        AdvancedPillSound(
                            {
                                stringe = "gentoi/scp096/Triggered.wav",
                                pitchPercent = 100,
                                volume = 1,
                                soundLevel = 87
                            },
                            ent
                        )

                        if ent.FirstTime_triggered_scp096 then
                        else
                            ent.FirstTime_triggered_scp096 = true
                            AdvancedPillSound(
                                {
                                    stringe = "gentoi/scp096/seen.wav",
                                    pitchPercent = 100,
                                    volume = 1,
                                    soundLevel = 87
                                },
                                ent
                            )
                        end
                                            
                        if ent:GetNWFloat("Gentoi_scp96_counter") > 0 then
                            if not ent:GetNWBool('Gentoi_scp96_rage_toggle_counter') then
                                ent:SetNWBool("Gentoi_scp96_rage_toggle_counter", true)
                                AdvancedPillSound(
                                    {
                                        stringe = "gentoi/scp096/WhenSeen.wav",
                                        pitchPercent = 100,
                                        volume = 1,
                                        soundLevel = 87
                                    },
                                    ent
                                )
                            end
                        end

                        if ent.PillAnim then
                            ent:PillAnim('rage')
                        end
                    end
                    ent:SetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever_forced", false)
                end
            end

            if ent:GetNWFloat("Bar_scp096_rage_buildup") > CurTime() then
                if not ent:GetNWBool("Gentoi_scp96_rage2_toggle") then ent:SetNWBool("Gentoi_scp96_rage2_toggle", true) end
            else
                if ent:GetNWBool("Gentoi_scp96_rage2_toggle") then
                    ent:SetNWBool("Gentoi_scp96_rage2_toggle", false)

                    local duration = ent.formTable.Gentoi_scp096_stats.rage.dur
                    ent:SetNWFloat("Bar_scp096_rage_max", duration)
                    ent:SetNWFloat("Bar_scp096_rage_ui", CurTime()+ duration)
                    ent:SetNWFloat("Gentoi_scp96_ragedur", CurTime()+ duration)
                    ent:SetNWFloat("gent_scp096_cutscenebar_tre", CurTime()+ duration)

                    --[[
                    AdvancedPillSound(
                        {
                            stringe = "gentoi/scp096/Scream.wav",
                            pitchPercent = 100,
                            volume = 1,
                            soundLevel = 87
                        },
                        ent
                    )
                    ]]
                end


                --if not ent:GetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever") then
                --    if not ent.SCP096_Scream or not ent.SCP096_Scream:IsPlaying() then
                --        ent.SCP096_Scream = CreateSound(ent, "gentoi/scp096/Scream.wav")
                --        ent.SCP096_Scream:PlayEx(0, 100)
                --        ent.SCP096_Scream:SetSoundLevel(100)
                --        ent.SCP096_Scream:ChangeVolume(1, 1)
                --    end
                --end

                if SERVER then 
                    if not ent:GetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever") then
                        local startPos = ply:GetPos()+Vector(0,0,50)
                        local endPos = startPos + ply:GetForward() * 70
                        local tr = util.TraceLine({
                            start = startPos,
                            endpos = endPos,
                            filter = ply,
                            mask = MASK_SOLID
                        })
                        if tr.Hit then
                            local entity = tr.Entity
                            if IsValid(entity) then
                                if entity:GetClass() == "prop_door_rotating" or entity:GetClass() == "func_door_rotating" then
                                    local dprop = ents.Create("prop_physics")
                                    if not IsValid(dprop) then return end

                                    dprop:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
                                    dprop:SetMoveType(MOVETYPE_VPHYSICS)
                                    dprop:SetSolid(SOLID_BBOX)
                                    dprop:SetPos(entity:GetPos() + Vector(0, 0, 2))
                                    dprop:SetAngles(entity:GetAngles())
                                    dprop:SetModel(entity:GetModel())

                                    entity:Remove()

                                    dprop:Spawn()

                                    dprop:SetSkin(entity:GetSkin() or 0)

                                    if entity:GetNumBodyGroups() then
                                        for id = 0, entity:GetNumBodyGroups() - 1 do
                                            dprop:SetBodygroup(id, entity:GetBodygroup(id))
                                        end
                                    end

                                    for i = 0, 31 do
                                        local mat = entity:GetSubMaterial(i)
                                        if mat and mat:len() > 0 then
                                            dprop:SetSubMaterial(i, mat)
                                        end
                                    end

                                    dprop:EmitSound("physics/wood/wood_crate_break3.wav")
                                    local effectdata = EffectData()
                                    effectdata:SetOrigin(dprop:GetPos() + dprop:OBBCenter())
                                    effectdata:SetMagnitude(5)
                                    effectdata:SetScale(2)
                                    effectdata:SetRadius(5)
                                    util.Effect("Sparks", effectdata)
                                            
                                    local phys = dprop:GetPhysicsObject()
                                    if IsValid(phys) then
                                        phys:ApplyForceOffset(ply:GetForward() * 200000, phys:GetMassCenter())
                                    end
                                end
                            end
                        end

                        for _, fling in ipairs(ents.FindInSphere(ply:GetPos() + Vector(0,0,30), 60)) do
                            if not IsValid(fling) then continue end

                            local phys = fling:GetPhysicsObject()
                            if IsValid(phys) then
                                local dir = (fling:GetPos() - ( ply:GetPos() + Vector(0,0,30) ) ):GetNormalized()
                                phys:ApplyForceCenter(dir * 6000)
                            end
                        end
                    end
                end
            end
            if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
                if not ent:GetNWBool("Gentoi_scp96_rage3_toggle") then ent:SetNWBool("Gentoi_scp96_rage3_toggle", true) end
            else
                if ent:GetNWBool("Gentoi_scp96_rage3_toggle") then
                    local cd = ent.formTable.Gentoi_scp096_stats.rage.cd
                    ent:SetNWFloat("Bar_scp096_rage_cd", CurTime()+ cd)
                    pk_pills.setHNSCooldown(ent, "rage", ent:GetNWFloat("Bar_scp096_rage_cd") - CurTime())
                    ent:SetNWFloat("Bar_scp096_rage_ui", CurTime()+ cd)
                    ent:SetNWFloat("Bar_scp096_rage_max", cd)
                    ent:SetNWBool("increaseShyGuy", false)
                end
            end
        else
            if ent:GetNWBool("Gentoi_scp96_rage_toggle") then
                ent:SetNWBool("Gentoi_scp96_rage_toggle", false)
                ent:SetNWBool("Gentoi_scp96_rage2_toggle", false)
                ent:SetNWBool("Gentoi_scp96_rage3_toggle", false)
                if ent.SCP096_Scream then
                    ent.SCP096_Scream:Stop()
                    ent.SCP096_Scream = nil
                end

                AdvancedPillSound(
                    {
                        stringe = "gentoi/scp096/calmdown.wav",
                        pitchPercent = 100,
                        volume = 0.7,
                        soundLevel = 87
                    },
                    ent
                )
                
                if ent.SCP096_Ambience then ent.SCP096_Ambience:ChangeVolume(1, 1) end

                ent:SetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever", true)
            end
            if ent:GetNWFloat("Gentoi_scp96_counter") <= 0 then
                ent:SetNWBool("Gentoi_scp96_rage_toggle_counter", false)
                ent:SetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever", false)
            end 
        end

        if ent:GetNWBool("HoldinSpace") then
            if (ent:GetNWFloat("Gentoi_scp96_counter") > 0 and ent:GetNWFloat("Bar_scp096_rage_cd") < CurTime() and not ent:GetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever")) or ent:GetNWBool("increaseShyGuy") then
                if ent.PillAnim then
                    if ent:GetNWFloat("gentoi_scp096_door_open") > CurTime() then return end
                    local startPos = ply:GetPos() + Vector(0, 0, 50)
                    local endPos = startPos + ply:GetForward() * 70

                    local tr = util.TraceLine({
                        start = startPos,
                        endpos = endPos,
                        filter = ply,
                        mask = MASK_SOLID
                    })
                    local normal = tr.HitNormal

                    if tr.Hit and IsValid(tr.Entity) then
                        local door = tr.Entity
                        if math.abs(normal.z) < 0.5 then
                            if door:GetClass() == "func_door" then
                                ent:PillAnim("ForceOpenDoor")
                                door:Fire("Open")
                                local anim = ent:GetPuppet():LookupSequence("ForceOpenDoor")
                                local dur = ent:GetPuppet():SequenceDuration(anim)*0.95
                                ent:SetNWFloat("gentoi_scp096_door_open", CurTime()+dur)
                                ply:SetNWFloat("Disable_Gentoi_The_scp96_stunned", CurTime()+dur)

                                local startpos = tr.HitPos
                                local endpos = startpos + normal
                                startpos.z = 0
                                endpos.z = 0

                                local ang = (startpos - endpos):Angle()
                                ang.p = 0
                                ang.r = 0
                                ent:SetNWAngle("pill_assignedangle",ang)

                                AdvancedPillSound(
                                    {
                                        stringe = "gentoi/scp096/dooropen.wav",
                                        pitchPercent = 100,
                                        volume = 1,
                                        soundLevel = 87
                                    },
                                    ent
                                )
                            end
                        end
                    end
                end
            else
                local startPos = ply:GetPos()+Vector(0,0,50)
                local endPos = startPos + ent:GetPuppet():GetForward() * 50
                local tr = util.TraceLine({
                    start = startPos,
                    endpos = endPos,
                    filter = ply,
                    mask = MASK_SOLID
                })

                if tr.Hit then
                    local function latching( )
                        local normal = tr.HitNormal

                        if math.abs(normal.z) < 0.5 then
                            local startpos = tr.HitPos
                            local endpos = startpos + normal
                            startpos.z = 0
                            endpos.z = 0

                            local ang = (startpos - endpos):Angle()
                            ang.p = 0
                            ang.r = 0
                            ent:SetNWAngle("pill_assignedangle",ang)
                            ent:SetNWFloat("nearwall_scp_096", CurTime()+0.25)
                            ply:SetNWFloat("Disable_Gentoi_The_scp96_stunned", CurTime()+ 0.1)
                        end
                    end

                    local hitEnt = tr.Entity
                    if IsValid(hitEnt) then
                        if hitEnt:IsPlayer() or hitEnt:IsNPC() or hitEnt:IsNextBot() then
                        else
                            latching()
                        end
                    else
                        latching()
                    end
                end

            end
        end
    end,

    noodles_gent_scp096_keybinds_deactivate = function(ply,ent,button)
        if button == KEY_SPACE then
            ent:SetNWBool("HoldinSpace",false)
        end
    end,
    noodles_gent_scp096_keybinds_activate = function(ply,ent,button)
        if button == KEY_SPACE then
            ent:SetNWBool("HoldinSpace",true)
        end
        if button == KEY_R then
            if SERVER then
                if ent:GetNWBool("Shiftlock") then
                    ent:SetNWBool("Shiftlock", false)
                else
                    ent:SetNWBool("Shiftlock", true)
                end
            end
        end
        if button == KEY_1 then
            if ent:GetNWFloat("Bar_scp096_rage_buildup") > CurTime() then return end
            if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then return end
            if ent:GetNWFloat("Bar_scp096_rage_cd") > CurTime() then return end
            if ent:GetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever") then
                ent:SetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever", false)
                ent:SetNWBool("Gentoi_scp96_rage_toggle_CanUseWhenever_forced", true)
            end
        end
    end,
    
    attack = {
        mode = 'trigger',
        func = function(ply, ent)
            if SERVER then
                if ent:GetNWFloat("Gentoi_scp96_ragedur") > CurTime() then
                    local anim = ent:GetPuppet():LookupSequence("Kill")
                    local dur = ent:GetPuppet():SequenceDuration(anim)
                    return racheljackietien_jumpscare(
                        ply,
                        ent,
                        dur,
                        function(victim)

                            AdvancedPillSound(
                                {
                                    stringe = "gentoi/scp096/096 kill.wav",
                                    pitchPercent = 100,
                                    volume = 1,
                                    soundLevel = 87
                                },
                                ent
                            )

                            ent:PillAnim('kill')
                            local entity = victim or ent.jumpscare_entity
                            if entity:LookupBone("ValveBiped.Bip01_Pelvis") then
                                local JumpscareAnimEntity = ents.Create('prop_dynamic')
                                JumpscareAnimEntity:SetModel('models/Gentoi/scp/scp096/killanim.mdl')
                                JumpscareAnimEntity:SetPos(ent:GetPuppet():GetPos()+ent:GetPuppet():GetForward()*37)
                                JumpscareAnimEntity:SetAngles(ent:GetPuppet():GetAngles())
                                JumpscareAnimEntity:SetParent(ent:GetPuppet())
                                JumpscareAnimEntity:Spawn()
                                ent:DeleteOnRemove(JumpscareAnimEntity)

                                JumpscareAnimEntity:ResetSequence('killplayer')

                                local JumpscareFakeEntity = ents.Create('prop_dynamic')
                                JumpscareFakeEntity:SetModel(entity:GetModel())
                                JumpscareFakeEntity:SetPos(ent:GetPuppet():GetPos()+ent:GetPuppet():GetForward()*37)
                                JumpscareFakeEntity:SetAngles(ent:GetPuppet():GetAngles())                                
                                JumpscareFakeEntity:SetParent(JumpscareAnimEntity)
                                JumpscareFakeEntity:AddEffects(EF_BONEMERGE)
                                JumpscareFakeEntity:Fire('SetParentAttachment','camera')
                                JumpscareFakeEntity:Spawn()
                                ent:DeleteOnRemove(JumpscareFakeEntity)
                                ent:SetNWEntity("JumpscareDeathThing_ent", JumpscareFakeEntity)
                                JumpscareFakeEntity:SetNWEntity("JumpscareDeathThing_ent_scp096", entity)

                                local oldcolor = entity:GetColor()
                        local wasHidden = entity:GetNoDraw()
                                local oldRender = entity:GetRenderMode()
                                entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
                                entity:SetColor(Color(255, 255, 255, 0))
                                entity:SetNoDraw(true)

                                ent:CallOnRemove("jumpscareend_afkeacfharcter_"..ent:EntIndex(), function()
                                    if IsValid(entity) then
                                        if IsValid(JumpscareAnimEntity) then
                                            JumpscareAnimEntity:Remove()
                                        end
                                        if IsValid(JumpscareFakeEntity) then
                                            JumpscareFakeEntity:Remove()
                                        end
                                        entity:SetNoDraw(false)
                                        entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
                                        entity:SetColor(Color(255, 255, 255, 255))
                                        entity:SetRenderMode(oldRender)
                                        entity:SetColor(oldcolor)
                                    end
                                end)

                                timer.Simple(dur,function()
                                    if !IsValid(ent) then return end
                                    ent:RemoveCallOnRemove("jumpscareend_afkeacfharcter_"..ent:EntIndex())
                                    if not IsValid(JumpscareAnimEntity) then return end
                            JumpscareAnimEntity:SetParent(NULL)
                                    ent:SetNWEntity("JumpscareDeathThing_ent", NULL)

                                    if IsValid(JumpscareAnimEntity) and IsValid(JumpscareFakeEntity) then

                                        local rag = ents.Create("prop_ragdoll")
                                        rag:SetModel(JumpscareFakeEntity:GetModel())
                                        rag:SetPos(JumpscareAnimEntity:GetPos())
                                        local anglething = JumpscareFakeEntity:GetAngles()
                                        anglething:RotateAroundAxis(JumpscareAnimEntity:GetForward(), 90)
                                        anglething:RotateAroundAxis(JumpscareAnimEntity:GetUp(), 90)
                                        rag:SetAngles(anglething)
                                        rag:Spawn()
                                        rag:SetNWInt("DrawBlackSqaure_scp096", 1e9+CurTime())

                                        JumpscareAnimEntity:Remove()
                                        JumpscareFakeEntity:Remove()
                                    end
                                end)
                        if victim then
                            return function()
                                if IsValid(victim) then
                                    victim:SetNoDraw(wasHidden)
                                    victim:SetRenderMode(oldRender)
                                    victim:SetColor(oldcolor)
                                end
                            end
                        end
                            end
                        end
                    )
                end
            end
        end
    },

    attack2 = {
        mode = "tick",
        func = function(ply, ent)
        end,
    },

    reload=function(ply,ent) end,
    flashlight = function(ply, ent) end,
    jump = function(ply, ent) end
}, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
    pk_pills.bindHNSButtons(form, "noodles_gent_scp096_keybinds_activate", {
        { id = "rage", name = "Fúria", button = KEY_1, keyLabel = "1" },
        { id = "shiftlock", name = "Travar corrida", button = KEY_R, keyLabel = "R" },
    })
end)