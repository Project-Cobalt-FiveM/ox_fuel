local Cobalt <const> = exports.cobalt_core:GetCoreObject()

---@return number
local function spendable()
	local money = Cobalt.Functions.GetPlayerData().money or {}

	return math.max(money.cash or 0, money.bank or 0)
end

exports.ox_fuel:setMoneyCheck(spendable)
