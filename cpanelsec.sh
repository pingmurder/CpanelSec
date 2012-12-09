#!/bin/bash

PS1='â•­â”€\[\033[01m\][ \[\033[01;34m\]\u@\h \[\033[00m\]\[\033[01m\]] \[\033[01;32m\]\w\[\033[00m\]\nâ•°â”€âž¤ '

unalias cp
unalias vi


pwnmail()
{
    if [ -z "$1" ]; then
        echo "Usage: pwnmail STRING"
        return
    fi

    exim -bp | grep -B1 "$1" | grep '<.*>' | awk '{print $3}' | while read line; do exim -Mrm $line; done
}


addspf()
{
    if [ -z "$1" ]; then
        echo "Usage: addspf USER"
        return
    fi

    /usr/local/cpanel/bin/spf_installer "$1" '' 1 1
    echo "Added SPF records for account $1"
}


injectcleaner()
{
    if [ -z "$1" ]; then
        echo "Usage: injectcleaner [-l] [-b] PATTERN [file|list]"
        return
    fi

    if [ "$1" == "-l" ];then
        cat "$3" | while read line;do perl -p0777i -e "s@$2@@gs" "$line";done
    else
        if [ "$1" == "-b" ];then
            cp "$3" "$3".bak
            echo "Backed up $3"
            perl -p0777i -e "s@$2@@gs" "$3"
        else
            perl -p0777i -e "s@$1@@gs" "$2"
        fi
    fi

    echo "Cleaned injection. (hopefully)"
}


sysinfo()
{
    echo '[===SYSTEM BUILD===]'; uname -a; echo '[===LANGUAGE HANDLERS===]'; /usr/local/cpanel/bin/rebuild_phpconf --current; echo '[===PHP CONFIG===]'; egrep -i "(disable_fun)"  /usr/local/lib/php.ini | sed 's/;//'; echo '[===FIREWALL STATUS===]'; egrep "(SMTP_BLOCK|SMTP_ALLOWLOCAL|SMTP_PORTS)[[:space:]]?=" /etc/csf/csf.conf; csf -v; echo '[===EMAIL STATUS===]'; echo Emails per Hour: $(cat /var/cpanel/maxemailsperhour); echo Emails in Queue: $(exim -bpc); echo '[===RESOURCE ALLOCATION===]'; OUT=$(/usr/loca<Plug>(neocomplcache_start_auto_complete)l/cpanel/bin/dcpumonview | grep -v Top | sed -e 's#<[^>]*># #g' | while read i ; do NF=`echo $i | awk {'print NF'}` ; if [[ "$NF" == "5" ]] ; then USER=`echo $i | awk '{print $1}'`; OWNER=`grep -e "^OWNER=" /var/cpanel/users/$USER | cut -d= -f2` ; echo "$OWNER $i"; fi ; done) ; (echo "USER CPU" ; echo "$OUT" | sort -nrk4 | awk '{print $2,$4}' | head -5) | column -t ; echo; (echo -e "USER MEMORY" ; echo "$OUT" | sort -nrk5 | awk '{print $2,$5}' | head -5) | column -t; echo '[===ESTABLISHED CONNECTIONS===]'; PORTS=([80]=Apache [110]=POP3 [143]=IMAP [25]=SMTP [26]=SMTP [21]=FTP); netstat -plan > /root/stats.txt; for port in ${!PORTS[*]}; do echo "$(tput bold)${PORTS[$port]}($port):$(tput sgr0)"; grep $port /root/stats.txt | awk {'print $5'} | grep -Po "\d{1,3}(?:\.\d{1,3}){3}" | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 | uniq -c | sort -nk 1 | grep -v "0.0.0.0" | tail -5 | awk '{ if ( $1 > 35 ) { printf "\033[1;31m" } else if ( $1 > 25 ) { printf "\033[1;33m" } else { printf "\033[1;32m" } ; print " ", $1, "\033[0;39m", $2 }'; done; rm -f /root/stats.txt; echo '[===CONNECTIONS BY DOMAIN===]';  lynx -dump -width=200 localhost/whm-server-status | grep 'POST\|GET' | awk '{print $12}' | sort | uniq -c; echo '[===DISK ALLOCATION===]'; df -h; echo '[===INODE AUDIT===]'; cat /etc/domainusers | cut -f1 -d: | sort -nk1 | while read USER; do quota -s $USER; done | grep '[0-9]k' -B 2 | grep -v "-" | grep '[0-9]k' -B 2; echo '[===EXCLUDED USERS===]'; cat /etc/cpbackup-userskip.conf; screen -ls; cat /etc/cpspamd.conf;
}


