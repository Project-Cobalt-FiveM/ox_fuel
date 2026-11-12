local config = require 'config'

if not config then return end

if config.versionCheck then lib.versionCheck('overextended/ox_fuel') end

local ox_inventory = require 'bridge.inventory.server'
local guard = require 'bridge.guard.server'

---@param vehicle number
---@param fuel number
---@param reduceOnly? boolean Don't allow fuel to be increased, unless fuel state has not been initialised.
local function setFuelState(vehicle, fuel, reduceOnly)
	if vehicle == 0 or GetEntityType(vehicle) ~= 2 then
		return
	end

	local state = Entity(vehicle).state
	fuel = math.clamp(fuel, 0, reduceOnly and state.fuel or 100)

	state:set('fuel', fuel, true)
end

---@param playerId number
---@param price number
---@return boolean?
local function defaultPaymentMethod(playerId, price)
	local success = ox_inventory:RemoveItem(playerId, 'money', price)

	if success then return true end

	local money = ox_inventory:GetItemCount(playerId, 'money')

	lib.notify(playerId, {
		type = 'error',
		description = locale('not_enough_money', price - money)
	})
end

local payMoney = defaultPaymentMethod

exports('setPaymentMethod', function(fn)
	payMoney = fn or defaultPaymentMethod
end)

RegisterNetEvent('ox_fuel:pay', function(_, fuel, netid, pump, startFuel)
	local source = source
	local vehicle, price
	vehicle, fuel, price = guard.pumpFill(source, fuel, netid, pump, startFuel)
	if not vehicle or not payMoney(source, price) then return end

	fuel = math.floor(fuel)
	setFuelState(vehicle, fuel)

	lib.notify(source, {
		type = 'success',
		description = locale('fuel_success', fuel, price)
	})
end)

RegisterNetEvent('ox_fuel:fuelCan', function(hasCan, _, pump)
	local source = source
	if not config.petrolCan.enabled or not guard.isAtPump(source, pump) then return end

	local price = hasCan and config.petrolCan.refillPrice or config.petrolCan.price
	if hasCan then
		local item = ox_inventory:GetCurrentWeapon(source)

		if not item or item.name ~= 'WEAPON_PETROLCAN' or not payMoney(source, price) then return end

		item.metadata.durability = 100
		item.metadata.ammo = 100

		ox_inventory:SetMetadata(source, item.slot, item.metadata)

		lib.notify(source, {
			type = 'success',
			description = locale('petrolcan_refill', price)
		})
	else
		if not ox_inventory:CanCarryItem(source, 'WEAPON_PETROLCAN', 1) then
			return lib.notify(source, {
				type = 'error',
				description = locale('petrolcan_cannot_carry')
			})
		end

		if not payMoney(source, price) then return end

		ox_inventory:AddItem(source, 'WEAPON_PETROLCAN', 1)

		lib.notify(source, {
			type = 'success',
			description = locale('petrolcan_buy', price)
		})
	end
end)

RegisterNetEvent('ox_fuel:updateFuelCan', function(durability, netid, _, startFuel)
	local source = source
	local item = ox_inventory:GetCurrentWeapon(source)
	local vehicle, fuel

	if item and item.name == 'WEAPON_PETROLCAN' then
		vehicle, durability, fuel = guard.canFill(source, durability, netid, item.metadata.durability or 0, startFuel)
	end

	if vehicle then
		durability = math.floor(item.metadata.durability - durability)
		item.metadata.durability = durability
		item.metadata.ammo = durability

		ox_inventory:SetMetadata(source, item.slot, item.metadata)
		setFuelState(vehicle, fuel)
	end

	-- player is sus?
end)

RegisterNetEvent('ox_fuel:setFuel', function(fuel)
	local vehicle = guard.drivenVehicle(source, fuel)

	if vehicle then setFuelState(vehicle, fuel, true) end
end)