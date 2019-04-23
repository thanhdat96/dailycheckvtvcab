set OSWHOME=/home/oracle/wecommit/dailycheck
set DIR="C:\wecommit\dailycheck"
winscp.com /ini=nul /command ^
    "open sftp://user:pass@ipTG -hostkey=*" ^
    "get %OSWHOME%/* "%DIR%\"" ^
    "exit"
	
