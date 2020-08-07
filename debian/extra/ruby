#!/bin/sh

BUNDLE_GEMFILE="${BUNDLE_GEMFILE:-/usr/share/metasploit-framework/Gemfile}"
export BUNDLE_GEMFILE

if [ -e /opt/metasploit/apps/pro/ui/config/database.yml ] ; then
    MSF_DATABASE_CONFIG="${MSF_DATABASE_CONFIG:-/opt/metasploit/apps/pro/ui/config/database.yml}"
    export MSF_DATABASE_CONFIG
fi

# Bootstrap bundler
if ! echo "$GEM_PATH" | egrep -q "/usr/share/metasploit-framework/vendor/bundle" ; then
    for dir in /usr/share/metasploit-framework/vendor/bundle/ruby/*; do
	if [ -d $dir ]; then
	    GEM_PATH="${GEM_PATH:+"$GEM_PATH:"}$dir"
	fi
    done
fi

# Add rubygems-integration in GEM_PATH. Since bundler version 1.17.3-3,
# the gem is no longer installed in /usr/lib/ruby/vendor_ruby but in
# /usr/share/rubygems-integration/all (see issue 5359)
GEM_PATH="${GEM_PATH:+"$GEM_PATH:"}"/usr/share/rubygems-integration/all""

export GEM_PATH

exec ruby "$@"
