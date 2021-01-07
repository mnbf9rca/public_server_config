# quick server config scripts

just some simple scripts i use when setting up a server. Probably i should learn some scripting tool...

## [add_user.sh](./add_user.sh "add_user.sh")

Adds a new user and pulls their `authorized_keys` from github, and **disables password authentication** at the same time. Usage:
`./add_user.sh -u <username> -p <password> -k <github username>`

Make sure you test before you log out...

## [automatic_updates.sh](./automatic_updates.sh "automatic_updates.sh")

enables automatic updates on the server.

## [disable-password.sh](./disable-password.sh "disable-password.sh")

Disables password authentication in sshd.

## [update_and_clean.sh](./update_and_clean.sh "update_and_clean.sh")

Removes snapd and updates server using `dist-upgrade`, then installs `nano` and `curl`
