#!/bin/bash

FOLDER_DIRECTORY="$HOME/.quitter"
DB_FILE="$FOLDER_DIRECTORY/horaires.db"
PID_FILE="$FOLDER_DIRECTORY/boucle.pid"

# Creation des folders de base
function f_init
{

if [ ! -d $FOLDER_DIRECTORY ]; then
    echo "Creation of $FOLDER_DIRECTORY"
    mkdir -p $FOLDER_DIRECTORY
fi

if [ ! -f $DB_FILE ]; then
    echo "Creation of $DB_FILE"
    touch $DB_FILE
fi

}

# Affichage de l'alerte
function f_show_message
{
OS=`uname -a  | cut -d' ' -f1`

if [ $OS == "Darwin" ]; then
/usr/bin/osascript > /dev/null  <<-EOF
    tell application "System Events"
        activate
        display dialog "$1"
    end tell
EOF

else
    echo $1
fi

}
# on run la boucle
function f_run
{
    echo "running..." > $PID_FILE
    while [ -f $PID_FILE ]; do
        HEUREMIN=`date +%H%M`
        sort $DB_FILE | while read line
        do
            HHMM=`echo $line | cut -d' ' -f1`
            if [ "$HHMM" == "$HEUREMIN" ]; then
                f_show_message "$( f_last_message $line )"
            fi
        done
        sleep 31
    done
}

# On stoppe
function f_stop
{
    rm $PID_FILE
    echo "Fin du programme"
}

# On remove
function f_remove
{
    # possibilite de faire un retour arriere de la derniere commande
    cp  "$DB_FILE" "$DB_FILE.bak"
    sed "/^$1/d" "$DB_FILE.bak" > "$DB_FILE"
    f_list
}

# On liste
function f_list
{
    cat $DB_FILE
}

# On clear
function f_clear
{
    cp  $DB_FILE "$DB_FILE.bak"
    echo "" > $DB_FILE
}

# On recup le backup
function f_recovery
{
    cp  "$DB_FILE.bak" $DB_FILE
    f_list
}

# On affiche l'aide
function f_help
{
    echo "Usage :"
    echo "$0 HHMM message : Ajouter un rendez vous. Ex: 1225 \"Resto avec Camille\"."
    echo "$0 -s : Demarre le programme."
    echo "$0 -q : Arreter le programme."
    echo "$0 -l : Lister les  rendez-vous."
    echo "$0 -recovery : Annuler la derniere suppression ou clear."
    echo "$0 -c : Vide les rendez-vous."
    echo "$0 -r HHMM : Supprimer un rendez-vous."
}

function f_test_horaire
{
    HH=`echo $1 | cut -c -2`
    if [[ $HH = [0-9][0-9] ]]; then
        if [ $HH -lt 0 -o $HH -gt 23 ]; then
            echo "Heures non valide, entre 00 et 23 attendu"
            f_help
            exit 1
        fi
    else
        echo "Heures non numeriques"
        f_help
        exit 1
    fi
    MM=`echo $1 | cut -c 3-`
    if [[ $MM = [0-9][0-9] ]]; then
        if [ $MM -lt 0 -o $MM -gt 59 ]; then
            echo "Minutes non valide, entre 00 et 59 attendu"
            f_help
            exit 1
        fi
    else
        echo "Minutes non numeriques"
        f_help
        exit 1
    fi
}

# on demarre
function f_start
{
# lancement de la boucle en arriere plan si necessaire
if [ ! -f $PID_FILE ]; then
    # on lance la boucle
    echo "Demarrage du processus"
    $0 run &
fi
}

# recupere tout sauf le premier
function f_last_message
{
    echo $@ | cut -d' ' -f 2-
}

#
# Main

# initialisation
f_init

# Gestion des erreurs
if [ $# -eq 0 ]; then
    echo "Arguments non valides."
    f_help $0
    exit 1
fi

if [ $1 == "-q" ]; then
    f_stop
    exit 0
fi

if [ $1 == "-recovery" ]; then
    f_recovery
    exit 0
fi


if [ $1 == "-c" ]; then
    f_clear
    exit 0
fi

if [ $1 == "-r" ]; then
    if [ $# -ne 2 ]; then
        echo "Il manque un argument."
        f_help $0
        exit 1
    fi
    f_remove $2
    exit 0
fi

if [ $1 == "-l" ]; then
    f_list
    exit 0
fi

if [ $1 == "-s" ]; then
    f_start
    exit 0
fi

if [ $1 == "run" ]; then
    f_run
    exit 0
fi

if [ $# -lt 2 ]; then
    echo "Il manque des arguments."
    f_help $0
    exit 1
fi

#
# Run / add
#

HORAIRE=$1
MESSAGE=$( f_last_message $* )
f_test_horaire $HORAIRE

echo "Ajout du rendez vous $HORAIRE avec le message: $MESSAGE"
echo "$HORAIRE $MESSAGE" >> $DB_FILE

f_start
