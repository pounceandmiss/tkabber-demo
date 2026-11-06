# pl.msg --
#
#       Polish messages for the Tkabber XMPP client.
#
# Author: Irek Chmielowiec <irek(at)chmielowiec.org>
# Contact: xmpp:irek(at)chmielowiec.org

# browser.tcl
::msgcat::mcset pl "%s: %s/%s, Description: %s, Version: %s\nNumber of\
        children: %s" "%s: %s/%s\nOpis: %s\nWersja: %s\nLiczba elementów: %s"
::msgcat::mcset pl "Browse" "Przeglądaj"
::msgcat::mcset pl "JID:" "JID:"
::msgcat::mcset pl "Number of children:" "Ilość elementów:"
::msgcat::mcset pl "Sort" "Sortuj"

# plugins/general/message_archive.tcl
::msgcat::mcset pl "#" "#"
::msgcat::mcset pl "Dir" "<->"
::msgcat::mcset pl "From/To" "Od/Do"
::msgcat::mcset pl "From:" "Od:"
::msgcat::mcset pl "Messages" "Wiadomości"
::msgcat::mcset pl "Received/Sent" "Odebrane/Wysłane"
::msgcat::mcset pl "Subject" "Temat"
::msgcat::mcset pl "Subject:" "Temat:"
::msgcat::mcset pl "To:" "Do:"

# register.tcl
::msgcat::mcset pl "Cancel" "Anuluj"
::msgcat::mcset pl "Change Password for %s" "Zmiana hasła dla %s"
::msgcat::mcset pl "Close" "Zamknij"
::msgcat::mcset pl "Enter the new password for %s" "Wprowadź nowe hasło dla\
        %s"
::msgcat::mcset pl "OK" "OK"
::msgcat::mcset pl "Register" "Zarejestruj"
::msgcat::mcset pl "Register in %s" "Rejestracja w %s"
::msgcat::mcset pl "Registration is successful!" "Rejestracja powiodła się!"
::msgcat::mcset pl "Registration: %s" "Rejestracja: %s"
::msgcat::mcset pl "Unregister" "Wyrejestruj"

# presence.tcl
::msgcat::mcset pl "Available" "Dostępny"
::msgcat::mcset pl "Away" "Zaraz wracam"
::msgcat::mcset pl "Change Presence Priority" "Zmień priorytet statusu"
::msgcat::mcset pl "Do not disturb" "Nie przeszkadzać"
::msgcat::mcset pl "Extended away" "Nieobecny"
::msgcat::mcset pl "Free to chat" "Chętny do rozmowy"
::msgcat::mcset pl "Illegal presence type \"%s\"" "Nieprawidłowy typ statusu\
        \"%s\""
::msgcat::mcset pl "invalid userstatus value " "nieprawidłowy status "
::msgcat::mcset pl "Invalid userstatus value %s" "Nieprawidłowa wartość\
        statusu użytkownika %s"
::msgcat::mcset pl "Invisible" "Niewidoczny"
::msgcat::mcset pl "Not logged in" "Rozłączony"
::msgcat::mcset pl "Stored user priority." "Zapamiętany priorytet\
        użytkownika."
::msgcat::mcset pl "Stored user status." "Zapamiętany status użytkownika."
::msgcat::mcset pl "Stored user text status." "Zapamiętany opis statusu\
        użytkownika."
::msgcat::mcset pl "Unavailable" "Rozłączony"
::msgcat::mcset pl "Unsubscribed from %s" "Subskrypcja od %s anulowana"
::msgcat::mcset pl "You are unsubscribed from %s" "Twoja subskrypcja od %s\
        została anulowana"

# filetransfer.tcl
::msgcat::mcset pl "Browse..." "Przeglądaj..."
::msgcat::mcset pl "Can't open file \"%s\": %s" "Nie można otworzyć pliku\
        \"%s\": %s"
::msgcat::mcset pl "Default directory for downloaded files." "Domyślny\
        katalog dla ściąganych plików."
::msgcat::mcset pl "Default protocol for sending files." "Domyślny protokół\
        wysyłania plików."
::msgcat::mcset pl "Description:" "Opis:"
::msgcat::mcset pl "File Transfer options." "Ustawienia przesyłania plików."
::msgcat::mcset pl "IP address:" "Nazwa lub adres IP:"
::msgcat::mcset pl "Name:" "Nazwa:"
::msgcat::mcset pl "Protocol:" "Protokół:"
::msgcat::mcset pl "Receive" "Odbierz"
::msgcat::mcset pl "Receive file from %s" "Odbierz plik od %s"
::msgcat::mcset pl "Request failed: %s" "Wywołanie nie powiodło się: %s"
::msgcat::mcset pl "Save as:" "Zapisz jako:"
::msgcat::mcset pl "Send" "Wyślij"
::msgcat::mcset pl "Send file to %s" "Wyślij plik do %s"
::msgcat::mcset pl "Size:" "Rozmiar:"
::msgcat::mcset pl "Transferring..." "Przesyłanie..."
::msgcat::mcset pl "unknown" "nieznany"
::msgcat::mcset pl "URL:" "URL:"

# default.tcl
::msgcat::mcset pl "Error displaying %s in browser\n\n%s" "Wystąpił błąd\
        podczas otwierania %s w przeglądarce\n\n%s"
::msgcat::mcset pl "Please define environment variable BROWSER" "Należy\
        ustawić zmienną systemową BROWSER"

# plugins/general/ispell.tcl
::msgcat::mcset pl "- nothing -" "- nic -"
::msgcat::mcset pl "Check spell after every entered symbol." "Sprawdzaj\
        pisownię po każdym wprowadzonym znaku."
::msgcat::mcset pl "Could not start ispell server. Check your ispell path and\
        dictionary name. Ispell is disabled now" "Nie udało się wystartować\
        programu ispell. Sprawdź ścieżkę do programu i nazwę słownika. Ispell\
        jest w tej chwili wyłączony"
::msgcat::mcset pl "Enable spellchecker in text input windows." "Włącz\
        sprawdzanie pisowni w oknach gdzie wpisuje się tekst."
::msgcat::mcset pl "Ispell dictionary encoding. If it is empty, system\
        encoding is used." "Kodowanie słownika ispell. Jeżeli niewypełnione,\
        użyte zostaną ustawienia systemu."
::msgcat::mcset pl "Ispell options. See ispell manual for\
        details.\n\nExamples:\n  -d russian\n  -d german -T latin1\n  -C -d\
        english" "Parametry programu ispell. Dokładny opis znajduje się w\
        dokumentacji programu. \n\nPrzykłady:\n  -d russian\n  -d german -T\
        latin1\n  -C -d english"
::msgcat::mcset pl "Path to the ispell executable." "Ścieżka do programu\
        ispell."
::msgcat::mcset pl "Plugins options." "Ustawienia wtyczek."
::msgcat::mcset pl "Spell check options." "Ustawienia sprawdzania pisowni."

# plugins/chat/events.tcl
::msgcat::mcset pl "%s is composing a reply" "%s pisze odpowiedź"
::msgcat::mcset pl "Chat message events plugin options." "Ustawienia wtyczki\
        zdarzeń wiadomości."
::msgcat::mcset pl "Composing a reply" "Pisze odpowiedź"
::msgcat::mcset pl "Enable sending chat message events." "Włącz wysyłanie\
        zdarzeń wiadomości w rozmowach."
::msgcat::mcset pl "Message delivered" "Wiadomość dostarczona"
::msgcat::mcset pl "Message delivered to %s" "Wiadomość dostarczona do %s"
::msgcat::mcset pl "Message displayed" "Wiadomość przeczytana"
::msgcat::mcset pl "Message displayed to %s" "%s przeczytał(a) wiadomość"
::msgcat::mcset pl "Message stored on %s's server" "Wiadomość zapamiętana na\
        serwerze %s"
::msgcat::mcset pl "Message stored on the server" "Wiadomość zapamiętana na\
        serwerze"

# plugins/chat/chatstate.tcl
::msgcat::mcset pl "%s has activated chat window" "%s aktywował okno rozmowy"
::msgcat::mcset pl "%s has gone chat window" "%s wyłączył okno rozmowy"
::msgcat::mcset pl "%s has inactivated chat window" "%s deaktywował okno\
        rozmowy"
::msgcat::mcset pl "%s is paused a reply" "%s wstrzymał odpowiedź"
::msgcat::mcset pl "Chat message window state plugin options." "Ustawienia\
        wtyczki stanu okna rozmowy."
::msgcat::mcset pl "Chat window is active" "Okno rozmowy jest aktywne"
::msgcat::mcset pl "Chat window is gone" "Okno rozmowy jest wyłączone"
::msgcat::mcset pl "Chat window is inactive" "Okno rozmowy jest nieaktywne"
::msgcat::mcset pl "Enable sending chat state notifications." "Włącz\
        wysyłanie powiadomień o stanie okna rozmowy."
::msgcat::mcset pl "Paused a reply" "Wstrzymanie odpowiedzi"

# search.tcl
::msgcat::mcset pl "An error occurred when searching in %s\n\n%s" "Wystąpił\
        błąd podczas wyszukiwania w %s\n\n%s"
::msgcat::mcset pl "Invite to conference..." "Zaproś do konferencji..."
::msgcat::mcset pl "Search" "Szukaj"
::msgcat::mcset pl "Search again" "Szukaj ponownie"
::msgcat::mcset pl "Search in %s" "Wyszukiwanie w %s"
::msgcat::mcset pl "Search in %s: No matching items found" "Wyszukiwanie w\
        %s: Nie znaleziono pasujących elementów"
::msgcat::mcset pl "Search: %s" "Wyszukiwanie: %s"
::msgcat::mcset pl "Send file..." "Wyślij plik..."
::msgcat::mcset pl "Send message..." "Wyślij wiadomość..."
::msgcat::mcset pl "Send users..." "Wyślij kontakty..."
::msgcat::mcset pl "Show history" "Historia wiadomości"
::msgcat::mcset pl "Show info" "Pokaż wizytówkę"
::msgcat::mcset pl "Start chat" "Rozmowa"
::msgcat::mcset pl "Try again" "Ponów"

# privacy.tcl
::msgcat::mcset pl "Activate visible/invisible/ignore/conference lists before\
        sending initial presence." "Aktywuj listy\
        widoczności/niewidoczności/ignorowania/konferecji przed wysłaniem\
        początkowego statusu."
::msgcat::mcset pl "Activating privacy list failed: %s\n\nTry to reconnect.\
        If problem persists, you may want to disable privacy list activation\
        at start" "Aktywacja listy zasad prywatności nie powiodła się:\
        %s\n\nSpróbuj połączyć się ponownie. Jeżeli problem będzie nadal\
        występował, być może konieczne będzie wyłączenie aktywacji list przy\
        starcie programu"
::msgcat::mcset pl "Active" "Aktywna"
::msgcat::mcset pl "Add item" "Dodaj regułę"
::msgcat::mcset pl "Add JID" "Dodaj JID"
::msgcat::mcset pl "Add list" "Dodaj listę"
::msgcat::mcset pl "Blocking communication (XMPP privacy lists) options."\
        "Ustawienia blokady komunikacji (listy zasad prywatności XMPP)."
::msgcat::mcset pl "Blocking communication options." "Ustawienia ochrony\
        prywatności."
::msgcat::mcset pl "Changing accept messages from roster only: %s" "Zmiana\
        akceptowania wiadomości tylko od osób z listy kontaktów: %s"
::msgcat::mcset pl "Creating default privacy list" "Tworzenie domyślnej listy\
        zasad prywatności"
::msgcat::mcset pl "Creating default privacy list failed: %s\n\nTry to\
        reconnect. If problem persists, you may want to disable privacy list\
        activation at start" "Tworzenie domyślnej listy zasad prywatności nie\
        powiodło się: %s\n\nSpróbuj połączyć się ponownie. Jeżeli problem\
        będzie nadal występował, być może konieczne będzie wyłączenie\
        aktywacji list przy starcie programu"
::msgcat::mcset pl "Default" "Domyślna"
::msgcat::mcset pl "Down" "Niżej"
::msgcat::mcset pl "Edit conference list" "Edytuj listę konferencji"
::msgcat::mcset pl "Edit ignore list" "Edycja listy ignorowanych"
::msgcat::mcset pl "Edit invisible list" "Edycja listy niewidoczności"
::msgcat::mcset pl "Edit list" "Edytuj listę"
::msgcat::mcset pl "Edit privacy list" "Edycja list z zasadami ochrony\
        prywatności"
::msgcat::mcset pl "Ignore list" "Lista ignorowanych"
::msgcat::mcset pl "Invisible list" "Lista niewidoczności"
::msgcat::mcset pl "IQ" "IQ"
::msgcat::mcset pl "List name" "Nazwa listy"
::msgcat::mcset pl "Name: " "Nazwa: "
::msgcat::mcset pl "No active list" "Brak aktywnej listy"
::msgcat::mcset pl "No default list" "Brak domyślnej listy"
::msgcat::mcset pl "Presence-in" "Status-przych."
::msgcat::mcset pl "Presence-out" "Status-wych."
::msgcat::mcset pl "Privacy list is activated" "Lista zasad ochrony\
        prywatności aktywna"
::msgcat::mcset pl "Privacy list is not activated" "Lista zasad ochrony\
        prywatności nieaktywna"
::msgcat::mcset pl "Privacy list is not created" "Lista zasad prywatności nie\
        została utworzona"
::msgcat::mcset pl "Privacy lists" "Listy zasad ochrony prywatności"
::msgcat::mcset pl "Privacy lists are not implemented" "Listy zasad\
        prywatności nie są zaimplementowane"
::msgcat::mcset pl "Privacy lists are unavailable" "Listy zasad prywatności\
        są niedostępne"
::msgcat::mcset pl "Privacy lists error" "Błąd list zasad prywatności"
::msgcat::mcset pl "Remove" "Usuń"
::msgcat::mcset pl "Remove from list" "Usuń z listy"
::msgcat::mcset pl "Remove list" "Usuń listę"
::msgcat::mcset pl "Requesting conference list: %s" "Pobieranie listy\
        konferecji: %s"
::msgcat::mcset pl "Requesting ignore list: %s" "Pobieranie listy\
        ignorowanych: %s"
::msgcat::mcset pl "Requesting invisible list: %s" "Pobieranie listy\
        niewidoczności: %s"
::msgcat::mcset pl "Requesting privacy list: %s" "Pobieranie listy zasad: %s"
::msgcat::mcset pl "Requesting privacy rules: %s" "Pobieranie listy zasad z\
        serwera: %s"
::msgcat::mcset pl "Requesting visible list: %s" "Pobieranie listy\
        widoczności: %s"
::msgcat::mcset pl "Sending conference list: %s" "Wysyłanie listy\
        konferencji: %s"
::msgcat::mcset pl "Sending ignore list: %s" "Wysyłanie listy ignorowanych:\
        %s"
::msgcat::mcset pl "Sending invisible list: %s" "Wysyłanie listy\
        niewidoczności: %s"
::msgcat::mcset pl "Sending visible list: %s" "Wysyłanie listy widoczności:\
        %s"
::msgcat::mcset pl "Type" "Typ"
::msgcat::mcset pl "Up" "Wyżej"
::msgcat::mcset pl "Visible list" "Lista widoczności"
::msgcat::mcset pl "Waiting for activating privacy list" "Oczekiwanie na\
        aktywację listy z zasadami ochrony prywatności"

# plugins/chat/draw_xhtml_message.tcl
::msgcat::mcset pl "Enable rendering of XHTML messages." "Włącz obsługę XHTML\
        w wiadomościach."

# plugins/chat/draw_timestamp.tcl
::msgcat::mcset pl "Format of timestamp in chat message. Refer to Tcl\
        documentation of 'clock' command for description of\
        format.\n\nExamples:\n  \[%R\] - \[20:37\]\n  \[%T\] - \[20:37:12\]\n \
        \[%a %b %d %H:%M:%S %Z %Y\] - \[Thu Jan 01 03:00:00 MSK 1970\]"\
        "Format czasu i daty w wiadomościach. Dokładny opis formatu w\
        dokumentacji Tcl dla polecenia 'clock'.\n\nPrzykłady:\n  \[%R\] –\
        \[20:37\]\n  \[%T\] – \[20:37:12\]\n  \[%a %b %d %H:%M:%S %Z %Y\] –\
        \[Wto Sty 01 03:00:00 CET 1970\]"
::msgcat::mcset pl "Format of timestamp in delayed chat messages delayed for\
        more than 24 hours." "Format czasu i daty w wiadomościach\
        dostarczonych z opóźnieniem większym niż 24 godziny."

# roster.tcl
::msgcat::mcset pl "Active Chats" "Aktywne rozmowy"
::msgcat::mcset pl "Add chats group in roster." "Pokaż grupę 'Aktywne\
        rozmowy' z listą aktualnie prowadzonych rozmów i konferencji."
::msgcat::mcset pl "Add conference..." "Dodaj konferencję..."
::msgcat::mcset pl "Add group by regexp on JIDs..." "Dodaj grupę wg\
        wyrażenia"
::msgcat::mcset pl "Add roster group by JID regexp" "Grupa wg wyrażenia\
        regularnego dla JID-ów"
::msgcat::mcset pl "All Files" "Wszystkie pliki"
::msgcat::mcset pl "Are you sure to remove %s from roster?" "Czy na pewno\
        chcesz usunąć %s ze swojej listy?"
::msgcat::mcset pl "Contact Information" "Wizytówka użytkownika"
::msgcat::mcset pl "doesn't want to be disturbed" "ma status Nie\
        przeszkadzać"
::msgcat::mcset pl "Edit item..." "Edytuj kontakt..."
::msgcat::mcset pl "Edit security..." "Ustawienia zabezpieczeń..."
::msgcat::mcset pl "Export roster..." "Eksportuj listę..."
::msgcat::mcset pl "Import roster..." "Importuj listę..."
::msgcat::mcset pl "is available" "ma status Dostępny"
::msgcat::mcset pl "is away" "ma status Zaraz wracam"
::msgcat::mcset pl "is extended away" "ma status Nieobecny"
::msgcat::mcset pl "is free to chat" "ma status Chętny do rozmowy"
::msgcat::mcset pl "is invisible" "ma status Niewidoczny"
::msgcat::mcset pl "is unavailable" "ma status Rozłączony"
::msgcat::mcset pl "JID regexp:" "Wyrażenie regularne:"
::msgcat::mcset pl "Join..." "Dołącz do..."
::msgcat::mcset pl "Log in" "Zaloguj..."
::msgcat::mcset pl "Log out" "Wyloguj..."
::msgcat::mcset pl "New group name:" "Nazwa nowej grupy:"
::msgcat::mcset pl "No users in roster..." "Brak użytkowników na liście..."
::msgcat::mcset pl "Rename roster group" "Zmień nazwę grupy"
::msgcat::mcset pl "Resubscribe to all users in group..." "Poproś ponownie o\
        subskrypcję od wszystkich w grupie..."
::msgcat::mcset pl "Roster" "Lista kontaktów"
::msgcat::mcset pl "Roster Files" "Pliki listy kontaktów"
::msgcat::mcset pl "Roster item may be dropped not only over group name but\
        also over any item in group." "Elementy listy przenoszone metodą\
        drag&drop mogą być upuszczone nie tylko na pozycję z nazwą grupy, ale\
        także na każdy inny element tej grupy."
::msgcat::mcset pl "Roster of %s" "Lista kontaktów dla %s"
::msgcat::mcset pl "Roster options." "Ustawienia listy kontaktów."
::msgcat::mcset pl "Send contacts to" "Wyślij kontakty do"
::msgcat::mcset pl "Send contacts to %s" "Wyślij kontakty do %s"
::msgcat::mcset pl "Send custom presence" "Wyślij status"
::msgcat::mcset pl "Show detailed info on conference room members in roster\
        item tooltips." "Pokaż szczegółowe informacje w dymku podpowiedzi dla\
        aktywnej konferencji, o użytkownikach biorących w niej udział."
::msgcat::mcset pl "Show native icons for contacts, connected to\
        transports/services in roster." "Pokaż własne ikony kontaktów,\
        połączonych przez transporty/agenty."
::msgcat::mcset pl "Show native icons for transports/services in roster."\
        "Pokaż własne ikony transportów/agentów."
::msgcat::mcset pl "Show offline users" "Pokaż użytkowników rozłączonych"
::msgcat::mcset pl "Show online users only" "Pokaż tylko użytkowników\
        dostępnych"
::msgcat::mcset pl "Show only online users in roster." "Pokaż tylko\
        użytkowników dostępnych."
::msgcat::mcset pl "Show subscription type in roster item tooltips." "Pokaż\
        typ subskrybcji w dymku podpowiedzi dla kontaktu."
::msgcat::mcset pl "Undefined" "Niezdefiniowane"
::msgcat::mcset pl "Use aliases to show multiple users in one roster item."\
        "Używaj aliasów do łączenia wielu kontaktów w jedną pozycję na liście\
        (metakontakty)."

# plugins/chat/clear.tcl
::msgcat::mcset pl "Clear chat window" "Wyczyść okno rozmów"

# gpgme.tcl
::msgcat::mcset pl "%s purportedly signed by %s can't be verified.\n\n%s."\
        "%s podpisany przez %s nie może być zweryfikowany.\n\n%s."
::msgcat::mcset pl "%s purportedly signed by %s can't be verified: %s." "%s\
        rzekomo podpisana przez %s nie może zostać zweryfikowana: %s."
::msgcat::mcset pl "Change security preferences for %s" "Zmień ustawienia\
        zabezpieczeń dla %s"
