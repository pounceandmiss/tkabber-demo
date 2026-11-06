package require critcl
package provide tclCarbonNotification 1.0

lappend critcl::v::compile -framework Carbon

critcl::ccode {
    #include <Carbon/Carbon.h>
}

critcl::cproc tclCarbonNotification {int bounce char* msg} ok {
    OSErr err;
    NMRec request;
    Str255 message;

    request.nmMark = bounce;

    if (strlen(msg)) {
        CopyCStringToPascal(msg, message);
        request.nmStr = (StringPtr)&message;
    } else {
        request.nmStr = NULL;
    }

    request.qType = nmType;
    request.nmSound = NULL;
    request.nmResp = NULL;

    err = NMInstall(&request);
    if (err != noErr)
        return TCL_ERROR;
    return TCL_OK;
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
