--[[
    RemoteEvents.lua
    Shared table of RemoteEvent / RemoteFunction names.
    All scripts require this module so names never go out of sync.
--]]

return {
    -- Fishing
    CastRod          = "CastRod",           -- Client → Server: start casting
    CancelCast       = "CancelCast",        -- Client → Server: cancel before bite
    ReelIn           = "ReelIn",            -- Client → Server: player reeled in time
    CatchResult      = "CatchResult",       -- Server → Client: catch outcome
    BiteAlert        = "BiteAlert",         -- Server → Client: fish on the line!

    -- Economy
    UpdateCoins      = "UpdateCoins",       -- Server → Client: current coin balance

    -- Inventory
    UpdateInventory  = "UpdateInventory",   -- Server → Client: full inventory table

    -- Quests
    UpdateQuests     = "UpdateQuests",      -- Server → Client: quest progress table
    QuestComplete    = "QuestComplete",     -- Server → Client: a quest was completed

    -- Rebirth
    RequestRebirth   = "RequestRebirth",    -- Client → Server
    RebirthResult    = "RebirthResult",     -- Server → Client: {Success, Level}

    -- Spin
    RequestSpin      = "RequestSpin",       -- Client → Server
    SpinResult       = "SpinResult",        -- Server → Client: reward table

    -- Shop
    PurchasePack     = "PurchasePack",      -- Client → Server: packId

    -- Stats (leaderboard)
    UpdateStats      = "UpdateStats",       -- Server → Client: full stats table
}
