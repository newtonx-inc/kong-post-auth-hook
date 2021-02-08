local Utilities = {}

function Utilities:shouldCheckConsumerACL(consumer, condition)
    -- Checks whether the given consumer meets the condition such that ACL should be checked
    -- (based on the condition provided)
    -- :param consumer: A table representing a Kong consumer
    -- :param condition: A regex pattern to look for a match for, in the consumer's username
    -- Returns: bool

    if not consumer then
        kong.log.warn("[utilities.lua] : Null consumer provided to shouldCheckConsumerACL.")
        return false
    end

    local res = string.match(consumer.username, condition)
    if res then
        return true
    end
    return false
end

function Utilities:isConsumerInAllowedConsumers(consumer, consumerAccessList)
    -- Checks if a consumer belongs to a given access list
    -- :param consumer: A table representing a Kong consumer
    -- :param consumerAccessList: A list of consumers to check against
    -- Returns: bool
    for _, c in ipairs(consumerAccessList) do
        if c == consumer.username then
            return true
        end
    end
    return false
end

function Utilities:exitForbidden(message)
    -- Exits with a 403:Forbidden
    -- :param message: Custom message to display instead of the default
    -- Returns: nothing
    kong.response.exit(403, message or 'Access forbidden')
end

return Utilities