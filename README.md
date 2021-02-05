# Kong PostAuth Hook
A Kong plugin for performing configurable operations after auth plugins run

**kong-post-auth-hook** performs a few customizable operations after auth plugins run, such as adding additional
useful consumer headers, stripping unwanted auth headers, and performing more fine grained ACL that is not possible
when using Kong's built in ACL plugin with custom (non Kong) auth plugins (e.g. kong-oidc-google-groups). It is
designed to be used in conjunction with the `kong-pre-auth-hook` plugin.

# What this plugin does
## Custom ACL
* Performs ACL-type authorization by ensuring the consumer belongs to one or more of the 
specified groups (using the `tags` property of a consumer).
* Terminates requests associated with an anonymous consumer with a 403:Forbidden response
unless the PreAuth hook allows anonymous requests (e.g. a public endpoint).

## Appends utility headers for upstream services 
* Adds X-Groups header to specify what groups a user belongs to if applicable
* Adds X-Auth-Mechanism header to specify what auth mechanism was used

## Strips unnecessary/undesirable headers
* Strips any intermediary headers that are generated between `kong-pre-auth-hook` and this plugin (`kong-post-auth-hook`)
* Strips any headers that are configured to be removed.

# Installation

```bash
luarocks install kong-pre-auth-hook
```

Make sure you set your `KONG_PLUGINS` environment variable such that it reflects this plugin:

```bash
export KONG_PLUGINS=bundled,pre-auth-hook,post-auth-hook
```

# Requirements
* Kong auth plugins to be used in conjunction (e.g. oauth2, key-auth, jwt, etc.)
* The [kong-pre-auth-hook](https://github.com/newtonx-inc/kong-pre-auth-hook) plugin

# Dependencies (libraries)
None

# Configuration

| Parameter                   | Default               | Required? | Description                                                                                   |
|-----------------------------|-----------------------|-----------|-----------------------------------------------------------------------------------------------|
| consumer_groups_tag         | "groups"              | No        | The name of the consumer tag that describes what groups a consumer belongs to                 |
| consumer_auth_mechanism_tag | "auth_mechanism"      | No        | The name of the consumer tag that describes what auth mechanism a consumer is associated with |
| strip_headers               | {"X-Skip-Kong-Auth",} | No        | The names of headers to remove before the upstream server                                     |
| allowed_entities            |                       | No        | The group(s) that this consumer must belong to, or consumer ids that are allowed              |

## Example configuration
### On the protected resource side
The following can be specified as part of the plugin (e.g. KongPlugin) configuration that will be associated with your 
upstream service or ingress.

```yaml
config:
    consumer_groups_tag: "groups"
    consumer_auth_mechanism_tag: "auth_mechanism"
    allowed_entities:
      - my_app_name
      - group1
      - group2
```

### On the consumer side
The following can be specified as part of the configuration of your consumer (e.g. KongConsumer) record that will be 
be associated with the plugin above. Take special note of the colon (`:`) operator within the tag strings, as this plugin
recognizes those as delimiters of key-value pairs. 

```yaml
username: "my_app_name"
custom_id: "my_app_name"
tags:
    - "auth_mechanism:oauth2"
    - "groups:group1,group3,group4"
```

# Development
## Publishing to LuaRocks
1. Update the Rockspec file name and version 
2. Update the git tag when ready for a release: `git tag v0.1-0`
3. Run `git push`
4. If authorized, follow the instructions here to upload https://github.com/luarocks/luarocks/wiki/Creating-a-rock