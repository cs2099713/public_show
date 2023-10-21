#!/bin/bash
# cs2099713


#---------------------------------------------------
#|                   Funktionen                    |
#---------------------------------------------------

help() {
    printf "\nUsage:\trotate.sh [OPTION]... [FILE]"
    printf "\n\trotate.sh [-l|-d|-z|-b [#] [-z]] [FILE]\n"
    printf "\n\tOptions:\n\t\t-h\t\tShows this help."
    printf "\n\t\t-l [FILE]\tLists all backups of given file"
    printf "\n\t\t-d [FILE]\tDeletes all backups of given file."
    printf "\n\t\t-z       \tBackups file compressed."
    printf "\n\t\t-b [#] [FILE]\tBackups file. Rotation #."
    printf "\n\t\t-b # -z [FILE]\tBackups file compressed."
    printf "\n\n\tNote:\tCombining other options is not allowed."
    printf "\n\t\tCustom rotation # must be >=1 and <=9.\n\n"
    exit 0
}

list() {
    if [ -f "$1" ]; then
        ls -l "$1"*
        exit 0
    else
        echo "Error: File $1 does not exist." 1>&2
        exit 1
    fi
}

delete() {
    if [ -f "$1" ]; then
        rm -f "${1}".* 2>/dev/null
        exit 0
    else
        echo "Error: File $1 does not found." 1>&2
        exit 1
    fi
}

check_retention() {
    #WENN kein Argument übergeben wird --> FEHLER
    if [ -z $1 ]; then
        echo "Error: Please provide an argument. [Val: $* ]" 1>&2
        exit 1

    #WENN ein Argument übergeben wird:
    # Prüfe ob numeric value

    elif [ $1 -eq $1 ] 2>/dev/null; then
        #WENN numeric dann prüfe ob für n: 1 <= n <= 9
        if ! [ $1 -lt 1 ] && ! [ $1 -gt 9 ]; then
            retention=$1
        else
        #WENN nicht --> FEHLER
            echo "Error: In -b [#], # must be a numeric value between from 1 to 9. [Val: $* ]" 1>&2
            exit 1
        fi
    else
        if [ $1 != "-z" ]; then
            filename=$1
        else
            compression=true
            filename=$2
        fi
    fi
}

backup() {
    #Datei existiert?
    if [ -f $filename ]; then
        #Datei leer?
        if [ -s $2 ]; then
            gap=0 #Finden einer Lücke im Backup z.B. foo.1 foo.2 foo.4 foo.5
            for ((i=$retention; i>0; i-- )); do
                if  [ -f "$filename.$i" ] || [ -f "$filename.$i.gz" ]; then
                    if [ $gap -lt $i ]; then
                        gap=0
                    fi
                else

                    gap=$i

                fi
            done

            #Wenn letzte Datei fehlt, muss gesamte folge weitergerückt werden.
            if [ $gap -eq 0 ]; then
                gap=$retention
            fi
            #Gap = niedrigste fehlende Stelle   --> Kopiervorgang muss bei $gap-1 beginnen, wenn gap != retention
            for ((i=$gap-1; i>0; i-- )); do
                if [ -f "$filename.$i" ]; then
                    mv "$filename.$i" "$filename.$((i+1))"
                    if [ -f "$filename.$((i+1)).gz" ]; then
                        rm "$filename.$((i+1)).gz"
                    fi
                fi
                if [ -f "$filename.$i.gz" ]; then
                    mv "$filename.$i.gz" "$filename.$((i+1)).gz"
                    if [ -f "$filename.$((i+1))" ]; then
                        rm "$filename.$((i+1))"
                    fi
                fi
            done
                    #Prüfen ob mit oder ohne Kompression
                    if [ $3 -eq 0 ]; then
                        #ohne kompression
                        cp -p "$filename" "$filename.1"
                    else
                        #mit kompression
                        gzip -k -f -N $filename
                        cp -p "$filename.gz" "$filename.1.gz"
                        rm "$filename.gz"
                    fi
                else
                    exit 0
                fi
    else
        echo "Error: File $2 does not exist." 1>&2
        exit 1
    fi
}

# ---------------------------------------------------
# |              Code zur Ausführung                |
# ---------------------------------------------------

# --------------- Erlaubte Optionen: ---------------|
# |  script.sh                                      |
# |              -h                    PASS         |
# |              -l FILE               PASS         |
# |              -d FILE               PASS         |
# |              -b # FILE             PASS         |
# |              -b   FILE             PASS         |
# |              -b # -z FILE          PASS         |
# |              -b   -z FILE          PASS         |
# |              -z -b # FILE          PASS         |
# |              -z -b   FILE          PASS         |
# |-------------------------------------------------|


while getopts ":b:d:hl:z" args
do
    case $args in
        # -b FILE --> 1. $OPTARG = FILE
        # -b # FILE --> 1. $OPTARG = #

        b)  check_retention "$OPTARG"
            backup=true;;
        d)  delete "$OPTARG";;
        h)  help;;
        l)  list "$OPTARG";;
        z)  backup=true
            compression=true
            shift $((OPTIND -1))
            shift $((OPTIND -1))
            check_retention $1;; #KEINE QUOTES, sonst kein word splitting
        *)  echo "Error: Option invalid. Use -h for help: -$OPTARG" 1>&2; exit 1;;
    esac
done
shift $((OPTIND -1))


if [ -z $filename ]; then
    filename=$1
fi
if [ -z $retention ]; then
    retention=5
fi
if [ $backup ] && ! [ $compression ]; then
    #printf "\n\nCall Backup ->\n\tRetention: %s\n\tFilename: %s\n\tCompression: %s\n\n" $retention $filename "0"
    backup $retention $filename 0
fi
if [ $backup ] && [ $compression ]; then
    #printf "\n\nCall Backup ->\n\tRetention: %s\n\tFilename: %s\n\tCompression: %s\n\n" $retention $filename "1"
    backup $retention $filename 1
fi
