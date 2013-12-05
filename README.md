# LDAP auth CouchDB plugin

A couchDB plugin that allows LDAP authentication, based on https://github.com/chao/couchdb/ and https://github.com/etnt/eldap.

## Preparation

To get started, you need to install CouchDB from source, grab the CouchDB sources:

    git clone https://git-wip-us.apache.org/repos/asf/couchdb.git
    cd couchdb

Follow the instructions in `couchdb/INSTALL.Unix` and `couchdb/DEVELOPERS` to get a development environment going.

Be sure to install CouchDB into your system. If you want to install CouchDB into a development directory, make sure that the `bin/` folder of that directory is in your `PATH`.

Next, install *rebar* from <https://github.com/rebar/rebar>. Rebar is a build tool for Erlang projects and it makes our lives a lot easier.

## Quick Start

To compile your code, simply run:

    make

The output should be something like this:

    ERL_LIBS=<..>: rebar compile
    ==> ldap_auth (compile)
    Compiled src/eldap/eldap_sup.erl
    src/ldap_auth.erl:101: Warning: variable 'LDAPRecord' is unused
    Compiled src/ldap_auth.erl
    Compiled src/eldap/eldap_app.erl
    Compiled src/eldap/eldap_fsm.erl
    Compiled src/eldap/eldap.erl
    Compiled src/eldap/ELDAPv3.erl

To run CouchDB with your new plugin make sure CouchDB isn’t already running elsewhere and then do this:

    make dev

## Publishing a Plugin

Publishing a plugin is both simple and not so simple. The mechanics are trivial, just type:

    make plugin

and you will see something like this:

    > make plugin
    rebar compile
    ==> ldap_auth (compile)
    my_first_couchdb_plugin-1.0.0-R15B03-1.4.0.tar.gz: 1/MeXYfxeBK7DQyk10/6ucIRusc=

That’s the easy part. The hard part is publishing the plugin. And since this is subject to change a lot in the near future, we will punt on explaining this in detail here, but to see how it works, look into this file in the CouchDB source distribution: `share/www/plugins.html`

===== Configuring couchdb =====

https://github.com/chao/couchdb/wiki/How-to-configure-couchdb-to-use-ldap-authentication-handler
