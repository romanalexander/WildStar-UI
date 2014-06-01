

function Apollo_BasicSerialize(o)
	if type(o) == "number" then
		return tostring(o)
	else	-- assume it is a string
		return string.format("%q", o)
	end
end

function Apollo_TableSave(name, value, saved)
	saved = saved or {}
	local str = ""
	str = name .. " = "
	if type(value) == "number" or type(value) == "string" then
		str = str .. Apollo_BasicSerialize(value) .. "\n"
	elseif type(value) == "table" then
		if saved[value] then
			str = str .. saved[value] .. "\n"
		else
			saved[value] = name
			str = str .. "{}\n"
			for k,v in pairs(value) do	-- save its fields
				k = Apollo_BasicSerialize(k)
				local fname = string.format("%s[%s]", name, k)
				str = str .. Apollo_TableSave(fname, v, saved)
			end
		end
	else
		error("cannot save a " .. type(value))
	end
	return str
end

function Apollo_SaveModuleData(c)
	local str = "local " .. Apollo_TableSave("t", c, nil) .. "Apollo_OnModuleRestored(t)\n"
	return str
end
