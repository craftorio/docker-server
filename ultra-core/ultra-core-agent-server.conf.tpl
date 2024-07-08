# Check session
r|https:\/\/sessionserver\.mojang\.com\/session\/minecraft\/hasJoined\?(.*)
f|https://${MC_AUTH_SESSION_SERVER}/session/minecraft/hasJoined?%s

# Client profile (skins)
r|https:\/\/sessionserver\.mojang\.com\/session\/minecraft\/profile\/([0-9a-f]+).*
f|https://${MC_AUTH_SESSION_SERVER}/session/minecraft/profile/%s
