local config = require 'config'
local state = require 'client.state'
local utils = require 'client.utils'
local inventory = require 'bridge.inventory.client'
local fuel = {}

---@param vehState StateBag
---@param vehicle integer
---@param amount number
---@param replicate? boolean
function fuel.setFuel(vehState, vehicle, amount, replicate)
	if DoesEntityExist(vehicle) then
		amount = math.clamp(amount, 0, 100)

		SetVehicleFuelLevel(vehicle, amount)
		vehState.fuel = amount

		if replicate and NetworkGetEntityIsNetworked(vehicle) then TriggerServerEvent('ox_fuel:setFuel', amount) end
	end
end

---@param entity integer?
---@return { coords: vector3, model: integer }?
local function pumpClaim(entity)
	if not entity or not DoesEntityExist(entity) then return end

	return { coords = GetEntityCoords(entity), model = GetEntityModel(entity) }
end

function fuel.getPetrolCan(coords, refuel, pumpEntity)
	local pump <const> = pumpClaim(pumpEntity)

	TaskTurnPedToFaceCoord(cache.ped, coords.x, coords.y, coords.z, config.petrolCan.duration)
	Wait(500)

	if lib.progressCircle({
			duration = config.petrolCan.duration,
			useWhileDead = false,
			canCancel = true,
			disable = {
				move = true,
				car = true,
				combat = true,
			},
			anim = {
				dict = 'timetable@gardener@filling_can',
				clip = 'gar_ig_5_filling_can',
				flags = 49,
			}
		}) then
		if refuel and inventory:GetItemCount('WEAPON_PETROLCAN') > 0 then
			return TriggerServerEvent('ox_fuel:fuelCan', true, config.petrolCan.refillPrice, pump)
		end

		TriggerServerEvent('ox_fuel:fuelCan', false, config.petrolCan.price, pump)
	end

	ClearPedTasks(cache.ped)
end

function fuel.startFueling(vehicle, isPump, pumpEntity)
	local pump <const> = pumpClaim(pumpEntity)
	local vehState = Entity(vehicle).state
	local fuelAmount = vehState.fuel or GetVehicleFuelLevel(vehicle)
	local startFuel <const> = fuelAmount
	local duration = math.ceil((100 - fuelAmount) / config.refillValue) * config.refillTick
	local price, moneyAmount
	local durability = 0

	if 100 - fuelAmount < config.refillValue then
		return lib.notify({ type = 'error', description = locale('tank_full') })
	end

	if isPump then
		price = 0
		moneyAmount = utils.getMoney()

		if config.priceTick > moneyAmount then
			return lib.notify({
				type = 'error',
				description = locale('not_enough_money', config.priceTick)
			})
		end
	elseif not state.petrolCan then
		return lib.notify({ type = 'error', description = locale('petrolcan_not_equipped') })
	elseif state.petrolCan.metadata.ammo <= config.durabilityTick then
		return lib.notify({
			type = 'error',
			description = locale('petrolcan_not_enough_fuel')
		})
	end

	state.isFueling = true

	TaskTurnPedToFaceEntity(cache.ped, vehicle, duration)
	Wait(500)

	CreateThread(function()
		lib.progressCircle({
			duration = duration,
			useWhileDead = false,
			canCancel = true,
			disable = {
				move = true,
				car = true,
				combat = true,
			},
			anim = {
				dict = isPump and 'timetable@gardener@filling_can' or 'weapon@w_sp_jerrycan',
				clip = isPump and 'gar_ig_5_filling_can' or 'fire',
			},
			prop = isPump and {
				model = 'prop_cs_fuel_nozle',
				bone = 18905,
				pos = vec3(0.1, 0.02, 0.02),
				rot = vec3(90.0, 40.0, 170.0),
				rotOrder = 1,
			} or nil,
		})

		state.isFueling = false
	end)

	while state.isFueling do
		if isPump then
			price += config.priceTick

			if price + config.priceTick >= moneyAmount and lib.progressActive() then
				lib.cancelProgress()
			end
		elseif state.petrolCan then
			durability += config.durabilityTick

			if durability >= state.petrolCan.metadata.ammo then
				lib.cancelProgress()
				durability = state.petrolCan.metadata.ammo
				break
			end
		else
			break
		end

		fuelAmount += config.refillValue

		if fuelAmount >= 100 then
			state.isFueling = false
			fuelAmount = 100.0
		end

		Wait(config.refillTick)
	end

	ClearPedTasks(cache.ped)

	if isPump then
		TriggerServerEvent('ox_fuel:pay', price, fuelAmount, NetworkGetNetworkIdFromEntity(vehicle), pump, startFuel)
	else
		TriggerServerEvent('ox_fuel:updateFuelCan', durability, NetworkGetNetworkIdFromEntity(vehicle), fuelAmount, startFuel)
	end
end

return fuel
