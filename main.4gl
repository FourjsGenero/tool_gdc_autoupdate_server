IMPORT os

DEFINE serverSideArchive, serverSidePath, clientSideArchive, clientWindowsPath
    STRING
DEFINE res, ret INTEGER

MAIN

#Due to a Windows bug with spaces in paths, we're using a hardcoded directory in place of value returned by datadirectory frontcall
    LET clientWindowsPath = "c:\\tmp\\gdc_auto_update_123456789"
#arg_val(1) is the xcf parameter corresponding to the path wherein are available your update folders for each OS
    LET serverSidePath = ARG_VAL(1), "/"

    CALL getGdcVersion()

END MAIN

#Find the server archive according to the OS
FUNCTION getServerArchive(osAcro)
    DEFINE osAcro STRING
    DEFINE h, msg STRING
    DEFINE serverArchive STRING
    DEFINE osServerSidePath STRING

    LET osServerSidePath = serverSidePath, osacro

    CALL os.Path.dirFMask(1 + 2 + 4)
    LET h = os.Path.dirOpen(osServerSidePath)

    DISPLAY "The handle is ", h

#If there is at least one file in directory
    IF h >= 1 THEN
        LET serverArchive = os.Path.dirNext(h) --switch to next
        WHILE TRUE
            --check if it's a zip file
            IF os.Path.extension(serverArchive) == "zip" THEN
                LET serverArchive =
                    os.path.join(osServerSidePath, serverArchive)
                EXIT WHILE
            ELSE
                LET serverArchive = os.Path.dirNext(h)
                IF serverArchive IS NULL THEN
                    LET msg =
                        "There is no zip available in the corresponding OS directory"
                    CLOSE WINDOW SCREEN
                    OPEN WINDOW w WITH FORM "noupdate"
                    DISPLAY msg TO t1
                    MENU
                        ON ACTION QUIT
                            EXIT PROGRAM
                    END MENU
                    CLOSE WINDOW w
                    EXIT WHILE
                END IF
            END IF
        END WHILE

    END IF

    RETURN serverArchive

END FUNCTION

#Find the client path of non-windows OSes
FUNCTION getClientPath()
    DEFINE clientPath STRING
    CALL ui.Interface.frontCall(
        "standard", "feInfo",["datadirectory"],[clientPath])

    RETURN clientPath

END FUNCTION

#Main function that retrieves the GDC client version and compare it to the server version
FUNCTION getGdcVersion()
    DEFINE gdcVersion,
            gdcVersionBuildString,
            gdcVersionBranchString,
            gdcOs,
            gdcServerArchive,
            gdcServerArchivePart1,
            gdcServerArchivePart2,
            msg
        STRING
    DEFINE gdcVersionBuild, gdcServerArchiveBuild INTEGER
    DEFINE gdcVersionBranch DECIMAL(3, 2)
    DEFINE gdcInstallPath STRING

    #retrieve the entire version
    LET gdcVersion = ui.Interface.getFrontEndVersion()
    DISPLAY "GDC current version is ", gdcVersion

    #retrieve the GDC path
    CALL ui.Interface.frontCall(
        "standard", "feInfo",["fePath"],[gdcInstallPath])
    DISPLAY "GDC directory is ", gdcInstallPath

    #retrieve the branch -- if lower than 3.10, update is impossible
    LET gdcVersionBranchString = gdcVersion.subString(1, 4)
    #Store the branch number in an Integer variable
    LET gdcVersionBranch = gdcVersionBranchString

    IF gdcVersionBranch < 3.10 THEN
        LET msg = "Your version is prior to 3.10, auto-update is not possible"
        CLOSE WINDOW SCREEN
        OPEN WINDOW w WITH FORM "noupdate"
        DISPLAY msg TO t1
        MENU
            ON ACTION QUIT
                EXIT PROGRAM
        END MENU
        CLOSE WINDOW w
    END IF

    #retrieve the build
    LET gdcVersionBuildString = gdcVersion.subString(9, 14)

    #get OS
    CALL ui.Interface.frontCall("standard", "feInfo",["target"],[gdcOs])
    #substring the target OS
    LET gdcOs = gdcOs.subString(1, 3)
    DISPLAY "The GDC OS is ", gdcOS

    #retrieve the name of the file on the server side acccording to the OS
    LET gdcServerArchive = getServerArchive(gdcOs)
    LET gdcServerArchive = os.Path.baseName(gdcServerArchive)

    LET gdcServerArchivePart1 = gdcServerArchive.subString(9, 15)
    LET gdcServerArchivePart2 = gdcServerArchive.subString(22, 27)

    LET gdcServerArchive = gdcServerArchivePart1, "-", gdcServerArchivePart2

    DISPLAY "Client version which is installed is ", gdcVersion
    DISPLAY "Server version which gonna be installed is ", gdcServerArchive

    #Convert substrings of builds to integers
    LET gdcVersionBuild = gdcVersionBuildString
    LET gdcServerArchiveBuild = gdcServerArchivePart2

    #Compare the client version and the server version and do action accordingly
    --if client version is more recent, no need to update
    IF gdcVersionBuild >= gdcServerArchiveBuild THEN
        LET msg =
            "You're using GDC ", gdcVersion, ", this version is up to date"
        CLOSE WINDOW SCREEN
        OPEN WINDOW w WITH FORM "noupdate"
        DISPLAY msg TO t1
        MENU
            ON ACTION quit
                EXIT PROGRAM
        END MENU
        CLOSE WINDOW w
        --if server version is more recent, then suggest the udpate
    ELSE
        LET msg =
            "The version available on the update server (",
            gdcServerArchive,
            ") is more recent than yours (",
            gdcVersion,
            "). Do you want to update?"

        CLOSE WINDOW SCREEN
        OPEN WINDOW w WITH FORM "update"
        DISPLAY msg TO t1
        MENU
            #if yes, execute the update
            ON ACTION yes
                DISPLAY "Please Wait..." TO t1
                CALL waitWindow()
                CALL executeUpdate(gdcOS)
                EXIT PROGRAM
            ON ACTION no
                EXIT PROGRAM
        END MENU
        CLOSE WINDOW w
    END IF

