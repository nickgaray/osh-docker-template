#!/bin/sh

# See https://stackoverflow.com/a/39398511/740048
# and https://forum.artixlinux.org/index.php/topic,3360.0.html
chown -R "$USER_UID":"$USER_GID" "$OSH_HOME"
exec setpriv --reuid "$USER_UID" --regid "$USER_GID" --init-groups "$@"
