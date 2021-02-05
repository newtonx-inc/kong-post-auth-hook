local Access = {
    config = nil
}

local function successfullyAuthorizedWithPlugins()
    -- Tells whether or not the request is authorized after going through all configured Kong auth plugins
    -- Returns: bool

    -- TODO

    -- If X-Anonymous-Consumer is true AND X-Skip-Kong-Auth is NOT true, it means the request could not be authorized

end

local function checkACL()
    -- checks to see if the consumer is a member of an allowed group or the list of allowed consumers
    -- TODO
end

local function appendHeaders()
    -- Adds headers with useful information about the consumer and auth activity
    -- auth mechanism (if available), group membership, (if available)
    -- X-Auth-Mechanism, X-Consumer-Group-Memberships
    -- TODO - Add the X-Consumer-Group-Memberships header to the default strip list for pre-auth-hook
end

local function stripUnwantedHeaders()
    -- Removes unwanted headers before sending the request to the upstream
end

function Access:start()
    -- TODO
    -- If X-Skip-Kong-Auth is present and has a value of true, auth is not required. Skip
    -- Otherwise check if the user could be authenticated
        -- If YES, check ACL
            -- If true, proceed. If no, 403:Forbidden w/ message
                -- Append desired headers
                -- Strip unwanted headers
        -- If NO, return 403:Forbidden w/ message
    -- Else return
end

return Access