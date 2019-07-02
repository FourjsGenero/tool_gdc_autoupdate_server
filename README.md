# tool_gdc_autoupdate_server

# Last commit

We added the Genero 3.20 project and now you will be able to generate the gar file from Genero Studio.
The .gar file can be integrate in your GAS 3.20. 
After that you have to add the fjs-gdc-3.20.07-build201906120954-w32v141-autoupdate.zip files in the 
$FGLASDIR/appdata/deployment/gdcuptate....../update/w32/ directory.
Repeat this precess for linux 64bit (l64..), macOs (m64..) and Windows 64bit (w64..)


# First commit
As you know Genero 3.10 come with a new feature : GDC autoupdate.
It is based on a GDC shortcut that executes through GAS a Genero BDL application. This Genero application executes some test of GDC version installed and execute the frontcall that will autoupdate your GDC.

Here is a demo that Four Js provided during the Genero EAP 3.10 before the GA.


