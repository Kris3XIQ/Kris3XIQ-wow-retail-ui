UltimateMouseCursor = {}
local UMC = UltimateMouseCursor 

local TrackerFrame = CreateFrame("Frame", "UMC_TrackerFrame", UIParent)
local LoaderFrame = CreateFrame("Frame")

local GCD_DURATION = 1.5
local GCD_SPELL_ID = 61304 
local _, _, _, interfaceVersion = GetBuildInfo()
local CURRENT_API = interfaceVersion
UMC.GCDCooldownFrame = nil
UMC.GCDBackgroundFrame = nil
UMC.CastFrame = nil
UMC.CastBackgroundFrame = nil
UMC.HealthFrame = nil
UMC.HealthBackgroundFrame = nil
UMC.PowerFrame = nil

UMC.currentGroupScale = 1.0 
UMC.lastGCDTime = 0 
UMC.isGCDAnimating = false 
UMC.isCasting = false
UMC.lastHealthPercent = 1.0
UMC.lastPowerPercent = 1.0

UMC.trailElements = {}
UMC.trailActive = {}
UMC.trailTimer = 0
UMC.trailLastX = 0
UMC.trailLastY = 0

UMC.lastShiftState = false
UMC.lastCtrlState = false
UMC.lastAltState = false

UMC.pingTimer = 0
UMC.isPingAnimating = false
UMC.pingDuration = 0.5
UMC.pingStartSize = 250
UMC.pingEndSize = 70

UMC.crosshairTimer = 0
UMC.isCrosshairAnimating = false
UMC.crosshairDuration = 1.5
UMC.crosshairGap = 35 -- Radius of the ring (70/2)

UMC.shakeTimer = 0
UMC.shakeCooldown = 0
UMC.shakeReversals = 0
UMC.shakeAccumDist = 0
UMC.shakeLastDirX = 0
UMC.shakeLastDirY = 0
UMC.shakeLastX = nil
UMC.shakeLastY = nil
UMC.shakeShowRingsTimer = 0

