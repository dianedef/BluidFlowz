#!/bin/bash

# Vérifier si gum est installé
if ! command -v gum &> /dev/null; then
    echo "gum n'est pas installé. Installation..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install -y gum
fi

clear

# Titre stylisé
gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 50 --margin "1 2" --padding "1 2" \
    "Menu Interactif" "Fait avec gum"

# Menu de sélection
CHOICE=$(gum choose "Afficher la date" "Infos système" "Créer une note" "Naviguer dans /root" "Docker: Lister les envs" "Docker: Ouvrir URLs" "Docker: Stopper env" "Quitter")

case $CHOICE in
    "Afficher la date")
        gum style --foreground 82 "$(date '+%A %d %B %Y - %H:%M:%S')"
        ;;
    "Infos système")
        gum spin --spinner dot --title "Chargement..." -- sleep 1
        echo ""
        gum style --foreground 226 "Hostname: $(hostname)"
        gum style --foreground 226 "Kernel: $(uname -r)"
        gum style --foreground 226 "Uptime: $(uptime -p)"
        ;;
    "Créer une note")
        NOTE=$(gum input --placeholder "Écris ta note ici...")
        if [ -n "$NOTE" ]; then
            echo "$NOTE" >> ~/notes.txt
            gum style --foreground 82 "✅ Note sauvegardée dans ~/notes.txt"
        fi
        ;;
    "Naviguer dans /root")
        gum style --foreground 45 "Dossiers disponibles dans /root :"
        FOLDERS=$(find /root -maxdepth 1 -type d ! -name ".*" ! -path /root | sort)
        if [ -z "$FOLDERS" ]; then
            gum style --foreground 196 "Aucun dossier trouvé dans /root"
        else
            SELECTED=$(echo "$FOLDERS" | gum choose)
            if [ -n "$SELECTED" ]; then
                gum style --foreground 82 "📁 Dossier sélectionné: $SELECTED"
                if gum confirm "Ouvrir un shell dans ce dossier ?"; then
                    cd "$SELECTED" && exec $SHELL
                fi
            fi
        fi
        ;;
    "Docker: Lister les envs")
        gum style \
            --foreground 45 --border-foreground 45 --border rounded \
            --align center --width 40 --padding "0 2" \
            "Environnements Docker"

        gum spin --spinner dot --title "Chargement des environnements..." -- sleep 0.5

        if ! docker compose ls --format json 2>/dev/null | jq -e '. | length > 0' >/dev/null 2>&1; then
            gum style --foreground 196 "Aucun environnement actif"
        else
            echo ""
            docker compose ls --format json | jq -r '.[] | "\(.Name)\t\(.Status)\t\(.ConfigFiles)"' | while IFS=$'\t' read -r name status config; do
                if [[ $status == *"running"* ]]; then
                    status_icon="✅ running"
                    color="82"
                else
                    status_icon="🔴 stopped"
                    color="196"
                fi

                gum style --foreground "$color" "[$status_icon] $name"
                gum style --foreground 245 "    $config"
                echo ""
            done
        fi
        ;;
    "Docker: Ouvrir URLs")
        gum style \
            --foreground 33 --border-foreground 33 --border rounded \
            --align center --width 40 --padding "0 2" \
            "Ouvrir Environnements"

        running=$(docker compose ls --filter "status=running" --format json 2>/dev/null | jq -r '.[] | "\(.Name)\t\(.ConfigFiles)"')

        if [ -z "$running" ]; then
            gum style --foreground 196 "Aucun environnement en cours d'exécution"
        else
            selected=$(echo "$running" | awk '{print $1}' | gum choose)

            if [ -n "$selected" ]; then
                config=$(echo "$running" | grep "^$selected" | awk '{print $2}')
                gum style --foreground 82 "URLs disponibles pour $selected :"
                echo ""
                docker compose -f "$config" ps --format json 2>/dev/null | jq -r '.[].Publishers[]? | "🌐 http://localhost:\(.PublishedPort)\n🌐 http://164.92.221.78:\(.PublishedPort)"' | sort -u
            fi
        fi
        ;;
    "Docker: Stopper env")
        gum style \
            --foreground 196 --border-foreground 196 --border rounded \
            --align center --width 40 --padding "0 2" \
            "Stopper Environnements"

        all_envs=$(docker compose ls --format json 2>/dev/null | jq -r '.[] | "\(.Name)\t\(.Status)\t\(.ConfigFiles)"')
        running=$(echo "$all_envs" | awk '$2 ~ /running/ {print $1 "\t" $3}')

        if [ -z "$running" ]; then
            gum style --foreground 196 "Aucun environnement en cours d'exécution"
        else
            selected=$(echo "$running" | awk '{print $1}' | gum choose)

            if [ -n "$selected" ]; then
                config=$(echo "$running" | grep "^$selected" | awk '{print $2}')
                config_file=$(echo "$config" | cut -d',' -f1)

                gum spin --spinner meter --title "Arrêt de $selected..." -- docker compose -f "$config_file" stop
                gum style --foreground 82 "✅ Environnement $selected arrêté ! (RAM libérée)"
            fi
        fi
        ;;
    "Quitter")
        gum style --foreground 196 "Au revoir! 👋"
        exit 0
        ;;
esac
