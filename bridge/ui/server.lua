local core <const> = exports.cobalt_core

---@param playerId integer
---@param data table
function lib.notify(playerId, data)
	core:Notify(playerId, data)
end
