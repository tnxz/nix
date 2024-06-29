```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- \
  install --extra-conf "trusted-users = $(whoami)" --extra-conf "use-xdg-base-directories = true"
```
```
nix run home-manager/master -- init --switch .
```
