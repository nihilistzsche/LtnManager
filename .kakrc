# Automatically format Lua files on save
hook global WinSetOption filetype=lua %{
    hook window BufWritePre .* format
}

# Automatically spellcheck locale and changelog
hook global WinSetOption filetype=(factorio-changelog|ini) %{
    hook window BufWritePost .* spell
}