END FUNCTION

#Function which executes the update
FUNCTION executeUpdate(osAcro)
    DEFINE osAcro STRING

    LET clientSideArchive = getClientPath(), "/", "tmp.zip"
    CASE osAcro
        WHEN "w32"
            LET serversideArchive = getServerArchive("w32")
            --LET clientSideArchive = "c:\\tmp\\gdc_auto_update_123456789\\tmp.zip"

            -- CALL ui.Interface.frontCall("standard", "execute", ["cmd /C rd /S /Q " || clientWindowsPath, TRUE], [ret])
            -- CALL ui.Interface.frontCall("standard", "execute", ["cmd /C md " || clientWindowsPath, TRUE], [ret])

            CALL FGL_PUTFILE(serverSideArchive, clientSideArchive)
            CALL ui.Interface.frontCall(
                "monitor", "update",[clientSideArchive],[res])

        WHEN "w64"
            LET serverSideArchive = getServerArchive("w64")
            --LET clientSideArchive =  getClientPath(),  "/", "tmp.zip"

            -- CALL ui.Interface.frontCall("standard", "execute", ["cmd /C rd /S /Q " || clientWindowsPath, TRUE], [ret])
            -- CALL ui.Interface.frontCall("standard", "execute", ["cmd /C md " || clientWindowsPath, TRUE], [ret])

            CALL FGL_PUTFILE(serverSideArchive, clientSideArchive)
            CALL ui.Interface.frontCall(
                "monitor", "update",[clientSideArchive],[res])

        WHEN "m64"
            LET serversideArchive = getServerArchive("m64")
            --LET clientSideArchive = getClientPath(), "/", "tmp.zip"
            CALL FGL_PUTFILE(serverSideArchive, clientSideArchive)
            CALL ui.Interface.frontCall(
                "monitor", "update",[clientSideArchive],[res])

        WHEN "l32"
            LET serversideArchive = getServerArchive("l32")
            -- LET clientSideArchive = getClientPath(), "/", "tmp.zip"
            CALL FGL_PUTFILE(serverSideArchive, clientSideArchive)
            CALL ui.Interface.frontCall(
                "monitor", "update",[clientSideArchive],[res])

        WHEN "l64"
            LET serversideArchive = getServerArchive("l64")
            -- LET clientSideArchive = getClientPath(), "/", "tmp.zip"
            CALL FGL_PUTFILE(serverSideArchive, clientSideArchive)
            CALL ui.Interface.frontCall(
                "monitor", "update",[clientSideArchive],[res])
    END CASE

END FUNCTION

#Display the Wait window
FUNCTION waitWindow()
    DEFINE w ui.Window
    DEFINE f ui.Form
    LET w = ui.Window.getCurrent()
    LET f = w.getForm()
    CALL f.setElementHidden("yes", 1)
    CALL f.setElementHidden("no", 1)
END FUNCTION
