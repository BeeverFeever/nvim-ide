local Logger = {}

Logger.session_id = string.format("nvim-ide-log://%s-%s", "nvim-ide", vim.fn.rand())

Logger.log_level = vim.log.levels.INFO

Logger.buffer = (function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, Logger.session_id)
    return buf
end)()

Logger.set_log_level = function(level)
    if type(level) == "string" then
        -- the string versions can be:
        --      "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "OFF"
        Logger.log_level = vim.log.levels[level]
    elseif type(level) == "integer" then
        Logger.log_level = level
    end
end

function Logger.open_log()
    vim.cmd("tabnew")
    vim.api.nvim_win_set_buf(0, Logger.buffer)
end

Logger.new = function(subsys, component)
    assert(subsys ~= nil, "Cannot construct a Logger without a subsys field.")
    local self = {
        -- the subsystem for this logger instance
        subsys = subsys,
        -- the component within the subsystem producing the log.
        component = "",
    }
    if component ~= nil then
        self.component = component
    end

    local function _log(level, fmt, ...)
        if Logger.log_level >= vim.log.levels[level] then
            local arg = {...}
            local str = string.format("[%s] [%s] [%s]: ", level, self.subsys, self.component)
            if arg ~= nil then
                str = str .. string.format(fmt, unpack(arg))
            else
                str = str .. string.format(fmt)
            end
            local lines = vim.fn.split(str, "\n")
            vim.api.nvim_buf_set_lines(Logger.buffer, -1, -1, false, lines)
        end
    end

    function self.error(fmt, ...)
        _log("ERROR", fmt, ...)
    end

    function self.warning(fmt, ...)
        _log("WARN", fmt, ...)
    end

    function self.info(fmt, ...)
        _log("INFO", fmt, ...)
    end

    function self.debug(fmt, ...)
        _log("DEBUG", fmt, ...)
    end

    function self.logger_from(subsys, component)
        local cur_subsys = self.subsys
        if subsys ~= nil then
            cur_subsys = subsys
        end
        local cur_comp = self.component
        if component ~= nil then
            cur_comp = component
        end
        return Logger.new(cur_subsys, cur_comp)
    end

    return self
end

return Logger
