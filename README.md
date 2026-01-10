# Dokploy CLI

Menu interactif pour gérer vos environnements de développement.

## Structure

```
cli/
├── lib.sh                  # Bibliothèque partagée (fonctions réutilisables)
├── menu_simple_color.sh    # Menu interactif principal
└── menu.sh                 # Ancien menu (déprécié)
```

## Architecture

### lib.sh
Contient toute la logique réutilisable :
- Gestion des ports (détection, recherche de ports disponibles)
- Détection de type de projet (Node.js, Python, Rust)
- Création automatique de fichiers compose.yml
- Fonctions de cycle de vie des environnements (start/stop/remove)
- Utilitaires GitHub CLI
- Réassignation automatique des ports en conflit

### menu_simple_color.sh
Interface utilisateur en mode menu interactif :
- Navigation dans /root
- Lister les environnements
- Afficher les URLs
- Stopper un environnement
- Ouvrir le répertoire de code
- Déployer un repo GitHub
- Supprimer un environnement
- Démarrer un environnement

## Utilisation

```bash
cd /root/dokploy/cli
./menu_simple_color.sh
```

## TODO

- [ ] Implémenter l'orchestrateur de conteneurs (remplacer Docker)
- [ ] Ajouter support pour plus de types de projets
- [ ] Ajouter gestion des logs
- [ ] Ajouter monitoring de ressources

## Notes

- Toutes les références à Docker ont été supprimées
- Les fonctions `env_start`, `env_stop`, `env_remove` dans lib.sh sont prêtes pour l'implémentation du nouvel orchestrateur
- Support rétrocompatible des noms de fichiers `compose.yml` et `docker-compose.yml`
