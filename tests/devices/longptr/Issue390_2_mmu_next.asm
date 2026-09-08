; verify behavior of going "back" in MMU "next" auto-wrap mode ends with some error
    DEVICE ZXSPECTRUMNEXT
    MMU $8000 n, 21, $8000      ; select slot with "next auto-wrap" feature
    ld a,7
    DS -2                       ; go backward to start of current slot (arguably "valid" state)
    ASSERT $8000 == $
    res 4,(ix+5),l              ; so this one should work
    DS -5                       ; go backward and leak outside of current slot
    ; it's edge case, not expected to be ever used by end user, so just verify sjasmplus
    ; is going down in flames in somewhat reasonable way, like currently with fatal error (but not a random crash)
    res 4,(ix+5),l              ; oopsie here
