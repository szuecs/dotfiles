function lock () {
  case `uname` in
  Darwin ) lock_osx ;;
  *) ;;
  esac
}
function unlock () {
  case `uname` in
  Darwin ) unlock_osx ;;
  *) ;;
  esac
}
function lock_osx () {
  osascript -e '
    on appIsRunning(appName)
      tell application "System Events"
        (name of processes) contains appName
      end tell
    end appIsRunning

    if appIsRunning("iTunes") then
      tell application "iTunes" to pause
    end if
    if appIsRunning("iChat") then
--      tell application "iChat" to set status message to "Away"
      tell application "iChat" to set status to away
    end if
    if appIsRunning("Adium") then
      tell application "Adium" to go away
    end if
    
    set volume with output muted
    tell application "ScreenSaverEngine" to activate
  ' 2>/dev/null
}
function unlock_osx () {
  osascript -e '
  on appIsRunning(appName)
    tell application "System Events"
      (name of processes) contains appName
    end tell
  end appIsRunning

  set volume without output muted

  if appIsRunning("iTunes") then
    tell application "iTunes" to play
  end if
  if appIsRunning("iChat") then
    tell application "iChat" 
--      set status message to "Available"
      set status to available
    end tell
  end if
  if appIsRunning("Adium") then
    tell application "Adium" to go available
  end if
  ' 2>/dev/null
}
