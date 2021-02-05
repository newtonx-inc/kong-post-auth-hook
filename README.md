# Kong PostAuth Hook
TBD

# Brainstorm
* Performs ACL-type authorization by ensuring the consumer belongs to one or more of the 
specified groups (using the `tags` property of a consumer).
* Terminates requests associated with an anonymous consumer with a 403:Forbidden response
unless the PreAuth hook allows anonymous requests (e.g. a public endpoint). 
* Adds X-Groups header to specify what groups a user belongs to if applicable
* Adds X-Auth-Mechanism header to specify what auth mechanism was used

# Notes
Talk about tag keys