inodebreakdown()
{
    find . -maxdepth 1 -type d |  while    read line  ; do    echo "$( find "$line"| wc -l) $line"  ; done |  sort -rn
}


secimgdir()
{
    if [ ! -f .htaccess ];then
        echo -e "AddHandler cgi-script .php .pl .py .jsp .asp .htm .shtml .sh .cgi .php5 .php4 .php3 .phps .txt .bat .cmd .rb\nOptions -ExecCGI -Indexes" > .htaccess
        chattr +ai .htaccess
    else
        sed -i '1s/^/AddHandler cgi-script .php .pl .py .jsp .asp .htm .shtml .sh .cgi .php5 .php4 .php3 .phps .txt .bat .cmd .rb\nOptions -ExecCGI -Indexes\n/' .htaccess
        chattr +ai .htaccess
    fi

    echo ".htaccess edited."
}


grepuser()
{
    if [ -z "$1" ];then
        echo "Usage: grepuser USER"
        return
    fi

    grep "$1" /etc/userdomains
}


trafficstats()
{
    if [ -z "$1" ];then
        echo "Usage: trafficstats [-f] DOMAIN"
        return
    fi


    if [ ! -f /etc/httpd/domlogs/"$1" ];then
        echo "Domain $1 not found."
        return
    fi

    

    local BEGIN=`head -n1 /etc/httpd/domlogs/"$1" | awk '{print $4$5}'`
    local END=`tail -n1 /etc/httpd/domlogs/"$1" | awk '{print $4$5}'`
    local HITS=`wc -l /etc/httpd/domlogs/"$1"| awk '{print $1}'`

    echo "From $BEGIN to $END there were $HITS hits for $1"
}


_trafficstats()
{
    local cur
    cur=${COMP_WORDS[COMP_CWORD]}

    COMPREPLY=( $( compgen -f /etc/httpd/domlogs/$cur | perl -pi -e 's/.*\/(.*)/$1/g' ) )
}

complete -o nospace -F _trafficstats trafficstats


alias dcpumonview="/usr/local/cpanel/bin/dcpumonview"
alias mc="exim -bpc"
alias m="exim -bp"
alias chkmailabuse='less /var/log/exim_mainlog | grep sendmail | grep -vE "csf|FCron"'
alias grep="grep --color=auto"
alias ll='ls -Al --color=tty'
alias vb='exim -Mvb'
alias vh='exim -Mvh'
alias vl='exim -Mvl'


showusage()
{
    du -k * | sort -nr | cut -f2- | xargs du -hs
}

owner()
{
    if [ -z "$1" ];then
        echo "Usage: owner USER"
        return
    fi

    grep "$1" /etc/trueuserowners
}

complete -o nospace -F _www owner

pwn()
{
    if [ -z "$1" ];then
        echo "Usage: pwn FILES"
        return
    fi

    until [ -z "$1" ];do
        chmod 000 "$1"
        chown 0:0 "$1"
        shift
    done
}


unpwn()
{
    if [ -z "$1" ];then
        echo "Usage: unpwn FILES"
        return
    fi

    until [ -z "$1" ];do
        if [ -d "$1" ];then
            chmod 755 "$1"
        else
            chmod 644 "$1"
        fi

        chown `pwd | cut -d/ -f3`:`pwd | cut -d/ -f3` "$1"
        shift
    done
}