::msgcat::mcset pl "Data purportedly sent by %s can't be deciphered.\n\n%s."\
        "Dane wysłane przez %s nie mogą być odszyfrowane.\n\n%s."
::msgcat::mcset pl "Display warning dialogs when signature verification\
        fails." "Pokazuj okno z ostrzeżeniem gdy nie powiedzie się\
        weryfikacja podpisu."
::msgcat::mcset pl "Encrypt traffic" "Szyfruj wiadomości"
::msgcat::mcset pl "Encrypt traffic (when possible)" "Szyfruj wiadomości\
        (kiedy możliwe)"
::msgcat::mcset pl "Encryption" "Szyfrowanie"
::msgcat::mcset pl "Error in signature processing" "Błąd podczas weryfikacji\
        podpisu"
::msgcat::mcset pl "Error in signature verification software: %s." "Błąd\
        programu weryfikującego podpis: %s."
::msgcat::mcset pl "Fetch GPG key" "Pobierz klucz GPG z serwera kluczy"
::msgcat::mcset pl "GPG error" "Błąd GPG"
::msgcat::mcset pl "GPG options (signing and encryption)." "Ustwienia GPG\
        (podpisywanie i szyfrowanie wiadomości)."
::msgcat::mcset pl "GPG-encrypt outgoing messages where possible." "Szyfruj\
        za pomocą GPG wychodzące wiadomości jeżeli to możliwe."
::msgcat::mcset pl "GPG-sign outgoing messages and presence updates."\
        "Podpisz za pomocą GPG wychodzące wiadomości i zmiany statusu."
::msgcat::mcset pl "Invalid signature" "Niepoprawny podpis"
::msgcat::mcset pl "Key ID" "ID klucza"
::msgcat::mcset pl "Malformed signature block" "Wadliwy blok podpisu"
::msgcat::mcset pl "Multiple signatures having different authenticity" "Wiele\
        podpisów mających różną wiarygodność"
::msgcat::mcset pl "No information available" "Brak informacji"
::msgcat::mcset pl "Passphrase:" "Hasło:"
::msgcat::mcset pl "Please enter passphrase" "Wprowadź hasło do klucza"
::msgcat::mcset pl "Please try again" "Spróbuj jeszcze raz"
::msgcat::mcset pl "Presence information" "Informacje o statusie"
::msgcat::mcset pl "Select" "Wybierz"
::msgcat::mcset pl "Select Key for Signing %s Traffic" "Wybierz klucz do\
        podpisywania wiadomości od %s"
::msgcat::mcset pl "Sign traffic" "Podpisuj wiadomości"
::msgcat::mcset pl "Signature not processed due to missing key" "Podpis nie\
        został zweryfikowany z powodu braku klucza"
::msgcat::mcset pl "The signature is good but has expired" "Podpis jest\
        prawidłowy ale uległ przedawnieniu"
::msgcat::mcset pl "The signature is good but the key has expired" "Podpis\
        jest prawidłowy ale klucz podpisujący uległ przedawnieniu"
::msgcat::mcset pl "Unable to encipher data for %s: %s.\n\nEncrypting traffic\
        to this user is now disabled.\n\nSend it as PLAINTEXT?" "Nie można\
        zaszyfrować danych dla %s: %s.\n\nSzyfrowanie wiadomości do tego\
        użytkownika jest wyłączone.\n\nCzy chcesz wysłać wiadomość jako\
        ZWYKŁY TEKST?"
::msgcat::mcset pl "Unable to sign message body: %s.\n\nSigning traffic is\
        now disabled.\n\nSend it WITHOUT a signature?" "Nie można podpisać\
        treści: %s.\n\nPodpisywanie wiadmości jest wyłączone.\n\nCzy chcesz\
        wysłać BEZ podpisu?"
::msgcat::mcset pl "Unable to sign presence information: %s.\n\nPresence will\
        be sent, but signing traffic is now disabled." "Nie można podpisać\
        statusu widoczności: %s.\n\nStatus zostanie wysłany, ale podpisywanie\
        wiadmości jest wyłączone."
::msgcat::mcset pl "Use specified key ID for signing and decrypting\
        messages." "Podaj ID klucza do podpisywania i odszyfrowania\
        wiadomości."
::msgcat::mcset pl "Use the same passphrase for signing and decrypting\
        messages." "Używaj tego samego hasła do podpisywania i odszyfrowania\
        wiadomości."
::msgcat::mcset pl "User ID" "ID użytkownika"

# roster_nested.tcl
::msgcat::mcset pl "Default nested roster group delimiter." "Domyślny\
        separator dla wielopoziomowych grup."
::msgcat::mcset pl "Enable nested roster groups." "Włącz wielopoziomowe grupy\
        na liście kontaktów."

# login.tcl
::msgcat::mcset pl ". Proceed?\n\n" ". Kontynuować?\n\n"
::msgcat::mcset pl "Account" "Konto"
::msgcat::mcset pl "Allow plaintext authentication mechanisms (when password\
        is transmitted unencrypted)." "Włącz mechanizmy uwierzytelniania\
        zwykłym tekstem (hasło jest wysyłane niezaszyfrowane)."
::msgcat::mcset pl "Authentication failed: %s" "Uwierzytelnianie nie powiodło\
        się: %s"
::msgcat::mcset pl "Authentication failed: %s\nCreate new account?"\
        "Uwierzytelnianie nie powiodło się: %s\nCzy chcesz zarejestrować nowe\
        konto?"
::msgcat::mcset pl "Certificate has expired" "Certyfikat stracił ważność"
::msgcat::mcset pl "Change password" "Zmiana hasła"
::msgcat::mcset pl "Connect via HTTP polling" "Połącz przez sewrer HTTP"
::msgcat::mcset pl "Connecting to %s" "Łączenie z %s"
::msgcat::mcset pl "Connection" "Połączenie"
::msgcat::mcset pl "Display SSL warnings." "Wyświetlaj ostrzeżenia SSL/TLS."
::msgcat::mcset pl "Failed to connect: %s" "Połączenie nie udało się: %s"
::msgcat::mcset pl "Forced logout" "Wymuszone wylogowanie"
::msgcat::mcset pl "HTTP Poll" "HTTP poll"
::msgcat::mcset pl "HTTP proxy address." "Adres proxy HTTP."
::msgcat::mcset pl "HTTP proxy password." "Hasło użytkownika proxy HTTP."
::msgcat::mcset pl "HTTP proxy port." "Port proxy HTTP."
::msgcat::mcset pl "HTTP proxy username." "Nazwa użytkownika proxy HTTP."
::msgcat::mcset pl "HTTPS" "HTTPS"
::msgcat::mcset pl "Keep trying" "Ponów próbę"
::msgcat::mcset pl "List of logout reasons." "Lista opisów wylogowania."
::msgcat::mcset pl "Login" "Zaloguj"
::msgcat::mcset pl "Login is successful" "Zalogowanie powiodło się"
::msgcat::mcset pl "Login log" "Dziennik połączeń"
::msgcat::mcset pl "Login options." "Ustawienia logowania."
::msgcat::mcset pl "Logout" "Wyloguj"
::msgcat::mcset pl "Logout with reason" "Wyloguj z opisem"
::msgcat::mcset pl "Maximum poll interval." "Maksymalny odstęp czasu dla\
        odwołań HTTP poll."
::msgcat::mcset pl "Minimum poll interval." "Minimalny odstęp czasu dla\
        odwołań HTTP poll."
::msgcat::mcset pl "New password:" "Nowe hasło:"
::msgcat::mcset pl "New passwords do not match" "Nowe hasła nie pasują"
::msgcat::mcset pl "Number of HTTP poll client security keys to send before\
        creating new key sequence." "Ilość kluczy klienta wysyłanych przed\
        utworzeniem nowej serii kluczy."
::msgcat::mcset pl "Old password is incorrect" "Stare hasło nie zgadza się"
::msgcat::mcset pl "Old password:" "Stare hasło:"
::msgcat::mcset pl "Password change failed: %s" "Zmiana hasła nie udała się:\
        %s"
::msgcat::mcset pl "Password is changed" "Hasło zostało zmienione"
::msgcat::mcset pl "Password." "Hasło."
::msgcat::mcset pl "Password:" "Hasło:"
::msgcat::mcset pl "Port:" "Port:"
::msgcat::mcset pl "Priority." "Priorytet."
::msgcat::mcset pl "Priority:" "Priorytet:"
::msgcat::mcset pl "Profile" "Profil"
::msgcat::mcset pl "Profiles" "Profile"
::msgcat::mcset pl "Proxy" "Proxy"
::msgcat::mcset pl "Proxy Login:" "Użytkownik proxy:"
::msgcat::mcset pl "Proxy Password:" "Hasło proxy:"
::msgcat::mcset pl "Proxy Port:" "Port proxy:"
::msgcat::mcset pl "Proxy Server:" "Adres serwera proxy:"
::msgcat::mcset pl "Proxy type to connect." "Typ serwera proxy."
::msgcat::mcset pl "Reason:" "Opis:"
::msgcat::mcset pl "Registration failed: %s" "Rejestracja nie udała się: %s"
::msgcat::mcset pl "Repeat new password:" "Powtórz nowe hasło:"
::msgcat::mcset pl "Replace opened connections" "Zastąp otwarte połączenia"
::msgcat::mcset pl "Replace opened connections." "Zastąp otwarte połączenia."
::msgcat::mcset pl "Resource." "Zasób."
::msgcat::mcset pl "Resource:" "Zasób:"
::msgcat::mcset pl "Retry to connect forever." "Ponawiaj próby połączena w\
        nieskończoność."
::msgcat::mcset pl "Self signed certificate" "Certyfikat typu self-signed"
::msgcat::mcset pl "Server name or IP-address." "Nazwa alternatywnego serwera\
        lub jego adres IP"
::msgcat::mcset pl "Server name." "Serwer."
::msgcat::mcset pl "Server port." "Port serwera."
::msgcat::mcset pl "Server:" "Serwer:"
::msgcat::mcset pl "SOCKS4a" "SOCKS4a"
::msgcat::mcset pl "SOCKS5" "SOCKS5"
::msgcat::mcset pl "SSL" "SSL"
::msgcat::mcset pl "SSL certificate file (optional)." "Plik certyfikatu SSL\
        (opcjonalnie)."
::msgcat::mcset pl "SSL Certificate:" "Certyfikat SSL:"
::msgcat::mcset pl "SSL certification authority file or directory\
        (optional)." "Katalog lub plik urzędu certyfikującego SSL\
        (opcjonalnie)."
::msgcat::mcset pl "SSL private key file (optional)." "Plik z kluczem\
        prywatnym SSL (opcjonalnie)."
::msgcat::mcset pl "Starting login" "Rozpoczęto logowanie"
::msgcat::mcset pl "Timeout" "Przekroczono czas oczekiwania"
::msgcat::mcset pl "Timeout for waiting for HTTP poll responses (if set to\
        zero, Tkabber will wait forever)." "Czas oczekiwania na odpowiedzi\
        HTTP poll (0 oznacza czekanie w nieskończoność)."
::msgcat::mcset pl "URL to connect to." "URL połączenia."
::msgcat::mcset pl "URL to poll:" "URL połączenia:"
::msgcat::mcset pl "Use client security keys" "Używaj kluczy klienta"
::msgcat::mcset pl "Use explicitly-specified server address and port."\
        "Ręczne ustawienie portu i nazwy serwera do połączenia."
::msgcat::mcset pl "Use HTTP poll client security keys (recommended)."\
        "Używaj kluczy klienta przy połączeniu typu HTTP poll (zalecane)."
::msgcat::mcset pl "Use HTTP poll connection method." "Użyj pasywnego\
        połączenia przez serwer HTTP (polling)."
::msgcat::mcset pl "Use Proxy" "Użyj serwera proxy"
::msgcat::mcset pl "Use SASL authentication." "Włącz uwierzytelnianie SASL."
::msgcat::mcset pl "User name." "Użytkownik."
::msgcat::mcset pl "User-Agent string." "Identyfikator przeglądarki\
        (User-Agent)."
::msgcat::mcset pl "Username:" "Użytkownik:"
::msgcat::mcset pl "Warning display options." "Ustawienia wyświetlania\
        ostrzeżeń."
::msgcat::mcset pl "XMPP stream options when connecting to server." "Opcje\
        strumienia XMPP przy połączeniu z serwerem."

# plugins/unix/wmdock.tcl
::msgcat::mcset pl "%s is %s" "%s - %s"
::msgcat::mcset pl "%s msgs" "%s wiad"
::msgcat::mcset pl "Message from %s" "Wiadomość od %s"

# plugins/unix/systray.tcl
::msgcat::mcset pl "Enable freedesktop systray icon." "Włącz obsługę ikony\
        zasobnika freedesktop."

# plugins/unix/tktray.tcl
::msgcat::mcset pl "Enable freedesktop system tray icon." "Włącz obsługę\
        ikony zasobnika freedesktop."

# plugins/general/autoaway.tcl
::msgcat::mcset pl "Automatically away due to idle" "Automatyczny status\
        'Zaraz wracam' z powodu bezczynności"
::msgcat::mcset pl "Idle for %s" "Bezczynny przez %s"
::msgcat::mcset pl "Idle threshold in minutes after that Tkabber marks you as\
        away." "Odstęp czasu w minutach, po którym Tkabber ustawi status\
        'Zaraz wracam'."
::msgcat::mcset pl "Idle threshold in minutes after that Tkabber marks you as\
        extended away." "Odstęp czasu w minutach, po którym Tkabber ustawi\
        status 'Nieobecny'."
::msgcat::mcset pl "Moving to extended away" "Zmiana autostatusu na\
        'Nieobecny'"
::msgcat::mcset pl "Options for module that automatically marks you as away\
        after idle threshold." "Ustawienia modułu, który automatycznie\
        ustawia status nieobecności po określonym czasie bezczynności."
::msgcat::mcset pl "Returning from auto-away" "Wyłączanie autostatusu 'Zaraz\
        wracam'"
::msgcat::mcset pl "Set priority to 0 when moving to extended away state."\
        "Ustaw priorytet na 0 przy przejściu do statusu 'Nieobecny'."
::msgcat::mcset pl "Starting auto-away" "Włączanie autostausu 'Zaraz wracam'"
::msgcat::mcset pl "Text status, which is set when Tkabber is moving to away\
        state." "Opis statusu, który będzie ustawiony po przejściu w stan\
        'Zaraz wracam'."

# plugins/general/clientinfo.tcl
::msgcat::mcset pl "\n\tClient: %s" "\n\tKlient: %s"
::msgcat::mcset pl "\n\tName: %s" "\n\tNazwa: %s"
::msgcat::mcset pl "\n\tOS: %s" "\n\tSystem: %s"
::msgcat::mcset pl "Options for Client Info module, which allows you to\
        automatically retrieve client names and versions for contacts in your\
        roster." "Ustawienia modułu Informacji o Kliencie, który pozwala na\
        automatyczne pobieranie nazw i wersji klientów używanych przez\
        użytkowników z listy kontaktów."

# userinfo.tcl
::msgcat::mcset pl " by " " przez "
::msgcat::mcset pl "%s info" "Wizytówka dla %s"
::msgcat::mcset pl "About " "Dodatkowe "
::msgcat::mcset pl "Address" "Adres"
::msgcat::mcset pl "Address 2:" "Adres 2:"
::msgcat::mcset pl "Address:" "Adres:"
::msgcat::mcset pl "All files" "Wszystkie pliki"
::msgcat::mcset pl "Avatar" "Awatar"
::msgcat::mcset pl "BBS:" "BBS:"
::msgcat::mcset pl "Birthday" "Urodziny"
::msgcat::mcset pl "Birthday:" "Data urodzin:"
::msgcat::mcset pl "Cell:" "Komórkowy:"
::msgcat::mcset pl "City:" "Miasto:"
::msgcat::mcset pl "Client" "Program"
::msgcat::mcset pl "Client:" "Nazwa:"
::msgcat::mcset pl "Country:" "Państwo:"
::msgcat::mcset pl "Day:" "Dzień:"
::msgcat::mcset pl "Description:" "Opis:"
::msgcat::mcset pl "Details" "Szczegóły"
::msgcat::mcset pl "E-mail:" "E-mail:"
::msgcat::mcset pl "Family name:" "Nazwisko:"
::msgcat::mcset pl "Fax:" "Fax:"
::msgcat::mcset pl "Full name:" "Pełna nazwa:"
::msgcat::mcset pl "Geographical position" "Położenie geograficzne"
::msgcat::mcset pl "GIF images" "Obrazy GIF"
::msgcat::mcset pl "Home:" "Domowy:"
::msgcat::mcset pl "Image" "Obraz"
::msgcat::mcset pl "Information" "Informacje"
::msgcat::mcset pl "Interval:" "Odstęp czasu:"
::msgcat::mcset pl "ISDN:" "ISDN:"
::msgcat::mcset pl "JPEG images" "Obrazy JPEG"
::msgcat::mcset pl "Last activity" "Ostatnia aktywność"
::msgcat::mcset pl "Last activity or uptime" "Ostatnia aktywność lub czas od\
        uruchomienia"
::msgcat::mcset pl "Latitude:" "Szerokość:"
::msgcat::mcset pl "List of users for userinfo." "Lista użytkowników."
::msgcat::mcset pl "Load image" "Ładuj obraz"
::msgcat::mcset pl "Loading photo failed: %s." "Nie udało się wczytać\
        zdjęcia: %s."
::msgcat::mcset pl "Location" "Miejsce zamieszkania"
::msgcat::mcset pl "Longitude:" "Długość:"
::msgcat::mcset pl "Message recorder:" "Aut. sekretarka:"
::msgcat::mcset pl "Middle name:" "Drugie imię:"
::msgcat::mcset pl "Modem:" "Modem:"
::msgcat::mcset pl "Month:" "Miesiąc:"
::msgcat::mcset pl "Name" "Dane osobowe"
::msgcat::mcset pl "Name:" "Imię:"
::msgcat::mcset pl "Name: " "Nazwa:"
::msgcat::mcset pl "Nickname:" "Pseudonim:"
::msgcat::mcset pl "None" "Wyłącz"
::msgcat::mcset pl "Organization" "Organizacja"
::msgcat::mcset pl "OS:" "System:"
::msgcat::mcset pl "Pager:" "Pager:"
::msgcat::mcset pl "PCS:" "PCS:"
::msgcat::mcset pl "Personal" "Osobiste"
::msgcat::mcset pl "Personal " "Osobiste "
::msgcat::mcset pl "Phones" "Telefony"
::msgcat::mcset pl "Photo" "Zdjęcie"
::msgcat::mcset pl "PNG images" "Obrazy PNG"
::msgcat::mcset pl "Postal Code:" "Kod pocztowy:"
::msgcat::mcset pl "Preferred:" "Preferowany:"
::msgcat::mcset pl "Prefix:" "Prefiks:"
::msgcat::mcset pl "Presence is signed" "Status podpisany"
::msgcat::mcset pl "Role:" "Stanowisko:"
::msgcat::mcset pl "Service info" "Wizytówka"
::msgcat::mcset pl "Show" "Pokaż"
::msgcat::mcset pl "Show user or service info" "Pokaż wizytówkę użytkownika,\
        usługi"
::msgcat::mcset pl "State:" "Województwo:"
::msgcat::mcset pl "Suffix:" "Sufiks:"
::msgcat::mcset pl "Telephone numbers" "Numery telefonów"
::msgcat::mcset pl "Time" "Czas"
::msgcat::mcset pl "Time zone:" "Strefa cz.:"
::msgcat::mcset pl "Time:" "Czas:"
::msgcat::mcset pl "Title:" "Tytuł:"
::msgcat::mcset pl "UID:" "UID:"
::msgcat::mcset pl "Unit:" "Jednostka:"
::msgcat::mcset pl "Update" "Aktualizuj"
::msgcat::mcset pl "Uptime" "Ostatnia aktywność/czas działania"
::msgcat::mcset pl "URL" "URL"
::msgcat::mcset pl "User info" "Informacje o użytkowniku"
::msgcat::mcset pl "UTC:" "UTC:"
::msgcat::mcset pl "Version" "Wersja"
::msgcat::mcset pl "Version:" "Wersja:"
::msgcat::mcset pl "Video:" "Video:"
::msgcat::mcset pl "Voice:" "Voice:"
::msgcat::mcset pl "Web site:" "Strona domowa:"
::msgcat::mcset pl "Work:" "Praca:"
::msgcat::mcset pl "Year:" "Rok:"

# datagathering.tcl
::msgcat::mcset pl "Data form" "Konfiguracja/dane"
::msgcat::mcset pl "Date:" "Data:"
::msgcat::mcset pl "Email:" "Email:"
::msgcat::mcset pl "Error requesting data: %s" "Błąd przy pobieraniu danych:\
        %s"
::msgcat::mcset pl "First name:" "Imię:"
::msgcat::mcset pl "Instructions" "Instrukcje"
::msgcat::mcset pl "Key:" "Klucz:"
::msgcat::mcset pl "Last Name:" "Nazwisko:"
::msgcat::mcset pl "Misc:" "Różne:"
::msgcat::mcset pl "Phone:" "Telefon:"
::msgcat::mcset pl "Text:" "Tekst:"
::msgcat::mcset pl "Zip:" "Kod pocztowy:"

# custom.tcl
::msgcat::mcset pl "Customization of the One True Jabber Client." "Ustawienia\
        dla Jednynego Prawdziwego Klienta Jabbera."
