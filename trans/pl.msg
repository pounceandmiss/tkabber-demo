# pl.msg --
#
#       Polish messages for replying to other client queries.
#
# Author: Irek Chmielowiec <irek.ch@gmail.com>

# plugins/general/gpgme.tcl
::trans::trset pl "This message is encrypted." "Ta wiadomość jest\
        zaszyfrowana."

# plugins/general/remote.tcl
::trans::trset pl "Change status" "Zmień status"
::trans::trset pl "Change Status" "Zmiana statusu"
::trans::trset pl "Choose chats or groupchats from which you want to forward\
        messages" "Wybierz rozmowy i konferencje"
::trans::trset pl "Choose groupchats you want to leave" \
        "Wybierz rozmowy i konferencje, które chcesz zamknąć"
::trans::trset pl "Choose status, priority, and status message" \
        "Wybierz status, priorytet i opis statusu"
::trans::trset pl "Forward all messages" "Przekaż wszystkie wiadomości"
::trans::trset pl "Forward messages from" "Przekaż wiadomości od"
::trans::trset pl "Forward unread messages" "Przekaż nieprzeczytane widomości"
::trans::trset pl "Forward Unread Messages" \
        "Przekazywanie nieprzeczytanych wiadomości"
::trans::trset pl "Groupchats" "Konferencje"
::trans::trset pl "Groupchats were left successfully" \
        "Konferencje zostały pomyślnie zamknięte"
::trans::trset pl "Leave all groupchats" "Zamknij wszystkie konferencje"
::trans::trset pl "Leave groupchats" "Zamknij konferencje"
::trans::trset pl "Leave Groupchats" "Zamknięcie konferencji"
::trans::trset pl "Message" "Opis statusu"
::trans::trset pl "No groupchats to leave" "Brak konferencji do zamknięcia"
::trans::trset pl "Priority" "Priorytet"
::trans::trset pl "Reason" "Powód"
::trans::trset pl "Remote control" "Zdalne sterowanie"
::trans::trset pl "%s at %s" "%s w %s"
::trans::trset pl "%s (%s)"
::trans::trset pl "%s: %s chat message(s)" "%s: %s wiadomość(i) w rozmowie"
::trans::trset pl "%s: %s groupchat message(s)" \
        "%s: %s wiadomość(i) w konferencji"
::trans::trset pl "%s: %s headline message(s)" "%s: %s nagłówek(ów) widomości"
::trans::trset pl "%s: %s normal message(s)" "%s: %s zwykła(e) wiadomość(i)"
::trans::trset pl "%s: %s unknown message(s)" \
        "%s: %s wiadomość(i) nieznana(ych)"
::trans::trset pl "Status" "Status"
::trans::trset pl "Status was changed successfully" \
        "Status został pomyślnie zmieniony"
::trans::trset pl "There are no unread messages" \
        "Brak nieprzeczytanych wiadomości"
::trans::trset pl "Unread messages were forwarded successfully" \
        "Nieprzeczytane wiadomości zostały pomyślnie przekazane"
::trans::trset pl "Available" "Dostępny"
::trans::trset pl "Free to chat" "Chętny do rozmowy"
::trans::trset pl "Away" "Zaraz wracam"
::trans::trset pl "Extended away" "Nieobecny"
::trans::trset pl "Do not disturb" "Nie przeszkadzać"
::trans::trset pl "Unavailable" "Rozłączony"

# muc.tcl
::trans::trset pl "Current rooms" "Aktywne konferencje"

# plugins/si/socks5.tcl
::trans::trset pl "Stream ID has not been negotiated" \
        "ID strumienia danych nie zostało wynegocjowane"

# plugins/si/iqibb.tcl
::trans::trset pl "Cannot decode received data" \
        "Nie można zdekodować odebranych danych"
::trans::trset pl "File transfer is aborted" \
        "Transmisja pliku została przerwana"
::trans::trset pl "Unexpected packet sequence number" \
        "Nieoczekiwany numer sekwencyjny pakietu"

# plugins/filetransfer/si.tcl
::trans::trset pl "File transfer is refused" "Odmówiono transmisji pliku"
::trans::trset pl "Stream ID is in use" "ID strumienia jest w użyciu"

# plugins/filetransfer/http.tcl
::trans::trset pl "File not found" "Nie znaleziono pliku"

# plugins/filetransfer/jidlink.tcl
::trans::trset pl "File transfer is failed" "Transmisja pliku nie udała się"
::trans::trset pl "Invalid file ID" "Nieprawidłowe ID pliku"
::trans::trset pl "Transfer is expired" "Transmisja pliku przedawniła się"

# plugins/si/socks5.tcl
::trans::trset pl "Cannot connect to any of the streamhosts" \
        "Nie udało się połączyć z żadnym pośrednikiem strumienia danych"

# vim:ft=tcl:ts=8:sw=4:sts=4:et
