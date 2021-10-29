# Automatically format Lua files on save
hook global WinSetOption filetype=lua %{
    hook window BufWritePre .* format
}
