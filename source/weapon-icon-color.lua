script_name("WIC")

local ffi = require("ffi")
local memory = require("memory")
local imgui = require("mimgui")
local jsoncfg = require("jsoncfg")
local hook = require("monethook")
local base = MONET_GTASA_BASE

local gta = ffi.load("GTASA")
ffi.cdef[[
    void _ZN7CSprite18RenderOneXLUSpriteEfffffhhhsfhhhff(float ScreenX, float ScreenY, float ScreenZ, float SizeX, float SizeY, uint8_t R, uint8_t G, uint8_t B, int16_t Intensity16, float RecipZ, uint8_t Alpha, uint8_t FlipU, uint8_t FlipV, float uvPad1, float uvPad2);
]]

local defaultConfig = { R = 255, G = 255, B = 255, RgbMode = false, RgbSpeed = 2.0 }
local config = jsoncfg.load(defaultConfig, "WeaponIconColor", ".json")

local SW, SH = getScreenResolution()
local show_menu = imgui.new.bool(false)
local icon_color = imgui.new.float[4](config.R / 255, config.G / 255, config.B / 255, 1.0)
local rgb_mode = imgui.new.bool(config.RgbMode)
local rgb_speed = imgui.new.float(config.RgbSpeed)

local addr_r = base + 0x2BDBDE
local addr_g = base + 0x2BDBE0
local addr_b = base + 0x2BDBE2

local function applyColor(r, g, b)
    memory.setuint8(addr_r, r, true)
    memory.setuint8(addr_g, g, true)
    memory.setuint8(addr_b, b, true)
    config.R = r
    config.G = g
    config.B = b
end

local function saveConfig()
    config.R = math.floor(icon_color[0] * 255)
    config.G = math.floor(icon_color[1] * 255)
    config.B = math.floor(icon_color[2] * 255)
    config.RgbMode = rgb_mode[0]
    config.RgbSpeed = rgb_speed[0]
    applyColor(config.R, config.G, config.B)
    jsoncfg.save(config, "WeaponIconColor", ".json")
end

local renderSpriteHook
renderSpriteHook = hook.new(
    "void(*)(float, float, float, float, float, uint8_t, uint8_t, uint8_t, int16_t, float, uint8_t, uint8_t, uint8_t, float, float)",
    function(sx, sy, sz, sizex, sizey, r, g, b, intensity, recipz, alpha, flipu, flipv, uv1, uv2)
        r = config.R
        g = config.G
        b = config.B
        renderSpriteHook(sx, sy, sz, sizex, sizey, r, g, b, intensity, recipz, alpha, flipu, flipv, uv1, uv2)
    end,
    ffi.cast("uintptr_t", ffi.cast("void*", gta._ZN7CSprite18RenderOneXLUSpriteEfffffhhhsfhhhff))
)

imgui.OnFrame(
    function() return show_menu[0] end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(SW / 2, SH / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin("Weapon Icon Color", show_menu, imgui.WindowFlags.NoCollapse)

        if imgui.Checkbox("RGB Mode", rgb_mode) then saveConfig() end

        if rgb_mode[0] then
            imgui.PushItemWidth(imgui.GetContentRegionAvail().x)
            if imgui.SliderFloat("##speed", rgb_speed, 0.5, 10.0, "Speed: %.1f") then saveConfig() end
            imgui.PopItemWidth()
        else
            imgui.PushItemWidth(imgui.GetContentRegionAvail().x)
            if imgui.ColorEdit3("##color", icon_color) then saveConfig() end
            imgui.PopItemWidth()
        end

        imgui.End()
    end
)

function main()
    wait(0)
    applyColor(config.R, config.G, config.B)
    sampRegisterChatCommand("wic", function()
        show_menu[0] = not show_menu[0]
    end)
    while true do
        if rgb_mode[0] then
            local t = os.clock() * rgb_speed[0]
            local r = math.floor(((math.sin(t)          + 1) / 2) * 255)
            local g = math.floor(((math.sin(t + 2.0944) + 1) / 2) * 255)
            local b = math.floor(((math.sin(t + 4.1888) + 1) / 2) * 255)
            applyColor(r, g, b)
        end
        wait(0)
    end
end
