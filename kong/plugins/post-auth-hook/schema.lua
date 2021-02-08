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
                        -- The consumer app names that are allowed to access the upstream associated with this plugin
                        allowed_consumer_apps = {
                            type = "array",
                            required = false,
                            elements = {
                                type = "string",
                            },
                            default = {},
                        },
                    },
                    {
                        -- The pattern to look for to decide whether to check for ACL rules or not for this consumer.
                        consumer_condition_for_acl = {
                            type = "string",
                            required = false,
                            default = "^.+$"
                        },
                    },
                },
            },
        },
    },
}