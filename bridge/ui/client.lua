local core <const> = exports.cobalt_core

---@param data table
function lib.notify(data)
	core:Notify(data)
end

---@param data table
---@return boolean
---@diagnostic disable-next-line: duplicate-set-field
function lib.progressCircle(data)
	return core:Progressbar(data)
end

---@return boolean
---@diagnostic disable-next-line: duplicate-set-field
function lib.progressActive()
	return core:progressActive()
end

---@diagnostic disable-next-line: duplicate-set-field
function lib.cancelProgress()
	core:cancelProgress()
end