::msgcat::mcset pl "Customize" "Ustawienia"
::msgcat::mcset pl "Group:" "Grupa:"
::msgcat::mcset pl "Open" "Otwórz"
::msgcat::mcset pl "Parent group" "Nadrzędna grupa"
::msgcat::mcset pl "Parent groups" "Nadrzędne grupy"
::msgcat::mcset pl "Reset to current value" "Przywróć aktualną wartość"
::msgcat::mcset pl "Reset to default value" "Przywróć domyślną wartość"
::msgcat::mcset pl "Reset to saved value" "Przywróć zapisaną wartość"
::msgcat::mcset pl "Reset to value from config file" "Przywróć wartość z\
        pliku ustawień"
::msgcat::mcset pl "Set for current and future sessions" "Zapamiętaj dla\
        obecnej i przyszłych sesji"
::msgcat::mcset pl "Set for current session only" "Zapamiętaj dla obecnej\
        sesji"
::msgcat::mcset pl "State" "Stan"
::msgcat::mcset pl "the option is set and saved." "opcja została zmieniona i\
        zapamiętana."
::msgcat::mcset pl "the option is set to its default value." "opcja ma\
        wartość domyślną."
::msgcat::mcset pl "the option is set, but not saved." "opcja została\
        zmieniona, ale nie zapamiętana."
::msgcat::mcset pl "the option is taken from config file." "opcja ma warość z\
        pliku ustawień."
::msgcat::mcset pl "value is changed, but the option is not set." "wartość\
        edytowana, ale nie zapamiętano stanu opcji."

# muc.tcl
::msgcat::mcset pl "\n\tAffiliation: %s" "\n\tPrzynależność: %s"
::msgcat::mcset pl "\n\tJID: %s" "\n\tJID: %s"
::msgcat::mcset pl "\nAlternative venue: %s" "\nAlternatywne miejsce: %s"
::msgcat::mcset pl "\nReason: %s" "\nPrzyczyna: %s"
::msgcat::mcset pl " by %s" " przez %s"
::msgcat::mcset pl "%s has been assigned a new affiliation: %s" "%s otrzymał\
        nową przynależność: %s"
::msgcat::mcset pl "%s has been assigned a new role: %s" "%s otrzymał nową\
        rolę: %s"
::msgcat::mcset pl "%s has been assigned a new room position: %s/%s" "%s\
        otrzymał nowe stanowisko w konferencji: %s/%s"
::msgcat::mcset pl "%s has been banned" "Zablokowano wstęp dla %s"
::msgcat::mcset pl "%s has been kicked" "%s został wyrzucony"
::msgcat::mcset pl "%s has been kicked because of membership loss" "%s został\
        wyrzucony z powodu utraty praw członka"
::msgcat::mcset pl "%s has been kicked because room became members-only" "%s\
        został wyrzucony, ponieważ pokój konferencyjny jest tylko dla\
        użytkowników z prawami członka"
::msgcat::mcset pl "%s has entered" "%s dołączył do konferencji"
::msgcat::mcset pl "%s has left" "%s wyszedł"
::msgcat::mcset pl "%s is now known as %s" "%s nazywa się teraz %s"
::msgcat::mcset pl "A new room is created" "Utworzono nowy pokój\
        konferencyjny"
::msgcat::mcset pl "Accept default config" "Akceptuj domyślną konfigurację"
::msgcat::mcset pl "Add" "Dodaj"
::msgcat::mcset pl "Add new item" "Dodaj nowe elementy"
::msgcat::mcset pl "admin" "administrator"
::msgcat::mcset pl "Affiliation" "Przynależność"
::msgcat::mcset pl "All items:" "Wszystkie elementy:"
::msgcat::mcset pl "and" "i"
::msgcat::mcset pl "as %s/%s" "jako %s/%s"
::msgcat::mcset pl "Ban" "Zabroń wstępu"
::msgcat::mcset pl "Can't change nickname in MUC incompatible rooms" "Zmiana\
        pseudonimu działa tylko w pokojach kompatybilnych z MUC"
::msgcat::mcset pl "Cancelling configure form" "Anulowanie konfiguracji od"
::msgcat::mcset pl "Conference room %s will be destroyed\
        permanently.\n\nProceed?" "Pokój konferencyjny \"%s\" zostanie\
        usunięty na stałe.\n\nKontynuować?"
::msgcat::mcset pl "Configure form: %s" "Próba konfiguracji od: %s"
::msgcat::mcset pl "Configure room" "Konfiguracja pokoju"
::msgcat::mcset pl "Destroy room" "Zamknij pokój"
::msgcat::mcset pl "Edit admin list" "Lista administratorów"
::msgcat::mcset pl "Edit ban list" "Lista bez prawa wstępu"
::msgcat::mcset pl "Edit member list" "Lista członków"
::msgcat::mcset pl "Edit moderator list" "Lista moderatorów"
::msgcat::mcset pl "Edit outcast list" "Edytuj listę wyrzuconych"
::msgcat::mcset pl "Edit owner list" "Lista właścicieli"
::msgcat::mcset pl "Edit participant list" "Edytuj listę uczestników"
::msgcat::mcset pl "Edit visitor list" "Edytuj listę gości"
::msgcat::mcset pl "Edit voice list" "Lista z prawem głosu"
::msgcat::mcset pl "Generate groupchat messages when occupant changes his/her\
        status and/or status message" "Generuj wiadomości kiedy uczestnik\
        konferencji zmienia swój status lub opis statusu"
::msgcat::mcset pl "Generate groupchat messages when occupant changes his/her\
        status and/or status message." "Generuj wiadomości w pokoju\
        konferencyjnym, kiedy uczestnik zmienia swój status lub opis\
        statusu."
::msgcat::mcset pl "Generate groupchat messages when occupant's room position\
        (affiliation and/or role) changes." "Generuj wiadomości w pokoju\
        konferencyjnym, kiedy uczestnik zmienia swoje stanowisko\
        (przynależność lub rolę)."
::msgcat::mcset pl "Generate status messages when occupants enter/exit MUC\
        compatible conference rooms." "Generuj wiadomości o statusie\
        użytkowników wchodzących/wychodzących w pokojach konferencyjnych\
        zgodnych z MUC."
::msgcat::mcset pl "Grant Admin Privileges" "Przyznaj prawa administratora"
::msgcat::mcset pl "Grant Membership" "Przyznaj prawa członka"
::msgcat::mcset pl "Grant Moderator Privileges" "Przyznaj prawa moderatora"
::msgcat::mcset pl "Grant Owner Privileges" "Przyznaj prawa właściciela"
::msgcat::mcset pl "Grant Voice" "Przyznaj prawo głosu"
::msgcat::mcset pl "Join conference" "Dołącz do konferencji"
::msgcat::mcset pl "Join groupchat" "Dołącz do konferencji"
::msgcat::mcset pl "Kick" "Wyrzuć"
::msgcat::mcset pl "Maximum number of characters in the history in MUC\
        compatible conference rooms." "Maksymalna liczba znaków historii\
        pokoi konferencyjnych MUC."
::msgcat::mcset pl "Maximum number of stanzas in the history in MUC\
        compatible conference rooms." "Maksymalna liczba zwrotek historii\
        pokoi konferencyjnych MUC."
::msgcat::mcset pl "member" "członek"
::msgcat::mcset pl "moderator" "moderator"
::msgcat::mcset pl "MUC" "Polecenia MUC"
::msgcat::mcset pl "Nick" "Pseudonim"
::msgcat::mcset pl "none" "brak"
::msgcat::mcset pl "outcast" "wyrzucony"
::msgcat::mcset pl "owner" "właściciel"
::msgcat::mcset pl "participant" "uczestnik"
::msgcat::mcset pl "Propose to configure newly created MUC room. If set to\
        false then the default room configuration is automatically accepted."\
        "Proponuj konfigurowanie nowo tworzonych pokoi konferencyjnych MUC.\
        Jeżeli opcja będzie wyłączona, to domyślna konfiguracja zostanie\
        zaakceptowana automatycznie."
::msgcat::mcset pl "Reason" "Powód"
::msgcat::mcset pl "Report the list of current MUC rooms on disco#items\
        query." "Wysyłaj listę aktywnych pokoi MUC przy zapytaniu\
        disco#items."
::msgcat::mcset pl "Request only unseen (which aren't displayed in the chat\
        window) messages in the history in MUC compatible conference rooms."\
        "Pobierz tylko nieprzeczytane (niewidoczne w oknie rozmowy)\
        wiadomości historii pokoi konferencyjnych MUC."
::msgcat::mcset pl "Retry to join MUC room with a different nickname (with\
        added _ suffix) in case of name conflicts." "Ponów próbę przyłączenia\
        się do pokoju MUC z innym pseudonimem (z dodanym przyrostkiem _) w\
        przypadku konfliktu nazw."
::msgcat::mcset pl "Retrying with nickname '%s_'" "Próba połączenia z\
        pseudonimem '%s_'"
::msgcat::mcset pl "Revoke Admin Privileges" "Odbierz prawa administratora"
::msgcat::mcset pl "Revoke Membership" "Odbierz prawa członka"
::msgcat::mcset pl "Revoke Moderator Privileges" "Odbierz prawa moderatora"
::msgcat::mcset pl "Revoke Owner Privileges" "Odbierz prawa właściciela"
::msgcat::mcset pl "Revoke Voice" "Odbierz prawo głosu"
::msgcat::mcset pl "Role" "Rola"
::msgcat::mcset pl "Room %s is successfully created" "Pokój %s został\
        pomyślnie utworzony"
::msgcat::mcset pl "Room is created" "Pokój został utworzony"
::msgcat::mcset pl "Room is destroyed" "Pokój został zamknięty"
::msgcat::mcset pl "Sending %s %s list" "Wysyłanie listy %s %s"
::msgcat::mcset pl "Sending configure form" "Wysyłanie formularza\
        konfiguracji"
::msgcat::mcset pl "Update item" "Aktualizuj element"
::msgcat::mcset pl "User already %s" "Użytkownik już %s"
::msgcat::mcset pl "User is unbanned" "Użytkownik jest odblokowany"
::msgcat::mcset pl "visitor" "gość"
::msgcat::mcset pl "Whois" "Kim jest"
::msgcat::mcset pl "whois '%s': %s" "whois '%s': %s"
::msgcat::mcset pl "whois '%s': no info" "whois '%s': brak informacji"
::msgcat::mcset pl "You must join the room to set %s" "Należy dołączyć do\
        pokoju aby ustawic %s"

# itemedit.tcl
::msgcat::mcset pl "<- Remove" "<- Usuń"
::msgcat::mcset pl "Add ->" "Dodaj ->"
::msgcat::mcset pl "Available groups" "Dostępne grupy"
::msgcat::mcset pl "Current groups" "Aktualnie przypisane"
::msgcat::mcset pl "Edit groups for %s" "Zmień grupy dla %s"
::msgcat::mcset pl "Edit nickname for %s" "Zmień nazwę dla %s"
::msgcat::mcset pl "Edit properties for %s" "Edycja właściwości dla %s"

# plugins/general/stats.tcl
::msgcat::mcset pl "Name " "Nazwa "
::msgcat::mcset pl "Node" "Węzeł"
::msgcat::mcset pl "Open statistics monitor" "Otwórz monitor statystyki"
::msgcat::mcset pl "Request" "Pobierz"
::msgcat::mcset pl "Service statistics" "Statystyka usługi"
::msgcat::mcset pl "Set" "Ustaw"
::msgcat::mcset pl "Statistics" "Statystyka"
::msgcat::mcset pl "Statistics monitor" "Monitor statystyki"
::msgcat::mcset pl "Timer" "Timer"
::msgcat::mcset pl "Units" "Jednostka"
::msgcat::mcset pl "Value" "Wartość"

# messages.tcl
::msgcat::mcset pl "\nReason is: %s" "\nPrzyczyna: %s"
::msgcat::mcset pl "%s Headlines" "%s Nagłówki"
::msgcat::mcset pl "%s invites you to conference room %s" "%s zaprasza Cię do\
        konferencji w pokoju %s"
::msgcat::mcset pl "Approve subscription" "Zaakceptuj prośbę o subskrypcję"
::msgcat::mcset pl "Attached URL:" "Załączone odnośniki:"
::msgcat::mcset pl "Attached user:" "Załączony kontakt:"
::msgcat::mcset pl "Cache headlines on exit and restore on start." "Zapisuj\
        nagłówki przy zamykaniu programu i przywracaj przy starcie."
::msgcat::mcset pl "Chat" "Rozmowa"
::msgcat::mcset pl "Copy headline to clipboard" "Kopiuj nagłówek do schowka"
::msgcat::mcset pl "Copy URL to clipboard" "Kopiuj URL do schowka"
::msgcat::mcset pl "Decline subscription" "Odrzuć prośbę o subskrypcję"
::msgcat::mcset pl "Delete" "Usuń"
::msgcat::mcset pl "Delete all" "Usuń wszystkie"
::msgcat::mcset pl "Delete seen" "Usuń przeczytane"
::msgcat::mcset pl "Display headlines in single/multiple windows." "Pokazuj\
        nagłówki w jednym/wielu oknach."
::msgcat::mcset pl "Do not display headline descriptions as tree nodes." "Nie\
        pokazuj opisów nagłówków jako elementów drzewka (pokazuj tylko\
        tytuł)."
::msgcat::mcset pl "Extras from %s" "%s"
::msgcat::mcset pl "Extras from:" "Wiadomość od:"
::msgcat::mcset pl "Forward headline" "Przekaż nagłówek"
::msgcat::mcset pl "Forward to %s" "Przekaż do %s"
::msgcat::mcset pl "Forward..." "Przekaż..."
::msgcat::mcset pl "From: " "Od: "
::msgcat::mcset pl "Grant subscription" "Wyślij subskrypcję"
::msgcat::mcset pl "Group: " "Grupa: "
::msgcat::mcset pl "Headlines" "Nagłówki"
::msgcat::mcset pl "I would like to add you to my roster." "Witam! Chcę dodać\
        Cię do mojej listy kontaktów."
::msgcat::mcset pl "Invited to:" "Zaproszony do:"
::msgcat::mcset pl "List of JIDs to whom headlines have been sent." "Lista\
        odbiorców do których przesłano nagłówki."
::msgcat::mcset pl "List of message destination JIDs." "Lista odbiorców\
        wiadomości"
::msgcat::mcset pl "Mark all seen" "Oznacz wszystkie jako przeczytane"
::msgcat::mcset pl "Mark all unseen" "Oznacz wszystkie jako nieprzeczytane"
::msgcat::mcset pl "Message and Headline options." "Ustawienia wiadomości i\
        nagłówków."
::msgcat::mcset pl "Message body" "Treść wiadomości"
::msgcat::mcset pl "Message from:" "Wiadomość od:"
::msgcat::mcset pl "One window per bare JID" "Jedno okno na JID"
::msgcat::mcset pl "One window per full JID" "Jedno okno na JID/zasób"
::msgcat::mcset pl "Quote" "Cytuj"
::msgcat::mcset pl "Received by:" "Otrzymana przez:"
::msgcat::mcset pl "Reply" "Odpowiedz"
::msgcat::mcset pl "Reply subject:" "Temat odpowiedzi:"
::msgcat::mcset pl "Request subscription" "Poproś o subskrypcję"
::msgcat::mcset pl "Request unsubscription" "Poproś o usunięcie subskrypcji"
::msgcat::mcset pl "Revoke subscription" "Wycofaj subskrypcję"
::msgcat::mcset pl "Send message" "Wyślij wiadomość"
::msgcat::mcset pl "Send message to %s" "%s"
::msgcat::mcset pl "Send message to group" "Wyślij wiadomość do grupy"
::msgcat::mcset pl "Send message to group %s" "Wyślij wiadomość do grupy %s"
::msgcat::mcset pl "Send request to: " "Wyślij prośbę do: "
::msgcat::mcset pl "Send subscription request" "Wyślij prośbę o subskrypcję"
::msgcat::mcset pl "Send subscription request to %s" "Wyślij prośbę o\
        subskrypcję do %s"
::msgcat::mcset pl "Send subscription to: " "Prośba o subskrypcję do: "
::msgcat::mcset pl "Single window" "Jedno okno"
::msgcat::mcset pl "Subject: " "Temat: "
::msgcat::mcset pl "Subscribe" "Subskrybuj"
::msgcat::mcset pl "Subscription request from %s" "Prośba o subskrypcję od\
        %s"
::msgcat::mcset pl "Subscription request from:" "Prośba o subskrypcję od:"
::msgcat::mcset pl "To: " "Do: "
::msgcat::mcset pl "Toggle encryption" "GPG - włącz szyfrowanie wiadomości"
::msgcat::mcset pl "Toggle seen" "Zazanacz/Odznacz jako przeczytany"
::msgcat::mcset pl "Toggle signing" "GPG - włącz podpisywanie wiadomości"

# iface.tcl
::msgcat::mcset pl "%s SSL Certificate Info" "Informacje o certyfikacie SSL z\
        %s"
::msgcat::mcset pl "About" "O programie"
::msgcat::mcset pl "Add new user..." "Dodaj nowy kontakt..."
::msgcat::mcset pl "Admin tools" "Narzędzia administracyjne"
::msgcat::mcset pl "Allow downloading" "Pozwól na ściąganie"
::msgcat::mcset pl "Announce" "Włącz"
::msgcat::mcset pl "Authors:" "Autorzy:"
::msgcat::mcset pl "Begin date" "Data wydania"
::msgcat::mcset pl "Browser" "Przeglądarka usług"
::msgcat::mcset pl "Change password..." "Zmień hasło..."
::msgcat::mcset pl "Change priority..." "Zmień priorytet..."
::msgcat::mcset pl "Chats" "Rozmowy i konferencje"
::msgcat::mcset pl "Chats:" "Rozmowy i konferecje:"
::msgcat::mcset pl "Cipher" "Algorytm szyfru"
::msgcat::mcset pl "Close all tabs" "Zamknij wszystkie karty"
::msgcat::mcset pl "Close other tabs" "Zamknij pozostałe karty"
::msgcat::mcset pl "Delay between getting focus and updating window or tab\
        title in milliseconds." "Opóźnienie w milisekundach pomiędzy\
        otrzymaniem fokusu a odświeżeniem tytułu okna lub karty."
::msgcat::mcset pl "Delete message of the day" "Usuń MOTD"
::msgcat::mcset pl "Disabled\n" "Wyłączony\n"
::msgcat::mcset pl "Disconnected" "Rozłączony"
::msgcat::mcset pl "Discovery" "Informacje Discovery"
::msgcat::mcset pl "Edit my info..." "Edytuj własną wizytówkę..."
::msgcat::mcset pl "Emphasize" "Wyświetl formatowanie dla słów pomiędzy * / i\
        _"
::msgcat::mcset pl "Enabled\n" "Włączony\n"
::msgcat::mcset pl "Expiry date" "Data ważności"
::msgcat::mcset pl "Extended away" "Nieobecny"
::msgcat::mcset pl "Generate enter/exit messages" "Generuj wiadomości przy\
        wejściu/wyjściu"
::msgcat::mcset pl "Help" "Pomoc"
::msgcat::mcset pl "Issuer" "Wydawca"
::msgcat::mcset pl "Join group..." "Dołącz do konferencji..."
::msgcat::mcset pl "Log in..." "Zaloguj..."
::msgcat::mcset pl "Log out with reason..." "Wyloguj z opisem..."
::msgcat::mcset pl "Message archive" "Archiwum wiadomości"
::msgcat::mcset pl "Options for main interface." "Ustawienia wyglądu i\
        zachowania aplikacji."
::msgcat::mcset pl "Presence" "Status"
::msgcat::mcset pl "Quick Help" "Szybka Pomoc"
::msgcat::mcset pl "Quick help" "Szybka Pomoc"
::msgcat::mcset pl "Quit" "Zakończ"
::msgcat::mcset pl "Raise new tab." "Otwieraj nowe karty na wierzchu."
::msgcat::mcset pl "Send broadcast message..." "Wyślij wiadomość do\
        wszystkich..."
::msgcat::mcset pl "Send message of the day..." "Ustaw Wiadomość Dnia\
        (MOTD)..."
::msgcat::mcset pl "Send to server" "Wyślij na serwer"
::msgcat::mcset pl "Serial number" "Numer seryjny"
::msgcat::mcset pl "Service Discovery" "Przeglądarka usług (protokół\
        Discovery)"
::msgcat::mcset pl "Session key bits" "Liczba bitów klucza sesji"
::msgcat::mcset pl "SHA1 hash" "Skrót SHA1"
::msgcat::mcset pl "Show number of unread messages in tab titles." "Pokaż\
        ilość nieprzeczytanych wiadomości w tytułach kart."
::msgcat::mcset pl "Show Toolbar." "Pokaż pasek przycisków."
::msgcat::mcset pl "Show user or service info..." "Pokaż wizytówkę\
        użytkownika, usługi..."
::msgcat::mcset pl "Smart autoscroll" "Inteligentne autoprzewijanie"
::msgcat::mcset pl "Sound" "Dźwięki"
::msgcat::mcset pl "SSL Info" "Informacje o SSL"
::msgcat::mcset pl "Stop autoscroll" "Zatrzymaj autoprzewijanie"
::msgcat::mcset pl "Tabs:" "Karty:"
::msgcat::mcset pl "Toggle encryption (when possible)" "GPG - Włącz\
        szyfrowanie rozmów (kiedy możliwe)"
::msgcat::mcset pl "Toggle showing offline users" "Pokaż/Ukryj rozłączonych"
::msgcat::mcset pl "Update message of the day..." "Aktualizuj MOTD..."
::msgcat::mcset pl "Use Tabbed Interface (you need to restart)." "Włącz\
        interfejs z kartami w jednym oknie (wymagany restart)."

