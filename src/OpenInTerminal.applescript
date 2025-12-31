property fallbackDir : POSIX path of (path to home folder)
property logFile : "/tmp/OpenInTerminal.log"

on run
	my logLine("run start")
	
	set dirsToOpen to my uniqueDirsFromFinderContext()
	if (count of dirsToOpen) is 0 then set dirsToOpen to {fallbackDir}
	my logLine("dirsToOpen=" & my joinList(dirsToOpen, ","))
	
	my openDirsInTerminal(dirsToOpen)
	my logLine("run end")
end run

on uniqueDirsFromFinderContext()
	set dirsToOpen to {}
	
	if application "Finder" is running then
		try
			tell application "Finder"
				set sel to selection as list
				my logLine("Finder selection count=" & (count of sel))
				
				if (count of sel) > 0 then
					repeat with anItem in sel
						try
							if (class of anItem is folder) then
								set end of dirsToOpen to POSIX path of (anItem as alias)
							else
								set end of dirsToOpen to POSIX path of ((container of anItem) as alias)
							end if
						on error errMsg2 number errNum2
							my logLine("Finder selection item error(" & errNum2 & "): " & errMsg2)
						end try
					end repeat
				else if (count of Finder windows) > 0 then
					my logLine("Finder windows count=" & (count of Finder windows))
					set end of dirsToOpen to POSIX path of (target of front window as alias)
				else
					my logLine("Finder has no windows")
				end if
			end tell
		on error errMsg number errNum
			my logLine("Finder error(" & errNum & "): " & errMsg)
		end try
	else
		my logLine("Finder not running")
	end if
	
	return my dedupeDirs(dirsToOpen)
end uniqueDirsFromFinderContext

on uniqueDirsFromPosixPaths(posixPaths)
	set dirsToOpen to {}
	repeat with p in posixPaths
		try
			set d to my ensureDirectoryPath((p as text))
			set end of dirsToOpen to d
		on error errMsg number errNum
			my logLine("arg path error(" & errNum & "): " & errMsg)
		end try
	end repeat
	return my dedupeDirs(dirsToOpen)
end uniqueDirsFromPosixPaths

on dedupeDirs(dirList)
	set outList to {}
	repeat with d in dirList
		set dText to d as text
		if dText is not "" then
			if outList does not contain dText then set end of outList to dText
		end if
	end repeat
	return outList
end dedupeDirs

on ensureDirectoryPath(posixPath)
	set quotedPath to quoted form of posixPath
	set isDir to do shell script "test -d " & quotedPath & "; echo $?"
	if isDir is "0" then
		return posixPath
	else
		return do shell script "dirname " & quotedPath
	end if
end ensureDirectoryPath

on openDirsInTerminal(dirsToOpen)
	if (count of dirsToOpen) is 0 then return
	
	set hadFailure to false
	set lastError to ""
	
	repeat with dirPath in dirsToOpen
		set p to (dirPath as text)
		set cmd to "open -a Terminal " & quoted form of p
		my logLine("exec: " & cmd)
		
		-- 参考 Go2Shell：通过 System Events 执行 open，避免直接 tell Terminal
		try
			tell application "System Events"
				do shell script cmd
			end tell
		on error errMsg number errNum
			-- 兜底再尝试一次（不依赖 System Events）
			try
				do shell script cmd
			on error errMsg2 number errNum2
				set hadFailure to true
				set lastError to "System Events(" & errNum & "): " & errMsg & " | Shell(" & errNum2 & "): " & errMsg2
				my logLine("open error: " & lastError)
			end try
		end try
	end repeat
	
	if hadFailure then
		my logLine("display alert: " & lastError)
		try
			set alertMsg to "无法打开 Terminal。" & return & return & "请检查：" & return & "1) Finder 工具栏按钮是否从最新的 OpenInTerminal.app 重新拖入。" & return & "2) 系统设置 → 隐私与安全 → 自动化：允许 OpenInTerminal 控制 Finder/系统事件（如有）。" & return & return & "错误信息：" & return & lastError
			display alert "OpenInTerminal 执行失败" message alertMsg as critical
		end try
	end if
end openDirsInTerminal

on logLine(msg)
	try
		set ts to do shell script "date '+%Y-%m-%d %H:%M:%S'"
		do shell script "printf %s\\\\n " & quoted form of (ts & " " & msg) & " >> " & quoted form of logFile
	end try
end logLine

on joinList(theList, sep)
	if (count of theList) is 0 then return ""
	set outText to item 1 of theList as text
	if (count of theList) > 1 then
		repeat with i from 2 to (count of theList)
			set outText to outText & sep & (item i of theList as text)
		end repeat
	end if
	return outText
end joinList
