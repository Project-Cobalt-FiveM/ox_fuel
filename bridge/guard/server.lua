local config <const> = require 'config'
local stations <const> = require 'data.stations'

local PUMP_RANGE <const> = 5.0
local VEHICLE_RANGE <const> = 15.0
local TICK_EPSILON <const> = 0.001

---@class FuelPumpClaim
---@field coords vector3
---@field model integer

---@type vector3[]
local pumps <const> = {}

---@type table<integer, true>
local pumpModels <const> = {}

for i = 1, #config.pumpModels do
	pumpModels[config.pumpModels[i] & 0xFFFFFFFF] = true
end

for _, stationPumps in pairs(stations) do
	for i = 1, #stationPumps do
		pumps[#pumps + 1] = stationPumps[i]
	end
end

---@param value unknown
---@return boolean
local function isFinite(value)
	return type(value) == 'number' and value == value and value > -math.huge and value < math.huge
end

---@param source integer
---@return vector3
local function playerCoords(source)
	return GetEntityCoords(GetPlayerPed(source))
end

---@param source integer
---@param key string
local function refuse(source, key)
	lib.notify(source, { type = 'error', description = locale(key) })
end

---@param source integer
---@param netid unknown
---@return integer?
local function nearbyVehicle(source, netid)
	local vehicle <const> = math.type(netid) == 'integer' and NetworkGetEntityFromNetworkId(netid) or 0

	if vehicle == 0 or GetEntityType(vehicle) ~= 2 then return refuse(source, 'vehicle_far') end
	if #(playerCoords(source) - GetEntityCoords(vehicle)) > VEHICLE_RANGE then return refuse(source, 'vehicle_far') end

	return vehicle
end

---@param vehicle integer
---@param reported unknown
---@return number?
local function fuelLevel(vehicle, reported)
	local state <const> = Entity(vehicle).state

	if state.fuel then return state.fuel end
	if not isFinite(reported) then return end

	local level <const> = math.clamp(reported, 0, 100)

	state:set('fuel', level, true)

	return level
end

---@param coords vector3
---@param pump FuelPumpClaim | unknown
---@return boolean
local function isClaimedPumpNear(coords, pump)
	if type(pump) ~= 'table' then return false end
	if type(pump.coords) ~= 'vector3' or math.type(pump.model) ~= 'integer' then return false end

	return pumpModels[pump.model & 0xFFFFFFFF] == true and #(coords - pump.coords) <= PUMP_RANGE
end

---@class FuelGuard
local guard <const> = {}

---@param source integer
---@param pump FuelPumpClaim | unknown
---@return boolean
function guard.isAtPump(source, pump)
	local coords <const> = playerCoords(source)

	if isClaimedPumpNear(coords, pump) then return true end

	for i = 1, #pumps do
		if #(coords - pumps[i]) <= PUMP_RANGE then return true end
	end

	refuse(source, 'pump_far')

	return false
end

---@param source integer
---@param fuel unknown
---@param netid unknown
---@param pump FuelPumpClaim | unknown
---@param startFuel unknown
---@return integer? vehicle
---@return number? fuel
---@return integer? price
function guard.pumpFill(source, fuel, netid, pump, startFuel)
	if not isFinite(fuel) or not guard.isAtPump(source, pump) then return end

	local vehicle <const> = nearbyVehicle(source, netid)
	local current <const> = vehicle and fuelLevel(vehicle, startFuel)

	if not current then return end

	local target <const> = math.min(fuel, 100)
	local ticks <const> = math.ceil((target - current) / config.refillValue - TICK_EPSILON)

	if ticks < 1 then return refuse(source, 'tank_full') end

	return vehicle, target, ticks * config.priceTick
end

---@param source integer
---@param used unknown
---@param netid unknown
---@param canDurability number
---@param startFuel unknown
---@return integer? vehicle
---@return number? used
---@return number? fuel
function guard.canFill(source, used, netid, canDurability, startFuel)
	if not isFinite(used) or used <= 0 then return end

	local vehicle <const> = nearbyVehicle(source, netid)
	local current <const> = vehicle and fuelLevel(vehicle, startFuel)

	if not current then return end

	local spent <const> = math.min(used, canDurability)
	local added <const> = math.floor(spent / config.durabilityTick + TICK_EPSILON) * config.refillValue

	return vehicle, spent, math.min(current + added, 100)
end

---@param source integer
---@param fuel unknown
---@return integer?
function guard.drivenVehicle(source, fuel)
	if not isFinite(fuel) then return end

	local ped <const> = GetPlayerPed(source)
	local vehicle <const> = GetVehiclePedIsIn(ped, false)

	if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then return end

	return vehicle
end

return guard
