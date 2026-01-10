#!/bin/bash

# Menu Local - Gestion des tunnels SSH vers Hetzner
# Accès rapide aux projets distants via tunnels SSH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

REMOTE_HOST="hetzner"

# Fonction d'affichage avec couleurs
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${YELLOW}BuildFlowz - Local${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}           ${BLUE}SSH Tunnel Manager${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Fonction d'affichage du menu
show_menu() {
    echo -e "${GREEN}Choisissez une option :${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 🚇 Démarrer les tunnels SSH"
    echo -e "  ${CYAN}2)${NC} 📋 Afficher les URLs disponibles"
    echo -e "  ${CYAN}3)${NC} 🛑 Arrêter les tunnels"
    echo -e "  ${CYAN}4)${NC} 📊 Statut des tunnels"
    echo -e "  ${CYAN}5)${NC} 🔄 Redémarrer les tunnels"
    echo -e "  ${CYAN}6)${NC} ❌ Quitter"
    echo ""
}

# Fonction pour obtenir les ports actifs
get_active_ports() {
    ssh "$REMOTE_HOST" "pm2 jlist 2>/dev/null | python3 -c \"
import sys, json
try:
    apps = json.load(sys.stdin)
    for app in apps:
        if app['pm2_env']['status'] == 'online':
            env = app['pm2_env'].get('env', {})
            port = env.get('PORT') or env.get('port')
            if port:
                name = app['name']
                print(f'{port}:{name}')
except:
    pass
\"" 2>/dev/null
}

# Fonction pour démarrer les tunnels
start_tunnels() {
    echo -e "${BLUE}🚇 Démarrage des tunnels SSH${NC}"
    echo ""
    
    # Vérifier autossh
    if ! command -v autossh &> /dev/null; then
        echo -e "${RED}✗ autossh n'est pas installé${NC}"
        echo -e "${YELLOW}  Installation: brew install autossh (macOS) ou apt install autossh (Linux)${NC}"
        return 1
    fi
    
    # Arrêter les tunnels existants
    echo -e "${YELLOW}🛑 Arrêt des tunnels existants...${NC}"
    pkill -f "autossh.*$REMOTE_HOST" 2>/dev/null || true
    sleep 1
    
    # Récupérer les ports
    echo -e "${BLUE}📡 Récupération des ports actifs depuis PM2...${NC}"
    PORTS=$(get_active_ports)
    
    if [ -z "$PORTS" ]; then
        echo -e "${RED}✗ Aucun port trouvé ou PM2 n'est pas accessible${NC}"
        echo -e "${YELLOW}  Vérifiez que PM2 tourne sur le serveur distant${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Création des tunnels SSH${NC}"
    echo ""
    
    # Créer les tunnels
    while IFS= read -r line; do
        port=$(echo "$line" | cut -d':' -f1)
        name=$(echo "$line" | cut -d':' -f2)
        
        echo -e "${GREEN}  ✓ localhost:${port} → ${name}${NC}"
        
        autossh -M 0 -f -N \
            -o "ServerAliveInterval=30" \
            -o "ServerAliveCountMax=3" \
            -o "ExitOnForwardFailure=yes" \
            -L "${port}:localhost:${port}" \
            "$REMOTE_HOST" 2>/dev/null
    done <<< "$PORTS"
    
    echo ""
    echo -e "${GREEN}✅ Tunnels actifs !${NC}"
}

# Fonction pour afficher les URLs
show_urls() {
    echo -e "${BLUE}📋 URLs disponibles${NC}"
    echo ""
    
    PORTS=$(get_active_ports)
    
    if [ -z "$PORTS" ]; then
        echo -e "${RED}✗ Aucun port trouvé${NC}"
        return 1
    fi
    
    while IFS= read -r line; do
        port=$(echo "$line" | cut -d':' -f1)
        name=$(echo "$line" | cut -d':' -f2)
        
        # Vérifier si le tunnel est actif
        if ps aux | grep -q "[a]utossh.*:${port}:localhost:${port}"; then
            echo -e "  ${GREEN}✓${NC} http://localhost:${port} ${YELLOW}(${name})${NC}"
        else
            echo -e "  ${RED}✗${NC} http://localhost:${port} ${YELLOW}(${name})${NC} ${RED}[tunnel inactif]${NC}"
        fi
    done <<< "$PORTS"
}

# Fonction pour arrêter les tunnels
stop_tunnels() {
    echo -e "${BLUE}🛑 Arrêt des tunnels SSH${NC}"
    echo ""
    
    if pkill -f "autossh.*$REMOTE_HOST" 2>/dev/null; then
        echo -e "${GREEN}✓ Tunnels arrêtés${NC}"
    else
        echo -e "${YELLOW}⚠ Aucun tunnel actif${NC}"
    fi
}

# Fonction pour afficher le statut
show_status() {
    echo -e "${BLUE}📊 Statut des tunnels${NC}"
    echo ""
    
    PROCESSES=$(ps aux | grep -E "autossh.*$REMOTE_HOST" | grep -v grep)
    
    if [ -z "$PROCESSES" ]; then
        echo -e "${YELLOW}⚠ Aucun tunnel actif${NC}"
    else
        echo -e "${GREEN}✓ Tunnels actifs :${NC}"
        echo ""
        
        # Extraire les ports des tunnels actifs
        echo "$PROCESSES" | while read -r line; do
            port=$(echo "$line" | grep -oP '(?<=-L )\d+(?=:localhost)')
            if [ -n "$port" ]; then
                echo -e "  ${GREEN}•${NC} localhost:${port}"
            fi
        done
    fi
}

# Fonction de pause
pause() {
    echo ""
    echo -e "${YELLOW}Appuyez sur Entrée pour continuer...${NC}"
    read -r
}

# Fonction principale
main() {
    while true; do
        clear
        print_header
        show_menu

        echo -e "${YELLOW}Votre choix :${NC} \c"
        read -r CHOICE

        case $CHOICE in
            1)
                start_tunnels
                pause
                ;;
            2)
                show_urls
                pause
                ;;
            3)
                stop_tunnels
                pause
                ;;
            4)
                show_status
                pause
                ;;
            5)
                echo -e "${BLUE}🔄 Redémarrage des tunnels${NC}"
                echo ""
                stop_tunnels
                sleep 2
                start_tunnels
                pause
                ;;
            6)
                echo -e "${GREEN}👋 Au revoir !${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Choix invalide${NC}"
                pause
                ;;
        esac
    done
}

# Lancer le menu
main
