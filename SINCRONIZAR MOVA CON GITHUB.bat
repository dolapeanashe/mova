@echo off
setlocal
cd /d "%~dp0"
title MOVA - Sincronizacion con GitHub

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo ERROR: Esta carpeta no es un repositorio Git.
    pause
    exit /b 1
)

for /f "delims=" %%B in ('git branch --show-current') do set "BRANCH=%%B"

if /i "%BRANCH%"=="master" (
    echo ERROR: No uses este boton desde master.
    echo Cambia primero a tu rama de desarrollo.
    pause
    exit /b 1
)

cls
echo =====================================
echo          SINCRONIZAR MOVA
echo =====================================
echo.
echo Rama actual: %BRANCH%
echo.
echo 1. SUBIR MIS CAMBIOS A GITHUB
echo 2. DESCARGAR CAMBIOS DE MI RAMA
echo.
choice /c 12 /n /m "Elegir opcion: "

if errorlevel 2 goto DESCARGAR
goto SUBIR

:SUBIR
echo.
echo Revisando archivos...
git add -A

if errorlevel 1 goto ERROR

echo.
echo ARCHIVOS QUE SE VAN A GUARDAR:
git diff --cached --name-only
echo.
echo IMPORTANTE: Revisar que no haya claves ni archivos privados.
choice /c SN /n /m "Confirmas que queres subir estos archivos? "

if errorlevel 2 (
    git reset
    echo Cambios preparados cancelados. No se borro tu codigo.
    goto FIN
)

git diff --cached --quiet
if not errorlevel 1 (
    echo No hay cambios nuevos para guardar.
    goto DESCARGAR
)

echo.
set /p "MSG=Escribi un mensaje para esta version: "
if not defined MSG set "MSG=Actualizacion MOVA"

git commit -m "%MSG%"
if errorlevel 1 goto ERROR

echo.
echo Buscando actualizaciones de tu rama...
git pull --rebase origin "%BRANCH%"
if errorlevel 1 goto ERROR_REBASE

echo.
echo Publicando cambios...
git push -u origin "%BRANCH%"
if errorlevel 1 goto ERROR

echo.
echo MOVA GUARDADO CORRECTAMENTE EN GITHUB.
goto FIN

:DESCARGAR
echo.
git pull --rebase origin "%BRANCH%"
if errorlevel 1 goto ERROR_REBASE

echo.
echo ACTUALIZACION COMPLETADA.

goto FIN

:ERROR_REBASE
echo.
echo Hubo un conflicto o un problema al actualizar.
echo No borres archivos. Revisa el estado con git status.
goto FIN

:ERROR
echo.
echo No se pudo completar la operacion.
echo Revisa los mensajes anteriores.

:FIN
echo.
pause
