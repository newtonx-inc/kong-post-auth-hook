local Utilities = require('kong.plugins.post-auth-hook.utilities')
local constants = require("kong.constants")

local Access = {
    config = nil,
    consumer = nil,
}

local function successfullyAuthorizedWithPlugins()
    -- Tells whether or not the request is authorized after going through all configured Kong auth plugins
    -- Returns: bool

    -- If X-Anonymous-Consumer is true AND X-Skip-Kong-Auth is NOT true, it means the request could not be authorized
    local anonymousHeader = kong.request.get_header(constants.HEADERS.ANONYMOUS)
    if anonymousHeader then
        kong.log.debug("[access.lua] : 'X-Anonymous-Consumer' is present, meaning no previous plugin could successfully auth. NOT allowing to pass.")
        return false
    end

    -- The only other state is that one of the previous auth plugins successfully authenticated.
    kong.log.debug("[[access.lua] : Successfully authd by a previous plugin. Allowing to pass.")
    return true
end

function Access:checkACL()
    -- Checks to see if the consumer is a member of the list of allowed consumers
    -- (IF conditions for the consumer are met. Otherwise, this function returns true so that this step can be skipped).
    -- Returns: bool (true if a member of any allowed entities, false otherwise) (returns true if no allowed_consumer_apps present)

    kong.log.debug("[access.lua] : Checking ACL rules")

    -- Get allowed entities
    local allowedConsumerApps = self.config.allowed_consumer_apps
    -- If no allowed entities present or empty, automatically return true
    if (not allowedConsumerApps) or (next(allowedConsumerApps) == nil) then
        kong.log.debug("[access.lua] : Plugin configuration has no allowed_consumer_apps. Skipping ACL checks.")
        return true
    end

    -- If consumer meets the condition for being checked for ACL, then check ACL rules
    if Utilities:shouldCheckConsumerACL(self.consumer, self.config.consumer_condition_for_acl) then
        return Utilities:isConsumerInAllowedConsumers(self.consumer, allowedConsumerApps)
    else
        return true
    end

    return false
end

function Access:stripUnwantedHeaders()
    -- Removes unwanted headers before sending the request to the upstream
    -- Returns: nothing

    kong.log.debug("[access.lua] : Stripping any unwanted headers")

    for _, header in ipairs(self.config.strip_headers) do
        kong.log.debug("[access.lua] : Stripping header with name: " .. header)
        kong.service.request.clear_header(header)
    end
end

function Access:new(config)
    -- Constructor
    -- :param config: The plugin config object
    self.config = config
    self.consumer = kong.client.get_consumer()
    return Access
end

function Access:start()
    -- The main function of this plugin. Runs all business logic to determine if the user
    -- Returns: nothing

    kong.log.debug("[access.lua] : Starting main function. Checking to see if request requires auth and was previously authenticated")

    -- First check if auth is required,
    -- If X-Skip-Kong-Auth is present and has a value of true, auth is not required. Skip
    if kong.request.get_header('X-Skip-Kong-Auth') then
        kong.log.debug("[access.lua] : 'X-Skip-Kong-Auth' header is true, so auth is not needed. Allowing to pass.")
        return
    end

    -- If auth is required, did one of the previous kong auth plugins (oauth2, key-auth, jwt, etc.) successfully authenticate?
    if not successfullyAuthorizedWithPlugins() then
        Utilities:exitForbidden('Access forbidden. Authentication failure: Could not authenticate with any of the available mechanisms.')
        return
    end

    -- If authenticated, check if entity membership is required, and if so, does this consumer belong to any of the allowed entities?
    if not self:checkACL() then
        Utilities:exitForbidden('Access forbidden. ACL failure: User is authenticated but does not belong to any of the allowed entities.')
        return
    end

    -- At this point, the user has been authenticated AND authorized. Now performing cleanup work.

    -- Strip unwanted headers
    self:stripUnwantedHeaders()
end

return Access