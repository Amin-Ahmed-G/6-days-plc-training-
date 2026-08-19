@echo off
echo ========================================================
echo Pushing plc-6-days-training to GitHub...
echo ========================================================
git push -u origin main
if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================================
    echo Successfully pushed all projects and materials to GitHub!
    echo ========================================================
) else (
    echo.
    echo ========================================================
    echo Push failed. Please ensure you have created the empty
    echo repository 'plc-6-days-training' at https://github.com/new
    echo ========================================================
)
pause
