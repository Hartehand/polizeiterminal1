DDRPT = DDRPT or {}

DDRPT.DB = DDRPT.DB or {}
local DB = DDRPT.DB

local function log(msg)
    MsgC(Color(120, 200, 255), DDRPT.Config.AddonPrefix .. " ", color_white, msg .. "\n")
end

function DB:Connect()
    local cfg = DDRPT.Config.DB
    if cfg.Adapter == "mysqloo" then
        if not mysqloo then
            log("mysqloo not found, falling back to tmysql4.")
            cfg.Adapter = "tmysql4"
        end
    end

    if cfg.Adapter == "mysqloo" then
        self.Connection = mysqloo.connect(cfg.Host, cfg.User, cfg.Pass, cfg.Database, cfg.Port)
        function self.Connection:onConnected()
            log("MySQL connected (mysqloo).")
            DDRPT.DB.Connected = true
            hook.Run("DDRPT_DB_Connected")
        end
        function self.Connection:onConnectionFailed(err)
            log("MySQL connection failed: " .. err)
            DDRPT.DB.Connected = false
        end
        self.Connection:connect()
    elseif cfg.Adapter == "tmysql4" then
        if not tmysql4 then
            log("tmysql4 not found, database disabled.")
            return
        end
        tmysql4.Initialize(cfg.Host, cfg.User, cfg.Pass, cfg.Database, cfg.Port, nil, function(db, err)
            if err then
                log("MySQL connection failed: " .. err)
                DDRPT.DB.Connected = false
                return
            end
            DDRPT.DB.Connection = db
            DDRPT.DB.Connected = true
            log("MySQL connected (tmysql4).")
            hook.Run("DDRPT_DB_Connected")
        end)
    else
        log("Unknown DB adapter: " .. tostring(cfg.Adapter))
    end
end

function DB:Escape(value)
    if self.Connection and self.Connection.escape then
        return self.Connection:escape(value)
    end
    if tmysql4 and tmysql4.Escape then
        return tmysql4.Escape(tostring(value))
    end
    return string.gsub(tostring(value), "'", "''")
end

function DB:Query(sql, callback)
    if not self.Connected then
        log("Query skipped, DB not connected.")
        if callback then
            callback(false, "not_connected")
        end
        return
    end
    local cfg = DDRPT.Config.DB
    if cfg.Adapter == "mysqloo" then
        local q = self.Connection:query(sql)
        function q:onSuccess(data)
            if callback then
                callback(true, data, self:lastInsert())
            end
        end
        function q:onError(err)
            log("Query error: " .. err .. " SQL: " .. sql)
            if callback then
                callback(false, err)
            end
        end
        q:start()
    else
        self.Connection:Query(sql, function(results)
            if results.error and results.error ~= "" then
                log("Query error: " .. results.error .. " SQL: " .. sql)
                if callback then
                    callback(false, results.error)
                end
                return
            end
            if callback then
                callback(true, results, results.lastid)
            end
        end)
    end
end

hook.Add("Initialize", "DDRPT_DB_Init", function()
    DB:Connect()
end)
