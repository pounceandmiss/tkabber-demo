# config.tcl --
#
#       Sample config file for Tkabber

# login settings
set loginconf(user) aleksey
set loginconf(password) secret
set loginconf(resource) tkabber
set loginconf(server) jabber.ru

# Also instead of above login settings you can setup few different profiles:
#set loginconf1(profile)  "Local test login"
#set loginconf1(user)     test
#set loginconf1(password) test
#set loginconf1(resource) tkabber
#set loginconf1(server)   localhost
#set loginconf2(profile)  "aleksey@jabber.ru"
#set loginconf2(user)     aleksey
#set loginconf2(password) secret
#set loginconf2(resource) tkabber
#set loginconf2(server)   jabber.ru
# And by default use first profile:
#array set loginconf [array get loginconf1]

# For different you can set different default nicks:
#set defaultnick(cool@conference.jabber.org) mY_cOOl_NIcK

# You can choose different set of icons:
#set pixmaps_theme gabber
#set pixmaps_theme psi

# Use this to load X resources
#option readfile $configdir/teopetuk.xrdb userDefault

# Popup balloons on roster and browser can work in two styles: "delay" &
# "follow".
#option add *Balloon.style follow userDefault

# Define 'browseurl' to browse urls with your favorite browser.
# For konqueror:
#proc browseurl {url} {
#    exec konqueror $url &
#}
# For galeon:
#proc browseurl {url} {
#    exec galeon -n $url &
#}

# This function called after loading of tkabber's modules (maybe removed in the
# future)
proc postload {} {
    # To setup your avatar uncomment this:
    #avatar::load_file $configdir/myface.gif

    # If you download some emoticons theme, and untar it e.g. in
    # ~/.tkabber/cool-emoticon-theme, then you can load it as follow:
    #plugins::emoticons::load_dir $configdir/cool-emoticon-theme
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
