# Simple policy-rc.d

This script is intended to be placed in `/usr/sbin/policy-rc.d`. It allows
specifying policies for automatic service actions in a simpler manner than
having to write a customized shell script every single time.

## Configuration files

Configuration files are placed in the folder `/etc/policy-rc.d` and are simply
named after the service they are defining policies for. Each text line in this
file will define a policy for one or more actions like this:

```sh
# This is an example policy configuration file.
# If you want to apply a policy to more than one action at once, use a
# comma-delimited list. The special action name '*' applies to all actions.
# The script will take the order of policies into consideration as well.

# 'allow' will allow actions to be executed automatically.
allow start,reload

# This will deny all other actions.
deny *

# This would define a fallback for an action named 'graceful-restart' to
# action 'reload'. If 'reload' fails, another fallback to 'restart' is done.
# Fallback actions will not be checked for further policies to apply, they are
# assumed to be allowed.
fallback graceful-restart reload,restart
```

For details about the effects of policies check [the policy-d.rc reference](http://people.debian.org/~hmh/invokerc.d-policyrc.d-specification.txt).

# License

This script is licensed under the terms of the *GNU General Public License 2.0
or later*. See [LICENSE.txt](LICENSE.txt) for more information.
