@echo off
rem Serves the blog at http://localhost:4000 with live reload using a local Ruby
rem (RubyInstaller 3.3 with DevKit) instead of Docker. Gems install into the
rem project-local vendor/bundle on the first run.
cd /d "%~dp0"
where ruby >nul 2>nul
if errorlevel 1 (
    echo Ruby not found on PATH. Install it with:
    echo   winget install --id RubyInstallerTeam.RubyWithDevKit.3.3 --source winget
    echo then open a new terminal and run this script again.
    exit /b 1
)
call bundle config set --local path vendor/bundle
call bundle install || exit /b 1
call bundle exec jekyll serve --config _config.yml,_config.local.yml --livereload
