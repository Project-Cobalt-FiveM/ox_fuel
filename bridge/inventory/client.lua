local cobalt_inventory <const> = exports.cobalt_inventory

---@class FuelInventoryWeapon
---@field name string
---@field metadata { durability: number, ammo: number }

---@param weapon? { name: string, metadata: table }
---@return FuelInventoryWeapon?
local function toFuelWeapon(weapon)
	if not weapon then return end

	local durability = weapon.metadata.durability or 0

	return { name = weapon.name:upper(), metadata = { durability = durability, ammo = durability } }
end

---@class FuelInventory
local inventory <const> = {}

---@return FuelInventoryWeapon?
function inventory:getCurrentWeapon()
	return toFuelWeapon(cobalt_inventory:GetCurrentWeapon())
end

---@param name string
---@return integer
function inventory:GetItemCount(name)
	return cobalt_inventory:GetItemCount(name:lower())
end

---@param cb fun(weapon?: FuelInventoryWeapon)
function inventory:onCurrentWeapon(cb)
	AddEventHandler('cobalt_inventory:client:currentWeapon', function(weapon)
		cb(toFuelWeapon(weapon))
	end)
end

return inventory