fixperms()
{
    find -type f ! -perm 000 -exec bash -c 'if [[ "$1" =~ "wp-config.php" || "$1" =~ "configuration.php" ]];then chmod 600 "$1";else chmod 644 "$1";fi' bash '{}' \;
    find -type d ! -perm 000 -exec chmod 755 {} \;
}


rmsymlinks()
{
    find -type l -exec unlink {} \;
}


www()
{
    if [ -z "$1" ];then
        echo "Usage: www USER"
        return
    fi

    if [ ! -d /home/"$1"/public_html ];then
        echo "Public html directory for user $1 not found."
        return
    fi

    cd /home/"$1"/public_html
}

_www()
{
    local cur
    cur=${COMP_WORDS[COMP_CWORD]}

    COMPREPLY=( $( compgen -f /home/$cur | perl -pi -e 's/.*\/(.*)/$1/g' ) )
}

complete -o nospace -F _www www
complete -o nospace -F _www addspf


chpass()
{
    if [ -z "${ALLOW_PASSWORD_CHANGE+xxx}" ];then
        export ALLOW_PASSWORD_CHANGE=1
    fi

    if [ -z "$1" ];then
        echo "Usage: chpass USER"
        return
    fi
    
    local NEWPW=`cat /dev/urandom| tr -dc 'a-zA-Z0-9' | head -c 10`
    echo "Changing password for user $1 to:  $NEWPW"
    /scripts/chpass "$1" "$NEWPW"

    if [ $? -ne 0 ];then
        return
    fi

    /scripts/ftpupdate
}

complete -o nospace -F _www chpass


beachheadfinder()
{
    screen -A -a -d -m -L -t 'Beach-Head Finder' -S 'bhfinder' /bin/bash -c "find /home* -type d \( -path '/home*/virtfs' -or -path '/home*/.cpan' -or -path '/home*/.cpanm' -or -path '/home*/cpeasyapache' -or -path '/home*/cpapachebuild' -or -path '/home*/cpphpbuild' -or -path '/home*/cpzendinstall' \) -prune -false -or -type l -not -lname 'public_html' -not -lname '/usr/local/apache/domlogs/*' -not -path '/home*/*/mail/.*' -not -lname '/home*/*/.rvsitebuilder/projects/*' -not -lname '/var/cpanel/rvglobalsoft/rvsitebuilder/*' -not -lname '/var/netenberg/click_be/*' -not -lname '*/.click_be/database/' -not -lname '*/.click_be/advertisements/' -not -lname '*/.click_be/click_be/' -not -lname '*/.click_be/backup/' -not -lname '/usr/local/urchin/*' -not \( -path '/home*/*/wp-content/advanced-cache.php' -and -lname '/home*/wp-content/plugins/*' \) -not \( -path '/home*/rvadmin/public_html/rvadmin/themeimages/tran' -and -lname '/usr/local/cpanel/base/frontend/*/themeimages/tran' \) -printf '%p => %l\n\c' -fprintf '/dev/stderr' '%p => %l\n\c' 2>> /root/found_links.txt"
}


qgrep()
{
    local OPTIND
    local OPTARG

    while getopts ":plsc:" opt; do
        case $opt in
            p ) local NONULL='! -perm 000' ;;
            l ) local LFILES='-EHil' ;;
            s ) local SHLLSRCH="(c3284|filesman|r57shell|default_action|tryag)";;
            c ) local SHLLSRCH="($OPTARG)";;
        : ) echo "-$OPTARG requires an argument";return 1;;
            \? ) echo "Usage: qgrep [-l (list files)] [-s (shells) ] [-p (no perm 000) ] [-c SEARCHSTR]"
                return 1;;
        esac
    done

    GREPARGS=${LFILES:-'-EHi'}
    ARGS1=${NONULL:-''}
    SEARCH=${SHLLSRCH:-"(gzinflate|base64_decode)"}

    find $ARGS1 -regex ".*\.\(htm\|html\|php\|inc\|tmp\|js\|htaccess\|pl\)" -print0 | xargs -0 grep $GREPARGS $SEARCH --color=auto 

    return 0
}


complete -o nospace -F _www d7monview

