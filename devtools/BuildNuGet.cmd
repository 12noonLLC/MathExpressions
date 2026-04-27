@echo off
rem
rem	Perform a clean restore and build.
rem	Run all unit tests.
rem	Pack a NuGet library.
rem

setlocal EnableExtensions EnableDelayedExpansion

if NOT EXIST "MathExpressions.slnx" (
  echo Run this script from the solution folder.
  goto :EOF
)

echo.
echo To avoid errors on locked files and folders, such as PackageLayout, etc.:
echo    - Pause Onedrive
echo    - Exit Visual Studio
echo.
echo Update the version in:
echo    - Directory.Build.props
echo.

::
:: SETUP
::

set PROJECT=MathExpressions
set BUILD_OUTPUT_ROOT=C:\VSIntermediate\%PROJECT%
set PUBLISH_FILES_PATH=%BUILD_OUTPUT_ROOT%\publish
set DIRECTORY_BUILD_PROPS=.\Directory.Build.props
set PROJECT_TESTS_PATH=.\%PROJECT%.UnitTests\%PROJECT%.UnitTests.csproj

set PROJECT_NUGET_PATH=MathExpressions\MathExpressions.csproj

::
:: PRE-BUILD CHECKS
::

echo.
echo === DISPLAY VERSION IN Directory.Packages.props ===
echo.

rem === 1. Locate the Directory.Build.props file ===
if not exist "%DIRECTORY_BUILD_PROPS%" (
	echo ERROR: Version file not found: %DIRECTORY_BUILD_PROPS%
	exit /b 1
)

rem === 2. Extract VersionPrefix from Directory.Build.props ===
for /f "usebackq delims=" %%V in (`
	powershell -NoLogo -NoProfile -Command ^
		"[xml]$x = Get-Content '%DIRECTORY_BUILD_PROPS%'; $x.Project.PropertyGroup.VersionPrefix"
`) do set "VERSION_PREFIX=%%V"

if "%VERSION_PREFIX%" == "" (
	echo ERROR: VersionPrefix not found in %DIRECTORY_BUILD_PROPS%
	exit /b 1
)

rem === 3. Display version (in A.B.C format) ===
set EXPECTED=%VERSION_PREFIX%

echo Version check successful: %EXPECTED%

set VERSION=%VERSION_PREFIX%

echo.
choice /c YN /n /m "Press N to quit, Y to continue: "
if errorlevel 2 (
	echo Quitting...
	exit /b 0
)

::
:: RESTORE PACKAGES
::

echo.
echo === DOTNET CLEAN ===
dotnet clean "%PROJECT_NUGET_PATH%"
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo === DOTNET RESTORE (NuGet library) ===
dotnet restore "%PROJECT_NUGET_PATH%"
if errorlevel 1 exit /b %ERRORLEVEL%

dotnet restore "%PROJECT_TESTS_PATH%"
if errorlevel 1 exit /b %ERRORLEVEL%

::
:: BUILD
::

echo.
echo === DOTNET BUILD (NuGet library) ===
dotnet build "%PROJECT_NUGET_PATH%" --configuration Release --no-restore
if errorlevel 1 exit /b %ERRORLEVEL%

dotnet build "%PROJECT_TESTS_PATH%" --configuration Release --no-restore
if errorlevel 1 exit /b %ERRORLEVEL%

::
:: TEST
::

echo.
echo === DOTNET TEST ===
dotnet test ^
	--project "%PROJECT_TESTS_PATH%" ^
	--configuration Release ^
	--no-restore ^
	--no-build ^
	--no-ansi ^
	--no-progress ^
	--output detailed
if errorlevel 1 exit /b %ERRORLEVEL%

::
:: PACK the NuGet library
::

echo.
echo === PACK (NuGet library) ===
dotnet pack ^
	"%PROJECT_NUGET_PATH%" ^
	--configuration Release ^
	--version %VERSION% ^
	--no-restore ^
	--no-build ^
   --include-symbols ^
   --property:SymbolPackageFormat=snupkg ^
	--output "%PUBLISH_FILES_PATH%"
if errorlevel 1 exit /b %ERRORLEVEL%

endlocal
