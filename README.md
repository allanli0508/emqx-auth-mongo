
emqttd_auth_mongo
=================

Authentication with MongoDB

Build the Plugin
----------------

```
make & make tests
```

Configuration
-------------

File: etc/emqttd_auth_mongo.conf

```erlang
{mongo_pool, [
  {pool_size, 8},
  {auto_reconnect, 3},

  %% Mongodb Opts
  {host, "localhost"},
  {port, 27017},
  %% {login, ""},
  %% {password, ""},
  {database, "mqtt"}
]}.

%% Variables: %u = username, %c = clientid

%% Superuser Query
{superquery, pool, [
  {collection, "mqtt_user"},
  {super_field, "is_superuser"},
  {selector, {"username", "%u"}}
]}.

%% Authentication Query
{authquery, pool, [
  {collection, "mqtt_user"},
  {password_field, "password"},
  %% Hash Algorithm: plain, md5, sha, sha256, pbkdf2?
  {password_hash, sha256},
  {selector, {"username", "%u"}}
]}.

%% ACL Query: "%u" = username, "%c" = clientid
{aclquery, pool, [
  {collection, "mqtt_acl"},
  {selector, {"username", "%u"}}
]}.

%% If no ACL rules matched, return...
{acl_nomatch, deny}.
```

Load the Plugin
---------------

```
./bin/emqttd_ctl plugins load emqttd_auth_mongo
```

MongoDB Database
----------------

```
use mqtt
db.createCollection("mqtt_user")
db.createCollection("mqtt_acl")
db.mqtt_user.ensureIndex({"username":1})
```

mqtt_user Collection
--------------------

```
{
    username: "user",
    password: "password hash",
    is_superuser: boolean (true, false),
    created: "datetime"
}
```

For example:
```
db.mqtt_user.insert({username: "test", password: "password hash", is_superuser: false})
db.mqtt_user:insert({username: "root", is_superuser: true})
```

mqtt_acl Collection
-------------------

```
{
    username: "username",
    clientid: "clientid",
    publish: ["topic1", "topic2", ...],
    subscribe: ["subtop1", "subtop2", ...],
    pubsub: ["topic/#", "topic1", ...]
}
```

For example:

```
db.mqtt_acl.insert({username: "test", publish: ["t/1", "t/2"], subscribe: ["user/%u", "client/%c"]})
db.mqtt_acl.insert({username: "admin", pubsub: ["#"]})
```

License
-------

Apache License Version 2.0

Author
------

Feng Lee <feng@emqtt.io>
