@echo off
setlocal ENABLEDELAYEDEXPANSION

REM ===== Rutas FFmpeg/FFprobe (tus rutas) =====
set "FFMPEG=C:\Tools\ffmpeg\bin\ffmpeg.exe"
set "FFPROBE=C:\Tools\ffmpeg\bin\ffprobe.exe"

#set "FFMPEG=C:\Users\Sammi De Blas\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg.Essentials_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.0-essentials_build\bin\ffmpeg.exe"
#set "FFPROBE=C:\Users\Sammi De Blas\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg.Essentials_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.0-essentials_build\bin\ffprobe.exe"

REM ===== Config =====
set "DEFAULT_FONT=C:\Windows\Fonts\segoeui.ttf"
set "FPS=2"
set "WIDTH=1280"
set "HEIGHT=720"
set "AUDIO_BR=160k"
set "AUDIO_AR=48000"

REM ===== Comprobación FFmpeg/FFprobe =====
if not exist "%FFMPEG%" (
  echo [ERROR] No se encuentra ffmpeg en: %FFMPEG%
  pause
  exit /b 1
)
if not exist "%FFPROBE%" (
  echo [ERROR] No se encuentra ffprobe en: %FFPROBE%
  pause
  exit /b 1
)

REM ===== Solicitar archivos =====
set "COVER="
set /p COVER=Ruta de la portada (PNG/JPG), por ejemplo cover.png: 
if not exist "%COVER%" (
  echo [ERROR] No existe la portada "%COVER%".
  pause
  exit /b 1
)

set "AUDIO="
set /p AUDIO=Ruta del audio (.m4a preferente): 
if not exist "%AUDIO%" (
  echo [ERROR] No existe el audio "%AUDIO%".
  pause
  exit /b 1
)

REM ===== Solicitar titulo =====
set "TITLE="
set /p TITLE=TITULO a mostrar en el video (se dibujara en la imagen): 

REM ===== Comprobar fuente =====
if not exist "%DEFAULT_FONT%" (
  echo [WARN] Fuente por defecto no encontrada: %DEFAULT_FONT%
  echo Intentando Arial...
  set "DEFAULT_FONT=C:\Windows\Fonts\arial.ttf"
  if not exist "%DEFAULT_FONT%" (
    echo [ERROR] No encuentro una fuente valida. Edita el .bat y fija DEFAULT_FONT a una TTF existente.
    pause
    exit /b 1
  )
)

REM ===== Normalizar titulo a slug para nombre de archivo =====
set "SLUG=%TITLE%"
set "SLUG=%SLUG: =-%"
set "SLUG=%SLUG:á=a%"
set "SLUG=%SLUG:é=e%"
set "SLUG=%SLUG:í=i%"
set "SLUG=%SLUG:ó=o%"
set "SLUG=%SLUG:ú=u%"
set "SLUG=%SLUG:Á=A%"
set "SLUG=%SLUG:É=E%"
set "SLUG=%SLUG:Í=I%"
set "SLUG=%SLUG:Ó=O%"
set "SLUG=%SLUG:Ú=U%"
set "SLUG=%SLUG:ñ=n%"
set "SLUG=%SLUG:Ñ=N%"
set "SLUG=%SLUG:¿=%"
set "SLUG=%SLUG:?=%"
set "SLUG=%SLUG:¡=%"
set "SLUG=%SLUG:!=%"
set "SLUG=%SLUG:/=%"
set "SLUG=%SLUG:\=%"
set "SLUG=%SLUG:^=%"
set "SLUG=%SLUG:&=%"
set "SLUG=%SLUG:|=%"
set "SLUG=%SLUG:>=%"
set "SLUG=%SLUG:<=%"
set "SLUG=%SLUG:*=%"
set "SLUG=%SLUG:+=%"
set "SLUG=%SLUG:.,=%"
set "SLUG=%SLUG:(=%"
set "SLUG=%SLUG:)=%"
set "SLUG=%SLUG:[=%"
set "SLUG=%SLUG:]=%"
set "SLUG=%SLUG:{=%"
set "SLUG=%SLUG:}=%"
set "SLUG=%SLUG:'=%"
set "SLUG=%SLUG:"=%"

REM Fecha YYYY-MM-DD (ajustada para ES)
for /f "tokens=1-3 delims=/.- " %%a in ("%date%") do (
  set "D1=%%a" & set "D2=%%b" & set "D3=%%c"
)
set "YYYY=%D1%"
set "MM=%D2%"
set "DD=%D3%"
echo %YYYY%| findstr /r "^[0-9][0-9][0-9][0-9]$" >nul || (
  set "YYYY=%D3%"
  set "MM=%D2%"
  set "DD=%D1%"
)
if 1%MM% LSS 110 set "MM=0%MM%"
if 1%DD% LSS 110 set "DD=0%DD%"
set "DATESTR=%YYYY%-%MM%-%DD%"

REM ===== Determinar codec de audio =====
for /f "tokens=* usebackq" %%i in (`"%FFPROBE%" -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=nokey^=1:noprint_wrappers^=1 "%AUDIO%"`) do (
  set "ACODEC=%%i"
)
if "%ACODEC%"=="" (
  echo [WARN] No se pudo detectar codec de audio. Se recodificara a AAC por seguridad.
  set "AUDIO_MODE=reencode"
) else (
  echo [INFO] Codec de audio detectado: %ACODEC%
  if /i "%ACODEC%"=="aac" (
    set "AUDIO_MODE=copy"
  ) else (
    set "AUDIO_MODE=reencode"
  )
)

REM ===== Preparar salida =====
set "OUT=%DATESTR%-%SLUG%_720p.mp4"

REM ===== Preparar drawtext =====
set "FONT_ESC=%DEFAULT_FONT:\=\\%"
set "FONT_ESC=%FONT_ESC::=\:%"

set "TT=__titulo_tmp.txt"
> "%TT%" (
  echo %TITLE%
)

REM Filtro con letterbox opcional si la portada no es 16:9
set "FILTER=[0:v]scale=w=%WIDTH%:h=-1:force_original_aspect_ratio=decrease,pad=%WIDTH%:%HEIGHT%:(%WIDTH%-iw)/2:(%HEIGHT%-ih)/2:black,format=yuv420p,drawtext=fontfile='%FONT_ESC%':textfile='%TT%':fontcolor=white:fontsize=54:box=1:boxcolor=0x00000099:boxborderw=24:x=(w-text_w)/2:y=h-text_h-80"

echo.
echo [INFO] Generando video: %OUT%
if /i "%AUDIO_MODE%"=="copy" (
  "%FFMPEG%" -y -loop 1 -framerate %FPS% -i "%COVER%" -i "%AUDIO%" -filter_complex "%FILTER%" -c:v libx264 -tune stillimage -pix_fmt yuv420p -c:a copy -shortest "%OUT%"
) else (
  "%FFMPEG%" -y -loop 1 -framerate %FPS% -i "%COVER%" -i "%AUDIO%" -filter_complex "%FILTER%" -c:v libx264 -tune stillimage -pix_fmt yuv420p -c:a aac -b:a %AUDIO_BR% -ar %AUDIO_AR% -shortest "%OUT%"
)

set "ERR=%ERRORLEVEL%"
del "%TT%" >nul 2>&1

if not "%ERR%"=="0" (
  echo.
  echo [ERROR] FFmpeg fallo con codigo %ERR%.
  pause
  exit /b %ERR%
)

echo.
echo [OK] Listo: %OUT%
echo Sube este MP4 a YouTube (Studio -> Crear -> Subir).
pause
endlocal