# OpenSSL ignores SSL_CERT_FILE in Android applications (their processes are
# AT_SECURE), so tls::import (and tls::socket, which uses it) gets the CA
# certificates of the system, which main.tcl put in that file, when the caller
# gives no -cafile or -cadir of its own. A -cafile or -cadir which does not
# exist is dropped: applications default to the paths of desktop systems
# (Tkabber to /etc/ssl/certs), which Android does not have, and would get no
# CA certificates at all.
rename ::tls::import ::tls::ImportWithoutCAs
proc ::tls::import {chan args} {
    set given 0
    set kept {}
    foreach {opt value} $args {
	if {$opt in {-cafile -cadir}} {
	    if {$value eq "" || ![file exists $value]} {
		continue
	    }
	    set given 1
	}
	lappend kept $opt $value
    }
    if {!$given && [info exists ::env(SSL_CERT_FILE)]} {
	set kept [linsert $kept 0 -cafile $::env(SSL_CERT_FILE)]
    }
    tailcall ::tls::ImportWithoutCAs $chan {*}$kept
}