# plugins/chat/info_commands.tcl
::msgcat::mcset pl "Address 2" "Adres 2"
::msgcat::mcset pl "City" "Miasto"
::msgcat::mcset pl "Country" "Państwo"
::msgcat::mcset pl "Display %s in chat window when using /vcard command."\
        "Pokaż pole \"%s\" w oknie rozmowy po wykonaniu polecenia /vcard."
::msgcat::mcset pl "E-mail" "E-mail"
::msgcat::mcset pl "Family name" "Nazwisko"
::msgcat::mcset pl "Full name" "Pełna nazwa"
::msgcat::mcset pl "JID" "JID"
::msgcat::mcset pl "last %s%s:" "ostatnio aktywny %s%s:"
::msgcat::mcset pl "last %s%s: %s" "ostatnio aktywny %s%s: %s"
::msgcat::mcset pl "Latitude" "Szerokość geograficzna"
::msgcat::mcset pl "Longitude" "Długość geograficzna"
::msgcat::mcset pl "Middle name" "Drugie imię"
::msgcat::mcset pl "Nickname" "Pseudonim"
::msgcat::mcset pl "Organization name" "Ogranizacja"
::msgcat::mcset pl "Organization unit" "Jednostka"
::msgcat::mcset pl "Phone BBS" "Telefon BBS"
::msgcat::mcset pl "Phone cell" "Telefon komórkowy"
::msgcat::mcset pl "Phone fax" "Fax"
::msgcat::mcset pl "Phone home" "Telefon domowy"
::msgcat::mcset pl "Phone ISDN" "ISDN"
::msgcat::mcset pl "Phone message recorder" "Automatyczna sekretarka"
::msgcat::mcset pl "Phone modem" "Modem"
::msgcat::mcset pl "Phone pager" "Pager"
::msgcat::mcset pl "Phone PCS" "Telefon PCS"
::msgcat::mcset pl "Phone preferred" "Telefon preferowany"
::msgcat::mcset pl "Phone video" "Videotelefon"
::msgcat::mcset pl "Phone voice" "Poczta głosowa"
::msgcat::mcset pl "Phone work" "Telefon w pracy"
::msgcat::mcset pl "Postal code" "Kod pocztowy"
::msgcat::mcset pl "Prefix" "Prefiks"
::msgcat::mcset pl "State " "Województwo "
::msgcat::mcset pl "Suffix" "Sufiks"
::msgcat::mcset pl "time %s%s:" "czas dla %s%s:"
::msgcat::mcset pl "time %s%s: %s" "czas dla %s%s: %s"
::msgcat::mcset pl "Time Zone:" "Strefa cz.:"
::msgcat::mcset pl "Title" "Tytuł"
::msgcat::mcset pl "UID" "UID"
::msgcat::mcset pl "vcard %s%s:" "wizytówka dla %s%s:"
::msgcat::mcset pl "vcard %s%s: %s" "wizytówka dla %s%s: %s"
::msgcat::mcset pl "vCard display options in chat windows." "Ustawienia\
        wyświetlania elementów wizytówki w oknach rozmów."
::msgcat::mcset pl "version %s%s:" "wersja klienta %s%s:"
::msgcat::mcset pl "version %s%s: %s" "wersja klienta %s%s: %s"
::msgcat::mcset pl "Web site" "Strona domowa"

# plugins/chat/logger.tcl
::msgcat::mcset pl "All" "Wszystkie"
::msgcat::mcset pl "April" "Kwiecień"
::msgcat::mcset pl "August" "Sierpień"
::msgcat::mcset pl "Chats history is converted.\nBackup of the old history is\
        stored in %s" "Historia rozmów została przekonwertowana.\nKopia\
        zapasowa starej historii została zapisana w %s"
::msgcat::mcset pl "Conversion is finished" "Konwersja zakończona"
::msgcat::mcset pl "Converting Log Files" "Konwersja plików historii"
::msgcat::mcset pl "December" "Grudzień"
::msgcat::mcset pl "Directory to store logs." "Katalog przechowywania plików\
        historii."
::msgcat::mcset pl "Export to XHTML" "Zapisz jako XHTML"
::msgcat::mcset pl "February" "Luty"
::msgcat::mcset pl "File %s cannot be opened: %s. History for %s (%s) is NOT\
        converted\n" "Nie można otworzyć pliku %s: %s. Historia dla %s (%s)\
        NIE jest przekonwertowana\n"
::msgcat::mcset pl "File %s cannot be opened: %s. History for %s is NOT\
        converted\n" "Nie można otworzyć pliku %s: %s. Historia dla %s NIE\
        jest przekonwertowana\n"
::msgcat::mcset pl "File %s is corrupt. History for %s (%s) is NOT\
        converted\n" "Plik %s jest uszkodzony. Historia dla %s (%s) NIE\
        została przekonwertowana\n"
::msgcat::mcset pl "File %s is corrupt. History for %s is NOT converted\n"\
        "Plik %s jest uszkodzony. Historia dla %s NIE została\
        przekonwertowana\n"
::msgcat::mcset pl "History for %s" "Historia dla %s"
::msgcat::mcset pl "January" "Styczeń"
::msgcat::mcset pl "July" "Lipiec"
::msgcat::mcset pl "June" "Czerwiec"
::msgcat::mcset pl "Logging options." "Ustawienia historii rozmów."
::msgcat::mcset pl "March" "Marzec"
::msgcat::mcset pl "May" "Maj"
::msgcat::mcset pl "November" "Listopad"
::msgcat::mcset pl "October" "Październik"
::msgcat::mcset pl "Please, be patient while chats history is being converted\
        to new format" "Proszę czekać, historia rozmów jest konwertowana do\
        nowego formatu"
::msgcat::mcset pl "Search down" "Szukaj w dół"
::msgcat::mcset pl "Search up" "Szukaj w górę"
::msgcat::mcset pl "Select month:" "Wybierz miesiąc: "
::msgcat::mcset pl "September" "Wrzesień"
::msgcat::mcset pl "Store group chats logs." "Zapisuj historię rozmów w\
        pokojach konferencyjnych."
::msgcat::mcset pl "Store private chats logs." "Zapisuj historię prywatnych\
        rozmów."
::msgcat::mcset pl "You're using root directory %s for storing Tkabber\
        logs!\n\nI refuse to convert logs database." "Używasz katalogu\
        głównego %s do przechowywania plików historii Tkabbera!\n\nW tym\
        przypadku nie zostanie przeprowadzona konwersja historii."

# plugins/chat/nick_colors.tcl
::msgcat::mcset pl "Color message bodies in chat windows." "Koloruj treść\
        wiadomości w oknach rozmów."
::msgcat::mcset pl "Edit %s color" "Edycja koloru dla %s"
::msgcat::mcset pl "Edit chat user colors" "Przypisywanie kolorów"
::msgcat::mcset pl "Edit nick color..." "Edycja koloru..."
::msgcat::mcset pl "Edit nick colors..." "Przypisz kolory użytkownikom..."
::msgcat::mcset pl "Use colored messages" "Koloruj treść wiadomości w oknie\
        rozmowy"
::msgcat::mcset pl "Use colored nicks" "Koloruj pseudonimy w oknie rozmowy"
::msgcat::mcset pl "Use colored nicks in chat windows." "Koloruj pseudonimy w\
        oknach rozmów."
::msgcat::mcset pl "Use colored nicks in groupchat rosters." "Koloruj\
        pseudonimy listy uczestników konferencji."
::msgcat::mcset pl "Use colored roster nicks" "Koloruj pseudonimy listy\
        kontaktów"

# plugins/chat/complete_last_nick.tcl
::msgcat::mcset pl "Number of groupchat messages to expire nick completion\
        according to the last personally addressed message." "Ilość\
        wiadomości, po których wygasa uzupełnianie pseudonimu zgodnie z\
        ostatnią nadaną do tej osoby wiadomością."

# plugins/chat/highlight.tcl
::msgcat::mcset pl "Enable highlighting plugin." "Włącz kolorowanie."
::msgcat::mcset pl "Groupchat message highlighting plugin options."\
        "Ustawienia wyświetlania wiadomości w pokojach konferencyjnych."
::msgcat::mcset pl "Highlight current nickname in messages." "Koloruj\
        aktualny pseudonim w wiadomościach."
::msgcat::mcset pl "Highlight only whole words in messages." "Koloruj tylko\
        całe wyrazy w wiadomościach."
::msgcat::mcset pl "Substrings to highlight in messages." "Koloruj wybrane\
        fragmenty wiadomości."

# plugins/chat/bookmark_highlighted.tcl
::msgcat::mcset pl "Next highlighted" "Następne zaznaczenie"
::msgcat::mcset pl "Prev highlighted" "Poprzednie zaznaczenie"

# plugins/chat/popupmenu.tcl
::msgcat::mcset pl "Clear bookmarks" "Usuń zakładki"
::msgcat::mcset pl "Copy selection to clipboard" "Kopiuj do schowka"
::msgcat::mcset pl "Google selection" "Znajdź w Google"
::msgcat::mcset pl "Next bookmark" "Następna zakładka"
::msgcat::mcset pl "Prev bookmark" "Poprzednia zakładka"
::msgcat::mcset pl "Set bookmark" "Dodaj do zakładek"

# sound.tcl
::msgcat::mcset pl "External program, which is to be executed to play sound.\
        If empty, Snack library is used (if available) to play sound."\
        "Zewnętrzny program do odtwarzania dźwięków. Jeżeli puste, do\
        odtwarzania używana jest biblioteka Snack (instalowana oddzielnie)."
::msgcat::mcset pl "Mute sound if Tkabber window is focused." "Wyłącz dźwięk\
        jeżeli okno Tkabbera jest aktywne."
::msgcat::mcset pl "Mute sound notification." "Nie odtwarzaj dźwięków."
::msgcat::mcset pl "Mute sound when displaying delayed groupchat messages."\
        "Wyłącz dźwięki dla wiadomości wyświetlanych z opóźnieniem w pokojach\
        konferencyjnych."
::msgcat::mcset pl "Mute sound when displaying delayed personal chat\
        messages." "Wyłącz dźwięki dla prywatnych wiadomości wyświetlanych z\
        opóźnieniem."
::msgcat::mcset pl "Notify only when available" "Powiadamiaj tylko gdy mam\
        status Dostępny"
::msgcat::mcset pl "Options for external play program" "Parametry dla\
        zewnętrznego programu odtwarzającego dźwięk"
::msgcat::mcset pl "Sound options." "Ustawienia dźwięków aplikacji."
::msgcat::mcset pl "Sound to play when available presence is received."\
        "Dźwięk odtwarzany kiedy kontakt staje się dostępny."
::msgcat::mcset pl "Sound to play when connected to Jabber server." "Dźwięk\
        odtwarzany po nawiązaniu połączenia z serwerem."
::msgcat::mcset pl "Sound to play when disconnected from Jabber server."\
        "Dźwięk odtwarzany po rozłączeniu się z serwerem."
::msgcat::mcset pl "Sound to play when groupchat message from me is\
        received." "Dźwięk odtwarzany po otrzymaniu wiadomości ode mnie w\
        pokoju konferencyjnym."
::msgcat::mcset pl "Sound to play when groupchat message is received."\
        "Dźwięk odtwarzany po otrzymaniu wiadomości w pokoju konferencyjnym."
::msgcat::mcset pl "Sound to play when groupchat server message is received."\
        "Dźwięk odtwarzany po otrzymaniu wiadomości systemowej."
::msgcat::mcset pl "Sound to play when highlighted (usually addressed\
        personally) groupchat message is received." "Dźwięk odtwarzany po\
        otrzymaniu wiadomości z wyróżnionym fragmentem (ustawiane oddzielnie)\
        w pokoju konferencyjnym."
::msgcat::mcset pl "Sound to play when personal chat message is received."\
        "Dźwięk odtwarzany po otrzymaniu wiadomości."
::msgcat::mcset pl "Sound to play when sending personal chat message."\
        "Dźwięk odtwarzany przy wysyłaniu wiadomości."
::msgcat::mcset pl "Sound to play when unavailable presence is received."\
        "Dźwięk odtwarzany kiedy kontakt rozłącza się."
::msgcat::mcset pl "Time interval before playing next sound (in\
        milliseconds)." "Odstęp czasu przed odtworzeniem następnego dźwięku\
        (w milisekundach)."
::msgcat::mcset pl "Use sound notification only when being available." "Włącz\
        powiadomienia dźwiękowe tylko przy statusie Dostępny."

# joingrdialog.tcl
::msgcat::mcset pl "Connection:" "Połączenie:"
::msgcat::mcset pl "Join" "Dołącz"
::msgcat::mcset pl "Join group" "Dołącz do konferencji"
::msgcat::mcset pl "Join group dialog data (groups)." "Dołącz do konferencji\
        (pokoje)."
::msgcat::mcset pl "Join group dialog data (nicks)." "Dołącz do konferencji\
        (pseudonimy)."
::msgcat::mcset pl "Join group dialog data (servers)." "Dołącz do konferencji\
        (serwery)."
::msgcat::mcset pl "Nick:" "Pseudonim:"

# filters.tcl
::msgcat::mcset pl "Action" "Akcja"
::msgcat::mcset pl "Edit" "Edytuj"
::msgcat::mcset pl "Move down" "Na dół"
::msgcat::mcset pl "Move up" "Do góry"

# plugins/general/rawxml.tcl
::msgcat::mcset pl "Available presence" "Status Dostępny"
::msgcat::mcset pl "Chat message" "Rozmowa"
::msgcat::mcset pl "Clear" "Wyczyść"
::msgcat::mcset pl "Create node" "Utwórz węzęł"
::msgcat::mcset pl "Generic IQ" "Ogólne zapytania IQ"
::msgcat::mcset pl "Get items" "Pobierz elementy"
::msgcat::mcset pl "Headline message" "Nagłówek"
::msgcat::mcset pl "Indentation for pretty-printed XML subtags." "Rozmiar\
        wcięć dla formatowanych znaczników XML."
::msgcat::mcset pl "Normal message" "Zwykła wiadomość"
::msgcat::mcset pl "Not connected" "Rozłączony"
::msgcat::mcset pl "Open raw XML window" "Otwórz konsolę XML"
::msgcat::mcset pl "Options for Raw XML Input module, which allows you to\
        monitor incoming/outgoing traffic from connection to server and send\
        custom XML stanzas." "Ustawienia modułu Konsoli XML, który umożliwia\
        monitorowanie wchodzącego/wychodzącego ruchu pomiędzy klientem a\
        serwerm, oraz wysyłanie własnych komunikatów."
::msgcat::mcset pl "Pretty print incoming and outgoing XML stanzas."\
        "Formatuj i koloruj znaczniki przychodzącego/wychodzącego strumienia\
        XML."
::msgcat::mcset pl "Pretty print XML" "Formatuj/koloruj znaczniki XML"
::msgcat::mcset pl "Pub/sub" "Pub/sub"
::msgcat::mcset pl "Publish node" "Publikuj węzęł"
::msgcat::mcset pl "Raw XML" "Konsola XML"
::msgcat::mcset pl "Retract node" "Wycofaj węzęł"
::msgcat::mcset pl "Show all connections" "Pokaż dla wszystkich połączeń"
::msgcat::mcset pl "Show stanzas for all (current and past) connections in\
        Raw XML window." "Pokaż zwrotki XML dla wszystkich (obecnych i\
        przeszłych) połączeń w oknie konsoli XML."
::msgcat::mcset pl "Subscribe to a node" "Subskrybuj węzęł"
::msgcat::mcset pl "Templates" "Wzorce"
::msgcat::mcset pl "Unavailable presence" "Status Niedostępny"
::msgcat::mcset pl "Unsubscribe from a node" "Anuluj subskrypcję węzła"

# disco.tcl
::msgcat::mcset pl "Clear window" "Wyczyść okno"
::msgcat::mcset pl "Delete current node and subnodes" "Usuń zanaczony węzeł i\
        podwęzły"
::msgcat::mcset pl "Delete subnodes" "Usuń podwęzły"
::msgcat::mcset pl "Error getting info: %s" "Błąd przy pobieraniu informacji:\
        %s"
::msgcat::mcset pl "Error getting items: %s" "Błąd przy pobieraniu elementów:\
        %s"
::msgcat::mcset pl "Error negotiate: %s" "Błąd negocjacji: %s"
::msgcat::mcset pl "Illegal value \"%s\" for option \"%s\", boolean expected"\
        "Nieprawidłowa wartość \"%s\" dla opcji \"%s\", oczekiwano wartości\
        typu boolean"
::msgcat::mcset pl "List of discovered JID nodes." "Lista elementów."
::msgcat::mcset pl "List of discovered JIDs." "Lista JID-ów."
::msgcat::mcset pl "Node:" "Węzeł:"
::msgcat::mcset pl "Sort items by JID/node" "Sortuj według JID/węzła"
::msgcat::mcset pl "Sort items by name" "Sortuj według nazwy"

# avatars.tcl
::msgcat::mcset pl "No avatar to store" "Brak awatara do wysłania"

# plugins/jidlink/ibb.tcl
::msgcat::mcset pl "Opening IBB connection" "Otwieranie połącznia IBB"

# plugins/general/conferenceinfo.tcl
::msgcat::mcset pl "\n\tCan't browse: %s" "\n\tNie można przeglądać: %s"
::msgcat::mcset pl "\nRoom is empty at %s" "\nPokój jest pusty o godz. %s"
::msgcat::mcset pl "\nRoom participants at %s:" "\nUczestnicy konferencji o\
        godz. %s:"
::msgcat::mcset pl "Interval (in minutes) after error reply on request of\
        participants list." "Odstęp czasu (w minutach) po otrzymaniu\
        komunikatu błędu przy sprawdzaniu listy uczestników."
::msgcat::mcset pl "Interval (in minutes) between requests of participants\
        list." "Odstęp czasu (w minutach) przy sprawdzaniu listy\
        uczestników."
::msgcat::mcset pl "Options for Conference Info module, that allows you to\
        see list of participants in roster popup, regardless of whether you\
        are currently joined with the conference." "Ustawienia modułu, który\
        pozwala oglądać listę uczestników konferencji umieszczonych na liście\
        kontaktów, niezależnie od tego czy aktualnie bierzemy w niej udział."
::msgcat::mcset pl "Periodically browse roster conferences" "Okresowo\
        przeglądaj konferencje z listy kontaktów"
::msgcat::mcset pl "Use this module" "Włącz ten moduł"

# plugins/roster/conferences.tcl
::msgcat::mcset pl "Add Conference to Roster" "Dodaj konferencję do listy\
        kontaktów"
::msgcat::mcset pl "Automatically join conference upon connect"\
        "Automatycznie dołącz do konferencji po połączeniu"
::msgcat::mcset pl "Conference:" "Konferencja:"
::msgcat::mcset pl "Conferences" "Konferencje"
::msgcat::mcset pl "Default group for conferences in roster." "Domyślna grupa\
        dla konferencji na liście kontaktów."
::msgcat::mcset pl "Ignore autojoin option and do not automatically join\
        conference rooms on login." "Ignoruj opcję autodołączania oraz nie\
        dołączaj automatycznie do konferencji po zalogowaniu."
::msgcat::mcset pl "Roster group:" "Grupa na liście:"
::msgcat::mcset pl "Storing conferences failed: %s" "Zapisanie konferencji\
        nie powiodło się: %s"

# plugins/general/presenceinfo.tcl
::msgcat::mcset pl "\n\tPresence is signed:" "\n\tStatus podpisano:"

# plugins/general/subscribe_gateway.tcl
::msgcat::mcset pl "Convert" "Konwertuj"
::msgcat::mcset pl "Convert screenname" "Konwertuj identyfikator"
::msgcat::mcset pl "Enter screenname of contact you want to add" "Wprowadź\
        identyfikator kontaktu, który chcesz dodać"
::msgcat::mcset pl "Error while converting screenname: %s." "Błąd podczas\
        konwersji identyfikatora: %s."
::msgcat::mcset pl "Screenname conversion" "Konwersja identyfikatora"
::msgcat::mcset pl "Screenname:" "Identyfikator:"
::msgcat::mcset pl "Screenname: %s\n\nConverted JID: %s" "Identyfikator:\
        %s\n\nJID po konwersji: %s"
::msgcat::mcset pl "Send subscription at %s" "Wyślij subskrypcję do %s"

# iq.tcl
::msgcat::mcset pl "%s request from %s" "Zapytanie %s od %s"
::msgcat::mcset pl "Info/Query options." "Ustawienia Informacji/Zapytań."
::msgcat::mcset pl "Show IQ requests in the status line." "Pokazuj zapytania\
        IQ na pasku statusu."
::msgcat::mcset pl "Strip leading \"http://jabber.org/protocol/\" from IQ\
        namespaces in the status line." "Usuwaj fragment\
        \"http://jabber.org/protocol/\" z przestrzeni nazw IQ pokazywanych na\
        pasku statusu."

# plugins/iq/last.tcl
::msgcat::mcset pl "Reply to idle time (jabber:iq:last) requests."\
        "Odpowiadaj na zapytania o ostatnią aktywność/czas działania\
        (jabber:iq:last)."

# plugins/iq/version.tcl
::msgcat::mcset pl "Include operating system info into a reply to version\
        (jabber:iq:version) requests." "Dodaj informację o systemie\
        operacyjnym do zapytań o wersję klienta (jabber:iq:version)."
::msgcat::mcset pl "Reply to version (jabber:iq:version) requests."\
        "Odpowiadaj na zapytania o wersję klienta (jabber:iq:version)."

