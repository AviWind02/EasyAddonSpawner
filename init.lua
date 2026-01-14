local Language = require("Core/Language")
local Logger = require("Core/Logger")
local Event = require("Core/Event")
local JsonHelper = require("Core/JsonHelper")
local Session = require("Core/cp2077-cet-kit/GameSession")
local Cron = require("Core/cp2077-cet-kit/Cron")
local OptionConfig = require("Config/OptionConfig")
local Input = require("Core/Input")

-- Config
local BindingsConfig = require("Config/BindingsConfig")
local UIConfig = require("Config/UIConfig")
local NavigationConfig = require("Config/NavigationConfig")

local State = require("Controls/State")
local Handler = require("Controls/Handler")
local Restrictions = require("Controls/Restrictions")

local Notification = require("UI/Elements/Notification")
local InfoBox = require("UI/Elements/InfoBox")

local VehicleLoader = require("Utils/DataExtractors/VehicleLoader")



registerForEvent("onOverlayOpen", function() State.overlayOpen = true end)
registerForEvent("onOverlayClose", function() State.overlayOpen = false end)

local modulesLoaded = false
GameState = {}

local function GetStartingState()
    GameState = Session.GetState()
end

local lastState = {
    isLoaded = nil,
    isPaused = nil,
    isDead = nil,
}

local function UpdateSessionStateTick()
    local loaded = Session.IsLoaded()
    local paused = Session.IsPaused()
    local dead = Session.IsDead()
    GameState.isLoaded = loaded
    GameState.isPaused = paused
    GameState.isDead = dead
end

local function TryLoadModules()
    if Session.IsLoaded() and not modulesLoaded then
        local ok = true

        MainMenu = require("View/MainMenu")
        if not (MainMenu) then
            ok = false
        end

        if ok then
            modulesLoaded = true
            Logger.Log("Game modules initialized.")
        end
    end
end

local function OnSessionUpdate(state)
    GameState = state
    if GameState.event == "Start" and not GameState.wasLoaded then
        TryLoadModules()
    end
end


Event.RegisterInit(function()
    Logger.Initialize()
    Logger.Log("Initialization")

    Input.Initialize()

    Cron.After(0.1, GetStartingState)

    Session.Listen(OnSessionUpdate)

    Cron.Every(1.0, UpdateSessionStateTick)
    Cron.Every(0.5, TryLoadModules)

    Logger.Log("Cron Started")


    local config = JsonHelper.Read("Config/JSON/Settings.json")
    local lang = (config and config.Lang) or "en"
    if not Language.Load(lang) then
        Logger.Log("Language failed to load, fallback to English")
        Language.Load("en")
    else
        Logger.Log("Language loaded: " .. lang)
    end


    TeleportLocations.LoadAll()


    VehicleLoader:LoadAll()
    Logger.Log("DataLoaded")


    BindingsConfig.Load()
    Logger.Log("Bindings loaded")

    UIConfig.Load()
    Logger.Log("UI config loaded")

    NavigationConfig.Load()
    Logger.Log("Navigation config loaded")

    OptionConfig.Load()
    Logger.Log("Option config loaded")

    Event.Override("scannerDetailsGameController", "ShouldDisplayTwintoneTab", function(this, wrappedMethod)
        return VehicleLoader:HandleTwinToneScan(this, wrappedMethod)
    end)

    Logger.Log("Initialized")

end)
Event.RegisterUpdate(function(dt)
    Cron.Update(dt)

    if not modulesLoaded then 
        return
    end
    
    if not GameState.isLoaded or GameState.isPaused or GameState.isDead then
        return
    end


end)

Event.RegisterDraw(function()

    Notification.Render()
    if not modulesLoaded then return end
    MainMenu.Initialize()
    Handler.Update()
    if not State.menuOpen then return end

    local menuX, menuY, menuW, menuH
    ImGui.SetNextWindowSize(300, 500, ImGuiCond.FirstUseEver)

    if ImGui.Begin("EasyTrainer", ImGuiWindowFlags.NoScrollbar + ImGuiWindowFlags.NoScrollWithMouse + ImGuiWindowFlags.NoTitleBar) then
        menuX, menuY = ImGui.GetWindowPos()
        menuW, menuH = ImGui.GetWindowSize()
        MainMenu.Render(menuX, menuY, menuW, menuH)
        ImGui.End()
    end

    InfoBox.Render(menuX, menuY, menuW, menuH)
end)

Event.RegisterShutdown(function()
    if modulesLoaded then
        Restrictions.Clear()
        BindingsConfig.Save()
        OptionConfig.Save()
    end
    Logger.Log("Clean up")
end)
