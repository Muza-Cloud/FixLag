-- | Made By m7za | --

if getgenv().M7ZA_LoaderRan then return end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local games = {
    [10449761463] = "https://raw.githubusercontent.com/m7za/fixlag/main/tsbg.lua",
    [15269951959] = "https://raw.githubusercontent.com/m7za/fixlag/main/lbg.lua"
}

local url = games[game.PlaceId]

if url then
    getgenv().M7ZA_LoaderRan = true
    loadstring(game:HttpGet(url))()
end