-- Toggle Ghostty with alt-tab
-- Handled by Ghostty now
hs.hotkey.bind({ "alt" }, "tab", function()
  if hs.application.frontmostApplication():name() == "Ghostty" then
    hs.application.frontmostApplication():hide()
  else
    hs.application.launchOrFocus("Ghostty")
  end
end)

-- Modified from https://fanf.livejournal.com/139925.html
local pow = hs.caffeinate.watcher
local log = hs.logger.new("gpg lock")

local function statusToString(status)
  if status then return "ok" else return "fail" end
end

-- Lock GPG keys when not using the laptop.
local function lockGpgOnExit(event)
  local name = "?"
  for key, val in pairs(pow) do
    if event == val then name = key end
  end
  log.f("caffeinate event %d => %s", event, name)

  if event == pow.screensDidSleep
      or event == pow.systemWillSleep
      or event == pow.systemWillPowerOff
      or event == pow.sessionDidResignActive
      or event == pow.screensDidLock
  then
    log.i("sleeping…")
    local ok, status, type, exitCode = hs.execute("gpg-connect-agent reloadagent /bye", true)
    log.f("lock keys => %s %d", statusToString(status), exitCode)
    return
  end
end

-- pow.new(lockGpgOnExit):start()