chkbackup()
{    
    if [ -z "$1" ];then
        echo "Usage: chkbackup FILE"
        return
    fi

    local ACCOUNT=`pwd | cut -d/ -f3`
    local TARGET="$1"

    diff /backup/cpbackup/daily/"$ACCOUNT"/homedir/public_html/"$TARGET" "$TARGET" 
    if [ $? -ne 0 ];then
        echo "Restore file? (y or n): "
        read option

        if [ "$option" == "y" ];then
            cp /backup/cpbackup/daily/"$ACCOUNT"/homedir/public_html/"$TARGET" .
            return
        fi
    else
        echo "No changes in daily copy"
    fi


    diff /backup/cpbackup/weekly/"$ACCOUNT"/homedir/public_html/"$TARGET" "$TARGET" 
    if [ $? -ne 0 ];then
        echo "Restore file? (y or n): "
        read option

        if [ "$option" == "y" ];then
            cp /backup/cpbackup/weekly/"$ACCOUNT"/homedir/public_html/"$TARGET" .
            return
        fi
    else
        echo "No changes in weekly copy"
    fi


}


vzsuspend()
{
    if [ -z "$1" ];then
        echo "Usage: vzsuspend VEID"
        return
    fi

    vzlist -a | grep "$1" 1> /dev/null

    if [ "$?" -ne 0 ];then
        echo "VEID $1 not found!"
        return
    fi

    local HOSTNAME=`vzlist -a | grep "$1" | awk '{print $5}'`

    vzctl set "$1" --hostname HD-SUSPENDED-"$HOSTNAME" --save
    vzctl stop "$1" --fast
    vzctl set "$1" --disabled yes --save
}


vzunsuspend()
{
    if [ -z "$1" ];then
        echo "Usage: vzunsuspend VEID"
        return
    fi

    vzlist -a | grep "$1" 1> /dev/null

    if [ "$?" -ne 0 ];then
        echo "VEID $1 not found!"
        return
    fi

    vzctl set "$1" --disabled no --save

    local HOSTNAME=`vzlist -a | grep "$1" | awk '{print $5}' | awk -F'HD-SUSPENDED-' '{print $1}'`

    vzctl set "$1" --hostname "$HOSTNAME" --save
    vzctl start "$1"
}

adddkim()
{

    if [ -z "$1" ];then
        echo "Usage: adddkim USER"
        return
    fi

    if [ -e /usr/local/cpanel/bin/domain_keys_installer ];then
        /usr/local/cpanel/bin/domain_keys_installer "$1"
        echo "Added domain keys for user $1"
    else
        /usr/local/cpanel/bin/dkim_keys_install "$1"
        echo "Added DKIM for user $1"
    fi
}

complete -o nospace -F _www adddkim

function checkapache() 
{ 
    if [[ `strings /usr/local/apache/bin/httpd |  grep "UnhardenedSymLinks\|UnsecuredSymLinks"` != '' ]]; then 
        echo -e  "Apache \033[0;32mis patched\033[m\017 against SYMLINK attacks."; 
    else  echo -e "Apache is \033[0;31mNOT PATCHED\033[m\017 against SYMLINK  attacks."; 
    fi 
} 

lsandrew()
{
    echo -e "pwnmail STRING\ncmscheck\naddspf USER\nupdatemodsec\ninjectcleaner [-l] [-b] PATTERN [FILE|LIST]\nsysinfo\ninodebreakdown\nsecimgdr"
    echo -e "grepuser USER\ntrafficstats [-f] DOMAIN\npwn FILE\nfixperms\nrmsymlinks\nwww USER\nchpass USER\nchkmailabuse\nbeachheadfinder"
    echo -e "qgrep [-f (full)] [-l (list)] [-h (hack|shell) ] [-p (no perm 000) ] [search str]"
    echo -e "aShellScanner\njsecure\ncpanel GREPSTR\nfastscan\nd7monview USER\nchkbackup FILE\nowner USER\nvzsuspend VEID\nvzunsuspend VEID"
    echo -e "adddkim USER\nshowusage\nunpwn USERS\nblist IP\n"
}
