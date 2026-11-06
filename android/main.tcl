# tkabber on Android: the libraries of lib (tcllib, BWidget, tls, ...), then tkabber.
set dir [file dirname [info script]]
set auto_path [linsert $auto_path 0 [file join $dir lib] [file join $dir lib tcllib2.0]]

# OpenSSL (tls) finds no CA certificates of its own on Android: put those of
# the system, one PEM file each, into one file, which SSL_CERT_FILE names.
foreach cadir {/apex/com.android.conscrypt/cacerts /system/etc/security/cacerts} {
    if {[file isdirectory $cadir]} {
	set pem [file join $env(TMPDIR) cacerts.pem]
	set out [open $pem w]
	foreach f [glob -nocomplain -directory $cadir *] {
	    set in [open $f]
	    puts $out [read $in]
	    close $in
	}
	close $out
	set env(SSL_CERT_FILE) $pem
	break
    }
}

set argv0 [file join $dir tkabber tkabber.tcl]
source $argv0
