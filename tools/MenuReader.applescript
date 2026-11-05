-- MenuReader: dumps an app's menu items and keyboard shortcuts so remote buttons can be mapped to them.
-- Usage: echo "ChatGPT" > /tmp/menureader-target; open -W -a MenuReader; cat /tmp/menureader-out.txt
-- Modifier codes: 0 Cmd, 1 Shift+Cmd, 2 Option+Cmd, 3 Option+Shift+Cmd, 4 Ctrl+Cmd, 8 no Cmd (add 1/2/4 for Shift/Option/Ctrl).
set appName to do shell script "cat /tmp/menureader-target"
set out to ""
try
	tell application "System Events" to tell process appName
		repeat with mb in menu bar items of menu bar 1
			set mName to name of mb
			try
				repeat with mi in menu items of menu 1 of mb
					set iName to name of mi
					if iName is not missing value then
						set k to ""
						try
							set c to value of attribute "AXMenuItemCmdChar" of mi
							set m to value of attribute "AXMenuItemCmdModifiers" of mi
							if c is not missing value then set k to (m as text) & ":" & c
						end try
						set out to out & mName & " > " & iName & "  [" & k & "]" & linefeed
					end if
				end repeat
			end try
		end repeat
	end tell
on error e
	set out to "ERROR: " & e
end try
set f to open for access (POSIX file "/tmp/menureader-out.txt") with write permission
set eof of f to 0
write out to f as «class utf8»
close access f