# plugins/iq/time.tcl
::msgcat::mcset pl "Reply to current time (jabber:iq:time) requests."\
        "Odpowiadaj na zapytania o aktualny czas (jabber:iq:time)."

# splash.tcl
::msgcat::mcset pl "%s plugin" "wtyczka %s"
::msgcat::mcset pl "auto-away" "autostatus"
::msgcat::mcset pl "avatars" "awatary"
::msgcat::mcset pl "balloon help" "dymki pomocy"
::msgcat::mcset pl "browsing" "przeglądanie"
::msgcat::mcset pl "bwidget workarounds" "dodatki do bwidget"
::msgcat::mcset pl "configuration" "konfiguracja"
::msgcat::mcset pl "connections" "połączenia"
::msgcat::mcset pl "cryptographics" "kryptografia"
::msgcat::mcset pl "customization" "dostosowanie"
::msgcat::mcset pl "emoticons" "emotikonki"
::msgcat::mcset pl "extension management" "zarządzanie dodatkami"
::msgcat::mcset pl "file transfer" "transfer plików"
::msgcat::mcset pl "general plugins" "podstawowe wtyczki"
::msgcat::mcset pl "kde" "kde"
::msgcat::mcset pl "macintosh plugins" "wtyczki dla systemu Mac"
::msgcat::mcset pl "negotiation" "uzgadnianie"
::msgcat::mcset pl "pixmaps management" "zarządzanie obrazkami"
::msgcat::mcset pl "plugin management" "zarządzanie wtyczkami"
::msgcat::mcset pl "presence" "status"
::msgcat::mcset pl "privacy rules" "zasady ochrony prywatności"
::msgcat::mcset pl "roster plugins" "wtyczki listy kontaktów"
::msgcat::mcset pl "Save To Log" "Zapisz do pliku dziennika"
::msgcat::mcset pl "search plugins" "wtyczki wyszukiwania"
::msgcat::mcset pl "searching" "wyszukiwanie"
::msgcat::mcset pl "service discovery" "informacje discovery"
::msgcat::mcset pl "sound" "dźwięk"
::msgcat::mcset pl "unix plugins" "wtyczki dla systemu Unix"
::msgcat::mcset pl "user interface" "intrerfejs użytkownika"
::msgcat::mcset pl "utilities" "użytki"
::msgcat::mcset pl "windows plugins" "wtyczki dla systemu Windows"
::msgcat::mcset pl "wmaker" "wmaker"
::msgcat::mcset pl "xmpp chat/muc" "obsługa rozmów/konferencji"
::msgcat::mcset pl "xmpp iq" "xmpp iq"
::msgcat::mcset pl "xmpp library" "biblioteka xmpp"
::msgcat::mcset pl "xmpp messages" "obsługa wiadomości"
::msgcat::mcset pl "xmpp presence" "xmpp obecność"
::msgcat::mcset pl "xmpp registration" "xmpp rejestracja"
::msgcat::mcset pl "xmpp roster" "lista kontaktów"

# chats.tcl
::msgcat::mcset pl "%s - Chat" "%s - Rozmowa"
::msgcat::mcset pl "%s has changed nick to %s." "%s zmienił pseudonim na %s."
::msgcat::mcset pl "/me has set the subject to: %s" "/me zmienił temat na:\
        %s"
::msgcat::mcset pl ">>> Unable to decipher data: %s <<<" ">>> Nie można\
        odszyfrować danych: %s <<<"
::msgcat::mcset pl "Chat " "Rozmowa"
::msgcat::mcset pl "Chat options." "Ustawienia rozmów i konferencji."
::msgcat::mcset pl "Chat with %s" "%s"
::msgcat::mcset pl "Default message type (if not specified explicitly)."\
        "Domyślny typ wiadomości (jeżeli nie określono)."
::msgcat::mcset pl "Display description of user status in chat windows."\
        "Pokaż status użytkownika na górnym pasku okna rozmowy (opis statusu\
        w dymku podpowiedzi)"
::msgcat::mcset pl "Enable chat window autoscroll only when last message is\
        shown." "Włącz autoprzewijanie okna tylko kiedy widać ostatnią\
        wiadomość."
::msgcat::mcset pl "Error %s" "Błąd %s"
::msgcat::mcset pl "Generate chat messages when chat peer changes his/her\
        status and/or status message" "Generuj wiadomości kiedy uczestnik\
        rozmowy zmienia swój status lub opis statusu"
::msgcat::mcset pl "Invite" "Zaproś"
::msgcat::mcset pl "Invite %s to conferences" "Zaproś '%s' do konferencji"
::msgcat::mcset pl "Invite users to %s" "Zaproś użytkowników do %s"
::msgcat::mcset pl "Invite users..." "Zaproś..."
::msgcat::mcset pl "List of users for chat." "Lista uczestników rozmowy."
::msgcat::mcset pl "Moderators" "Moderatorzy"
::msgcat::mcset pl "No conferences for %s in progress..." "Brak aktywnych\
        konferencji dla %s..."
::msgcat::mcset pl "No users in %s roster..." "Brak kontaktów na liście\
        %s..."
::msgcat::mcset pl "Normal" "Zwykła"
::msgcat::mcset pl "Open chat" "Rozpocznij rozmowę"
::msgcat::mcset pl "Open new conversation" "Otwórz nową rozmowę"
::msgcat::mcset pl "Opens a new chat window for the new nick of the room\
        occupant" "Otwiera nowe okno rozmowy z nowym pseudonimem uczestnika\
        konferencji"
::msgcat::mcset pl "Participants" "Uczestnicy"
::msgcat::mcset pl "Please join %s" "Zaproszenie do konferencji %s"
::msgcat::mcset pl "Remove from roster..." "Usuń z listy kontaktów..."
::msgcat::mcset pl "Stop chat window autoscroll." "Zatrzymaj autoprzewijanie\
        okna rozmów."
::msgcat::mcset pl "Subject is set to: %s" "Temat konferencji to: %s"
::msgcat::mcset pl "Users" "Użytkownicy"
::msgcat::mcset pl "Visitors" "Goście"

# plugins/windows/taskbar.tcl
::msgcat::mcset pl "Enable windows tray icon." "Włącz obsługę ikony zasobnika\
        systemowego Windows."
::msgcat::mcset pl "Hide Main Window" "Ukryj główne okno"
::msgcat::mcset pl "Show Main Window" "Pokaż główne okno"

# plugins/unix/dockingtray.tcl
::msgcat::mcset pl "Enable KDE tray icon." "Włącz obsługę ikony zasobnika\
        systemowego KDE."

# ifacetk/systray.tcl
::msgcat::mcset pl "Change icon on server and enter/exit groupchat messages."\
        "Zmień ikonę na wiadomościach serwera i wiadomościach wejścia/wyjścia\
        w konferencji."
::msgcat::mcset pl "Display status tooltip when main window is minimized to\
        systray." "Pokazuj dymek podpowiedzi ze statusem nad ikoną w\
        zasobniku systemowym."
::msgcat::mcset pl "Systray icon blinks when there are unread messages."\
        "Migająca ikonka w zasobniku systemowym dla nieprzeczytanych\
        wiadomości."
::msgcat::mcset pl "Systray icon options." "Ustawienia ikony zasobnika\
        systemowego."
::msgcat::mcset pl "Tkabber Systray" "Ikona Tkabber"

# plugins/windows/console.tcl
::msgcat::mcset pl "Show console" "Pokaż konsolę"

# ifaceck/widgets.tcl
::msgcat::mcset pl "Message" "Wiadomość"
::msgcat::mcset pl "Warning" "Ostrzeżenie"

# ifacetk/iroster.tcl
::msgcat::mcset pl "Always use main JID label for metacontact." "Zawsze\
        używaj etykiety głównego JID dla metakontaktu."
::msgcat::mcset pl "Are you sure to remove all users in group '%s' from\
        roster? \n(Users which are not in this group only, will be removed\
        from the roster as well.)" "Czy na pewno usunąć z listy wszystkie\
        kontakty z grupy '%s'? \n(Kontakty przypisane równocześnie do innych\
        grup także zostaną usunięte.)"
::msgcat::mcset pl "Are you sure to remove group '%s' from roster? \n(Users\
        which are in this group only, will be in undefined group.)" "Czy na\
        pewno usunąć grupę '%s' z listy kontaktów? \n(Kontakty, które są\
        tylko w tej grupie, znajdą się w grupie 'Niezdefiniowane'.)"
::msgcat::mcset pl "Ask:" "Prośba:"
::msgcat::mcset pl "Enable grouping contacts into a single metacontact in\
        roster." "Włącz łączenie kontaktów w pojedyńczy metakontakt."
::msgcat::mcset pl "Match contact JIDs in addition to nicknames in roster\
        filter." "Filtruj wg JID użytkowników (dodmuatkowo obok filtrowania\
        wg nazwy kontaktu)."
::msgcat::mcset pl "My Resources" "Moje zasoby"
::msgcat::mcset pl "Remove all users in group..." "Usuń wszystkie kontakty z\
        grupy..."
::msgcat::mcset pl "Remove group..." "Usuń grupę..."
::msgcat::mcset pl "Rename group..." "Zmień nazwę grupy..."
::msgcat::mcset pl "Roster filter." "Filtr listy kontaktów."
::msgcat::mcset pl "Send message to all users in group..." "Wyślij wiadomość\
        do wszystkich w grupie..."
::msgcat::mcset pl "Stored collapsed roster groups." "Lista pamiętanych\
        zwiniętych grup listy kontaktów."
::msgcat::mcset pl "Stored show offline roster groups." "Lista pamiętanych\
        grup z widokiem kontaków rozłączonych."
::msgcat::mcset pl "Subscription:" "Subskrypcja:"
::msgcat::mcset pl "Use roster filter." "Włącz filtr listy kontaktów."

# ifacetk/iface.tcl
::msgcat::mcset pl "&Help" "&Pomoc"
::msgcat::mcset pl "&Services" "&Usługi"
::msgcat::mcset pl "Accept messages from roster users only" "Akceptuj\
        wiadomości tylko od osób z listy kontaktów"
::msgcat::mcset pl "Activate lists at startup" "Aktywuj listy podczas\
        uruchomienia"
::msgcat::mcset pl "Activate search panel" "Włącz panel wyszukiwania"
::msgcat::mcset pl "Add conference to roster..." "Dodaj konferencję do\
        listy..."
::msgcat::mcset pl "Add user to roster..." "Dodaj kontakt do listy..."
::msgcat::mcset pl "Bottom" "Dół"
::msgcat::mcset pl "Clear history" "Wyczyść historię"
::msgcat::mcset pl "Close Tkabber" "Zamknij Tkabbera"
::msgcat::mcset pl "Command to be run when you click a URL in a message. '%s'\
        will be replaced with this URL (e.g. \"chromium %s >>& /dev/null\" or\
        \"{C:/Program Files (x86)/Mozilla Firefox/firefox.exe} %s\")."\
        "Polecenie uruchamiane po kliknięciu adresu URL w wiadomościach. '%s'\
        zostanie zastąpione adresem URL (n.p. \"chromium %s >>& /dev/null\"\
        lub \"{C:/Program Files (x86)/Mozilla Firefox/firefox.exe} %s\")."
::msgcat::mcset pl "Common:" "Wspólne:"
::msgcat::mcset pl "Complete nickname or command" "Uzupełnij pseudonim lub\
        polecenie"
::msgcat::mcset pl "Debug tools" "Zaawansowane"
::msgcat::mcset pl "Do nothing" "Nic nie rób"
::msgcat::mcset pl "Edit conference list " "Edytuj listę konferencji "
::msgcat::mcset pl "Edit ignore list " "Edycja listy ignorowanych"
::msgcat::mcset pl "Edit invisible list " "Edycja listy niewidoczności"
::msgcat::mcset pl "Edit visible list" "Edycja listy widoczności"
::msgcat::mcset pl "Enable metacontacts" "Włącz metakontakty"
::msgcat::mcset pl "Font to use in chat windows." "Czcionka używana w oknach\
        rozmów."
::msgcat::mcset pl "Font to use in roster windows." "Czcionka używana w oknie\
        listy kontaktów."
::msgcat::mcset pl "Hide main window" "Ukryj główne okno"
::msgcat::mcset pl "History of availability status messages" "Historia\
        używanych opisów statusu"
::msgcat::mcset pl "Iconize" "Minimalizuj do ikony w zasobniku"
::msgcat::mcset pl "If set then open chat window/tab when user doubleclicks\
        roster item. Otherwise open normal message window." "Opcja włączona\
        oznacza że podwójne kliknięcie na element listy kontaktów otwiera\
        okno/kartę rozmowy. W przeciwnym przypadku otwierane jest okno\
        wiadomości."
::msgcat::mcset pl "Left" "Lewa"
::msgcat::mcset pl "Left mouse button" "Lewy przycisk myszy"
::msgcat::mcset pl "Manually edit rules" "Ręczna edycja reguł"
::msgcat::mcset pl "Maximum number of status messages to keep. If the history\
        size reaches this threshold, the oldest message will be deleted\
        automatically when a new one is recorded." "Maksymalna liczba\
        pamiętanych w historii opisów. Jeżeli rozmiar historii przekracza ten\
        próg, automatycznie usuwane są najstarsze opisy podczas dodawania\
        nowego."
::msgcat::mcset pl "Maximum width of tab buttons in tabbed mode." "Maksymalna\
        szerokość przycisku karty w trybie interfejsu z kartami."
::msgcat::mcset pl "Middle mouse button" "Środkowy przycisk myszy"
::msgcat::mcset pl "Minimize" "Minimalizuj do paska zadań"
::msgcat::mcset pl "Minimize to systray (if systray icon is enabled,\
        otherwise do nothing)" "Minimalizuj do ikony w zasobniku (jeżeli\
        ikona jest wyłączona to nic nie rób)"
::msgcat::mcset pl "Minimum width of tab buttons in tabbed mode." "Minimalna\
        szerokość przycisku karty w trybie interfejsu z kartami."
::msgcat::mcset pl "Mute sound" "Wyłącz dźwięki powiadomień"
::msgcat::mcset pl "Open chat..." "Rozpocznij rozmowę..."
::msgcat::mcset pl "Open login log" "Otwórz dziennik połączeń"
::msgcat::mcset pl "Plugins" "Wtyczki"
::msgcat::mcset pl "Popup menu" "Pokaż menu"
::msgcat::mcset pl "Presence bar" "Pasek wyboru statusu"
::msgcat::mcset pl "Privacy rules" "Ochrona prywatności"
::msgcat::mcset pl "Right" "Prawa"
::msgcat::mcset pl "Show main window" "Pokaż główne okno"
::msgcat::mcset pl "Show menu tearoffs when possible." "Włącz odrywane menu."
::msgcat::mcset pl "Show only the number of personal unread messages in\
        window title." "Pokaż tylko ilość wiadomości osobistych na pasku\
        tytułowym okna."
::msgcat::mcset pl "Show own resources" "Pokaż własne zasoby"
::msgcat::mcset pl "Show palette of emoticons" "Pokaż zestaw emotikonek"
::msgcat::mcset pl "Show presence bar." "Pokaż pasek wyboru statusu."
::msgcat::mcset pl "Show status bar." "Pokaż pasek stanu aplikacji."
::msgcat::mcset pl "Side where to place tabs in tabbed mode." "Miejsce\
        umieszczenia kart w głównym oknie programu w trybie interfejsu z\
        kartami."
::msgcat::mcset pl "Status bar" "Pasek stanu"
::msgcat::mcset pl "Stored main window state (normal or zoomed)"\
        "Przechowywany widok głównego okna (normalny lub powiększony)"
::msgcat::mcset pl "Systray:" "Zasobnik systemowy:"
::msgcat::mcset pl "Toolbar" "Pasek narzędzi"
::msgcat::mcset pl "Top" "Góra"
::msgcat::mcset pl "Use roster filter" "Włącz filtr listy kontaktów"
::msgcat::mcset pl "View" "Widok"
::msgcat::mcset pl "What action does the close button." "Akcja dla przycisku\
        zamykania okna."

# ifacetk/iroster.tcl
::msgcat::mcset pl "Alexey Shchepin" "Aleksej Szczepin"
::msgcat::mcset pl "Close tab" "Zamknij kartę"
::msgcat::mcset pl "Correct word" "Korekta słowa (ispell)"
::msgcat::mcset pl "Hide/Show roster" "Ukryj/pokaż listę kontaktów"
::msgcat::mcset pl "Konstantin Khomoutov" "Konstantin Khomoutow"
::msgcat::mcset pl "Main window:" "Okno Główne:"
::msgcat::mcset pl "Marshall T. Rose" "Marshall T. Rose"
::msgcat::mcset pl "Michail Litvak" "Michaił Litwak"
::msgcat::mcset pl "Move tab left/right" "Przesuń kartę w lewo/prawo"
::msgcat::mcset pl "Previous/Next history message" "Następna/poprzednia\
        wiadomość w historii"
::msgcat::mcset pl "Previous/Next tab" "Poprzedna/następna karta"
::msgcat::mcset pl "Redo" "Ponów"
::msgcat::mcset pl "Right mouse button" "Prawy przycisk myszy"
::msgcat::mcset pl "Scroll chat window up/down" "Przewiń okno rozmów w górę/w\
        dół"
::msgcat::mcset pl "Sergei Golovan" "Siergiej Golowan"
::msgcat::mcset pl "Show emoticons" "Pokaż zestaw emotikonek"
::msgcat::mcset pl "Switch to tab number 1-9,10" "Przełącz na kartę nr\
        1-9,10"
::msgcat::mcset pl "Undo" "Cofnij"

# ifacetk/ilogin.tcl
::msgcat::mcset pl "Address type not supported by SOCKS proxy"\
        "Nieobsługiwany przez SOCKS proxy typ adresu"
::msgcat::mcset pl "Allow plaintext authentication mechanisms" "Włącz\
        mechanizmy uwierzytelniania zwykłym tekstem"
::msgcat::mcset pl "Allow X-GOOGLE-TOKEN authentication mechanisms. It\
        requires connection to Google via HTTPS." "Włącz mechanizm\
        uwierzytelniania X-GOOGLE-TOKEN. Wymaga to połączenia do serwerów\
        Google przez HTTPS."
::msgcat::mcset pl "Allow X-GOOGLE-TOKEN SASL mechanism" "Wlącz mechanizm\
        X-GOOGLE-TOKEN w SASL"
::msgcat::mcset pl "Authentication" "Uwierzytelnianie"
::msgcat::mcset pl "Compression" "Kompresja"
::msgcat::mcset pl "Connection refused by destination host" "Połączenie\
        odrzucone przez serwer docelowy"
::msgcat::mcset pl "Encryption (legacy SSL)" "Szyfrowanie SSL"
::msgcat::mcset pl "Encryption (STARTTLS)" "Szyfrowanie STARTTLS"
::msgcat::mcset pl "Explicitly specify host and port to connect" "Ręczne\
        ustawienie portu i nazwy serwera do połączenia"
::msgcat::mcset pl "Host unreachable" "Serwer niedostępny"
::msgcat::mcset pl "Host:" "Serwer:"
::msgcat::mcset pl "Incorrect SOCKS version" "Nieprawidłowa wersja SOCKS"
::msgcat::mcset pl "Login retry for %s in %s" "Ponowna próba połączenia dla\
        %s za %s"
::msgcat::mcset pl "Network failure" "Awaria sieci"
::msgcat::mcset pl "Network unreachable" "Sieć nieosiągalna"
::msgcat::mcset pl "Plaintext" "Zwykły tekst"
::msgcat::mcset pl "Proxy authentication required" "Wymagane uwierzytelnianie\
        proxy"
::msgcat::mcset pl "Proxy password:" "Hasło proxy:"
::msgcat::mcset pl "Proxy port:" "Port proxy:"
::msgcat::mcset pl "Proxy server:" "Nazwa serwera proxy:"
::msgcat::mcset pl "Proxy type:" "Typ proxy:"
::msgcat::mcset pl "Proxy username:" "Użytkownik proxy:"
::msgcat::mcset pl "SOCKS authentication failed" "Uwierzytelnianie SOCKS nie\
        powiodło się"
::msgcat::mcset pl "SOCKS command not supported" "Nieobsługiwane polecenie\
        SOCKS"
::msgcat::mcset pl "SOCKS connection not allowed by ruleset" "Połączenie\
        SOCKS zablokowane przez reguły dostępu"
::msgcat::mcset pl "SOCKS request failed" "Odwołanie SOCKS nie powiodło się"
::msgcat::mcset pl "SOCKS server cannot identify username" "Serwer SOCKS nie\
        może zidentyfikować nazwy użytkownika"
::msgcat::mcset pl "SOCKS server username identification failed"\
        "Identyfikacja nazwy użytkownika serwera SOCKS nie powiodła się"
::msgcat::mcset pl "SSL & Compression" "Kompresja i SSL"
::msgcat::mcset pl "SSL certificate:" "Certyfikat SSL:"
::msgcat::mcset pl "TTL expired" "TTL wygasło"
::msgcat::mcset pl "Unknown address type" "Nieznany typ adresu"
::msgcat::mcset pl "Unknown error" "Nieznany błąd"
::msgcat::mcset pl "Unsupported SOCKS authentication method" "Nieobsługiwana\
        metoda uwierzytelniania SOCKS"
::msgcat::mcset pl "Unsupported SOCKS method" "Nieobsługiwana metoda SOCKS"
::msgcat::mcset pl "Use SASL authentication" "Włącz uwierzytelnianie SASL"

