local cobalt_inventory <const> = exports.cobalt_inventory
local ox_inventory <const> = exports.ox_inventory

---@class FuelInventorySlot
---@field invName string
---@field itemId string

---@class FuelServerWeapon
---@field name string
---@field slot FuelInventorySlot
---@field metadata table

---@class FuelInventory
local inventory <const> = {}

---@param source integer
---@return FuelServerWeapon?
function inventory:GetCurrentWeapon(source)
	local weapon = cobalt_inventory:GetCurrentWeapon(source)

	if not weapon then return end

	return {
		name = weapon.name:upper(),
		slot = { invName = weapon.invName, itemId = weapon.itemId },
		metadata = weapon.metadata,
	}
end

---@param _ integer
---@param slot FuelInventorySlot
---@param metadata table
---@return boolean
function inventory:SetMetadata(_, slot, metadata)
	return cobalt_inventory:SetFullMetadata(slot.invName, slot.itemId, metadata)
end

---@param source integer
---@param name string
---@param count integer
---@return boolean
function inventory:CanCarryItem(source, name, count)
	return cobalt_inventory:CanCarry(source, name:lower(), count)
end

---@param source integer
---@param name string
---@param count integer
---@return boolean
function inventory:AddItem(source, name, count)
	return cobalt_inventory:AddItem(source, name:lower(), count, { durability = 100, ammo = 100 }, nil, 'ox_fuel')
end

---@param source integer
---@param name string
---@param count integer
---@return boolean
function inventory:RemoveItem(source, name, count)
	return ox_inventory:RemoveItem(source, name, count)
end

---@param source integer
---@param name string
---@return integer
function inventory:GetItemCount(source, name)
	return ox_inventory:GetItemCount(source, name) or 0
end

return inventory