UMC.defaults = {
    scale = 1.0,
    frameStrata = "HIGH",
    positionMode = "cursor",
    positionX = 0,
    positionY = 0,
    innerRing = "GCD",
    mainRing = "Main Ring",
    outerRing = "Cast",
    usePowerColors = false,
    
    -- Color modes: "default", "class", or "custom"
    reticleColorMode = "default",
    reticleCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    mainRingColorMode = "default",
    mainRingCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    mainRingCombatColorEnabled = false,
    mainRingCombatColor = {r = 1.0, g = 0.0, b = 0.0},
    gcdColorMode = "default",
    gcdCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    castColorMode = "default",
    castCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    healthColorMode = "default",
    healthCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    healthColorLock = false,  
    trailColorMode = "default",
    trailCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    powerColorMode = "default",
    powerCustomColor = {r = 1.0, g = 1.0, b = 1.0},
    
    -- Legacy fields (kept for backwards compatibility)
    useMainRingClassColor = false,
    useGCDClassColor = false,
    useCastClassColor = false,
    useReticleClassColor = false,
    
    enableTrail = false,
    trailUseClassColor = false,
    trailDuration = 0.5,
    trailDensity = 0.005,
    trailScale = 1.0,
    trailMinMovement = 0.5,
    showOnlyInCombat = false,
    
    -- Activity Visibility
    visibilityWorld = true,
    visibilityDungeon = true,
    visibilityRaid = true,
    visibilityDelve = true,
    visibilityBattleground = true,
    visibilityArena = true,
    
    shiftAction = "None",
    ctrlAction = "None",
    altAction = "None",
    shakeAction = "None",
    reticle = "Dot",
    reticleScale = 1.5,
    transparency = 1.0,
    
    -- High Contrast Ring settings
    highContrastOuterThickness = 2,
    highContrastOuterColor = {r = 0.0, g = 0.0, b = 0.0},
    highContrastOuterColorMode = "default",
    highContrastInnerThickness = -4,
    highContrastInnerColor = {r = 1.0, g = 1.0, b = 1.0},
    highContrastInnerColorMode = "default",
    
    -- Seasonal Effect settings
    seasonalEffectStyle = "Candy Cane",
    seasonalParticleType = "Snowflakes",
    
    -- Cast/GCD Animation settings
    gcdFillDrain = "fill",               -- "drain" or "fill"
    castFillDrain = "fill",              -- "drain" or "fill"
    gcdRotation = 12,                    -- 1-12 (clock position, 12 = 12 o'clock)
    castRotation = 12,                   -- 1-12 (clock position)
    
    -- Textures
    mainRingTexture = "Main (Default)",
    gcdTexture = "Main (Default)",
    castTexture = "Main (Default)",
    hcOuterTexture = "Main (Default)",
    hcInnerTexture = "Main (Default)",
}

UMC.ringTextureOptions = {
    "Main (Default)",
    "Main (Thick)",
    "Dark",
    "Dark (Large)",
    "Glass",
    "Glass (Thick)",
    "Rune"
}

UMC.ringTextureFiles = {
    ["Main (Default)"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main",
    ["Main (Thick)"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main_Thick",
    ["Dark"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Dark",
    ["Dark (Large)"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Dark_L",
    ["Glass"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Glass",
    ["Glass (Thick)"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Glass_Thick",
    ["Rune"] = "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Rune"
}

UMC.ringOptions = {
    "None",
    "Main Ring",
    "Main Ring + GCD",
    "Main Ring + Cast",
    "Cast",
    "GCD",
    -- "Health and Power",
    -- "Health",
    -- "Power",
    "High Contrast Ring",
}

UMC.modifierOptions = {
    "None",
    "Show Rings",
    "Ping with ring",
    "Ping with area",
    "Ping with crosshair",
    "Show Crosshair",
}

UMC.shakeOptions = {
    "None",
    "Ping with ring",
    "Ping with area",
    "Ping with crosshair",
    "Show rings if hidden",
}

UMC.strataOptions = {
    "BACKGROUND",
    "LOW",
    "MEDIUM",
    "HIGH",
    "DIALOG",
    "FULLSCREEN",
    "FULLSCREEN_DIALOG",
    "TOOLTIP",
}

UMC.reticleOptions = {
    "Dot",
    "Chevron",
    "Crosshair",
    "Diamond",
    "Flatline",
    "Star",
    "Ring",
    "Tech Arrow",
    "X",
    "No Reticle",
}

UMC.reticleTextures = {
    ["Dot"] = { path = "Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Dot", scale = 0.5 },
    ["Chevron"] = { path = "uitools-icon-chevron-down", scale = 1.0, isAtlas = true },
    ["Crosshair"] = { path = "uitools-icon-plus", scale = 1.0, isAtlas = true },
    ["Diamond"] = { path = "UF-SoulShard-FX-FrameGlow", scale = 1.0, isAtlas = true },
    ["Flatline"] = { path = "uitools-icon-minus", scale = 1.0, isAtlas = true },
    ["Star"] = { path = "AftLevelup-WhiteStarBurst", scale = 2.0, isAtlas = true },
    ["Ring"] = { path = "Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Circle", scale = 1.0 },
    ["Tech Arrow"] = { path = "ProgLan-w-4", scale = 1.0, isAtlas = true }, -- Assuming Atlas for now
    ["X"] = { path = "uitools-icon-close", scale = 1.0, isAtlas = true },
    ["No Reticle"] = { path = nil, scale = 1.0 },
}

function UMC:GetClassColor(ringType)
    local colorMode = "default"
    local customColor = nil
    
    if ringType == "main" then
        colorMode = UMC_Config.mainRingColorMode or "default"
        customColor = UMC_Config.mainRingCustomColor
        
        if UMC_Config.mainRingCombatColorEnabled and (InCombatLockdown() or UMC.isPlayerInCombat) then
            colorMode = "custom"
            customColor = UMC_Config.mainRingCombatColor or {r = 1.0, g = 0.0, b = 0.0}
        end
    elseif ringType == "gcd" then
        colorMode = UMC_Config.gcdColorMode or "default"
        customColor = UMC_Config.gcdCustomColor
    elseif ringType == "cast" then
        colorMode = UMC_Config.castColorMode or "default"
        customColor = UMC_Config.castCustomColor
    elseif ringType == "reticle" then
        colorMode = UMC_Config.reticleColorMode or "default"
        customColor = UMC_Config.reticleCustomColor
    elseif ringType == "trail" then
        colorMode = UMC_Config.trailColorMode or "default"
        customColor = UMC_Config.trailCustomColor
    elseif ringType == "power" then
        colorMode = UMC_Config.powerColorMode or "default"
        customColor = UMC_Config.powerCustomColor
    end
    
    -- Return custom color if mode is custom
    if colorMode == "custom" and customColor then
        return customColor.r or 1.0, customColor.g or 1.0, customColor.b or 1.0
    end
    
    -- Return power type color if mode is "power" (special case for power ring)
    if colorMode == "power" and ringType == "power" then
        -- This will be handled by UpdatePowerRing function
        return nil, nil, nil
    end
    
    -- Return class color if mode is class
    if colorMode == "class" then
        local _, class = UnitClass("player")
        local classColor = C_ClassColor.GetClassColor(class)
        if classColor then
            return classColor.r, classColor.g, classColor.b
        end
    end

    -- Return default color
    -- Power ring default is cyan blue (original color), others are white
    if ringType == "power" then
        return 0.0, 0.5, 1.0  -- Cyan blue for power (original default)
    else
        return 1.0, 1.0, 1.0  -- White for others
    end
end

function UMC:ClockToRadians(clockPosition)
    -- Convert clock position (1-12) to radians for SetRotation
    -- 12 = 12 o'clock (top), 3 = 3 o'clock (right), 6 = 6 o'clock (bottom), 9 = 9 o'clock (left)
    -- WoW rotation: 0 radians = 12 o'clock
    local position = (clockPosition == 12) and 0 or clockPosition
    return (position * math.pi / 6) -- Each hour = 30 degrees = π/6 radians
end

function UMC:UpdateRingTextures()
    if not UMC_CursorFrame then return end
    
    local function GetTexture(name)
        return UMC.ringTextureFiles[name] or UMC.ringTextureFiles["Main (Default)"]
    end
    
    if UMC_CursorFrame.MainRing then
        UMC_CursorFrame.MainRing:SetTexture(GetTexture(UMC_Config.mainRingTexture))
    end
    
    if UMC.GCDBackgroundFrame then
        UMC.GCDBackgroundFrame:SetSwipeTexture(GetTexture(UMC_Config.gcdTexture))
    end
    if UMC.GCDCooldownFrame then
        UMC.GCDCooldownFrame:SetSwipeTexture(GetTexture(UMC_Config.gcdTexture))
    end
    
    if UMC.CastBackgroundFrame then
        UMC.CastBackgroundFrame:SetSwipeTexture(GetTexture(UMC_Config.castTexture))
    end
    if UMC.CastFrame then
        UMC.CastFrame:SetSwipeTexture(GetTexture(UMC_Config.castTexture))
    end
    
    if UMC.HighContrastRings then
        for _, ring in pairs(UMC.HighContrastRings) do
            if ring.outerHalf then
                ring.outerHalf:SetTexture(GetTexture(UMC_Config.hcOuterTexture))
            end
            if ring.innerHalf then
                ring.innerHalf:SetTexture(GetTexture(UMC_Config.hcInnerTexture))
            end
        end
    end
end

function UMC:UpdateRingColors()
    -- Check which configurations are selected
    local hasMainRingPlusGCD = false
    local hasMainRingPlusCast = false
    
    local slots = {
        {config = UMC_Config.innerRing},
        {config = UMC_Config.mainRing},
        {config = UMC_Config.outerRing},
    }
    
    for _, slot in ipairs(slots) do
        if slot.config == "Main Ring + GCD" then
            hasMainRingPlusGCD = true
        end
        if slot.config == "Main Ring + Cast" then
            hasMainRingPlusCast = true
        end
    end
    
    -- GCD: Use gray if "Main Ring + GCD" is selected without class colors
    -- GCD: Use gray if "Main Ring + GCD" is selected AND mode is "default"
    if UMC.GCDCooldownFrame then
        local gcdMode = UMC_Config.gcdColorMode or "default"
        if hasMainRingPlusGCD and gcdMode == "default" then
            -- Gray for contrast with white Main Ring
            UMC.GCDCooldownFrame:SetSwipeColor(0.4, 0.4, 0.4, 1.0)
        else
            -- Use class color (white or class color or custom)
            local r, g, b = UMC:GetClassColor("gcd")
            UMC.GCDCooldownFrame:SetSwipeColor(r, g, b, 1.0)
        end
    end

    -- Cast: Use gray if "Main Ring + Cast" is selected AND mode is "default"
    if UMC.CastFrame then
        local castMode = UMC_Config.castColorMode or "default"
        if hasMainRingPlusCast and castMode == "default" then
            -- Gray for contrast with white Main Ring
            UMC.CastFrame:SetSwipeColor(0.4, 0.4, 0.4, 1.0)
        else
            -- Use class color (white or class color or custom)
            local r, g, b = UMC:GetClassColor("cast")
            UMC.CastFrame:SetSwipeColor(r, g, b, 1.0)
        end
    end

    -- Main Ring: Always use class color (white or class color)
    if UMC_CursorFrame and UMC_CursorFrame.MainRing then
        local r, g, b = UMC:GetClassColor("main")
        UMC_CursorFrame.MainRing:SetVertexColor(r, g, b, 1.0)
    end
end

function UMC:UpdateReticle()
    if not UMC_CursorFrame or not UMC_CursorFrame.Reticle then return end
    
    local reticleName = UMC_Config.reticle or "Dot"
    local reticleInfo = UMC.reticleTextures[reticleName]
    
    if not reticleInfo or not reticleInfo.path then
        -- No Reticle or invalid
        UMC_CursorFrame.Reticle:Hide()
    else
        UMC_CursorFrame.Reticle:Show()
        
        if reticleInfo.isAtlas then
            UMC_CursorFrame.Reticle:SetAtlas(reticleInfo.path)
        else
            UMC_CursorFrame.Reticle:SetTexture(reticleInfo.path)
        end
        
        -- Apply scale
        local globalScale = UMC_Config.reticleScale or 1.0
        UMC_CursorFrame.Reticle:SetScale(reticleInfo.scale * globalScale)
        
        -- Apply color using GetClassColor
        local r, g, b = UMC:GetClassColor("reticle")
        UMC_CursorFrame.Reticle:SetVertexColor(r, g, b, 1.0)
    end
end

function UMC:SetGroupScale(scale)
    if type(scale) == "number" and scale > 0 then
        UMC.currentGroupScale = scale
        UMC_CursorFrame:SetScale(scale)
    end
end

function UMC:CreateHighContrastRing(size)
    -- Initialize High Contrast Ring frames if they don't exist
    if not UMC.HighContrastRings then
        UMC.HighContrastRings = {}
    end
    
    -- Create or reuse ring for this size
    local ringKey = "ring_" .. size
    local ring = UMC.HighContrastRings[ringKey]
    
    if not ring then
        -- Create the two-ring structure
        ring = {}
        
        -- Outer Half: Larger ring (for visibility on light backgrounds)
        local outerHalf = UMC_CursorFrame:CreateTexture(nil, "ARTWORK")
        outerHalf:SetTexture(UMC.ringTextureFiles[UMC_Config.hcOuterTexture] or "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
        outerHalf:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
        outerHalf:SetDrawLayer("ARTWORK", 1)
        ring.outerHalf = outerHalf
        
        -- Inner Half: Smaller ring (for visibility on dark backgrounds)
        local innerHalf = UMC_CursorFrame:CreateTexture(nil, "ARTWORK")
        innerHalf:SetTexture(UMC.ringTextureFiles[UMC_Config.hcInnerTexture] or "Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
        innerHalf:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
        innerHalf:SetDrawLayer("ARTWORK", 2)
        ring.innerHalf = innerHalf
        
        UMC.HighContrastRings[ringKey] = ring
    end
    
    -- Get colors based on color mode
    local function GetHighContrastColor(colorMode, customColor, defaultColor)
        if colorMode == "class" then
            local _, class = UnitClass("player")
            if class then
                local classColor = RAID_CLASS_COLORS[class]
                if classColor then
                    return classColor.r, classColor.g, classColor.b
                end
            end
        elseif colorMode == "custom" then
            return customColor.r, customColor.g, customColor.b
        end
        -- default mode
        return defaultColor.r, defaultColor.g, defaultColor.b
    end
    
    -- Apply colors and thickness from config
    local outerColorMode = UMC_Config.highContrastOuterColorMode or "default"
    local outerCustomColor = UMC_Config.highContrastOuterColor or {r = 0.0, g = 0.0, b = 0.0}
    local outerDefaultColor = {r = 0.0, g = 0.0, b = 0.0}  -- Black
    local outerThickness = UMC_Config.highContrastOuterThickness or 2
    
    local innerColorMode = UMC_Config.highContrastInnerColorMode or "default"
    local innerCustomColor = UMC_Config.highContrastInnerColor or {r = 1.0, g = 1.0, b = 1.0}
    local innerDefaultColor = {r = 1.0, g = 1.0, b = 1.0}  -- White
    local innerThickness = UMC_Config.highContrastInnerThickness or -4
    
    -- Calculate sizes
    -- Outer half is the base size plus outer thickness
    local outerSize = size + (outerThickness * 2)
    -- Inner half also grows with thickness (same direction as outer)
    local innerSize = size + (innerThickness * 2)
    
    -- Apply sizes
    ring.outerHalf:SetSize(outerSize, outerSize)
    ring.innerHalf:SetSize(innerSize, innerSize)
    
    -- Apply colors using color mode system
    local outerR, outerG, outerB = GetHighContrastColor(outerColorMode, outerCustomColor, outerDefaultColor)
    local innerR, innerG, innerB = GetHighContrastColor(innerColorMode, innerCustomColor, innerDefaultColor)
    
    ring.outerHalf:SetVertexColor(outerR, outerG, outerB, 1.0)
    ring.innerHalf:SetVertexColor(innerR, innerG, innerB, 1.0)
    
    -- Show the ring
    ring.outerHalf:Show()
    ring.innerHalf:Show()
    
    -- Hide other rings of different sizes
    for key, otherRing in pairs(UMC.HighContrastRings) do
        if key ~= ringKey then
            if otherRing.outerHalf then otherRing.outerHalf:Hide() end
            if otherRing.innerHalf then otherRing.innerHalf:Hide() end
            -- Hide old sandwich layers if they exist
            if otherRing.outerBorder then otherRing.outerBorder:Hide() end
            if otherRing.centerRing then otherRing.centerRing:Hide() end
            if otherRing.innerBorder then otherRing.innerBorder:Hide() end
        end
    end
end

function UMC:InitializeTrail()
    for i = 1, 300 do
        local texture = UIParent:CreateTexture(nil, "ARTWORK")
        texture:SetTexture("Interface\\Addons\\UltimateMouseCursor\\media\\reticle_dot")
        texture:SetBlendMode("ADD")
        texture:Hide()
        UMC.trailElements[i] = texture
    end
end

-- Seasonal Particle System
UMC.particlePool = {}
UMC.activeParticles = {}
UMC.maxParticles = 100
UMC.particleTimer = 0

function UMC:InitializeSeasonalParticles()
    -- Pre-create particle pool
    for i = 1, UMC.maxParticles do
        local particle = UIParent:CreateTexture(nil, "ARTWORK")
        particle:SetBlendMode("ADD")
        particle:Hide()
        table.insert(UMC.particlePool, particle)
    end
end

function UMC:GetParticleAtlasForStyle(style)
    -- Particle types: Snowflakes (drift down), Sparkles (burst out), Both, None
    local configs = {}
    local particleType = UMC_Config.seasonalParticleType or "Snowflakes"
    
    if particleType == "None" then
        -- No particles
        return configs
    elseif particleType == "Snowflakes" then
        -- Snowflakes: drift down gently (increased lifetime for continuity)
        table.insert(configs, {atlas = "Adventures-Buff-Heal-Burst", tint = {1.0, 1.0, 1.0}, size = 24, lifetime = 2.5, drift = true})
    elseif particleType == "Sparkles" then
        -- Sparkles: burst outward (increased lifetime for continuity)
        table.insert(configs, {atlas = "Adventures-Buff-Heal-Burst", tint = {1.0, 1.0, 1.0}, size = 20, lifetime = 1.5, burst = true})
    elseif particleType == "Both" then
        -- Both: mix of snowflakes and sparkles
        table.insert(configs, {atlas = "Adventures-Buff-Heal-Burst", tint = {1.0, 1.0, 1.0}, size = 24, lifetime = 2.5, drift = true})
        table.insert(configs, {atlas = "Adventures-Buff-Heal-Burst", tint = {1.0, 1.0, 1.0}, size = 20, lifetime = 1.5, burst = true})
    end
    
    return configs
end

function UMC:GetTrailColorForStyle(style)
    -- Returns color for trail based on style
    -- Candy Cane: alternates between red and white
    -- Christmas Lights: cycles through red, green, gold
    -- None: default white
    
    if style == "None" then
        -- Default white
        return 1.0, 1.0, 1.0
    elseif style == "Candy Cane" then
        -- Alternate between red and white
        UMC.candyCaneToggle = not UMC.candyCaneToggle
        if UMC.candyCaneToggle then
            return 1.0, 0.0, 0.0 -- Red
        else
            return 1.0, 1.0, 1.0 -- White
        end
    elseif style == "Christmas Lights" then
        -- Cycle through colors: red, green, gold, white, blue
        UMC.lightsIndex = (UMC.lightsIndex or 0) + 1
        if UMC.lightsIndex > 5 then UMC.lightsIndex = 1 end
        
        if UMC.lightsIndex == 1 then
            return 1.0, 0.0, 0.0 -- Red
        elseif UMC.lightsIndex == 2 then
            return 0.0, 1.0, 0.0 -- Green
        elseif UMC.lightsIndex == 3 then
            return 1.0, 0.84, 0.0 -- Gold
        elseif UMC.lightsIndex == 4 then
            return 1.0, 1.0, 1.0 -- White
        else
            return 0.3, 0.7, 1.0 -- Blue
        end
    end
    
    -- Default white
    return 1.0, 1.0, 1.0
end

function UMC:CreateSeasonalParticle(x, y)
    if #UMC.particlePool == 0 then return end
    if #UMC.activeParticles >= UMC.maxParticles then return end
    
    local style = UMC_Config.seasonalEffectStyle or "Candy Cane"
    local particleConfigs = UMC:GetParticleAtlasForStyle(style)
    
    -- If no particle configs (None selected), don't create particles
    if #particleConfigs == 0 then return end
    
    -- Select random particle config from available options
    local selectedConfig = particleConfigs[math.random(#particleConfigs)]
    
    local particle = table.remove(UMC.particlePool)
    table.insert(UMC.activeParticles, particle)
    
    -- Set atlas texture
    particle:SetAtlas(selectedConfig.atlas)
    
    -- Set color
    local tint = selectedConfig.tint
    particle:SetVertexColor(tint[1], tint[2], tint[3], 1.0)
    
    -- Set size with random variation
    local sizeVariation = 0.7 + (math.random() * 0.6) -- 0.7 to 1.3
    local size = selectedConfig.size * sizeVariation
    particle:SetSize(size, size)
    
    -- Position
    local uiScale = UIParent:GetEffectiveScale()
    particle.x = x / uiScale
    particle.y = y / uiScale
    particle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", particle.x, particle.y)
    
    -- Lifetime
    particle.lifetime = selectedConfig.lifetime
    particle.maxLifetime = selectedConfig.lifetime
    
    -- Movement properties
    if selectedConfig.drift then
        -- Snowflake: gentle downward drift with wobble
        particle.vx = (math.random() - 0.5) * 20 -- Horizontal wobble
        particle.vy = -30 - (math.random() * 20) -- Downward drift
        particle.rotation = math.random() * 360
        particle.rotationSpeed = (math.random() - 0.5) * 90 -- degrees per second
    elseif selectedConfig.burst then
        -- Sparkle: slight outward burst
        local angle = math.random() * math.pi * 2
        local speed = 10 + (math.random() * 20)
        particle.vx = math.cos(angle) * speed
        particle.vy = math.sin(angle) * speed
        particle.rotation = math.random() * 360
        particle.rotationSpeed = (math.random() - 0.5) * 180
    elseif selectedConfig.rotate then
        -- Candy cane: rotating in place
        particle.vx = 0
        particle.vy = -10 -- Slight downward
        particle.rotation = math.random() * 360
        particle.rotationSpeed = 180 + (math.random() * 180)
    elseif selectedConfig.pulse then
        -- Christmas lights: pulsing
        particle.vx = 0
        particle.vy = 0
        particle.rotation = 0
        particle.rotationSpeed = 0
        particle.pulsePhase = math.random() * math.pi * 2
    else
        particle.vx = 0
        particle.vy = 0
        particle.rotation = 0
        particle.rotationSpeed = 0
    end
    
    particle.config = selectedConfig
    particle:SetAlpha(1.0)
    particle:Show()
end

function UMC:UpdateSeasonalParticles(elapsed)
    -- Update existing particles
    for i = #UMC.activeParticles, 1, -1 do
        local particle = UMC.activeParticles[i]
        particle.lifetime = particle.lifetime - elapsed
        
        if particle.lifetime <= 0 then
            -- Return to pool
            particle:Hide()
            table.insert(UMC.particlePool, table.remove(UMC.activeParticles, i))
        else
            -- Update position
            particle.x = particle.x + (particle.vx * elapsed)
            particle.y = particle.y + (particle.vy * elapsed)
            particle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", particle.x, particle.y)
            
            -- Update rotation
            if particle.rotationSpeed and particle.rotationSpeed ~= 0 then
                particle.rotation = particle.rotation + (particle.rotationSpeed * elapsed)
                -- Note: WoW textures don't have SetRotation, so we'll skip actual rotation
                -- The visual variety comes from movement and fading
            end
            
            -- Update alpha (fade out)
            local progress = particle.lifetime / particle.maxLifetime
            local alpha = progress
            
            -- Pulsing effect for Christmas lights
            if particle.config.pulse then
                particle.pulsePhase = particle.pulsePhase + (elapsed * 3)
                local pulseAlpha = 0.6 + (math.sin(particle.pulsePhase) * 0.4)
                alpha = alpha * pulseAlpha
            end
            
            particle:SetAlpha(alpha)
        end
    end
end

function UMC:UpdateTrail(elapsed)
    -- Check if trail should be visible based on cursor visibility
    local shouldShowTrail = UMC_Config.enableTrail and UMC_CursorFrame and UMC_CursorFrame:IsShown()
    
    if shouldShowTrail then
        local cursorX, cursorY = GetCursorPosition()
        local uiScale = UIParent:GetEffectiveScale()

        local x = cursorX - UMC.trailLastX
        local y = cursorY - UMC.trailLastY
        local movement = math.sqrt(x * x + y * y)

        local minMovement = UMC_Config.trailMinMovement or 0.5
        local density = UMC_Config.trailDensity or 0.008

        UMC.trailTimer = UMC.trailTimer + elapsed

        if UMC.trailTimer >= density and movement >= minMovement and #UMC.trailElements > 0 then
            UMC.trailTimer = 0

            -- Check if we should use seasonal effects
            local trailColorMode = UMC_Config.trailColorMode or "default"
            
            if trailColorMode == "seasonal" then
                local style = UMC_Config.seasonalEffectStyle or "Candy Cane"
                
                -- Spawn more particles for continuous effect (3-5 instead of 1-2)
                local particleCount = math.random(3, 5)
                for i = 1, particleCount do
                    UMC:CreateSeasonalParticle(cursorX, cursorY)
                end
                
                -- Only show colored trail if style is NOT None
                if style ~= "None" then
                    local element = table.remove(UMC.trailElements)
                    table.insert(UMC.trailActive, element)

                    element.duration = UMC_Config.trailDuration or 0.4
                    element.x = cursorX / uiScale
                    element.y = cursorY / uiScale

                    -- Get color based on style
                    local r, g, b = UMC:GetTrailColorForStyle(style)

                    element:SetVertexColor(r, g, b, 1.0)
                    local baseSize = 50 * (UMC_Config.trailScale or 1.0)
                    element:SetSize(baseSize, baseSize)
                    element:SetPoint("CENTER", UIParent, "BOTTOMLEFT", element.x, element.y)
                    element:SetAlpha(0.5)  -- Start at 50% alpha so colors are more visible
                    element:Show()
                end
            else
                -- Regular trail behavior
                local element = table.remove(UMC.trailElements)
                table.insert(UMC.trailActive, element)

                element.duration = UMC_Config.trailDuration or 0.4
                element.x = cursorX / uiScale
                element.y = cursorY / uiScale

                -- Use GetClassColor for trail color
                local r, g, b = UMC:GetClassColor("trail")

                element:SetVertexColor(r, g, b, 1.0)
                local baseSize = 50 * (UMC_Config.trailScale or 1.0)
                element:SetSize(baseSize, baseSize)
                element:SetPoint("CENTER", UIParent, "BOTTOMLEFT", element.x, element.y)
                element:SetAlpha(1.0)
                element:Show()
            end

            UMC.trailLastX = cursorX
            UMC.trailLastY = cursorY
        end
        
        -- Update seasonal particles
        UMC:UpdateSeasonalParticles(elapsed)
    else
        for i = #UMC.trailActive, 1, -1 do
            local element = UMC.trailActive[i]
            element:Hide()
            table.insert(UMC.trailElements, table.remove(UMC.trailActive, i))
        end
        
        -- Hide all seasonal particles when trail is disabled
        for i = #UMC.activeParticles, 1, -1 do
            local particle = UMC.activeParticles[i]
            particle:Hide()
            table.insert(UMC.particlePool, table.remove(UMC.activeParticles, i))
        end
    end

    for i = #UMC.trailActive, 1, -1 do
        local element = UMC.trailActive[i]
        element.duration = element.duration - elapsed

        if element.duration <= 0 then
            element:Hide()
            table.insert(UMC.trailElements, table.remove(UMC.trailActive, i))
        else
            local progress = element.duration / (UMC_Config.trailDuration or 0.4)
            progress = math.min(1.0, math.max(0.0, progress))
            local baseSize = 50 * (UMC_Config.trailScale or 1.0)
            local size = math.max(5, baseSize * progress)
            element:SetSize(size, size)
            element:SetAlpha(progress)
            element:SetPoint("CENTER", UIParent, "BOTTOMLEFT", element.x, element.y)
        end
    end
end

function UMC:IsDragonriding()
    if not IsMounted() then
        local form = GetShapeshiftFormID()
        if form ~= 27 and form ~= 29 then 
            return false 
        end
    end
    
    if HasBonusActionBar() and GetActionBarPage() == 5 then
        return true
    end

    if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
        local isGliding, canGlide = C_PlayerInfo.GetGlidingInfo()
        if isGliding or canGlide then
            return true
        end
    end
    
    if IsFlying() then
        return true
    end
    
    return false
end

function UMC:OnUpdate(elapsed)
    local uiScale = UIParent:GetScale()
    local groupScale = UMC.currentGroupScale

    local isFixed = (UMC_Config.positionMode == "fixed")
    if UMC_Config.positionMode == "dragonriding" then
        isFixed = UMC:IsDragonriding()
    end

    if not isFixed then
        local cursorX, cursorY = GetCursorPosition()
        local correctedX = (cursorX / uiScale) / groupScale
        local correctedY = (cursorY / uiScale) / groupScale

        UMC_CursorFrame:ClearAllPoints()
        UMC_CursorFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", correctedX, correctedY)
        UMC.wasFixed = false
    else
        UMC_CursorFrame:ClearAllPoints()
        UMC_CursorFrame:SetPoint("CENTER", UIParent, "CENTER", (UMC_Config.positionX or 0) / UMC.currentGroupScale, (UMC_Config.positionY or 0) / UMC.currentGroupScale)
        UMC.wasFixed = true
    end

    UMC:UpdateTrail(elapsed)
    UMC:UpdateShake(elapsed)

    -- Modifier Key Logic
    local shiftDown = IsShiftKeyDown()
    local ctrlDown = IsControlKeyDown()
    local altDown = IsAltKeyDown()

    -- Check for Ping/Crosshair triggers (OnPress)
    if shiftDown and not UMC.lastShiftState then
        if UMC_Config.shiftAction == "Ping with ring" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
        elseif UMC_Config.shiftAction == "Ping with area" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Dot")
        elseif UMC_Config.shiftAction == "Ping with crosshair" then UMC:PlayCrosshairAnimation() end
    end
    if ctrlDown and not UMC.lastCtrlState then
        if UMC_Config.ctrlAction == "Ping with ring" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
        elseif UMC_Config.ctrlAction == "Ping with area" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Dot")
        elseif UMC_Config.ctrlAction == "Ping with crosshair" then UMC:PlayCrosshairAnimation() end
    end
    if altDown and not UMC.lastAltState then
        if UMC_Config.altAction == "Ping with ring" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
        elseif UMC_Config.altAction == "Ping with area" then UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Dot")
        elseif UMC_Config.altAction == "Ping with crosshair" then UMC:PlayCrosshairAnimation() end
    end

    -- Check for "Show Crosshair" (OnHold)
    local showCrosshair = (shiftDown and UMC_Config.shiftAction == "Show Crosshair") or
                          (ctrlDown and UMC_Config.ctrlAction == "Show Crosshair") or
                          (altDown and UMC_Config.altAction == "Show Crosshair")

    if showCrosshair then
        UMC.isCrosshairAnimating = false -- Stop animation if it was running
        UMC.CrosshairFrame:Show()
        UMC.CrosshairFrame:SetAlpha(1.0)
        UMC:UpdateCrosshairPosition()
    elseif (not shiftDown and UMC.lastShiftState and UMC_Config.shiftAction == "Show Crosshair") or
           (not ctrlDown and UMC.lastCtrlState and UMC_Config.ctrlAction == "Show Crosshair") or
           (not altDown and UMC.lastAltState and UMC_Config.altAction == "Show Crosshair") then
        -- Just released "Show Crosshair", trigger fade out
        UMC:PlayCrosshairAnimation()
    end

    -- Check for Visibility triggers (OnHold)
    local showRings = false
    if shiftDown and UMC_Config.shiftAction == "Show Rings" then showRings = true end
    if ctrlDown and UMC_Config.ctrlAction == "Show Rings" then showRings = true end
    if altDown and UMC_Config.altAction == "Show Rings" then showRings = true end

    if showRings then
        UMC:UpdateVisibility(true)
    elseif (not shiftDown and UMC.lastShiftState and UMC_Config.shiftAction == "Show Rings") or
           (not ctrlDown and UMC.lastCtrlState and UMC_Config.ctrlAction == "Show Rings") or
           (not altDown and UMC.lastAltState and UMC_Config.altAction == "Show Rings") then
         -- Just released a "Show Rings" key, revert to normal visibility
         UMC:UpdateVisibility()
    end

    UMC.lastShiftState = shiftDown
    UMC.lastCtrlState = ctrlDown
    UMC.lastAltState = altDown

    -- Ping Animation Update
    if UMC.isPingAnimating then
        UMC.pingTimer = UMC.pingTimer + elapsed
        if UMC.pingTimer >= UMC.pingDuration then
            UMC.isPingAnimating = false
            UMC.PingFrame:Hide()
        else
            local progress = UMC.pingTimer / UMC.pingDuration
            local size = UMC.pingStartSize - ((UMC.pingStartSize - UMC.pingEndSize) * progress)
            local alpha = 1.0 - progress
            
            UMC.PingFrame:SetSize(size, size)
            UMC.PingFrame:SetAlpha(alpha)
            UMC.PingFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER") 
        end
    end

    -- Crosshair Animation Update
    if UMC.isCrosshairAnimating then
        UMC.crosshairTimer = UMC.crosshairTimer + elapsed
        if UMC.crosshairTimer >= UMC.crosshairDuration then
            UMC.isCrosshairAnimating = false
            UMC.CrosshairFrame:Hide()
        else
            local progress = UMC.crosshairTimer / UMC.crosshairDuration
            local alpha = 1.0
            if progress > 0.7 then -- Fade out in last 30%
                alpha = 1.0 - ((progress - 0.7) / 0.3)
            end
            
            UMC.CrosshairFrame:SetAlpha(alpha)
            
            UMC:UpdateCrosshairPosition()
        end
    end
end

function UMC:UpdateCrosshairPosition()
    if not UMC.CrosshairFrame then return end
    
    local gap = UMC.crosshairGap * UMC.currentGroupScale
    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    cx = cx / scale
    cy = cy / scale
    
    -- Top Line
    UMC.CrosshairFrame.Top:ClearAllPoints()
    UMC.CrosshairFrame.Top:SetPoint("TOP", UIParent, "TOPLEFT", cx, 0)
    UMC.CrosshairFrame.Top:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", cx, cy + gap)
    
    -- Bottom Line
    UMC.CrosshairFrame.Bottom:ClearAllPoints()
    UMC.CrosshairFrame.Bottom:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", cx, 0)
    UMC.CrosshairFrame.Bottom:SetPoint("TOP", UIParent, "BOTTOMLEFT", cx, cy - gap)
    
    -- Left Line
    UMC.CrosshairFrame.Left:ClearAllPoints()
    UMC.CrosshairFrame.Left:SetPoint("LEFT", UIParent, "BOTTOMLEFT", 0, cy)
    UMC.CrosshairFrame.Left:SetPoint("RIGHT", UIParent, "BOTTOMLEFT", cx - gap, cy)
    
    -- Right Line
    UMC.CrosshairFrame.Right:ClearAllPoints()
    UMC.CrosshairFrame.Right:SetPoint("RIGHT", UIParent, "BOTTOMRIGHT", 0, cy)
    UMC.CrosshairFrame.Right:SetPoint("LEFT", UIParent, "BOTTOMLEFT", cx + gap, cy)
end

function UMC:PlayPingAnimation(texturePath)
    if not UMC.PingFrame then return end
    if texturePath then
        UMC.PingFrame:SetTexture(texturePath)
    end
    UMC.isPingAnimating = true
    UMC.pingTimer = 0
    UMC.PingFrame:SetSize(UMC.pingStartSize, UMC.pingStartSize)
    UMC.PingFrame:SetAlpha(1.0)
    UMC.PingFrame:Show()
end

function UMC:PlayCrosshairAnimation()
    if not UMC.CrosshairFrame then return end
    UMC.isCrosshairAnimating = true
    UMC.crosshairTimer = 0
    UMC.CrosshairFrame:SetAlpha(1.0)
    UMC.CrosshairFrame:Show()
end

function UMC:UpdateShake(elapsed)
    if UMC.shakeCooldown and UMC.shakeCooldown > 0 then
        UMC.shakeCooldown = UMC.shakeCooldown - elapsed
    end

    if UMC.shakeShowRingsTimer and UMC.shakeShowRingsTimer > 0 then
        UMC.shakeShowRingsTimer = UMC.shakeShowRingsTimer - elapsed
        if UMC.shakeShowRingsTimer <= 0 then
            UMC.shakeShowRingsTimer = 0
            UMC:UpdateVisibility()
        end
    end

    if not UMC_Config.shakeAction or UMC_Config.shakeAction == "None" then
        UMC.shakeReversals = 0
        UMC.shakeAccumDist = 0
        UMC.shakeTimer = 0
        UMC.shakeLastX = nil
        UMC.shakeLastY = nil
        return
    end

    if IsMouselooking and IsMouselooking() then
        UMC.shakeReversals = 0
        UMC.shakeAccumDist = 0
        UMC.shakeTimer = 0
        UMC.shakeLastX = nil
        UMC.shakeLastY = nil
        return
    end

    local cx, cy = GetCursorPosition()
    if not UMC.shakeLastX then
        UMC.shakeLastX, UMC.shakeLastY = cx, cy
        return
    end

    local dx = cx - UMC.shakeLastX
    local dy = cy - UMC.shakeLastY
    UMC.shakeLastX, UMC.shakeLastY = cx, cy

    local frameDist = math.sqrt(dx * dx + dy * dy)

    -- Ignore tiny sub-pixel jitters or micro-movements (< 8 px)
    if frameDist > 8 then
        local dirX = 0
        if math.abs(dx) > 6 then
            dirX = dx > 0 and 1 or -1
        end
        local dirY = 0
        if math.abs(dy) > 6 then
            dirY = dy > 0 and 1 or -1
        end

        local reversed = false
        if dirX ~= 0 and UMC.shakeLastDirX ~= 0 and dirX ~= UMC.shakeLastDirX then
            reversed = true
            UMC.shakeLastDirX = dirX
        elseif dirX ~= 0 then
            UMC.shakeLastDirX = dirX
        end

        if dirY ~= 0 and UMC.shakeLastDirY ~= 0 and dirY ~= UMC.shakeLastDirY then
            reversed = true
            UMC.shakeLastDirY = dirY
        elseif dirY ~= 0 then
            UMC.shakeLastDirY = dirY
        end

        if reversed then
            UMC.shakeReversals = (UMC.shakeReversals or 0) + 1
        end

        UMC.shakeAccumDist = (UMC.shakeAccumDist or 0) + frameDist
        UMC.shakeTimer = (UMC.shakeTimer or 0) + elapsed

        -- Trigger condition: At least 3 directional reversals and >= 250px accumulated distance in < 0.45s
        if (UMC.shakeReversals or 0) >= 3 and (UMC.shakeAccumDist or 0) >= 250 and (UMC.shakeCooldown or 0) <= 0 then
            UMC:TriggerShakeAction()
            UMC.shakeReversals = 0
            UMC.shakeAccumDist = 0
            UMC.shakeTimer = 0
            UMC.shakeLastDirX = 0
            UMC.shakeLastDirY = 0
            UMC.shakeCooldown = 1.0
        end
    else
        UMC.shakeTimer = (UMC.shakeTimer or 0) + elapsed
    end

    -- Reset detection window if exceeded
    if (UMC.shakeTimer or 0) > 0.45 then
        UMC.shakeReversals = 0
        UMC.shakeAccumDist = 0
        UMC.shakeTimer = 0
        UMC.shakeLastDirX = 0
        UMC.shakeLastDirY = 0
    end
end

function UMC:TriggerShakeAction()
    local action = UMC_Config.shakeAction
    if not action or action == "None" then return end

    if action == "Ping with ring" then
        UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    elseif action == "Ping with area" then
        UMC:PlayPingAnimation("Interface\\Addons\\UltimateMouseCursor\\media\\Reticle_Dot")
    elseif action == "Ping with crosshair" then
        UMC:PlayCrosshairAnimation()
    elseif action == "Show rings if hidden" then
        UMC.shakeShowRingsTimer = 2.0
        UMC:UpdateVisibility()
    end
end







function UMC:UpdateHealthRing()
    if CURRENT_API >= 120000 then return end
    local healthFrame = UMC.HealthFrame
    if not healthFrame then return end

    local currentHealth = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")

    if maxHealth == 0 then return end

    local healthPercent = currentHealth / maxHealth
    local missingHealthPercent = 1 - healthPercent

    local r, g, b
    
    -- Check if health color is locked (always use selected color)
    local healthColorLock = UMC_Config.healthColorLock or false
    
    if healthColorLock or healthPercent > 0.70 then
        -- Use configured health color when locked or when health is high
        local healthColorMode = UMC_Config.healthColorMode or "default"
        if healthColorMode == "class" then
            local _, class = UnitClass("player")
            if class then
                local classColor = RAID_CLASS_COLORS[class]
                if classColor then
                    r, g, b = classColor.r, classColor.g, classColor.b
                else
                    r, g, b = 1.0, 1.0, 1.0  -- Fallback to white
                end
            else
                r, g, b = 1.0, 1.0, 1.0  -- Fallback to white
            end
        elseif healthColorMode == "custom" then
            local customColor = UMC_Config.healthCustomColor or {r = 1.0, g = 1.0, b = 1.0}
            r, g, b = customColor.r, customColor.g, customColor.b
        else
            -- default mode
            r, g, b = 1.0, 1.0, 1.0  -- White
        end
    elseif healthPercent > 0.50 then
        r, g, b = 1.0, 0.788, 0.302
    elseif healthPercent > 0.35 then
        r, g, b = 1.0, 0.451, 0.184
    else
        r, g, b = 0.8, 0.0, 0.02
    end

    healthFrame:SetSwipeColor(r, g, b, 0.8)

    -- Clear previous cooldown state before setting new one
    healthFrame:SetCooldown(0, 0)
    healthFrame:Clear()
    local hugeDuration = 86400
    local elapsed = missingHealthPercent * hugeDuration
    healthFrame:SetCooldown(GetTime() - elapsed, hugeDuration)
    healthFrame:Show()

    UMC.lastHealthPercent = healthPercent
end

function UMC:HealthEventHandler(self, event, unit)
    if unit ~= "player" then return end

    UMC:UpdateHealthRing()
end

function UMC:UpdatePowerRing()
    if CURRENT_API >= 120000 then return end
    local powerFrame = UMC.PowerFrame
    if not powerFrame then return end

    local currentPower = UnitPower("player")
    local maxPower = UnitPowerMax("player")

    if maxPower == 0 then return end

    local powerPercent = currentPower / maxPower
    local missingPowerPercent = 1 - powerPercent

    -- Get color using GetClassColor system
    local r, g, b = UMC:GetClassColor("power")
    
    -- If GetClassColor returned nil (power mode), use power type colors
    if not r then
        local powerType, powerToken = UnitPowerType("player")
        
        if powerType == 0 then
            r, g, b = 0.00, 0.00, 1.00  -- Mana
        elseif powerType == 1 then
            r, g, b = 1.00, 0.00, 0.00  -- Rage
        elseif powerType == 2 then
            r, g, b = 1.00, 0.50, 0.25  -- Focus
        elseif powerType == 3 then
            r, g, b = 1.00, 1.00, 0.00  -- Energy
        elseif powerType == 4 then
            r, g, b = 1.00, 0.96, 0.41  -- Combo Points
        elseif powerType == 5 then
            r, g, b = 0.50, 0.50, 0.50  -- Runes
        elseif powerType == 6 then
            r, g, b = 0.00, 0.82, 1.00  -- Runic Power
        elseif powerType == 7 then
            r, g, b = 0.50, 0.32, 0.55  -- Soul Shards
        elseif powerType == 8 then
            r, g, b = 0.30, 0.52, 0.90  -- Lunar Power
        elseif powerType == 9 then
            r, g, b = 0.95, 0.90, 0.60  -- Holy Power
        elseif powerType == 11 then
            r, g, b = 0.00, 0.50, 1.00  -- Maelstrom
        elseif powerType == 13 then
            r, g, b = 0.40, 0.00, 0.80  -- Insanity
        elseif powerType == 12 then
            r, g, b = 0.71, 1.00, 0.92  -- Chi
        elseif powerType == 16 then
            r, g, b = 0.10, 0.10, 0.98  -- Arcane Charges
        elseif powerType == 17 then
            r, g, b = 0.788, 0.259, 0.992  -- Fury
        elseif powerType == 18 then
            r, g, b = 1.00, 0.61, 0.00  -- Pain
        else
            r, g, b = 0.00, 0.00, 1.00  -- Default to mana blue
        end
    end

    powerFrame:SetSwipeColor(r, g, b, 0.8)

    local hugeDuration = 86400
    local elapsed = missingPowerPercent * hugeDuration
    powerFrame:SetCooldown(GetTime() - elapsed, hugeDuration)
    powerFrame:Show()

    UMC.lastPowerPercent = powerPercent
end

function UMC:PowerEventHandler(self, event, unit)
    if unit ~= "player" then return end

    UMC:UpdatePowerRing()
end

function UMC:StartGCDAnimation(startTime, duration)
    if not UMC.GCDCooldownFrame then return end
    if not UMC.enableGCD then return end
    
    UMC.isGCDAnimating = true
    
    -- Simple fill/drain control
    local fillDrain = UMC_Config.gcdFillDrain or "drain"
    UMC.GCDCooldownFrame:SetReverse(fillDrain == "fill")
    
    UMC.GCDCooldownFrame:SetCooldown(startTime, duration)
    UMC.GCDCooldownFrame:Show()
end











function UMC:StartCastAnimation(startTime, duration)
    if not UMC.CastFrame then return end
    if not UMC.enableCast then return end
    
    UMC.isCasting = true
    
    -- Detect if this is a channel or regular cast
    local isChanneling = UnitChannelInfo("player") ~= nil
    
    -- For channels, automatically reverse the fill/drain behavior
    local fillDrain = UMC_Config.castFillDrain or "fill"
    local shouldReverse = (fillDrain == "fill")
    
    -- Invert for channels to create the opposite visual effect
    if isChanneling then
        shouldReverse = not shouldReverse
    end
    
    UMC.CastFrame:SetReverse(shouldReverse)
    
    UMC.CastFrame:SetCooldown(startTime, duration)
    UMC.CastFrame:Show()
end




function UMC:StopCastAnimation()
    if not UMC.CastFrame then return end
    
    UMC.isCasting = false
    UMC.CastFrame:Clear()
    UMC.CastFrame:Hide()
end

function UMC:GCDCastHandler(self, event, unit, spellName, spellId)
    --if CURRENT_API >= 120000 then return end
    if GetTime() - UMC.lastGCDTime < 0.1 then return end

    UMC.lastGCDTime = GetTime()

    local GCDInfo = C_Spell.GetSpellCooldown(GCD_SPELL_ID)

    if GCDInfo and GCDInfo.duration > 0 then
        UMC:StartGCDAnimation(GCDInfo.startTime, GCDInfo.duration)
    end

end

function UMC:CastEventHandler(self, event, unit) 

    local startTime, endTime, infoValid = nil, nil, false

    if event == "UNIT_SPELLCAST_START" then
        local cName, cRank, cTarget, cStartTime, cEndTime = UnitCastingInfo("player")
        startTime, endTime = cStartTime, cEndTime
        infoValid = true

    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local chName, chRank, chTarget, chStartTime, chEndTime, isMoving = UnitChannelInfo("player")
        startTime, endTime = chStartTime, chEndTime
        infoValid = true
    end

    if infoValid and startTime and endTime then
        local duration = (endTime - startTime) / 1000 

        if duration > 0.1 then 
            UMC:StartCastAnimation(startTime / 1000, duration)
        end

    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        UMC:StopCastAnimation()
    end
end

function UMC:GetCurrentActivity()
    local inInstance, instanceType = IsInInstance()
    
    if not inInstance or instanceType == "none" then
        return "world"
    elseif instanceType == "party" then
        return "dungeon"
    elseif instanceType == "raid" then
        return "raid"
    elseif instanceType == "arena" then
        return "arena"
    elseif instanceType == "pvp" then
        return "battleground"
    elseif instanceType == "scenario" then
        if (C_PartyInfo and C_PartyInfo.IsDelve and C_PartyInfo.IsDelve()) or
           (C_DelvesUI and C_DelvesUI.HasActiveDelve and C_DelvesUI.HasActiveDelve()) then
            return "delve"
        end
        local _, _, difficultyID = GetInstanceInfo()
        if difficultyID == 208 or difficultyID == 218 then
            return "delve"
        end
        return "delve"
    end
    
    -- Additional check for Delves
    if C_PartyInfo and C_PartyInfo.IsDelve and C_PartyInfo.IsDelve() then
        return "delve"
    end
    local _, _, difficultyID = GetInstanceInfo()
    if difficultyID == 208 or difficultyID == 218 then
        return "delve"
    end

    return "world"
end

function UMC:IsActivityVisible()
    local activity = UMC:GetCurrentActivity()
    if activity == "world" then
        return UMC_Config.visibilityWorld ~= false
    elseif activity == "dungeon" then
        return UMC_Config.visibilityDungeon ~= false
    elseif activity == "raid" then
        return UMC_Config.visibilityRaid ~= false
    elseif activity == "delve" then
        return UMC_Config.visibilityDelve ~= false
    elseif activity == "battleground" then
        return UMC_Config.visibilityBattleground ~= false
    elseif activity == "arena" then
        return UMC_Config.visibilityArena ~= false
    end
    return true
end

function UMC:UpdateVisibility(forceState)
    if not UMC_CursorFrame then return end

    -- Check Activity Visibility
    if not UMC:IsActivityVisible() then
        UMC_CursorFrame:Hide()
        return
    end

    -- Check Temporary Shake Show (Override)
    if UMC.shakeShowRingsTimer and UMC.shakeShowRingsTimer > 0 then
        UMC_CursorFrame:Show()
        return
    end

    -- Check Modifiers first (Override - Always Show)
    local shiftDown = IsShiftKeyDown()
    local ctrlDown = IsControlKeyDown()
    local altDown = IsAltKeyDown()
    
    local modifierShow = (shiftDown and UMC_Config.shiftAction == "Show Rings") or
                         (ctrlDown and UMC_Config.ctrlAction == "Show Rings") or
                         (altDown and UMC_Config.altAction == "Show Rings")

    if modifierShow then
        UMC_CursorFrame:Show()
        return
    end

    -- Check Combat State
    local inCombat = forceState
    if inCombat == nil then
        inCombat = InCombatLockdown()
    end

    -- Determine Base Visibility
    if UMC_Config.showOnlyInCombat then
        if inCombat then
            UMC_CursorFrame:Show()
        else
            UMC_CursorFrame:Hide()
        end
    else
        -- Show Only In Combat is FALSE (Normally Always Visible)
        -- BUT, if any key is configured to "Show Rings", we want to hide it by default
        -- so that the key press actually does something (Push-to-Show).
        
        local isAnyShowRingsConfigured = (UMC_Config.shiftAction == "Show Rings") or
                                         (UMC_Config.ctrlAction == "Show Rings") or
                                         (UMC_Config.altAction == "Show Rings")
                                         
        if isAnyShowRingsConfigured then
            UMC_CursorFrame:Hide()
        else
            UMC_CursorFrame:Show()
        end
    end
end

function UMC:ResetCooldownFrames()
    -- Stop any running animations
    UMC.isGCDAnimating = false
    UMC.isCasting = false
    UMC.gcdCompletionTime = nil
    UMC.castCompletionTime = nil
    
    -- Destroy old GCD frames
    if UMC.GCDCooldownFrame then
        UMC.GCDCooldownFrame:Hide()
        UMC.GCDCooldownFrame:SetParent(nil)
        UMC.GCDCooldownFrame = nil
    end
    if UMC.GCDBackgroundFrame then
        UMC.GCDBackgroundFrame:Hide()
        UMC.GCDBackgroundFrame:SetParent(nil)
        UMC.GCDBackgroundFrame = nil
    end
    
    -- Destroy old Cast frames
    if UMC.CastFrame then
        UMC.CastFrame:Hide()
        UMC.CastFrame:SetParent(nil)
        UMC.CastFrame = nil
    end
    if UMC.CastBackgroundFrame then
        UMC.CastBackgroundFrame:Hide()
        UMC.CastBackgroundFrame:SetParent(nil)
        UMC.CastBackgroundFrame = nil
    end
    
    local timestamp = GetTime()
    
    -- Recreate GCD Background Frame
    local gcdBgFrame = CreateFrame("Cooldown", nil, UMC_CursorFrame)
    gcdBgFrame:SetSize(70, 70)
    gcdBgFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    gcdBgFrame:SetFrameLevel(2)
    UMC.GCDBackgroundFrame = gcdBgFrame
    gcdBgFrame:SetSwipeTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    gcdBgFrame:SetSwipeColor(0.5, 0.5, 0.5, 0.7)
    gcdBgFrame:SetReverse(false)
    gcdBgFrame:SetHideCountdownNumbers(true)
    -- Set a cooldown that already finished to show as a static full circle
    gcdBgFrame:SetCooldown(GetTime() - 1, 0.01)
    gcdBgFrame:Hide()

    -- Recreate GCD Cooldown Frame
    local cooldownFrame = CreateFrame("Cooldown", nil, UMC_CursorFrame)
    cooldownFrame:SetSize(50, 50)
    cooldownFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    cooldownFrame:SetFrameLevel(3)
    UMC.GCDCooldownFrame = cooldownFrame
    cooldownFrame:SetSwipeTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    local r, g, b = UMC:GetClassColor("gcd")
    cooldownFrame:SetSwipeColor(r, g, b, 1.0) 
    cooldownFrame:SetHideCountdownNumbers(true)
    
    -- Apply rotation from clock position and direction
    local gcdRotation = UMC_Config.gcdRotation or 12
    local gcdDirection = UMC_Config.gcdDirection or "clockwise"
    local gcdFillDrain = UMC_Config.gcdFillDrain or "drain"
    cooldownFrame:SetRotation(UMC:ClockToRadians(gcdRotation, gcdDirection, gcdFillDrain))
    
    cooldownFrame:Hide()

    -- Recreate Cast Background Frame
    local castBgFrame = CreateFrame("Cooldown", nil, UMC_CursorFrame)
    castBgFrame:SetSize(70, 70)
    castBgFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    castBgFrame:SetFrameLevel(2)
    UMC.CastBackgroundFrame = castBgFrame
    castBgFrame:SetSwipeTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    castBgFrame:SetSwipeColor(0.5, 0.5, 0.5, 0.7)
    castBgFrame:SetReverse(false)
    castBgFrame:SetHideCountdownNumbers(true)
    -- Set a cooldown that already finished to show as a static full circle
    castBgFrame:SetCooldown(GetTime() - 1, 0.01)
    castBgFrame:Hide()

    -- Recreate Cast Frame
    local castFrame = CreateFrame("Cooldown", nil, UMC_CursorFrame)
    castFrame:SetSize(90, 90) 
    castFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    castFrame:SetFrameLevel(3)
    UMC.CastFrame = castFrame
    castFrame:SetSwipeTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    r, g, b = UMC:GetClassColor("cast")
    castFrame:SetSwipeColor(r, g, b, 1.0) 
    castFrame:SetHideCountdownNumbers(true)
    
    -- Apply rotation from clock position and direction
    local castRotation = UMC_Config.castRotation or 12
    local castDirection = UMC_Config.castDirection or "clockwise"
    local castFillDrain = UMC_Config.castFillDrain or "drain"
    castFrame:SetRotation(UMC:ClockToRadians(castRotation))
    
    castFrame:Hide()
    UMC:UpdateRingTextures()
    
    -- Reapply settings to ensure correct ring sizes (e.g., Main Ring + Cast)
    if UMC.ApplySettings then
        UMC:ApplySettings()
    end
end

function UMC:SetupUI()

    if UMC_CursorFrame then
        local transparency = UMC_Config.transparency or 1.0
        UMC_CursorFrame:SetAlpha(transparency)
        
        if UMC_Config.positionMode == "fixed" then
            UMC_CursorFrame:ClearAllPoints()
            -- We anchor relative to CENTER since 'Reset to Center' uses mostly 0,0 offset
            UMC_CursorFrame:SetPoint("CENTER", UIParent, "CENTER", (UMC_Config.positionX or 0) / UMC.currentGroupScale, (UMC_Config.positionY or 0) / UMC.currentGroupScale)
        end
    end
    UMC_CursorFrame:SetFrameStrata(UMC_Config.frameStrata or "HIGH")
    UMC_CursorFrame:SetToplevel(false)
    UMC_CursorFrame:Show()
    UMC:SetGroupScale(UMC.currentGroupScale)
    UMC_CursorFrame.MainRing:Show()
    
    UMC:UpdateReticle()

    local gcdBgFrame = CreateFrame("Cooldown", "UMC_GCD_BG_COOLDOWN", UMC_CursorFrame)
    gcdBgFrame:SetSize(70, 70)
    gcdBgFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    gcdBgFrame:SetFrameLevel(2)
    UMC.GCDBackgroundFrame = gcdBgFrame
    gcdBgFrame:SetSwipeTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    gcdBgFrame:SetSwipeColor(0.5, 0.5, 0.5, 0.7)
    gcdBgFrame:SetReverse(false)
    gcdBgFrame:SetHideCountdownNumbers(true)
    -- Set a cooldown that already finished to show as a static full circle
    gcdBgFrame:SetCooldown(GetTime() - 1, 0.01)
    gcdBgFrame:Hide()

    local cooldownFrame = CreateFrame("Cooldown", "UMC_GCD_COOLDOWN", UMC_CursorFrame)
    cooldownFrame:SetSize(50, 50)
    cooldownFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    cooldownFrame:SetFrameLevel(3)
    UMC.GCDCooldownFrame = cooldownFrame
    cooldownFrame:SetSwipeTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    local r, g, b = UMC:GetClassColor("gcd")
    cooldownFrame:SetSwipeColor(r, g, b, 1.0) 
    cooldownFrame:SetHideCountdownNumbers(true)
    
    -- Apply rotation from clock position and direction
    local gcdRotation = UMC_Config.gcdRotation or 12
    local gcdDirection = UMC_Config.gcdDirection or "clockwise"
    local gcdFillDrain = UMC_Config.gcdFillDrain or "drain"
    cooldownFrame:SetRotation(UMC:ClockToRadians(gcdRotation, gcdDirection, gcdFillDrain))
    
    cooldownFrame:Hide()

    local castBgFrame = CreateFrame("Cooldown", "UMC_CAST_BG_COOLDOWN", UMC_CursorFrame)
    castBgFrame:SetSize(70, 70)
    castBgFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    castBgFrame:SetFrameLevel(2)
    UMC.CastBackgroundFrame = castBgFrame
    castBgFrame:SetSwipeTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    castBgFrame:SetSwipeColor(0.5, 0.5, 0.5, 0.7)
    castBgFrame:SetReverse(false)
    castBgFrame:SetHideCountdownNumbers(true)
    -- Set a cooldown that already finished to show as a static full circle
    castBgFrame:SetCooldown(GetTime() - 1, 0.01)
    castBgFrame:Hide()

    local castFrame = CreateFrame("Cooldown", "UMC_CAST_COOLDOWN", UMC_CursorFrame)
    castFrame:SetSize(90, 90) 
    castFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    castFrame:SetFrameLevel(3)
    UMC.CastFrame = castFrame
    castFrame:SetSwipeTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    r, g, b = UMC:GetClassColor("cast")
    castFrame:SetSwipeColor(r, g, b, 1.0) 
    castFrame:SetHideCountdownNumbers(true)
    
    -- Apply rotation from clock position and direction
    local castRotation = UMC_Config.castRotation or 12
    local castDirection = UMC_Config.castDirection or "clockwise"
    local castFillDrain = UMC_Config.castFillDrain or "drain"
    castFrame:SetRotation(UMC:ClockToRadians(castRotation, castDirection, castFillDrain))
    
    castFrame:Hide()

    -- Health Background - use Texture instead of Cooldown since it's always full
    local healthBgFrame = UMC_CursorFrame:CreateTexture(nil, "ARTWORK")
    healthBgFrame:SetSize(70, 70)
    healthBgFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    healthBgFrame:SetTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    healthBgFrame:SetVertexColor(0.5, 0.5, 0.5, 0.7)
    UMC.HealthBackgroundFrame = healthBgFrame
    healthBgFrame:Hide()

    local healthFrame = CreateFrame("Cooldown", "UMC_HEALTH_COOLDOWN", UMC_CursorFrame)
    healthFrame:SetSize(70, 70)
    healthFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    healthFrame:SetFrameLevel(3)
    UMC.HealthFrame = healthFrame
    healthFrame:SetSwipeTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    healthFrame:SetSwipeColor(1.0, 0.0, 0.0, 0.8)
    healthFrame:SetReverse(false)
    healthFrame:SetHideCountdownNumbers(true)
    healthFrame:Hide()

    local powerFrame = CreateFrame("Cooldown", "UMC_POWER_COOLDOWN", UMC_CursorFrame)
    powerFrame:SetSize(80, 80)
    powerFrame:SetPoint("CENTER", UMC_CursorFrame, "CENTER")
    powerFrame:SetFrameLevel(1)
    UMC.PowerFrame = powerFrame
    powerFrame:SetSwipeTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    powerFrame:SetSwipeColor(0.0, 0.5, 1.0, 0.8)
    powerFrame:SetReverse(false)
    powerFrame:SetHideCountdownNumbers(true)
    powerFrame:SetHideCountdownNumbers(true)
    powerFrame:Hide()

    local pingFrame = UMC_CursorFrame:CreateTexture(nil, "OVERLAY")
    pingFrame:SetTexture("Interface\\Addons\\UltimateMouseCursor\\media\\Ring_Main")
    pingFrame:SetBlendMode("ADD")
    pingFrame:SetVertexColor(1.0, 1.0, 1.0, 0.5)
    pingFrame:Hide()
    UMC.PingFrame = pingFrame

    -- Crosshair Frame
    local crosshairFrame = CreateFrame("Frame", "UMC_CrosshairFrame", UIParent)
    crosshairFrame:SetFrameStrata("BACKGROUND")
    crosshairFrame:SetAllPoints()
    crosshairFrame:EnableMouse(false)
    crosshairFrame:Hide()
    UMC.CrosshairFrame = crosshairFrame

    local function CreateLine(name)
        local line = crosshairFrame:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(1, 1, 1, 0.5) -- Red, semi-transparent
        line:SetWidth(2) -- Thickness
        return line
    end

    crosshairFrame.Top = CreateLine("Top")
    crosshairFrame.Bottom = CreateLine("Bottom")
    crosshairFrame.Left = CreateLine("Left")
    crosshairFrame.Right = CreateLine("Right")
    
    -- Adjust line thickness for horizontal lines (height instead of width)
    crosshairFrame.Left:SetWidth(0) -- Reset width
    crosshairFrame.Left:SetHeight(2)
    crosshairFrame.Right:SetWidth(0)
    crosshairFrame.Right:SetHeight(2)



    UMC:UpdateHealthRing()
    UMC:UpdatePowerRing()

    UMC:InitializeTrail()
    UMC:InitializeSeasonalParticles()
    
    UMC:UpdateRingTextures()

    if UMC.ApplySettings then
        UMC:ApplySettings()
    end

    UMC.isUISetup = true
end

function UMC:OnInitialize()
    UMC.TrackerFrame = TrackerFrame

    TrackerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    TrackerFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    TrackerFrame:RegisterEvent("ZONE_CHANGED")
    TrackerFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
    TrackerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    TrackerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")


    TrackerFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            if not UMC.isUISetup and UMC_CursorFrame then
                UMC:SetupUI()
            else
                UMC:UpdateVisibility()
            end

        elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "PLAYER_DIFFICULTY_CHANGED" then
            UMC:UpdateVisibility()

        elseif event:match("UNIT_SPELLCAST_") then 
            UMC:GCDCastHandler(self, event, ...)
            UMC:CastEventHandler(self, event, ...) 

        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            UMC:HealthEventHandler(self, event, ...)

        elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" then
            UMC:PowerEventHandler(self, event, ...)

        elseif event == "PLAYER_REGEN_DISABLED" then
            UMC.isPlayerInCombat = true
            UMC:UpdateVisibility(true)
            UMC:UpdateRingColors()
        elseif event == "PLAYER_REGEN_ENABLED" then
            UMC.isPlayerInCombat = false
            UMC:UpdateVisibility(false)
            UMC:UpdateRingColors()
        end
    end)

    TrackerFrame:SetScript("OnUpdate", UMC.OnUpdate)
    TrackerFrame:Show()
    UMC:OnUpdate(0)
end

LoaderFrame:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" and addon == "UltimateMouseCursor" then
        UMC:OnInitialize()
        UMC:InitializeSettings()
        UMC:CreateSettingsPanel()
        self:UnregisterAllEvents()
    end
end)
LoaderFrame:RegisterEvent("ADDON_LOADED")
