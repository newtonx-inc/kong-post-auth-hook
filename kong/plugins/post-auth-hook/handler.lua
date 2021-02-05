-- Extending the Base Plugin handler is optional, as there is no real
-- concept of interface in Lua, but the Base Plugin handler's methods
-- can be called from your child implementation and will print logs
-- in your `error.log` file (where all logs are printed).
local BasePlugin = require "kong.plugins.base_plugin"
local Access = require('kong.plugins.post-auth-hook.access')

local PostAuthHookHandler = BasePlugin:extend()

PostAuthHookHandler.VERSION = "0.0.0"
PostAuthHookHandler.PRIORITY = 940 -- Execute after all Kong auth plugins


-- Your plugin handler's constructor. If you are extending the
-- Base Plugin handler, it's only role is to instantiate itself
-- with a name. The name is your plugin name as it will be printed in the logs.
function PostAuthHookHandler:new()
    PostAuthHookHandler.super.new(self, "nx-kong-post-auth-hook")
end

function PostAuthHookHandler:init_worker()
    -- Eventually, execute the parent implementation
    -- (will log that your plugin is entering this context)
    PostAuthHookHandler.super.init_worker(self)
    -- Implement any custom logic here

end

function PostAuthHookHandler:access(config)
    -- Eventually, execute the parent implementation
    -- (will log that your plugin is entering this context)
    PostAuthHookHandler.super.access(self)
    -- Implement any custom logic here
    local access = Access:new(config)
    access:start()
end


-- This module needs to return the created table, so that Kong
-- can execute those functions.
return PostAuthHookHandler