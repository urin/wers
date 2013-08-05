@echo off

setlocal
for %%x in (ruby.exe) do (set currentRubyPath=%%~dp$PATH:x)
if "%currentRubyPath%" == "" (
  echo "Ruby does not exist in available PATH."
  exit /b
)
if /i "%~1" == "init" (
  ruby "%~dp0..\lib\%~n0.rb" init "%currentRubyPath%"
  exit /b
)
endlocal

if /i "%~1" == "shell" (
  call :UpdateRubyPath %*
) else if /i "%~1" == "local" (
  call :UpdateRubyPath %*
) else if /i "%~1" == "global" (
  call :UpdateRubyPath %*
) else (
  ruby "%~dp0..\lib\%~n0.rb" %*
)

exit /b

:UpdateRubyPath
  setlocal
  for /f "delims=" %%p in ('ruby "%~dp0..\lib\%~n0.rb" %*') do (set newPath=%%p)
  if /i "%newPath:~0,6%" == "Error:" (
    echo %newPath%
    ruby "%~dp0..\lib\%~n0.rb" help
    endlocal
  ) else (
    endlocal && set PATH=%newPath%
    ruby "%~dp0..\lib\%~n0.rb" list
  )
exit /b

