=====
GetIt
=====

>Intro
There are many Windows implimentations of the style of the linux apt-get function.

When you want to install something, you shouldn't have to think "Hm, which one had this program again?".
That's where GetIt comes in. It indexes repositories locally, and lets you choose which program to install from a master list of ALL avaliable programs.
Once you choose the program you want to install, GetIt knows who to talk to in order to get it.

>Commandline Usage

getit help
Shows this readme. :)


getit install APP
Install APP using the first supported engine it finds via the order of your preference.txt

getit show APP
Show details of APP and give you the option to then install it.


getit update
Updates all repositories/databases it knows how to, and then exports them into .git files in the Installs\ folder
Note: Exporting code is hard-coded. When adding custom engines, you will have to export them yourself when your custom UpdateEXE is called.

getit upgrade
Upgrades all installed applications using any app-getting engines that support such a feature

getit "C:\path...to...file\some.git"
Takes appropriate action with the current .git file. Quotes are required!

getit installfromfile "C:\...path to git file\APP.git"
Use of this parameter should generally be avoided.
Same as above, except overwrites the web-safe design, allowing you to silent-install this .git outside the \Installs folder.
This also assumes the .git file to be of type "AppPointer". 

getit showfromfile "C:\...path to git file\APP.git"
Same as 'show', but with path to .git file.

getit getengines
Detects and sets up all recommended app-getting engines. Must be run after install and getit updates (automatically done by default).

getit getenginesall
Detects and sets up all supported app-getting engines.

getit makeportable K:\GetIt
Makes GetIt portable to location on USB Stick, copies over all engines with it


>Portable GetIt
You can now make GetIt portable. This is still experimental. Just because GetIt supports being portable doesn't mean 3rd party App-Getting-Engines do.
While AppSnap and Appupdater seem to be generally OK with being run portably, there are some limitations:
-Appupdater currently requires you to update it's database of installed applications on the target PC (run "getit.exe update")


>Opening .Git files
If .git files didn't get associated properly, just tell windows to open them with GetIt.exe
The appropriate action should be taken (aka. They will be forwarded to the GetIt_GUI.exe for things like 'Add Repositories?' .git files)



>Preference.txt
This file has a list of all Application Getting Engines that you like to use, in the other you want them to be attempted.
So if you like one engine better than another, you should put it at the top. If you don't want a specific engine to be used, delete that line.

WARNING: You must keep a blank line at the end of the file!



>Repositories.txt
This file lists repositories to inject into Application-Getters that support that sort of thing. A simple line looks like so:
	AppSnap"http://puchisoft.com/GetIt/Repository.ini"
AppSnap is the AppGetter you want to inject a repository into.
http://puchisoft.com/GetIt/Repository.ini is the location of the repository (can be a local file or URL)
Quotes (") seperate this information.

AppSnap repositories use the same format that AppSnap's own db.ini uses, so take a look at it. :)

Example Repositories.txt:"
AppSnap"http://puchisoft.com/GetIt/Repository.ini"
AppSnap"http://puchisoft.com/gloriouscomputing/Repository.ini"

"

WARNING: There must again be a blank line at the end of the file!


>FARRv2
Using Git with Find and Run Robot is simple, because Git was designed around current FARRv2 features.

For example, you can add an alias: ^install (.*)
which does: dosearch C:\Program Files\Puchisoft\GetIt\Installs\.$$1

So when you type "install fire", it will suggest to you Applications containing "fire", mainly "Firefox".

You can also do "installrefresh" and "installupgrade"


>.Git File Format
They are just ini files. Take a look. They are simple to understand.
.Git files basically just say which Engines support their representive Application
