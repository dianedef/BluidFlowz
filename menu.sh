#!/bin/bash

# Load shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

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
    "BuildFlowz" "Menu Interactif avec Gum"

# Menu de sélection
CHOICE=$(gum choose "📁 Naviguer dans /root" "Quitter")

case $CHOICE in
    "📁 Naviguer dans /root")
        gum style --foreground 45 "📁 Dossiers disponibles dans /root"
        
        FOLDERS=$(find /root -maxdepth 1 -type d ! -name ".*" ! -path /root | sort)
        
        if [ -z "$FOLDERS" ]; then
            gum style --foreground 196 "❌ Aucun dossier trouvé"
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
    "Quitter")
        gum style --foreground 196 "Au revoir! 👋"
        exit 0
        ;;
esac

