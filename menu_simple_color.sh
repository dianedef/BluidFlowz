#!/bin/bash

# Menu Ultra-Simple - Version Texte Pure
# Menu fonctionnel sans dépendances graphiques

# Load shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Fonction d'affichage avec couleurs
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                ${YELLOW}DevServer Menu${NC}               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}           ${BLUE}Development Environment${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Fonction d'affichage du menu
show_menu() {
    echo -e "${GREEN}Choisissez une option :${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 📁 Naviguer dans /root"
    echo -e "  ${CYAN}2)${NC} 📋 Lister les environnements"
    echo -e "  ${CYAN}3)${NC} 🌐 Afficher les URLs"
    echo -e "  ${CYAN}4)${NC} 🛑 Stopper un environnement"
    echo -e "  ${CYAN}5)${NC} 📝 Ouvrir le répertoire de code"
    echo -e "  ${CYAN}6)${NC} 🚀 Déployer un repo GitHub"
    echo -e "  ${CYAN}7)${NC} 🗑️  Supprimer un environnement"
    echo -e "  ${CYAN}8)${NC} ▶️  Démarrer un environnement"
    echo -e "  ${CYAN}9)${NC} ❌ Quitter"
    echo ""
}

# Fonction de saisie
input() {
    local prompt="$1"
    local default="$2"
    echo -e "${YELLOW}$prompt${NC} \c"
    read -r result
    echo "${result:-$default}"
}

# Fonction principale
main() {
    # Nettoyer les projets orphelins au démarrage
    cleanup_orphan_projects
    
    while true; do
        clear
        print_header
        show_menu

        echo -e "${YELLOW}Votre choix :${NC} \c"
        read -r CHOICE

        case $CHOICE in
            1)
                echo -e "${GREEN}📁 Navigation dans /root${NC}"
                FOLDERS=$(find /root -maxdepth 1 -type d ! -name ".*" ! -path /root | sort)

                if [ -z "$FOLDERS" ]; then
                    echo -e "${RED}❌ Aucun dossier trouvé${NC}"
                else
                    echo -e "${BLUE}Dossiers disponibles :${NC}"
                    echo ""
                    i=1
                    while IFS= read -r folder; do
                        echo -e "  ${CYAN}$i)${NC} $folder"
                        ((i++))
                    done <<< "$FOLDERS"
                    echo ""
                    echo -e "${YELLOW}Choisissez un numéro (1-$((i-1))) :${NC} \c"
                    read -r choice

                    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
                        SELECTED=$(echo "$FOLDERS" | sed -n "${choice}p")
                        echo -e "${GREEN}📁 Dossier sélectionné : $SELECTED${NC}"
                        echo -e "${CYAN}Commande : cd $SELECTED${NC}"
                        echo -e "${GREEN}Ouverture du shell...${NC}"
                        cd "$SELECTED" && exec $SHELL
                    else
                        echo -e "${RED}❌ Choix invalide${NC}"
                    fi
                fi
                ;;
            2)
                echo -e "${GREEN}📋 Environnements actifs${NC}"
                echo "Chargement..."
                sleep 0.5

                ALL_ENVS=$(list_all_environments)
                
                if [ -z "$ALL_ENVS" ]; then
                    echo -e "${RED}❌ Aucun environnement trouvé${NC}"
                else
                    echo ""
                    while IFS= read -r name; do
                        pm2_status=$(get_pm2_status "$name")
                        project_dir=$(get_project_dir "$name")
                        
                        # Afficher le statut avec la bonne couleur
                        case "$pm2_status" in
                            "online")
                                echo -e "${GREEN}🟢 [ONLINE] $name${NC}"
                                ;;
                            "stopped")
                                echo -e "${YELLOW}🟡 [STOPPED] $name${NC}"
                                ;;
                            "errored"|"error")
                                echo -e "${RED}🔴 [ERROR] $name${NC}"
                                ;;
                            "pm2-not-installed")
                                echo -e "${RED}❌ [PM2 NOT INSTALLED] $name${NC}"
                                ;;
                            *)
                                echo -e "${CYAN}⚪ [${pm2_status^^}] $name${NC}"
                                ;;
                        esac
                        
                        # Afficher le répertoire du projet
                        if [ -n "$project_dir" ]; then
                            echo -e "${BLUE}   📂 $project_dir${NC}"
                            
                            # Afficher si environnement Flox présent
                            if [ -d "$project_dir/.flox" ]; then
                                echo -e "${GREEN}   ✅ Flox activé${NC}"
                            fi
                        fi
                        
                        # Afficher le port si disponible
                        local port=$(get_port_from_pm2 "$name")
                        if [ -n "$port" ]; then
                            echo -e "${CYAN}   🔌 Port: $port${NC}"
                        fi
                        echo ""
                    done <<< "$ALL_ENVS"
                fi
                ;;
            3)
                echo -e "${GREEN}🌐 URLs des environnements${NC}"
                ALL_ENVS=$(list_all_environments)

                if [ -z "$ALL_ENVS" ]; then
                    echo -e "${RED}❌ Aucun environnement trouvé${NC}"
                else
                    echo -e "${BLUE}Environnements disponibles :${NC}"
                    echo ""
                    i=1
                    while IFS= read -r env; do
                        echo -e "  ${CYAN}$i)${NC} $env"
                        ((i++))
                    done <<< "$ALL_ENVS"
                    echo ""
                    echo -e "  ${CYAN}0)${NC} Annuler"
                    echo ""
                    echo -e "${YELLOW}Choisissez un numéro (0-$((i-1))) :${NC} \c"
                    read -r choice

                    if [[ "$choice" == "0" ]]; then
                        echo -e "${BLUE}❌ Annulé${NC}"
                    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
                        ENV_NAME=$(echo "$ALL_ENVS" | sed -n "${choice}p")

                        echo ""
                        echo -e "${GREEN}🌐 URLs pour $ENV_NAME :${NC}"
                        
                        PORT=$(get_port_from_pm2 "$ENV_NAME")
                        
                        if [ -n "$PORT" ]; then
                            echo -e "  • ${CYAN}http://localhost:${PORT}${NC}"
                            echo -e "  • ${CYAN}http://164.92.221.78:${PORT}${NC}"
                        else
                            echo -e "${YELLOW}  ⚠️  Projet non démarré ou port non assigné${NC}"
                        fi
                    else
                        echo -e "${RED}❌ Choix invalide${NC}"
                    fi
                fi
                ;;
            4)
                echo -e "${GREEN}🛑 Stopper un environnement${NC}"
                ALL_ENVS=$(list_all_environments)

                if [ -z "$ALL_ENVS" ]; then
                    echo -e "${RED}❌ Aucun environnement trouvé${NC}"
                else
                    echo -e "${BLUE}Environnements à arrêter :${NC}"
                    echo ""
                    i=1
                    while IFS= read -r env; do
                        echo -e "  ${CYAN}$i)${NC} $env"
                        ((i++))
                    done <<< "$ALL_ENVS"
                    echo ""
                    echo -e "  ${CYAN}0)${NC} Annuler"
                    echo ""
                    echo -e "${YELLOW}Choisissez un numéro (0-$((i-1))) :${NC} \c"
                    read -r choice

                    if [[ "$choice" == "0" ]]; then
                        echo -e "${BLUE}❌ Annulé${NC}"
                    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
                        ENV_NAME=$(echo "$ALL_ENVS" | sed -n "${choice}p")

                        echo -e "${YELLOW}🛑 Arrêt de $ENV_NAME...${NC}"
                        env_stop "$ENV_NAME"
                        echo -e "${GREEN}✅ Environnement $ENV_NAME arrêté !${NC}"
                    else
                        echo -e "${RED}❌ Choix invalide${NC}"
                    fi
                fi
                ;;
            5)
                echo -e "${GREEN}📝 Ouvrir le répertoire de code${NC}"
                ALL_ENVS=$(list_all_environments)

                if [ -z "$ALL_ENVS" ]; then
                    echo -e "${RED}❌ Aucun environnement trouvé${NC}"
                else
                    echo -e "${BLUE}Environnements disponibles :${NC}"
                    echo ""
                    i=1
                    while IFS= read -r env; do
                        echo -e "  ${CYAN}$i)${NC} $env"
                        ((i++))
                    done <<< "$ALL_ENVS"
                    echo ""
                    echo -e "${YELLOW}Choisissez un numéro (1-$((i-1))) :${NC} \c"
                    read -r choice

                    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
                        ENV_NAME=$(echo "$ALL_ENVS" | sed -n "${choice}p")
                        PROJECT_DIR="$PROJECTS_DIR/$ENV_NAME"

                        if [ -d "$PROJECT_DIR" ]; then
                            echo -e "${GREEN}📂 Répertoire du projet : $PROJECT_DIR${NC}"
                            echo -e "${GREEN}Ouverture du dossier...${NC}"
                            cd "$PROJECT_DIR" && exec $SHELL
                        else
                            echo -e "${RED}❌ Répertoire introuvable : $PROJECT_DIR${NC}"
                        fi
                    else
                        echo -e "${RED}❌ Choix invalide${NC}"
                    fi
                fi
                ;;
            6)
                echo -e "${GREEN}🚀 Déployer un repo GitHub${NC}"
                echo "Fonctionnalité disponible ! 🚀"

                # Lister les repos GitHub
                echo ""
                echo -e "${BLUE}🔍 Recherche de vos repos GitHub...${NC}"
                echo ""

                GITHUB_REPOS=$(list_github_repos)

                if [ -z "$GITHUB_REPOS" ]; then
                    continue
                fi

                echo -e "${GREEN}Repos disponibles :${NC}"
                echo ""
                i=1
                while IFS= read -r repo; do
                    echo -e "  ${CYAN}$i)${NC} $repo"
                    ((i++))
                done <<< "$GITHUB_REPOS"
                echo ""
                echo -e "${YELLOW}Choisissez un numéro (1-$((i-1))) :${NC} \c"
                read -r choice

                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
                    SELECTED_REPO=$(echo "$GITHUB_REPOS" | sed -n "${choice}p" | cut -d':' -f1)

                    echo ""
                    echo -e "${GREEN}📦 Repo sélectionné : $SELECTED_REPO${NC}"
                    echo -e "${BLUE}🚀 Déploiement en cours...${NC}"
                    echo ""

                    # Nom du projet = nom du repo (sans timestamp)
                    PROJECT_NAME="${SELECTED_REPO,,}"
                    PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"

                    # Vérifier si le projet existe déjà
                    if [ -d "$PROJECT_DIR" ]; then
                        echo -e "${YELLOW}⚠️  Le projet $PROJECT_NAME existe déjà${NC}"
                        echo -e "${YELLOW}Voulez-vous le remplacer ? (o/N) :${NC} \c"
                        read -r confirm
                        if [[ ! "$confirm" =~ ^[oO]$ ]]; then
                            echo -e "${BLUE}❌ Annulé${NC}"
                            continue
                        fi
                        # Supprimer l'ancien projet
                        env_remove "$PROJECT_NAME"
                    fi

                    echo -e "${YELLOW}Création du projet $PROJECT_NAME...${NC}"
                    mkdir -p "$PROJECT_DIR"

                    # Cloner le repo
                    GITHUB_USER=$(get_github_username)
                    echo -e "${YELLOW}Clonage du repo https://github.com/$GITHUB_USER/$SELECTED_REPO...${NC}"
                    if git clone "https://github.com/$GITHUB_USER/$SELECTED_REPO.git" "$PROJECT_DIR"; then
                        echo -e "${GREEN}✅ Repo cloné avec succès${NC}"
                    else
                        echo -e "${RED}❌ Erreur lors du clonage${NC}"
                        rm -rf "$PROJECT_DIR"
                        continue
                    fi

                    # Initialiser l'environnement Flox
                    echo ""
                    echo -e "${YELLOW}🔧 Initialisation de l'environnement Flox...${NC}"
                    if ! init_flox_env "$PROJECT_DIR" "$PROJECT_NAME"; then
                        echo -e "${RED}❌ Échec de l'initialisation Flox${NC}"
                        rm -rf "$PROJECT_DIR"
                        continue
                    fi

                    # Démarrer l'environnement
                    echo ""
                    echo -e "${GREEN}🚀 Démarrage du projet...${NC}"
                    env_start "$PROJECT_NAME"
                    
                    PORT=$(get_port_from_pm2 "$PROJECT_NAME")
                    
                    echo ""
                    echo -e "${GREEN}✅ Déploiement réussi !${NC}"
                    echo ""
                    
                    if [ -n "$PORT" ]; then
                        echo -e "${BLUE}🌐 URLs disponibles :${NC}"
                        echo -e "  • ${CYAN}http://localhost:${PORT}${NC}"
                        echo -e "  • ${CYAN}http://164.92.221.78:${PORT}${NC}"
                        echo ""
                    fi
                    
                    echo -e "${YELLOW}📝 Code disponible dans : $PROJECT_DIR${NC}"
                else
                    echo -e "${RED}❌ Choix invalide${NC}"
                fi
                ;;
            7)
                echo -e "${GREEN}🗑️  Supprimer un environnement${NC}"
                ALL_ENVS=$(list_all_environments)

                if [ -z "$ALL_ENVS" ]; then
                    echo -e "${RED}❌ Aucun environnement trouvé${NC}"
                else
                    echo -e "${BLUE}Environnements disponibles :${NC}"
                    echo ""
                    i=1
                    while IFS= read -r env; do
                        echo -e "  ${CYAN}$i)${NC} $env"
                        ((i++))
                    done <<< "$ALL_ENVS"
                    echo ""
                    echo -e "  ${CYAN}0)${NC} Annuler"
                    echo ""
                    echo -e "${YELLOW}Choisissez un numéro (0-$((i-1))) :${NC} \c"
                    read -r choice

                    if [[ "$choice" == "0" ]]; then
                        echo -e "${BLUE}❌ Annulé${NC}"
                    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
                        ENV_NAME=$(echo "$ALL_ENVS" | sed -n "${choice}p")

                        echo ""
                        echo -e "${RED}⚠️  ATTENTION : Cette action est irréversible !${NC}"
                        echo -e "${YELLOW}Projet : $ENV_NAME${NC}"
                        echo -e "${YELLOW}Dossier : $PROJECTS_DIR/$ENV_NAME${NC}"
                        echo ""

                        env_remove "$ENV_NAME"
                        echo ""
                        echo -e "${GREEN}✅ Projet $ENV_NAME supprimé avec succès !${NC}"
                    else
                        echo -e "${RED}❌ Choix invalide${NC}"
                    fi
                fi
                ;;

            8)
                echo -e "${GREEN}▶️  Démarrer un environnement${NC}"
                ALL_ENVS=$(list_all_environments)

                if [ -z "$ALL_ENVS" ]; then
                    echo -e "${RED}❌ Aucun environnement trouvé${NC}"
                else
                    echo -e "${BLUE}Environnements disponibles :${NC}"
                    echo ""
                    i=1
                    while IFS= read -r env; do
                        echo -e "  ${CYAN}$i)${NC} $env"
                        ((i++))
                    done <<< "$ALL_ENVS"
                    echo ""
                    echo -e "  ${CYAN}0)${NC} Annuler"
                    echo ""
                    echo -e "${YELLOW}Choisissez un numéro (0-$((i-1))) :${NC} \c"
                    read -r choice

                    if [[ "$choice" == "0" ]]; then
                        echo -e "${BLUE}❌ Annulé${NC}"
                    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
                        ENV_NAME=$(echo "$ALL_ENVS" | sed -n "${choice}p")

                        PROJECT_DIR=$(get_project_dir "$ENV_NAME")

                        if [ -z "$PROJECT_DIR" ]; then
                            echo -e "${RED}❌ Projet introuvable : $ENV_NAME${NC}"
                        else
                            echo ""
                            echo -e "${GREEN}▶️  Démarrage du projet $ENV_NAME...${NC}"

                            env_start "$ENV_NAME"
                            
                            echo ""
                            echo -e "${GREEN}✅ Projet démarré avec succès !${NC}"
                            echo ""
                            
                            PORT=$(get_port_from_pm2 "$ENV_NAME")
                            if [ -n "$PORT" ]; then
                                echo -e "${BLUE}🌐 URLs disponibles :${NC}"
                                echo -e "  • ${CYAN}http://localhost:${PORT}${NC}"
                                echo -e "  • ${CYAN}http://164.92.221.78:${PORT}${NC}"
                            else
                                echo -e "${YELLOW}  ⚠️  Port non assigné${NC}"
                            fi
                            echo ""
                            echo -e "${YELLOW}📝 Code disponible dans : $PROJECT_DIR${NC}"
                        fi
                    else
                        echo -e "${RED}❌ Choix invalide${NC}"
                    fi
                fi
                ;;

            9)
                echo -e "${GREEN}👋 Au revoir !${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Option invalide${NC}"
                ;;
        esac

        echo ""
        echo -e "${YELLOW}Appuyez sur Entrée pour continuer...${NC}"
        read -r
    done
}

# Lancer le menu
main