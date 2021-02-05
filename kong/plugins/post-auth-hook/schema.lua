local typedefs = require('kong.db.schema.typedefs')

return {
    name = 'kong-post-auth-hook',
    fields = {
        {
            protocols = typedefs.protocols_http
        },
        {

            config = {
                type = 'record',
                fields = {
                    -- Describe your plugin's configuration's schema here.
                    {
                        -- The name of the consumer tag that describes what groups a consumer belongs to
                        consumer_groups_tag = {
                            type = "string",
                            required = false,
                            default = "groups"
                        },
                    },
                    {
                        -- The name of the consumer tag that describes what auth mechanism a consumer is associated with
                        consumer_auth_mechanism_tag = {
                            type = "string",
                            required = false,
                            default = "auth_mechanism"
                        },
                    },
                    {
                        -- The names of headers to remove before the upstream server
                        strip_headers = {
                            type = "array",
                            required = false,
                            elements = {
                                type = "string",
                            },
                            default = {
                                "X-Skip-Kong-Auth",
                            },
                        },
                    },
                    {
                        -- The group(s) that this consumer must belong to, or consumer ids that are allowed
                        allowed_entities = {
                            type = "array",
                            required = false,
                            elements = {
                                type = "string",
                            },
                            default = {},
                        },
                    },
                },
            },
        },
    },
}