# pixmaps.tcl
::msgcat::mcset pl "Tkabber icon theme. To make new theme visible for Tkabber\
        put it to some subdirectory of %s." "Motyw ikon Tkabbera. Aby nowy\
        motyw był widoczny w Tkabberze, należy umieścić go jako podkatalog\
        katalogu %s."

# si.tcl
::msgcat::mcset pl "Enable SI transport %s." "Włącz transport SI %s."
::msgcat::mcset pl "File transfer aborted" "Przesyłanie pliku zostało\
        przerwane"
::msgcat::mcset pl "Opening SI connection" "Otwieranie połączenia SI"
::msgcat::mcset pl "SI connection closed" "Połączenie SI zakończone"
::msgcat::mcset pl "Stream method negotiation failed" "Nie powiodło się\
        uzgadnianie metody przesyłu strumienia"

# plugins/si/socks5.tcl
::msgcat::mcset pl "Aborted" "Przerwano"
::msgcat::mcset pl "Cannot connect to proxy" "Nie można połączyć się z\
        serwerem proxy"
::msgcat::mcset pl "Cannot negotiate proxy connection" "Nie udało się\
        wynegocjować połączenia proxy"
::msgcat::mcset pl "Illegal result" "Nieprawidłowy wynik"
::msgcat::mcset pl "List of proxy servers for SOCKS5 bytestreams (all\
        available servers will be tried for mediated connection)."\
        "Rozdzielona spacjami lista serwerów proxy do połączeń SOCKS5\
        (wszystkie wymienione serwery zostaną sprawdzone przy połączeniu\
        negocjowanym)."
::msgcat::mcset pl "Opening SOCKS5 listening socket" "Otwieranie gniazda\
        SOCKS5"
::msgcat::mcset pl "Use mediated SOCKS5 connection if proxy is available."\
        "Włącz negocjację połączenia SOCKS5 jeżeli dostępny jest serwer\
        proxy."

# plugins/si/iqibb.tcl
::msgcat::mcset pl "Opening IQ-IBB connection" "Otwieranie połączenia IQ-IBB"

# plugins/filetransfer/si.tcl
::msgcat::mcset pl "Receive error: Stream ID is in use" "Błąd odbioru: ID\
        strumienia jest w użuciu"
::msgcat::mcset pl "Stream initiation options." "Ustawienia protokołu\
        inicjacji strumienia (SI)."
::msgcat::mcset pl "Transfer failed: %s" "Nie udało się przesłać pliku: %s"

# plugins/filetransfer/http.tcl
::msgcat::mcset pl "Can't receive file: %s" "Nie udało się odebrać pliku: %s"
::msgcat::mcset pl "File path:" "Plik:"
::msgcat::mcset pl "Force advertising this hostname (or IP address) for\
        outgoing HTTP file transfers." "Wymuś rozgłaszanie nazwy tego hosta\
        (lub adresu IP) przy wysyłaniu plików przez HTTP."
::msgcat::mcset pl "HTTP options." "Ustawienia protokołu HTTP."
::msgcat::mcset pl "Port for outgoing HTTP file transfers (0 for assigned\
        automatically). This is useful when sending files from behind a NAT\
        with a forwarded port." "Numer portu przy wysyłaniu plików przez HTTP\
        (jeżeli 0 to port zostanie przypisany automatycznie). Jest to\
        przydatne przy wysyłaniu plików z sieci ukrytej za NAT z\
        przekierowanym portem (forwarding)."

# plugins/general/offline.tcl
::msgcat::mcset pl "Fetch all messages" "Pobierz wszystkie wiadomości"
::msgcat::mcset pl "Fetch message" "Pobierz wiadomość"
::msgcat::mcset pl "Fetch unseen messages" "Pobierz nieoglądane wiadomości"
::msgcat::mcset pl "Offline Messages" "Wiadomości nieprzeczytane"
::msgcat::mcset pl "Purge all messages" "Usuń wszystkie wiadomości"
::msgcat::mcset pl "Purge message" "Usuń wiadomość"
::msgcat::mcset pl "Purge seen messages" "Usuń oglądane wiadomości"
::msgcat::mcset pl "Retrieve offline messages using POP3-like protocol."\
        "Pobierz nieprzeczytane wiadomości z serwera używając protokołu\
        podobnego do POP3."
::msgcat::mcset pl "Sort by from" "Sortuj wg nadawcy"
::msgcat::mcset pl "Sort by node" "Sortuj wg powiązań"
::msgcat::mcset pl "Sort by type" "Sortuj wg typu"

# plugins/general/annotations.tcl
::msgcat::mcset pl "Created: %s" "Utworzono: %s"
::msgcat::mcset pl "Edit item notes..." "Edytuj notatkę..."
::msgcat::mcset pl "Edit roster notes for %s" "Edycja notatki dla %s"
::msgcat::mcset pl "Modified: %s" "Zmodyfikowano: %s"
::msgcat::mcset pl "Notes" "Notatki"
::msgcat::mcset pl "Roster Notes" "Notatki dla pozycji w liście kontaktów"
::msgcat::mcset pl "Store" "Zapisz"
::msgcat::mcset pl "Storing roster notes failed: %s" "Zapis notatki dla\
        pozycji listy kontaktów nie powiódł się: %s"

# plugins/general/headlines.tcl
::msgcat::mcset pl "<none>" "<brak>"
::msgcat::mcset pl "Format of timestamp in headline tree view. Set to empty\
        string if you don't want to see timestamps." "Format znacznika czasu\
        w oknie nagłówków wiadomości. Zostawienie tego pola pustego spowoduje\
        wyłączenie znaczników czasu."
::msgcat::mcset pl "Read on..." "Czytaj dalej..."
::msgcat::mcset pl "Show balloons with headline messages over tree nodes."\
        "Pokazuj dymki podpowiedzi z treścią nagłówka nad elemetami drzewka\
        nagłówków."
::msgcat::mcset pl "Sort by date" "Sortuj wg daty"

# plugins/search/search.tcl
::msgcat::mcset pl "Match case while searching in chat, log or disco\
        windows." "Rozróżniaj wielkość liter podczas wyszukiwania w oknach\
        rozmowy, historii i przeglądarki usług."
::msgcat::mcset pl "Search in Tkabber windows options." "Ustawienia\
        wyszukiwania w oknach Tkabbera."
::msgcat::mcset pl "Specifies search mode while searching in chat, log or\
        disco windows. \"substring\" searches exact substring, \"glob\" uses\
        glob style matching, \"regexp\" allows to match regular expression."\
        "Określa tryb wyszukiwania w rozmowach, historii i przeglądarce\
        usług. \"substring\" wyszukuje dokładny podciąg znaków, \"glob\"\
        używa stylu dopasowań glob, \"regexp\" pozwala na używanie wyrażeń\
        regularnych."

# plugins/roster/cache_categories.tcl
::msgcat::mcset pl "Cached service categories and types (from disco#info)."\
        "Typy i kategorie usług przechowywane w pamięci podręcznej (z\
        disco#info)."

# plugins/general/xaddress.tcl
::msgcat::mcset pl "Blind carbon copy" "Ukryta kopia"
::msgcat::mcset pl "Carbon copy" "Kopia"
::msgcat::mcset pl "Extended addressing fields:" "Rozszerzone pola adresowe:"
::msgcat::mcset pl "Forwarded by:" "Przekazane przez:"
::msgcat::mcset pl "No reply" "Bez odpowiedzi"
::msgcat::mcset pl "Original from" "Oryginalny nadawca"
::msgcat::mcset pl "Original to" "Oryginalny adresat"
::msgcat::mcset pl "Reply to" "Odpowiedź do"
::msgcat::mcset pl "Reply to room" "Odpowiedź do pokoju"
::msgcat::mcset pl "This message was forwarded by %s\n" "Ta wiadomość została\
        przekazana przez %s\n"
::msgcat::mcset pl "This message was sent by %s\n" "Ta wiadomość została\
        wysłana przez %s\n"
::msgcat::mcset pl "To" "Do"

# plugins/general/xcommands.tcl
::msgcat::mcset pl "Commands" "Polecenia"
::msgcat::mcset pl "Error completing command: %s" "Błąd przy uzupełnianiu\
        polecenia: %s"
::msgcat::mcset pl "Error executing command: %s" "Błąd przy uruchamianiu\
        polecenia: %s"
::msgcat::mcset pl "Error:" "Błąd:"
::msgcat::mcset pl "Execute command" "Uruchom polecenie"
::msgcat::mcset pl "Finish" "Zakończ"
::msgcat::mcset pl "Info:" "Informacja:"
::msgcat::mcset pl "Next" "Poprzednie"
::msgcat::mcset pl "Prev" "Następne"
::msgcat::mcset pl "Submit" "Wyślij"
::msgcat::mcset pl "Warning:" "Ostrzeżenie:"

# plugins/general/remote.tcl
::msgcat::mcset pl "Accept connections from my own JID." "Akceptuj połączenia\
        z własnego JID."
::msgcat::mcset pl "Accept connections from the listed JIDs." "Akceptuj\
        połączenia od następujących JID (pozycje listy oddziel spacjami)."
::msgcat::mcset pl "All unread messages were forwarded to %s." "Wszystkie\
        nieprzeczytane wiadomości zostały przekazane do %s."
::msgcat::mcset pl "Enable remote control." "Włącz obsługę zdalnego\
        sterownia."
::msgcat::mcset pl "Remote control options." "Ustawienia zdalnego sterowania\
        Tkabberem."
::msgcat::mcset pl "Show my own resources in the roster." "Pokaż własne\
        zasoby na liście kontaktów."
::msgcat::mcset pl "This message was forwarded to %s" "Ta wiadomość została\
        przekazana do %s"

# plugins/chat/log_on_open.tcl
::msgcat::mcset pl "Maximum interval length in hours for which log messages\
        should be shown in newly opened chat window (if set to negative then\
        the interval is unlimited)." "Maksymalny odstęp czasu od ostatniej\
        rozmowy (w godzinach), dla którego wiadomości historii pokazywane\
        będą w nowo otwartych oknach (liczba ujemna oznacza brak limitu)"
::msgcat::mcset pl "Maximum number of log messages to show in newly opened\
        chat window (if set to negative then the number is unlimited)."\
        "Maksymalna liczba wiadomości historii, pokazywana w nowo otwieranych\
        oknach rozmów (liczba ujemna oznacza brak limitu)."

# plugins/richtext/stylecodes.tcl
::msgcat::mcset pl "Emphasize stylecoded messages using different fonts."\
        "Formatuj wyróżnione części tekstu używając różnych czcionek."
::msgcat::mcset pl "Handling of \"stylecodes\". Stylecodes are (groups of)\
        special formatting symbols used to emphasize parts of the text by\
        setting them with boldface, italics or underlined styles, or as\
        combinations of these." "Obsługa znaków formatujących. Znaki\
        formatujące są (grupującymi tekst) znakami specjalnymi, używanymi do\
        wyróżnienia części tekstu przez *wytłuszczenie*, \kursywę\,\
        _podkreślenie_ lub kombinację tych trzech opcji."
::msgcat::mcset pl "Hide characters comprising stylecode markup." "Ukryj\
        znaki formatujące tekst."

# richtext.tcl
::msgcat::mcset pl "Settings of rich text facility which is used to render\
        chat messages and logs." "Ustawienia mechanizmu formatowania tekstu,\
        który jest używany do wyświetlania wiadomości w rozmowach i\
        historii."

# plugins/richtext/emoticons.tcl
::msgcat::mcset pl "Handle ROTFL/LOL smileys -- those like :))) -- by\
        \"consuming\" all that parens and rendering the whole word with\
        appropriate icon." "Obsługa emotikonek ROTFL/LOL -- typu :))) --\
        przez obcięcie nadmiarowych znaków i wyświetlenie całego wyrazu za\
        pomocą odpowiedniej ikony."
::msgcat::mcset pl "Handling of \"emoticons\". Emoticons (also known as\
        \"smileys\") are small pictures resembling a human face used to\
        represent user's emotion. They are typed in as special mnemonics like\
        :) or can be inserted using menu." "Obsługa \"emotikon\". Emotikony\
        (nazywane także \"buźkami\") to małe obrazki przypominające ludzką\
        twarz, używane do wyrażania uczuć osoby piszącej. Wstawiane są\
        poprzez wpisanie specjalnych skrótów np. :) lub przez wybranie z\
        menu."
::msgcat::mcset pl "Show images for emoticons." "Pokaż obrazki emotikon."
::msgcat::mcset pl "Tkabber emoticons theme. To make new theme visible for\
        Tkabber put it to some subdirectory of %s." "Motyw emotikon Tkabbera.\
        Aby nowy motyw był widoczny w Tkabberze, należy umieścić go jako\
        podkatalog katalogu %s."
::msgcat::mcset pl "Use only whole words for emoticons." "Zamieniaj tylko\
        całe wyrazy na emotikony."

# utils.tcl
::msgcat::mcset pl "day" "dzień"
::msgcat::mcset pl "days" "dni"
::msgcat::mcset pl "hour" "godzina"
::msgcat::mcset pl "hours" "godzin"
::msgcat::mcset pl "minute" "minuta"
::msgcat::mcset pl "minutes" "minut"
::msgcat::mcset pl "second" "sekunda"
::msgcat::mcset pl "seconds" "sekund"

# pubsub.tcl
::msgcat::mcset pl "Configure node" "Konfiguracja węzła"
::msgcat::mcset pl "Edit entities affiliations: %s" "Edytuj przynależności\
        obiektów: %s"
::msgcat::mcset pl "Jabber ID" "Jabber ID"
::msgcat::mcset pl "Outcast" "Wyrzutek"
::msgcat::mcset pl "Owner" "Właściciel"
::msgcat::mcset pl "Pending" "Oczekujący"
::msgcat::mcset pl "Publisher" "Wydawca"
::msgcat::mcset pl "Pubsub request failed: %s" "Wywołanie pubsub nie powiodło\
        się: %s"
::msgcat::mcset pl "Pubsub request succeeded" "Wywołanie pubsub powiodło się"
::msgcat::mcset pl "Request default configuration" "Pobierz domyślną\
        konfigurację"
::msgcat::mcset pl "Retrieve subscriptions" "Pobierz subskrypcje"
::msgcat::mcset pl "SubID" "SubID"
::msgcat::mcset pl "Subscribed" "Zasubskrybowany"
::msgcat::mcset pl "Subscription" "Subskrypcja"
::msgcat::mcset pl "Subscriptions to pubsub nodes at %s" "Subskrypcje do\
        węzłów pubsub na %s"
::msgcat::mcset pl "Success" "Sukces"
::msgcat::mcset pl "Unconfigured" "Nieskonfigurowany"
::msgcat::mcset pl "Unubscribe" "Anuluj subskrypcję"

# plugins/roster/fetch_nicknames.tcl
::msgcat::mcset pl "Fetch nickname" "Pobierz pseudonim"
::msgcat::mcset pl "Fetch nicknames of all users in group" "Pobierz\
        pseudonimy dla wszystkich w grupie"
::msgcat::mcset pl "Fetch user nicknames" "Pobierz pseudonimy kontaktów"

# plugins/general/session.tcl
::msgcat::mcset pl "Load state on start" "Wczytaj zapisaną sesję przy\
        starcie"
::msgcat::mcset pl "Load state on Tkabber start." "Wczytaj zapisaną sesję\
        przy starcie Tkabbera."
::msgcat::mcset pl "Save state" "Zapisz sesję teraz"
::msgcat::mcset pl "Save state on exit" "Zapisz sesję przy zamknięciu"
::msgcat::mcset pl "Save state on Tkabber exit." "Zapisz sesję przy\
        zamknięciu Tkabbera."
::msgcat::mcset pl "Tkabber save state options." "Ustawienia zapisu sesji\
        Tkabbera."

# config.tcl
::msgcat::mcset pl "Attention" "Uwaga"
::msgcat::mcset pl "Please stand by..." "Proszę czekać..."
::msgcat::mcset pl "Please, be patient while Tkabber configuration directory\
        is being transferred to the new location" "Proszę czekać, katalog\
        konfiguracyjny Tkabbera jest przenoszony do nowej lokalizacji"
::msgcat::mcset pl "Tkabber configuration directory transfer failed\
        with:\n%s\n Tkabber will use the old directory:\n%s" "Nie udało się\
        przenieść katalogu konfiguracyjnego Tkabbera:\n%s\n Zostanie użyty\
        stary katalog:\n%s"
::msgcat::mcset pl "Your new Tkabber config directory is now:\n%s\nYou can\
        delete the old one:\n%s" "Nowy katalog konfiguracyjny Tkabber to\
        teraz:\n%s\nMoża już usunąć stary katalog:\n%s"

# plugins/general/tkcon.tcl
::msgcat::mcset pl "Show TkCon console" "Otwórz konsolę TkCon"

# plugins/general/copy_jid.tcl
::msgcat::mcset pl "Copy JID to clipboard" "Kopiuj JID do schowka"
::msgcat::mcset pl "Copy real JID to clipboard" "Kopiuj prawdziwy JID do\
        schowka"

# plugins/iq/ping.tcl
::msgcat::mcset pl "Ping server using XMPP ping requests." "Sprawdzaj serwer\
        za pomocą zapytań XMPP ping."
::msgcat::mcset pl "Reconnect to server if it does not reply (with result or\
        with error) to XMPP ping request in specified time interval (in\
        seconds)." "Połącz się ponownie z serwerem, jeżeli nie odpowiada on\
        (wynikiem lub błędem) na zapytania XMPP ping po określonym (w\
        sekundach) odstępnie czasu."
::msgcat::mcset pl "Reply to XMPP ping requests." "Odpowiadaj na zapytania\
        XMPP ping."

# plugins/chat/muc_ignore.tcl
::msgcat::mcset pl "Edit MUC ignore rules" "Edycja reguł ignorowania w MUC"
::msgcat::mcset pl "Error loading MUC ignore rules, purged." "Błąd podczas\
        wczytywania reguł ignorowania w MUC, reguły są puste."
::msgcat::mcset pl "Ignore" "Ignoruj"
::msgcat::mcset pl "Ignore chat messages" "Ignoruj wiadomości w rozmowach"
::msgcat::mcset pl "Ignore groupchat messages" "Ignoruj wiadomości w\
        konferencjach"
::msgcat::mcset pl "Ignoring groupchat and chat messages from selected\
        occupants of multi-user conference rooms." "Ignorowanie wiadomości w\
        rozmowach i konferencjach od wybranych uczestników pokoi\
        konferencyjnych."
::msgcat::mcset pl "MUC Ignore" "Ignorowanie w MUC"
::msgcat::mcset pl "MUC Ignore Rules" "Reguły ignorowania w MUC"
::msgcat::mcset pl "When set, all changes to the ignore rules are applied\
        only until Tkabber is closed\; they are not saved and thus will be\
        not restored at the next run." "Jeżeli ustawiono, to wszystkie zmiany\
        reguł ignorowania są widoczne tylko do czasu następnego uruchomienia\
        Tkabbera\; reguły nie są zapisywane i nie będą odtworzone przy\
        następnym uruchomieniu."

# plugins/chat/histool.tcl
::msgcat::mcset pl "Chats History" "Archiwum rozmów"
::msgcat::mcset pl "Chats history" "Archiwum rozmów"
::msgcat::mcset pl "Client message" "Wiadomość klienta"
::msgcat::mcset pl "Full-text search" "Wyszukiwanie"
::msgcat::mcset pl "JID list" "Lista JID"
::msgcat::mcset pl "Logs" "Dzienniki"
::msgcat::mcset pl "Server message" "Wiadomość serwera"
::msgcat::mcset pl "Unsupported log dir format" "Nieobsługiwany format\
        katalogu historii"
::msgcat::mcset pl "WARNING: %s\n" "UWAGA: %s\n"

# plugins/chat/abbrev.tcl
::msgcat::mcset pl "Abbreviations:" "Skróty:"
::msgcat::mcset pl "Added abbreviation:\n%s: %s" "Dodano skrót:\n%s: %s"
::msgcat::mcset pl "Deleted abbreviation: %s" "Usunięto skrót: %s"
::msgcat::mcset pl "No such abbreviation: %s" "Nie ma takiego skrótu: %s"
::msgcat::mcset pl "Purged all abbreviations" "Usunięto wszystkie skróty"
::msgcat::mcset pl "Usage: /abbrev WHAT FOR" "Użycie: /abbrev SKRÓT DO_CZEGO"
::msgcat::mcset pl "Usage: /unabbrev WHAT" "Użycie: /unabbrev SKRÓT"

# pep.tcl
::msgcat::mcset pl "Personal Eventing" "Zdarzenia osobiste"
::msgcat::mcset pl "Personal eventing" "Zdarzenia osobiste"
::msgcat::mcset pl "Personal eventing via pubsub plugins options."\
        "Ustawienia zdarzeń osobistych obsługiwanych przez wtyczki pubsub."

# plugins/pep/user_mood.tcl
::msgcat::mcset pl "\n\tMood: %s" "\n\tNastrój: %s"
::msgcat::mcset pl "\n\tUser mood subscription: %s" "\n\tSubskrypcja nastroju\
        użytkownika: %s"
::msgcat::mcset pl "%s's mood changed to %s" "%s zmienił nastrój na %s"
::msgcat::mcset pl "%s's mood is unset" "Użytkownik %s nie ustawił nastroju"
::msgcat::mcset pl "afraid" "przestraszony"
::msgcat::mcset pl "amazed" "zdumiony"
::msgcat::mcset pl "angry" "zły"
::msgcat::mcset pl "annoyed" "zirytowany"
::msgcat::mcset pl "anxious" "zaniepokojony"
::msgcat::mcset pl "aroused" "pobudzony"
::msgcat::mcset pl "ashamed" "zawstydzony"
::msgcat::mcset pl "Auto-subscribe to other's user mood" "Automatycznie\
        subskrybuj nastrój innego użytkownika"
