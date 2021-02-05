local Utilities = {}

local function splitStr(inputStr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputStr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

local function findMatchingTag(tags, key)
    -- Finds matching tag in a list of tags by key
    -- :param tags: The value of the tags property of a consumer
    -- :param key: The key representing groups to search for within tags (see README)
    -- Returns: string representing the matching tag, or nil
    for _, t in ipairs(tags) do
        -- Check if the tag contains the key prefix (e.g. "groups:group1,group2")
        if not string.find(t, "^" .. key .. ":") then
            break
        end
        return splitStr(t, ":")[2]
    end
    return nil
end

function Utilities:getGroupsFromConsumerTags(tags, key)
    -- Fetches any groups that the consumer claims to belong to via tags
    -- :param tags: The value of the tags property of a consumer
    -- :param key: The key representing groups to search for within tags (see README)
    -- Returns: table array of group names

    local groupsStr = findMatchingTag(tags, key)
    if not groupsStr then
        return {}
    end
    return splitStr(groupsStr, ",")
end

function Utilities:getAuthMechanismFromConsumerTags(tags, key)
    -- Fetches any groups that the consumer claims to belong to via tags
    -- :param tags: The value of the tags property of a consumer
    -- :param key: The key representing groups to search for within tags (see README)
    -- Returns: string representing the auth mechanism or nil
    return findMatchingTag(tags, key)
end

function Utilities:exitForbidden(message)
    -- Exits with a 403:Forbidden
    -- :param message: Custom message to display instead of the default
    -- Returns: nothing
    kong.response.exit(403, message or 'Access forbidden')
end

return Utilities