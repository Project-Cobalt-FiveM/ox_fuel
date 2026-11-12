---@meta

---@class OxFuelExports
local OxFuelExports = {}

---**Client.** Replaces how much money the pump thinks the player has; nil restores the default. `bridge/money/client.lua` sets it to the larger of cash and bank.
---@param fn? fun(): number
function OxFuelExports:setMoneyCheck(fn) end

---**Server.** Replaces how a fill-up is charged; nil restores the default. The function returns true when the player paid. `bridge/money/server.lua` sets it to charge cash, then bank.
---@param fn? fun(playerId: integer, price: number): boolean?
function OxFuelExports:setPaymentMethod(fn) end