::msgcat::mcset pl "Auto-subscribe to other's user mood notifications."\
        "Automatycznie subskrybuj powiadomienia o nastroju innego\
        użytkownika."
::msgcat::mcset pl "bored" "znudzony"
::msgcat::mcset pl "brave" "dzielny"
::msgcat::mcset pl "calm" "spokojny"
::msgcat::mcset pl "Cannot publish empty mood" "Nie można opublikować pustego\
        nastroju"
::msgcat::mcset pl "cold" "lodowaty"
::msgcat::mcset pl "confused" "rozkojarzony"
::msgcat::mcset pl "contented" "zadowolony"
::msgcat::mcset pl "cranky" "drażliwy"
::msgcat::mcset pl "curious" "zaciekawiony"
::msgcat::mcset pl "depressed" "przybity"
::msgcat::mcset pl "disappointed" "rozczarowany"
::msgcat::mcset pl "disgusted" "zdegustowany"
::msgcat::mcset pl "distracted" "strapiony"
::msgcat::mcset pl "embarrassed" "zakłopotany"
::msgcat::mcset pl "Error" "Błąd"
::msgcat::mcset pl "excited" "podniecony"
::msgcat::mcset pl "flirtatious" "kokieteryjny"
::msgcat::mcset pl "frustrated" "sfrustrowany"
::msgcat::mcset pl "grumpy" "zrzędliwy"
::msgcat::mcset pl "guilty" "winny"
::msgcat::mcset pl "happy" "szczęśliwy"
::msgcat::mcset pl "hot" "napalony"
::msgcat::mcset pl "humbled" "skromny"
::msgcat::mcset pl "humiliated" "upokorzony"
::msgcat::mcset pl "hungry" "głodny"
::msgcat::mcset pl "hurt" "zraniony"
::msgcat::mcset pl "impressed" "pod_wrażeniem"
::msgcat::mcset pl "in_awe" "zatrwożony"
::msgcat::mcset pl "in_love" "zakochany"
::msgcat::mcset pl "indignant" "oburzony"
::msgcat::mcset pl "interested" "zainteresowany"
::msgcat::mcset pl "intoxicated" "odurzony"
::msgcat::mcset pl "invincible" "niezwyciężony"
::msgcat::mcset pl "jealous" "zazdrosny"
::msgcat::mcset pl "lonely" "samotny"
::msgcat::mcset pl "mean" "wredny"
::msgcat::mcset pl "Mood" "Nastrój"
::msgcat::mcset pl "Mood:" "Nastrój:"
::msgcat::mcset pl "moody" "kapryśny"
::msgcat::mcset pl "nervous" "nerwowy"
::msgcat::mcset pl "neutral" "neutralny"
::msgcat::mcset pl "offended" "obrażony"
::msgcat::mcset pl "playful" "figlarny"
::msgcat::mcset pl "proud" "dumny"
::msgcat::mcset pl "Publish user mood..." "Publikuj nastrój użytkownika..."
::msgcat::mcset pl "Publishing is only possible while being online"\
        "Publikowanie jest możliwe dopiero po nawiązaniu połączenia"
::msgcat::mcset pl "relieved" "beznadziejny"
::msgcat::mcset pl "remorseful" "skruszony"
::msgcat::mcset pl "restless" "niespokojny"
::msgcat::mcset pl "sad" "smutny"
::msgcat::mcset pl "sarcastic" "sarkastyczny"
::msgcat::mcset pl "serious" "poważny"
::msgcat::mcset pl "shocked" "zaszokowany"
::msgcat::mcset pl "shy" "nieśmiały"
::msgcat::mcset pl "sick" "chory"
::msgcat::mcset pl "sleepy" "śpiący"
::msgcat::mcset pl "stressed" "zestresowany"
::msgcat::mcset pl "surprised" "zaskoczony"
::msgcat::mcset pl "thirsty" "spragniony"
::msgcat::mcset pl "Unpublish user mood" "Anuluj publikację nastroju"
::msgcat::mcset pl "Unpublish user mood..." "Anuluj publikację nastroju..."
::msgcat::mcset pl "Unsubscribe" "Anuluj subskrypcję"
::msgcat::mcset pl "Use connection:" "Użyj połączenia:"
::msgcat::mcset pl "User mood" "Nastrój użytkownika"
::msgcat::mcset pl "User mood publishing failed: %s" "Publikacja nastroju\
        użytkownika nie udała się: %s"
::msgcat::mcset pl "User mood unpublishing failed: %s" "Anulowanie publikacji\
        nastroju nie udało się: %s"
::msgcat::mcset pl "worried" "zmartwiony"

# plugins/pep/user_tune.tcl
::msgcat::mcset pl "\n\tTune: %s - %s" "\n\tMelodia: %s - %s"
::msgcat::mcset pl "\n\tUser tune subscription: %s" "\n\tSubskrypcja melodii\
        użytkownika: %s"
::msgcat::mcset pl "%s's tune changed to %s - %s" "%s zmienił melodię na %s -\
        %s"
::msgcat::mcset pl "%s's tune has stopped playing" "Odtwarzanie melodii %s\
        zostało zatrzymane"
::msgcat::mcset pl "%s's tune is unset" "Użytkownik %s nie ustawił melodii"
::msgcat::mcset pl "Artist:" "Artysta:"
::msgcat::mcset pl "Auto-subscribe to other's user tune" "Automatycznie\
        subskrybuj melodię innego użytkownika"
::msgcat::mcset pl "Auto-subscribe to other's user tune notifications."\
        "Automatycznie subskrybuj powiadomienia o melodii innego\
        użytkownika."
::msgcat::mcset pl "Length:" "Długość:"
::msgcat::mcset pl "Publish" "Publikuj"
::msgcat::mcset pl "Publish \"playback stopped\" instead" "Publikuj\
        \"odtwarzanie zatrzymane\" zamiast tego"
::msgcat::mcset pl "Publish user tune..." "Publikuj melodię użytkownika..."
::msgcat::mcset pl "Rating:" "Ocena:"
::msgcat::mcset pl "Source:" "Żródło:"
::msgcat::mcset pl "Track:" "Ścieżka:"
::msgcat::mcset pl "Unpublish" "Anuluj publikację"
::msgcat::mcset pl "Unpublish user tune" "Anuluj publikację melodii"
::msgcat::mcset pl "Unpublish user tune..." "Anuluj publikację melodii..."
::msgcat::mcset pl "Unpublishing is only possible while being online"\
        "Anulowanie publikacji jest możliwe dopiero po nawiązaniu połączenia"
::msgcat::mcset pl "URI:" "URI:"
::msgcat::mcset pl "User tune" "Melodia użytkownika"
::msgcat::mcset pl "User tune publishing failed: %s" "Publikacja melodii nie\
        udała się: %s"
::msgcat::mcset pl "User tune unpublishing failed: %s" "Anulowanie publikacji\
        melodii nie udało się: %s"

# plugins/pep/user_activity.tcl
::msgcat::mcset pl "\n\tActivity: %s" "\n\tCzynność: %s"
::msgcat::mcset pl "\n\tUser activity subscription: %s" "\n\tSubskrypcja\
        czynności użytkownika: %s"
::msgcat::mcset pl "%s's activity changed to %s" "%s zmienił czynność na %s"
::msgcat::mcset pl "%s's activity is unset" "Użytkownik %s nie ustawił\
        czynności"
::msgcat::mcset pl "Activity" "Czynność"
::msgcat::mcset pl "Activity:" "Czynność:"
::msgcat::mcset pl "at the spa" "jestem w uzdrowisku"
::msgcat::mcset pl "Auto-subscribe to other's user activity" "Automatycznie\
        subskrybuj czynność innego użytkownika"
::msgcat::mcset pl "Auto-subscribe to other's user activity notifications."\
        "Automatycznie subskrybuj powiadomienia o czynności innego\
        użytkownika."
::msgcat::mcset pl "brushing teeth" "myję zęby"
::msgcat::mcset pl "buying groceries" "kupuję jedzenie"
::msgcat::mcset pl "Cannot publish empty activity" "Nie można opublikować\
        pustej czynności"
::msgcat::mcset pl "cleaning" "sprzątam"
::msgcat::mcset pl "coding" "koduję"
::msgcat::mcset pl "commuting" "w drodze do pracy"
::msgcat::mcset pl "cooking" "gotuję"
::msgcat::mcset pl "cycling" "jeżdżę na rowerze"
::msgcat::mcset pl "day off" "dzień wolny"
::msgcat::mcset pl "doing chores" "prace domowe"
::msgcat::mcset pl "doing maintenance" "pielęgnuję się"
::msgcat::mcset pl "doing the dishes" "myję naczynia"
::msgcat::mcset pl "doing the laundry" "robię pranie"
::msgcat::mcset pl "drinking" "piję"
::msgcat::mcset pl "driving" "jadę samochodem"
::msgcat::mcset pl "eating" "jem"
::msgcat::mcset pl "exercising" "gimnastykuję się"
::msgcat::mcset pl "gaming" "gram"
::msgcat::mcset pl "gardening" "uprawiam ogród"
::msgcat::mcset pl "getting a haircut" "obcinam włosy"
::msgcat::mcset pl "going out" "na wychodnym"
::msgcat::mcset pl "grooming" "higiena osobista"
::msgcat::mcset pl "hanging out" "na pogaduszkach"
::msgcat::mcset pl "having a beer" "piję piwo"
::msgcat::mcset pl "having a snack" "jem zakąskę"
::msgcat::mcset pl "having appointment" "mam wizytę"
::msgcat::mcset pl "having breakfast" "jem śniadanie"
::msgcat::mcset pl "having coffee" "piję kawę"
::msgcat::mcset pl "having dinner" "jem kolację"
::msgcat::mcset pl "having lunch" "jem obiad"
::msgcat::mcset pl "having tea" "piję herbatę"
::msgcat::mcset pl "hiking" "wędruję"
::msgcat::mcset pl "in a car" "w samochodzie"
::msgcat::mcset pl "in a meeting" "na spotkaniu"
::msgcat::mcset pl "in real life" "żyję w rzeczywistości"
::msgcat::mcset pl "inactive" "brak aktywności"
::msgcat::mcset pl "jogging" "jogging"
::msgcat::mcset pl "on a bus" "jadę autobusem"
::msgcat::mcset pl "on a plane" "lecę samolotem"
::msgcat::mcset pl "on a train" "jadę pociągiem"
::msgcat::mcset pl "on a trip" "w podróży"
::msgcat::mcset pl "on the phone" "przy telefonie"
::msgcat::mcset pl "on vacation" "na wakacjach"
::msgcat::mcset pl "on video phone" "rozmowa wideo"
::msgcat::mcset pl "partying" "imprezuję"
::msgcat::mcset pl "playing sports" "uprawiam sport"
::msgcat::mcset pl "Publish user activity..." "Publikuj czynność\
        użytkownika..."
::msgcat::mcset pl "reading" "czytam"
::msgcat::mcset pl "rehearsing" "robię próbę"
::msgcat::mcset pl "relaxing" "odpoczywam"
::msgcat::mcset pl "running" "biegam"
::msgcat::mcset pl "running an errand" "biegam z przesyłkami"
::msgcat::mcset pl "scheduled holiday" "zaplanowane wakacje"
::msgcat::mcset pl "shaving" "golę się"
::msgcat::mcset pl "shopping" "robię zakupy"
::msgcat::mcset pl "skiing" "jeżdżę na nartach"
::msgcat::mcset pl "sleeping" "śpię"
::msgcat::mcset pl "socializing" "udzielam się towarzysko"
::msgcat::mcset pl "studying" "studiuję"
::msgcat::mcset pl "Subactivity" "Czynność podrzędna"
::msgcat::mcset pl "Subactivity:" "Czynność podrzędna:"
::msgcat::mcset pl "sunbathing" "opalam się"
::msgcat::mcset pl "swimming" "pływam"
::msgcat::mcset pl "taking a bath" "biorę kąpiel"
::msgcat::mcset pl "taking a shower" "biorę prysznic"
::msgcat::mcset pl "talking" "rozmawiam"
::msgcat::mcset pl "traveling" "podróżuję"
::msgcat::mcset pl "Unpublish user activity" "Anuluj publikację czynności"
::msgcat::mcset pl "Unpublish user activity..." "Anuluj publikację\
        czynności..."
::msgcat::mcset pl "User activity" "Czynność użytkownika"
::msgcat::mcset pl "User activity publishing failed: %s" "Publikacja\
        czynności nie udała się: %s"
::msgcat::mcset pl "User activity unpublishing failed: %s" "Anulowanie\
        publikacji czynności nie udało się: %s"
::msgcat::mcset pl "walking" "spaceruję"
::msgcat::mcset pl "walking the dog" "wyprowadzam psa"
::msgcat::mcset pl "watching a movie" "oglądam film"
::msgcat::mcset pl "watching tv" "oglądam tv"
::msgcat::mcset pl "working" "pracuję"
::msgcat::mcset pl "working out" "trenuję"
::msgcat::mcset pl "writing" "piszę"

# plugins/general/caps.tcl
::msgcat::mcset pl "Enable announcing entity capabilities in every outgoing\
        presence." "Włącz rozgłaszanie własnych możliwości w każdej\
        wychodzącej informacji o statusie."
::msgcat::mcset pl "Options for entity capabilities plugin." "Ustawenia\
        wtyczki rozgłaszania własnych możliwości."
::msgcat::mcset pl "Use the specified function to hash supported features\
        list." "Użyj wybranej funkcji do utworzenia skrótu listy\
        obsługiwanych cech."

# plugins/iq/time2.tcl
::msgcat::mcset pl "Reply to entity time (urn:xmpp:time) requests." "Wysyłaj\
        odpowiedzi na zapytanie o własny czas (urn:xmpp:time)."

# plugins/pep/user_location.tcl
::msgcat::mcset pl "\n\tLocation: %s : %s" "\n\tLokalizacja: %s : %s"
::msgcat::mcset pl "\n\tUser location subscription: %s" "\n\tSubskrypcja\
        lokalizacji użytkownika: %s"
::msgcat::mcset pl "%s's location changed to %s : %s" "Lokalizacja\
        użytkownika %s zmieniła się na %s : %s"
::msgcat::mcset pl "%s's location is unset" "Użytkownik %s nie ustawił\
        lokalizacji"
::msgcat::mcset pl "Altitude:" "Wysokość:"
::msgcat::mcset pl "Area:" "Strefa:"
::msgcat::mcset pl "Auto-subscribe to other's user location" "Automatycznie\
        subskrybuj lokalizację innego użytkownika"
::msgcat::mcset pl "Auto-subscribe to other's user location notifications."\
        "Automatycznie subskrybuj powiadomienia o lokalizacji innego\
        użytkownika."
::msgcat::mcset pl "Bearing:" "Namiar:"
::msgcat::mcset pl "Building:" "Budynek:"
::msgcat::mcset pl "Floor:" "Piętro:"
::msgcat::mcset pl "GPS datum:" "Układ odniesienia GPS:"
::msgcat::mcset pl "Horizontal GPS error:" "Błąd horyzontalny GPS:"
::msgcat::mcset pl "Locality:" "Miejscowość:"
::msgcat::mcset pl "Postal code:" "Kod pocztowy:"
::msgcat::mcset pl "Publish user location..." "Publikuj swoją lokalizację..."
::msgcat::mcset pl "Region:" "Region:"
::msgcat::mcset pl "Room:" "Pokój:"
::msgcat::mcset pl "Speed:" "Prędkość:"
::msgcat::mcset pl "Street:" "Ulica:"
::msgcat::mcset pl "Timestamp:" "Zmacznik czasu:"
::msgcat::mcset pl "Unpublish user location" "Anuluj publikację swojej\
        lokalizacji"
::msgcat::mcset pl "Unpublish user location..." "Anuluj publikację swojej\
        lokalizacji..."
::msgcat::mcset pl "User location" "Lokalizacja użytkownika"
::msgcat::mcset pl "User location publishing failed: %s" "Publikacja\
        lokalizacji nie udała się: %s"
::msgcat::mcset pl "User location unpublishing failed: %s" "Anulowanie\
        publikacji lokalizacji nie udało się: %s"

# plugins/roster/bkup_annotations.tcl
::msgcat::mcset pl "Error restoring annotations: %s" "Błąd podczas\
        przywracania notatek: %s"

# plugins/roster/bkup_conferences.tcl
::msgcat::mcset pl "Error restoring conference bookmarks: %s" "Błąd podczas\
        przywracania zakładek z konferencjami: %s"

# plugins/roster/bkup_metacontacts.tcl
::msgcat::mcset pl "Error restoring metacontacts: %s" "Błąd podczas\
        przywracania metakontaktów: %s"

# plugins/roster/backup.tcl
::msgcat::mcset pl "Error importing roster contacts: %s" "Błąd podczas\
        importu listy kontaktów: %s"
::msgcat::mcset pl "Export roster" "Eksport listy kontaktów"
::msgcat::mcset pl "Export roster for %s..." "Eksport listy kontaktów dla\
        %s..."
::msgcat::mcset pl "Import roster" "Import listy kontaktów"
::msgcat::mcset pl "Import roster for %s..." "Import listy kontaktów dla\
        %s..."
::msgcat::mcset pl "Roster files" "Pliki listy kontaktów"
::msgcat::mcset pl "Roster import for %s is completed" "Import listy\
        kontaktów dla %s zakończony"

# plugins.tcl
::msgcat::mcset pl "External plugins options." "Ustawienia zewnętrznych\
        wtyczek."
::msgcat::mcset pl "Loading and unloading external plugins." "Ładowanie i\
        usuwanie zewnętrznych wtyczek."

# plugins/general/geometry.tcl
::msgcat::mcset pl "Stored main window geometry" "Zapisano geometrię głównego\
        okna"
::msgcat::mcset pl "Stored main window geometry in non-tabbed mode" "Zapisano\
        geometrię głównego okna w trybie bez kart"
::msgcat::mcset pl "Stored main window state (normal or zoomed) in non-tabbed\
        mode" "Zapisano stan (normalne lub zmaksymalizowane) głównego okna w\
        trybie bez kart"

# plugins/roster/metacontacts.tcl
::msgcat::mcset pl "Are you sure to delete %s's metacontact?" "Czy na pewno\
        usunąć metakontakt %s?"
::msgcat::mcset pl "Are you sure to delete metacontact?" "Czy na pewno usunąć\
        metakontakt?"
::msgcat::mcset pl "Create metacontact" "Utwórz metakontakt"
::msgcat::mcset pl "Delete metacontact" "Usuń metakontakt"
::msgcat::mcset pl "Delete metacontact..." "Usuń metakontakt..."
::msgcat::mcset pl "Edit %s's Metacontact" "Edytuj metakontakt %s"
::msgcat::mcset pl "Edit Metacontact" "Edytuj metakontakt"
::msgcat::mcset pl "Edit metacontact" "Edytuj metakontakt"
::msgcat::mcset pl "Metacontact" "Metakontakt"
::msgcat::mcset pl "Remove from metacontact" "Usuń z metakontaktu"
::msgcat::mcset pl "Storing roster metacontacts failed: %s" "Zapisanie\
        metakontaktów nie powiodło się: %s"

# proxy.tcl
::msgcat::mcset pl "Add proxy" "Dodaj proxy"
::msgcat::mcset pl "Exclude:" "Wyjątki:"
::msgcat::mcset pl "HTTP" "HTTP"
::msgcat::mcset pl "HTTP proxies" "Serwery proxy HTTP"
::msgcat::mcset pl "Manage proxy servers" "Zarządzaj serwerami proxy"
::msgcat::mcset pl "Match:" "Ustaw proxy dla:"
::msgcat::mcset pl "Save" "Zapisz"
::msgcat::mcset pl "Serialized array of proxy servers to connect via."\
        "Serializowana tablica serwerów proxy przez które można się łączyć."
::msgcat::mcset pl "Tunnel proxies" "Proxy tunelowane"

# plugins/chat/irc_commands.tcl
::msgcat::mcset pl "Already joined" "Już dołączono"

# --------------------------- tclxmpp package --------------------------------

# tclxmpp/xmpp/roster.tcl
::msgcat::mcset pl "Illegal option \"%s\"" "Nieprawidłowa opcja \"%s\""

# tclxmpp/xmpp/starttls.tcl
::msgcat::mcset pl "Server hasn't provided STARTTLS feature" "Serwer nie\
        oferuje mechanizmu STARTTLS"
::msgcat::mcset pl "STARTTLS aborted" "STARTTLS zostało przerwane"
::msgcat::mcset pl "STARTTLS failed" "STARTTLS nie powiodło się"
::msgcat::mcset pl "STARTTLS successful" "STARTTLS powiodło się"
::msgcat::mcset pl "STARTTLS timed out" "Przekroczono czas oczekiwania na\
        STARTTLS"

# tclxmpp/xmpp/component.tcl
::msgcat::mcset pl "Component handshake aborted" "Wymiana potwierdzeń dla\
        komponentu została przerwana"
::msgcat::mcset pl "Component handshake failed" "Wymiana potwierdzeń dla\
        komponentu nie powiodła się"
::msgcat::mcset pl "Component handshake succeeded" "Wymiana potwierdzeń dla\
        komponentu powiodła się"
::msgcat::mcset pl "Component handshake timed out" "Przekroczono czas\
        oczekiwania na wymianę potwierdzeń dla komponentu"
