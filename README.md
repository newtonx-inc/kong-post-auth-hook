# Kong PostAuth Hook
A Kong plugin for performing configurable operations after auth plugins run

**kong-post-auth-hook** performs a few customizable operations after auth plugins run, such as adding additional
useful consumer headers, stripping unwanted auth headers, and performing more fine grained ACL that is not possible
when using Kong's built in ACL plugin with custom (non Kong) auth plugins (e.g. kong-oidc-google-groups). It is
designed to be used in conjunction with the `kong-pre-auth-hook` plugin.

# What this plugin does
## Custom ACL
* Performs ACL-type authorization by ensuring the consumer belongs to one or more of the 
specified entities.
* Terminates requests associated with an anonymous consumer with a 403:Forbidden response
unless the PreAuth hook allows anonymous requests (e.g. a public endpoint).

## Strips unnecessary/undesirable headers
* Strips any intermediary headers that are generated between `kong-pre-auth-hook` and this plugin (`kong-post-auth-hook`)
* Strips any headers that are configured to be removed.

# Installation

```bash
luarocks install kong-post-auth-hook
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
| strip_headers               | {"X-Skip-Kong-Auth",} | No        | The names of headers to remove before the upstream server                                     |
| allowed_consumer_apps       | {}                    | No        | The consumer app names that are allowed to access the upstream associated with this plugin    |
| consumer_condition_for_acl  | "^.+$"                | No        | The pattern to look for to decide whether to check for ACL rules or not for this consumer.    |

## Details

### allowed_consumer_apps
This parameter should be a list of zero or more consumers that are to be authorized. Note, that this list will only be checked
if the current consumer's username matches the `consumer_condition_for_acl` regex pattern. 

### consumer_condition_for_acl
This parameter is a regex pattern, that when a match for the current consumer is found, will apply the ACL rules. Defaults 
to `^.+$`, which covers ALL potential names. You can optionally put a more restrictive pattern in. Example use case: If 
you don't want to apply the ACL rules to the consumer associated with the [kong-oidc-google-groups](https://github.com/newtonx-inc/kong-oidc-google-groups)
plugin, set the `consumer_condition_for_acl` to `^.+:oidc-google-groups$`, if your oidc consumers are named like 
`user@domain.com:oidc-google-groups`.

## Example configuration
### On the protected resource side
The following can be specified as part of the plugin (e.g. KongPlugin) configuration that will be associated with your 
upstream service or ingress.

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: my-plugin
  namespace: my-namespace
plugin: post-auth-hook
config:
    allowed_consumer_apps:
      - my-app-name
      - some-other-app
```

### On the consumer side
The following can be specified as part of the configuration of your consumer (e.g. KongConsumer) record that will be 
be associated with the plugin above. Take special note of the colon (`:`) operator within the tag strings, as this plugin
recognizes those as delimiters of key-value pairs. 

```yaml
#...
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: my-app-name
  namespace: my-namespace
  annotations:
    kubernetes.io/ingress.class: kong
username: my-app-name
custom_id: my-app-name
#...
```

# Development
## Publishing to LuaRocks
1. Update the Rockspec file name and version 
2. Update the git tag when ready for a release: `git tag v0.1-0`
3. Run `git push`
4. If authorized, follow the instructions here to upload https://github.com/luarocks/luarocks/wiki/Creating-a-rock