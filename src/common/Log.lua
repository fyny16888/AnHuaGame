

-------------------------------------------------------------------
-- Public functions
-------------------------------------------------------------------

--正式包 打印e,i,w, 测试包都打印

local Log = {}

--调试信息
function Log.d( ... )
    if cc.PLATFORM_OS_DEVELOPER ~= PLATFORM_TYPE then
	    return
	end
	
    local traceback = string.split(debug.traceback("", 2), "\n")
    local logPath = "from: " .. string.trim(traceback[3])
    local tb = {...}
    local strLog = table.getTableString(tb)
    local dataInfo = string.format("%s - %s - %s","LDEBUG",os.date("%Y-%m-%d %H:%M:%S"), strLog)
	print(logPath .. "\n" .. dataInfo)
end

--错误信息
function Log.e( ... )
	local tb = {...};
    local strLog = table.getTableString(tb);
	print(string.format("%s - %s - %s","LERROR", os.date("%Y-%m-%d %H:%M:%S"), strLog));
end

--绿色信息
function Log.i( ... )
	local tb = {...};
    local strLog = table.getTableString(tb);
	print(string.format("%s - %s - %s","LINFO", os.date("%Y-%m-%d %H:%M:%S"), strLog));
end

--警告
function Log.w( ... )
	local tb = {...};
    local strLog = table.getTableString(tb);
	print(string.format("%s - %s - %s","LWARNING", os.date("%Y-%m-%d %H:%M:%S"), strLog));
end


-------------------------------------------------------------------
-- TableEx functions serialize
-------------------------------------------------------------------
local function _list_table(tb, table_list, level)
    local ret = ""
    local indent = string.rep(" ", level*4)

    for k, v in pairs(tb) do
        local quo = type(k) == "string" and "\"" or ""
        ret = ret .. indent .. "[" .. quo .. tostring(k) .. quo .. "] = "

        if type(v) == "table" then
            local t_name = table_list[v]
            if t_name then
                ret = ret .. tostring(v) .. " -- > [\"" .. t_name .. "\",]\n"
            else
                table_list[v] = tostring(k)
                ret = ret .. "{\n"
                ret = ret .. _list_table(v, table_list, level+1)
                ret = ret .. indent .. "},\n"
            end
        elseif type(v) == "string" then
            ret = ret .. "\"" .. tostring(v) .. "\",\n"
        else
            ret = ret .. tostring(v) .. ",\n"
        end
    end

    local mt = getmetatable(tb)
    if mt then 
        ret = ret .. "\n"
        local t_name = table_list[mt]
        ret = ret .. indent .. "<metatable> = "

        if t_name then
            ret = ret .. tostring(mt) .. " -- > [\"" .. t_name .. "\"]\n"
        else
            ret = ret .. "{\n"
            ret = ret .. _list_table(mt, table_list, level+1)
            ret = ret .. indent .. "}\n"
        end
        
    end

   return ret
end

local function printserialize(tb)
    if type(tb) ~= "table" then
        -- print(tb)
        return tb;
    else
        local ret = " = {\n"
        local table_list = {}
        table_list[tb] = "root table"
        ret = ret .. _list_table(tb, table_list, 1)
        ret = ret .. "}"
        -- print(ret)
        return ret;
    end
end

table.getTableString = function ( tb )
	local s = "";
	for k, v in pairs(tb or {}) do
		if type(v) == table then 
			s = s .. "\n";
		else 
			s = s .. "\t";
		end
        s = s .. tostring(printserialize(v));
	end
	return s;
end

return Log;