::msgcat::mcset pl "Missing option \"%s\"" "Brakująca opcja \"%s\""
::msgcat::mcset pl "Waiting for component handshake result" "Oczekiwanie na\
        wynik wymiany potwierdzeń dla komponentu"

# tclxmpp/xmpp/pconnect.tcl
::msgcat::mcset pl "Cannot connect to %s:%s" "Nie można połączyć się z %s:%s"
::msgcat::mcset pl "Cannot connect to proxy %s:%s" "Nie można połączyć się z\
        proxy %s:%s"
::msgcat::mcset pl "Connection aborted" "Połączenie zostało przerwane"
::msgcat::mcset pl "Connection to proxy aborted" "Połączenie z proxy zostało\
        przerwane"
::msgcat::mcset pl "IPv6 support is not available" "Nie jest dostępna obsługa\
        protokołu IPv6"
::msgcat::mcset pl "Options \"-host\" and \"-port\" are required" "Opcje\
        \"-host\" i \"-port\" są wymagane"
::msgcat::mcset pl "Unsupported proxy \"%s\"" "Nieobsługiwany serwer proxy\
        \"%s\""

# tclxmpp/xmpp/compress.tcl
::msgcat::mcset pl "Compression aborted" "Kompresja strumienia została\
        przerwana"
::msgcat::mcset pl "Compression negotiation failed" "Uzgadnianie metody\
        kompresji nie powiodło się"
::msgcat::mcset pl "Compression negotiation successful" "Uzgadnianie metody\
        kompresji powiodło się"
::msgcat::mcset pl "Compression setup failed" "Ustawienie kompresji nie\
        powiodło się"
::msgcat::mcset pl "Compression timed out" "Kompresja strumienia straciła\
        ważność"
::msgcat::mcset pl "Server hasn't provided compress feature" "Serwer nie\
        obsługuje kompresji strumienia"
::msgcat::mcset pl "Server hasn't provided supported compress method" "Serwer\
        nie oferuje obsługiwanej metody kompresji strumienia"
::msgcat::mcset pl "Unsupported compression method" "Nieobsługiwana metoda\
        kompresji"

# tclxmpp/xmpp/streamerror.tcl
::msgcat::mcset pl "Bad format" "Zły format"
::msgcat::mcset pl "Bad namespace prefix" "Zły prefiks przestrzeni nazw"
::msgcat::mcset pl "Connection timeout" "Przekroczono czas oczekiwania na\
        połączenie"
::msgcat::mcset pl "Host gone" "Serwer nie istnieje"
::msgcat::mcset pl "Host unknown" "Nieznany serwer"
::msgcat::mcset pl "Improper addressing" "Nieodpowiednia adresacja"
::msgcat::mcset pl "Invalid from" "Nieprawidłowy nadawca"
::msgcat::mcset pl "Invalid ID" "Nieprawidłowy ID"
::msgcat::mcset pl "Invalid namespace" "Nieprawidłowa przestrzeń nazw"
::msgcat::mcset pl "Invalid XML" "Nieprawidłowy XML"
::msgcat::mcset pl "Policy violation" "Naruszenie polityki bezpieczeństwa"
::msgcat::mcset pl "Remote connection failed" "Zdalne połączenie nie powiodło\
        się"
::msgcat::mcset pl "Resource constraint" "Ograniczenie zasobów"
::msgcat::mcset pl "Restricted XML" "Ograniczony XML"
::msgcat::mcset pl "See other host" "Sprawdź inny serwer"
::msgcat::mcset pl "Stream error" "Błąd strumienia"
::msgcat::mcset pl "Stream error (%s)" "Błąd strumienia (%s)"
::msgcat::mcset pl "Stream error (%s): %s" "Błąd strumienia (%s): %s"
::msgcat::mcset pl "Stream error: %s" "Błąd strumienia: %s"
::msgcat::mcset pl "System shutdown" "Wyłączenie systemu"
::msgcat::mcset pl "Unsupported encoding" "Nieobsługiwane kodowanie"
::msgcat::mcset pl "Unsupported stanza type" "Nieobsługiwany typ zwrotki"
::msgcat::mcset pl "Unsupported version" "Nieobsługiwana wersja"
::msgcat::mcset pl "XML not well-formed" "Źle sformatowany XML"

# tclxmpp/xmpp/iq.tcl
::msgcat::mcset pl "Illegal IQ type \"%s\"" "Nieprawidłowy typ IQ \"%s\""

# tclxmpp/xmpp/xmpp.tcl
::msgcat::mcset pl "An existing variable \"%s\" cannot be used as an XMPP\
        token" "Istniejąca zmienna \"%s\" nie może zostać użyta jako token\
        XMPP"
::msgcat::mcset pl "Free without disconnect" "Zwolnij bez rozłączenia"
::msgcat::mcset pl "IQ %s timed out" "Przekroczono czas oczekiwania na IQ %s"
::msgcat::mcset pl "IQ id %s doesn't exist in memory" "IQ o id %s nie\
        istnieje w pamięci"
::msgcat::mcset pl "IQ id doesn't exists in memory" "IQ id nie istnieje w\
        pamięci"
::msgcat::mcset pl "Opening stream aborted" "Przerwano otwieranie strumienia"
::msgcat::mcset pl "Opening stream timed out" "Przkeroczono czas oczekiwania\
        na otwarcie strumienia"
::msgcat::mcset pl "Option \"-command\" is illegal for IQ type \"%s\"" "Opcja\
        \"-command\" jest nieprawidłowa dla typu IQ \"%s\""
::msgcat::mcset pl "Unknown IQ type \"%s\"" "Nieznany typ IQ \"%s\""
::msgcat::mcset pl "Unknown message type %s" "Nieznany typ wiadomości %s"
::msgcat::mcset pl "Unsupported stream XMLNS \"%s\"" "Nieobsługiwana wartość\
        XMLNS \"%s\" dla strumienia"
::msgcat::mcset pl "Usage: ::xmpp::Set xlib property ?value?" "Użycie:\
        ::xmpp::Set xlib property ?value?"

# tclxmpp/xmpp/transport.tcl
::msgcat::mcset pl "Can't switch transport to \"%s\": %s" "Nie można\
        przełączyć transportu na \"%s\": %s"
::msgcat::mcset pl "Illegal command \"%s\"" "Nieprawidłowe polecenie \"%s\""
::msgcat::mcset pl "Transport \"%s\" already registered" "Transport \"%s\"\
        jest już zarejestrowany"
::msgcat::mcset pl "Unknown transport \"%s\"" "Nieznany transport \"%s\""

# tclxmpp/xmpp/auth.tcl
::msgcat::mcset pl "Illegal value \"%s\" for option \"%s\"" "Nieprawidłowa\
        wartość \"%s\" dla opcji \"%s\""
::msgcat::mcset pl "Non-SASL authentication aborted" "Uwierzytelnianie\
        Non-SASL zostało przerwane"
::msgcat::mcset pl "Non-SASL authentication failed" "Uwierzytelnianie\
        Non-SASL nie powiodło się"
::msgcat::mcset pl "Non-SASL authentication succeeded" "Uwierzytelnianie\
        Non-SASL powiodło się"
::msgcat::mcset pl "Non-SASL authentication timed out" "Przekroczono czas\
        oczekiwania na uwierzytelnianie Non-SASL"
::msgcat::mcset pl "Server doesn't support digest non-SASL authentication"\
        "Serwer nie obsługuje uwierzytelniania Non-SASL typu digest"
::msgcat::mcset pl "Server doesn't support plaintext non-SASL authentication"\
        "Serwer nie obsługuje uwierzytelniania Non-SASL zwykłym tekstem"
::msgcat::mcset pl "Server doesn't support plaintext or digest non-SASL\
        authentication" "Serwer nie obsługuje uwierzytelniania Non-SASL typu\
        digest i zwykłym tekstem"
::msgcat::mcset pl "Server hasn't provided non-SASL authentication feature"\
        "Serwer nie udostępnia uwierzytelniania Non-SASL"
::msgcat::mcset pl "Waiting for non-SASL authentication fields" "Oczekiwanie\
        na atrybuty uwierzytelniania non-SASL"
::msgcat::mcset pl "Waiting for non-SASL authentication results" "Oczekiwanie\
        na wyniki uwierzytelniania non-SASL"

# tclxmpp/xmpp/tls.tcl
::msgcat::mcset pl "TLS handshake failed: %s" "Wymiana potwierdzeń TLS nie\
        powiodła się: %s"

# tclxmpp/xmpp/xml.tcl
::msgcat::mcset pl "Illegal attribute \"xmlns\". Use -xmlns option"\
        "Nieprawidłowy atrybut \"xmlns\". Użyj opcji -xmlns"
::msgcat::mcset pl "Invalid option \"%s\"" "Nieprawidłowa opcja \"%s\""
::msgcat::mcset pl "Parser \"%s\" doesn't exist" "Parser \"%s\" nie istnieje"

# tclxmpp/xmpp/sasl.tcl
::msgcat::mcset pl "Authentication error" "Błąd uwierzytelniania"
::msgcat::mcset pl "Authentication failed" "Uwierzytelnianie nie powiodło\
        się"
::msgcat::mcset pl "Authentication succeeded" "Uwierzytelnianie powiodło się"
::msgcat::mcset pl "Cannot forbid digest mechanisms" "Nie można zabronić\
        mechanizmów digest"
::msgcat::mcset pl "Incorrect encoding" "Niepoprawne kodowanie"
::msgcat::mcset pl "Invalid authzid" "Niepoprawne authzid"
::msgcat::mcset pl "Invalid mechanism" "Nieprawidłowy mechanizm"
::msgcat::mcset pl "Mechanism too weak" "Mechanizm zbyt słaby"
::msgcat::mcset pl "Missing option \"-username\" or \"-domain\"" "Brakująca\
        opcja \"-username\" lub \"-domain\""
::msgcat::mcset pl "No SASL package found" "Nie znaleziono pakietu SASL"
::msgcat::mcset pl "Only one option \"-username\" or \"-domain\" is allowed"\
        "Tylko jedna z opcji \"-username\" lub \"-domain\" jest dozwolona"
::msgcat::mcset pl "SASL auth error:\n%s" "Błąd uwierzytelniania SASL:\n%s"
::msgcat::mcset pl "SASL authentication aborted" "Uwierzytelnianie SASL\
        zostało przerwane"
::msgcat::mcset pl "SASL authentication timed out" "Przekroczono czas\
        oczekiwania na uwierzytelnianie SASL"
::msgcat::mcset pl "SASL callback error: client needs to write \"%s\"" "Błąd\
        zwrotny SASL: klient musi zapisać \"%s\""
::msgcat::mcset pl "SASL step error: %s" "Bład kroku SASL: %s"
::msgcat::mcset pl "Server hasn't provided SASL authentication feature"\
        "Serwer nie udostępnia uwierzytelniania SASL"
::msgcat::mcset pl "Server provided mechanism %s. It is forbidden" "Serwer\
        udostępnia mechanizm %s. Nie jest on dozwolony"
::msgcat::mcset pl "Server provided mechanisms %s. They are forbidden"\
        "Server udostępnia mechanizmy %s. Nie są one dozwolone"
::msgcat::mcset pl "Server provided no SASL mechanisms" "Serwer nie\
        udostępnia mechanizmów SASL"
::msgcat::mcset pl "Temporary auth failure" "Tymczasowy błąd\
        uwierzytelniania"

# tclxmpp/xmpp/https.tcl
::msgcat::mcset pl "HTTPS proxy negotiation aborted" "Uzgadanianie proxy\
        HTTPS zostało przerwane"
::msgcat::mcset pl "HTTPS proxy negotiation timeout" "Przekroczono czas\
        oczekiwania na uzgadnianie proxy HTTPS"

# tclxmpp/xmpp/stanzaerror.tcl
::msgcat::mcset pl "Access Error" "Błąd dostępu"
::msgcat::mcset pl "Address Error" "Błąd adresu"
::msgcat::mcset pl "Application Error" "Błąd aplikacji"
::msgcat::mcset pl "Bad request" "Błędne żądanie"
::msgcat::mcset pl "Conflict" "Konflikt"
::msgcat::mcset pl "Feature not implemented" "Właściwość niezaimplementowana"
::msgcat::mcset pl "Forbidden" "Dostęp zabroniony"
::msgcat::mcset pl "Format Error" "Błąd formatu"
::msgcat::mcset pl "Gone" "Obiekt zmienił adres"
::msgcat::mcset pl "Internal server error" "Wewnętrzny błąd serwera"
::msgcat::mcset pl "Item not found" "Element nie znaleziony"
::msgcat::mcset pl "JID malformed" "Nieprawidłowy JID"
::msgcat::mcset pl "Not acceptable" "Nie zaakceptowane"
::msgcat::mcset pl "Not allowed" "Brak dostępu"
::msgcat::mcset pl "Not Found" "Nie znaleziono"
::msgcat::mcset pl "Not Implemented" "Nie zaimplementowano"
::msgcat::mcset pl "Payment required" "Wymagana opłata"
::msgcat::mcset pl "Recipient Error" "Błąd odbiorcy"
::msgcat::mcset pl "Recipient unavailable" "Odbiorca niedostępny"
::msgcat::mcset pl "Redirect" "Przekierowanie"
::msgcat::mcset pl "Registration required" "Wymagana rejestracja"
::msgcat::mcset pl "Remote Server Error" "Błąd zdalnego serwera"
::msgcat::mcset pl "Remote server not found" "Nie znaleziono serwera"
::msgcat::mcset pl "Remote server timeout" "Przekroczono czas oczekiwania na\
        odpowiedź serwera"
::msgcat::mcset pl "Request error" "Błąd żądania"
::msgcat::mcset pl "Request Timeout" "Upłynał czas oczekiwania na odpowiedź"
::msgcat::mcset pl "Server Error" "Błąd serwera"
::msgcat::mcset pl "Service unavailable" "Usługa niedostępna"
::msgcat::mcset pl "Subscription required" "Wymagana subskrypcja"
::msgcat::mcset pl "Temporary error" "Błąd tymczasowy"
::msgcat::mcset pl "Unauthorized" "Nie upoważniono"
::msgcat::mcset pl "Undefined condition" "Niezdefinowany warunek"
::msgcat::mcset pl "Unexpected request" "Nieoczekiwane żądanie"
::msgcat::mcset pl "Unrecoverable error" "Błąd nienaprawialny"
::msgcat::mcset pl "Username Not Available" "Nie znaleziono użytkownika"
::msgcat::mcset ru "Not authorized" "Brak autoryzacji"

# tclxmpp/xmpp/register.tcl
::msgcat::mcset pl "Date" "Data"
::msgcat::mcset pl "First name" "Imię"
::msgcat::mcset pl "Key" "Klucz"
::msgcat::mcset pl "Last name" "Nazwisko"
::msgcat::mcset pl "Misc" "Różne"
::msgcat::mcset pl "Password" "Hasło"
::msgcat::mcset pl "Phone" "Telefon"
::msgcat::mcset pl "Text" "Text"
::msgcat::mcset pl "Username" "Nazwa użytkownika"
::msgcat::mcset pl "Zip" "Kod pocztowy"

# tclxmpp/xmpp/socks5.tcl
::msgcat::mcset pl "Address type not supported" "Nieobsługiwany typ adresu"
::msgcat::mcset pl "Command not supported" "Nieobsługiwane polecenie"
::msgcat::mcset pl "Connection not allowed by ruleset" "Połączenie\
        zablokowane przez zestaw reguł"
::msgcat::mcset pl "Failed to read SOCKS5 authorization methods response"\
        "Nie udało się odczytać odpowiedzi o metodach uwierzytelniania\
        SOCKS5"
::msgcat::mcset pl "Failed to read SOCKS5 authorization response" "Nie udało\
        się odczytać odpowiedzi o uwierzytelnieniu SOCKS5"
::msgcat::mcset pl "Failed to read SOCKS5 connection response" "Nie udało się\
        odczytać odpowiedzi o połączeniu SOCKS5"
::msgcat::mcset pl "Failed to read SOCKS5 destination address type" "Nie\
        udało się odczytać typu adresu docelowego SOCKS5"
::msgcat::mcset pl "Failed to read SOCKS5 destination domain" "Nie udało się\
        odczytać domeny docelowej SOCKS5"
::msgcat::mcset pl "Failed to read SOCKS5 destination domain length" "Nie\
        udało się odczytać długości domeny docelowej SOCKS5"
::msgcat::mcset pl "Failed to read SOCKS5 destination IPv4 address and port"\
        "Nie udało się odczytać adresu IPv4 i portu docelowego SOCKS5"
::msgcat::mcset pl "Failed to read SOCKS5 destination IPv6 address and port"\
        "Nie udało się odczytać adresu IPv6 i portu docelowego SOCKS5"
::msgcat::mcset pl "Failed to read SOCKS5 destination port" "Nie udało się\
        odczytać portu docelowego SOCKS5"
::msgcat::mcset pl "Failed to send SOCKS5 authorization methods request" "Nie\
        udało się wysłać żądania metod uwierzytelniania SOCKS5"
::msgcat::mcset pl "Failed to send SOCKS5 authorization request" "Nie udało\
        się wysłać żądania uwierzytelnienia SOCKS5"
::msgcat::mcset pl "Failed to send SOCKS5 connection request" "Nie udało się\
        wysłać żądania połączenia SOCKS5"
::msgcat::mcset pl "General SOCKS server failure" "Błąd ogólny serwera SOCKS"
::msgcat::mcset pl "Incorrect SOCKS5 server version" "Nieprawidłowa wersja\
        serwera SOCKS5"
::msgcat::mcset pl "SOCKS5 negotiation timed out" "Upłynał czas negocjacji\
        połączenia SOCKS5"
::msgcat::mcset pl "SOCKS5 proxy negotiation aborted" "Negocjowanie proxy\
        SOCKS5 zostało anulowane"
::msgcat::mcset pl "SOCKS5 server authorization failed" "Uwierzytelnianie na\
        serwerze SOCKS5 nie powiodło się"
::msgcat::mcset pl "SOCKS5 server authorization required" "Wymagane\
        uwierzytelnianie na serwerze SOCKS5"
::msgcat::mcset pl "Unknown SOCKS5 destination address type" "Nieznany typ\
        adresu przeznaczenia SOCKS5"
::msgcat::mcset pl "Unsupported SOCKS5 authorization method" "Nieobsługiwana\
        metoda uwierzytelniania SOCKS5"

# tclxmpp/xmpp/pconnect.tcl
::msgcat::mcset pl "Connection timed out" "Upłynął czas ważności połączenia"
::msgcat::mcset pl "Connection via proxy aborted" "Połączenie przez proxy\
        zostało przerwane"
::msgcat::mcset pl "Connection via proxy timed out" "Upłynął czas ważności\
        połączenia przez proxy"
::msgcat::mcset pl "Options \"-host\" and \"-port\" are required (or your\
        proxy filter hasn't returned them)" "Opcje \"-host\" i \"-port\" są\
        wymagane (lub filtr proxy nie zwraca ich)"

# tclxmpp/xmpp/https.tcl
::msgcat::mcset pl "Failed to connect to HTTPS proxy" "Nie udało się\
        połączenie z proxy HTTPS"
::msgcat::mcset pl "HTTPS proxy negotiation timed out" "Upłynał czas\
        negocjacji połączenia proxy HTTPS"

# tclxmpp/xmpp/socks4.tcl
::msgcat::mcset pl "Client's identd could not confirm the userid" "Usługa\
        identd po stronie klienta nie może potwierdzić id użytkownika"
::msgcat::mcset pl "Failed to read SOCKS4a destination address" "Nie udało\
        się odczytać adresu docelowego SOCKS4a"
::msgcat::mcset pl "Failed to read SOCKS4a response" "Nie udało się odczytać\
        odpowiedzi SOCKS4a"
::msgcat::mcset pl "Failed to send SOCKS4a request" "Nie udało się wysłać\
        żądania SOCKS4a"
::msgcat::mcset pl "Incorrect SOCKS4a server version" "Nieprawidłowa wersja\
        serwera SOCKS4a"
::msgcat::mcset pl "Request rejected or failed" "Żądanie nie powiodło się lub\
        zostało odrzucone"
::msgcat::mcset pl "Server cannot reach client's identd" "Serwer nie może się\
        połączyć z usługą identd u klienta"
::msgcat::mcset pl "SOCKS4a proxy negotiation aborted" "Negocjowanie proxy\
        SOCKS4a zostało anulowane"
::msgcat::mcset pl "SOCKS4a proxy negotiation timed out" "Upłynał czas\
        negocjacji połączenia SOCKS4a"
::msgcat::mcset pl "Unknown SOCKS4a server error" "Nieznany błąd serwera\
        SOCKS4a"

# tclxmpp/xmpp/blocking.tcl
::msgcat::mcset pl "Nothing to block" "Brak elementów do zablokowania"

# tclxmpp/xmpp/muc.tcl
::msgcat::mcset pl "Already joining"
::msgcat::mcset pl "Disconnected from the room"
::msgcat::mcset pl "Empty nickname"
::msgcat::mcset pl "Illegal nickname"
::msgcat::mcset pl "Leaving room"
::msgcat::mcset pl "MUC room JID \"%s\" is malformed"
::msgcat::mcset pl "MUC room JID must have empty resource part. The specified\
        JID was \"%s\""
::msgcat::mcset pl "MUC token doesn't exist"
::msgcat::mcset pl "Must join room first"
::msgcat::mcset pl "Nickname didn't change"
::msgcat::mcset pl "Nickname is changing already"
::msgcat::mcset pl "The room isn't joined yet"
::msgcat::mcset pl "User is not banned"

# vim:ft=tcl:ts=8:sw=4:sts=4:et
