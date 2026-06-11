local activeTheme = nil

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function getDefaultTheme()
    for _, t in ipairs(Themes.list) do
        if t.id == 'midnight' then return t end
    end
    return Themes.list[1]
end

local function loadThemeFromKvp()
    local raw = GetResourceKvpString('off-target:theme')
    if not raw or raw == '' then
        return getDefaultTheme()
    end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' or not decoded.id then
        return getDefaultTheme()
    end
    return decoded
end

local function saveThemeToKvp(theme)
    local ok, encoded = pcall(json.encode, theme)
    if ok and encoded then
        SetResourceKvp('off-target:theme', encoded)
    end
end

-- ─── Init (synchronous — KVP is safe to read outside a thread) ───────────────

activeTheme = loadThemeFromKvp()

-- ─── NUI Callbacks ───────────────────────────────────────────────────────────

-- Called by contextMenu/index.tsx on mount to apply saved theme
RegisterNUICallback('GetActiveTheme', function(_, cb)
    cb(json.encode({
        themes = Themes.list,
        active = activeTheme,
    }))
end)

-- Called by ThemeEditor when the player saves a choice
RegisterNUICallback('SaveTheme', function(data, cb)
    if type(data) ~= 'table' or not data.id then
        cb(json.encode({ ok = false, error = 'invalid theme data' }))
        return
    end
    activeTheme = data
    saveThemeToKvp(data)
    cb(json.encode({ ok = true }))
end)

-- Called when ThemeEditor closes (releases NUI focus)
RegisterNUICallback('ThemeEditorClose', function(_, cb)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'nui:theme:visible', data = false })
    cb(json.encode({ ok = true }))
end)

-- ─── Command ─────────────────────────────────────────────────────────────────

RegisterCommand(Config.ThemeCommand, function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'nui:theme:open',
        data   = {
            themes = Themes.list,
            active = activeTheme,
        },
    })
end, false)

RegisterKeyMapping(
    Config.ThemeCommand,
    'Open context menu theme editor',
    'keyboard',
    ''
)

-- ─── Export (optional — other resources can read active theme) ────────────────

exports('GetActiveTheme', function()
    return activeTheme
end)