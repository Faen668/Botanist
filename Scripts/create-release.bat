call variables.cmd
call encode-csv-strings.bat

::Delete 'Release' folder and create a new one.
rmdir "%modpath%\release" /s /q
mkdir "%modpath%\release"
mkdir "%modpath%\release\loose"
mkdir "%modpath%\release\packed"

::Compile and copy over all local .ws scripts.
mkdir "%modpath%\release\loose\mods\mod%modname%\content\scripts\local\
> "%modpath%\release\loose\mods\mod%modname%\content\scripts\local\Botanist_Compiled.ws" (for /r "%modpath%\Source\local" %%F in (*.ws) do @type "%%F")

::Copy over the compiled scripts .ws scripts.
XCOPY "%modpath%\release\loose\mods\mod%modname%\content\scripts\local\" "%modpath%\Compiled" /e /s /y

::Copy over all vanilla .ws scripts.
XCOPY "%modpath%\Source\game" "%modpath%\release\loose\mods\mod%modname%\content\Scripts\game\" /e /s /y

::Copy over all primer patch .ws scripts.
XCOPY "%modpath%\primer\game" "%modpath%\release\loose\PrimerPatch\mods\mod%modname%\content\Scripts\game\" /e /s /y

::Copy over the menu xml.
mkdir "%modpath%\release\loose\bin\config\r4game\user_config_matrix\pc\"
XCOPY "%modPath%\Menu" "%modpath%\release\loose\bin\config\r4game\user_config_matrix\pc\" /e /s /y

::Copy over the encoded strings.
XCOPY "%modpath%\Strings\" "%modpath%\release\loose\mods\mod%modname%\content\" /e /s /y

::Copy over the DLC bundle files.
XCOPY "%modpath%\Build\Botanist\packed\DLC\dlc_botanist\content" "%modpath%\release\loose\dlc\dlc%modname%\content\" /e /s /y

::Copy over the Installation Instructions.
XCOPY "%modpath%\Instructions\Installation Instructions.txt" "%modpath%\release\loose\"
XCOPY "%modpath%\Instructions\Primer\Installation Instructions.txt" "%modpath%\release\loose\PrimerPatch"

::Copy over the Shared Util dependencies
XCOPY "%supath%\mod_sharedutils_mappins\" "%modpath%\release\loose\mods\mod_sharedutils_mappins\" /e /s /y
XCOPY "%supath%\mod_sharedutils_oneliners\" "%modpath%\release\loose\mods\mod_sharedutils_oneliners\" /e /s /y
XCOPY "%supath%\mod_sharedutils_helpers\" "%modpath%\release\loose\mods\mod_sharedutils_helpers\" /e /s /y
XCOPY "%supath%\mod_sharedutils_tiny_bootstrapper\" "%modpath%\release\loose\mods\mod_sharedutils_tiny_bootstrapper\" /e /s /y
XCOPY "%supath%\mod_sharedutils_storage\" "%modpath%\release\loose\mods\mod_sharedutils_storage\" /e /s /y

::Create zip file for the release.
"C:\Program Files\7-Zip\7z.exe" a "%modpath%\release\packed\Botanist.zip" "%modpath%\release\loose\mods"
"C:\Program Files\7-Zip\7z.exe" a "%modpath%\release\packed\Botanist.zip" "%modpath%\release\loose\dlc"
"C:\Program Files\7-Zip\7z.exe" a "%modpath%\release\packed\Botanist.zip" "%modpath%\release\loose\bin"
"C:\Program Files\7-Zip\7z.exe" a "%modpath%\release\packed\Botanist.zip" "%modpath%\release\loose\Installation Instructions.txt"

"C:\Program Files\7-Zip\7z.exe" a "%modpath%\release\packed\PrimerPatch.zip" "%modpath%\release\loose\PrimerPatch\mods"
"C:\Program Files\7-Zip\7z.exe" a "%modpath%\release\packed\PrimerPatch.zip" "%modpath%\release\loose\PrimerPatch\Installation Instructions.txt"

del "%modpath%\release\loose\Installation Instructions.txt"
del "%modpath%\release\loose\PrimerPatch\Installation Instructions.txt"