# Language
#::msgcat::mclocale en

# Now we will load Badlop's configuration file, if available.
# It will set a bunch of options.
# It's not a good idea to modify 'badlop-config.tcl'
#   as it will be updated often to add more and more options.
# If you want to change any of them, copy the corresponding line (or lines)
#   from that file, insert it on the following section ('finload_hook') so
#   your personal options will always be securely saved on your own config
#   file.
if {[file exists $rootdir/examples/configs/badlop-config.tcl]} {
    source $rootdir/examples/configs/badlop-config.tcl
}

# Configure here your own options
proc myfinload {} {

# Set here your Jabber account information

#                            1. User:
#    set ::loginconf(user)                ********
#                            2. Server:
#    set ::loginconf(server)              ********
#                            3. Password:
#    set ::loginconf(password)            ********

# You can modify the resource, for example put 'home', or 'laptop/work'
#    set ::loginconf(resource)  TkabberP
# If you have installed all the needed to run SSL, you can activate it
#    set ::loginconf(usessl)    0

# For example, if you do not want sound, uncomment this line
#   set sound::options(sound)   0

#   set ::BROWSER c:/Mozilla/mozillafirebird.exe

#   option add *font -monotype-arial-medium-r-*-*-11-*-100-100-*-*-iso10646-1
#   set font -monotype-arial-medium-r-*-*-11-*-100-100-*-*-iso10646-1

}

hook::add finload_hook myfinload

# vim:ft=tcl:ts=8:sw=4:sts=4:et
