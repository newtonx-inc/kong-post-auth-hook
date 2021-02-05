local Utilities = require('kong.plugins.post-auth-hook.utilities')

local Access = {
    config = nil,
    consumer = nil,
}

local function successfullyAuthorizedWithPlugins()
    -- Tells whether or not the request is authorized after going through all configured Kong auth plugins
    -- Returns: bool

    -- If X-Anonymous-Consumer is true AND X-Skip-Kong-Auth is NOT true, it means the request could not be authorized
    -- TODO - use a constant name for the header
    local anonymousHeader = kong.request.get_header('X-Anonymous-Consumer')
    if anonymousHeader then
        kong.log.debug("[access.lua] : 'X-Anonymous-Consumer' is present, meaning no previous plugin could successfully auth. NOT allowing to pass.")
        return false
    end

    -- The only other state is that one of the previous auth plugins successfully authenticated.
    kong.log.debug("[[access.lua] : Successfully authd by a previous plugin. Allowing to pass.")
    return true
end

function Access:checkACL()
    -- Checks to see if the consumer is a member of an allowed group or the list of allowed consumers
    -- Returns: bool (true if a member of any allowed entities, false otherwise) (returns true if no allowed_entities present)

    -- Get allowed entities
    local allowedEntities = self.config.allowed_entities
    -- If no allowed entities automatically return true
    if not allowedEntities then
        return true
    end

    -- Registered entities
    -- Get consumer name and group(s) it belongs to
    -- Start by assigning the consumer username as the first element of the entities that a consumer belongs to
    local registeredEntities = {consumer.username}
    if self.config.consumer_groups_tag then
        local groupMemberships = Utilities.getGroupsFromConsumerTags(self.consumer.tags, self.config.consumer_groups_tag)
        for _, gm in ipairs(groupMemberships) do
            table.insert(registeredEntities, gm)
        end
    end

    -- Finally, check to see if any of the registered entities match any of the allowed entities.
    for _, re in ipairs(registeredEntities) do
        for _, ae in ipairs(allowedEntities) do
            if ae == re then
                return true
            end
        end
    end

    return false
end

function Access:appendHeaders()
    -- Adds headers with useful information about the consumer and auth activity
    -- Returns: nothing

    kong.log.debug("[access.lua] : Appending desired and utility headers")

    -- Get consumer and tags (If available. If not, skip this function)
    if not self.consumer then
        return
    end
    local tags = self.consumer.tags

    -- Auth mechanism (if available) ("X-Auth-Mechanism")
    if self.config.consumer_auth_mechanism_tag then
        local authMechanism = Utilities:getAuthMechanismFromConsumerTags(tags, self.config.consumer_auth_mechanism_tag)
        if authMechanism then
            kong.service.request.set_header('X-Auth-Mechanism', authMechanism)
        end
    end

    -- Group membership (if available) ("X-Consumer-Group-Memberships")
    if self.config.consumer_groups_tag then
        local groupMemberships = Utilities.getGroupsFromConsumerTags(tags, self.config.consumer_groups_tag)
        local groupStr = table.concat(groupMemberships, ',')
        if groupStr == '' then
            kong.log.debug("[access.lua] : No groups found. Will not update header: 'X-Consumer-Group-Memberships'")
        else
            kong.service.request.set_header('X-Consumer-Group-Memberships', groupStr)
        end
    end
end

function Access:stripUnwantedHeaders()
    -- Removes unwanted headers before sending the request to the upstream
    -- Returns: nothing

    kong.log.debug("[access.lua] : Stripping any unwanted headers")

    for _, header in ipairs(self.config.strip_headers) do
        kong.log.debug("[access.lua] : Stripping header with name: " .. header)
        kong.request.service.request.clear_header(header)
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
    if not self.checkACL() then
        Utilities:exitForbidden('Access forbidden. ACL failure: User is authenticated but does not belong to any of the allowed entities.')
        return
    end

    -- At this point, the user has been authenticated AND authorized. Now performing cleanup work.

    -- Strip unwanted headers
    self.stripUnwantedHeaders()

    -- Append desired headers
    self.appendHeaders()
end

return Access