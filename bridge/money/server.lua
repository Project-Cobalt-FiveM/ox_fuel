local Cobalt <const> = exports.cobalt_core:GetCoreObject()

local ACCOUNTS <const> = { 'cash', 'bank' }

---@param playerId integer
---@param price number
---@return boolean
local function pay(playerId, price)
	local player = Cobalt.Functions.GetPlayer(playerId)

	if not player then return false end

	local best = 0

	for _, account in ipairs(ACCOUNTS) do
		if player.Functions.RemoveMoney(account, price, 'ox_fuel') then return true end

		best = math.max(best, player.Functions.GetMoney(account) or 0)
	end

	lib.notify(playerId, {
		type = 'error',
		description = locale('not_enough_money', price - best),
	})

	return false
end

exports.ox_fuel:setPaymentMethod(pay)
