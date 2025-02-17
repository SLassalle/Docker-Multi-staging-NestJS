# Introduction au multi-staging Docker

## Création d'une application NestJS pour la démonstration

On va créer une application avec NestJS pour la démonstration.

```bash
npm i -g @nestjs/cli
nest new project-name
```

Après avoir sélectionné les différentes options, on peut se rendre dans le dossier de l'application et démarrer l'application.

```bash
cd my-nest-js
# Démarrage de l'application
npm run start
```
### Création d'une image dédiée au développement

On va créer une image Docker pour l'application React.js en mode développement. Pour cela, on crée un fichier `Dockerfile.development` à la racine du projet.

```Dockerfile
FROM node:latest

WORKDIR /app

COPY ./package.json ./

RUN npm install

COPY ./ ./

CMD ["npm", "run", "start:dev", "--", "--host", "0.0.0.0"]
```

On peut maintenant construire l'image Docker.

```bash
docker build --tag my-app:development --file ./my-nest-js/Dockerfile.development ./my-nest-js
```

On peut maintenant démarrer un conteneur Docker avec l'image créée.

```bash
docker run --publish 3000:3000 my-app:development
```

On pourrait ajouter un volume pour synchroniser les modifications du code source avec le conteneur Docker, mais on préfèrera utiliser un Docker Compose pour cela, avec éventuellement Docker Compose Watch.

### Docker Compose Watch

On va utiliser Docker Compose Watch pour synchroniser les modifications du code source avec le conteneur Docker. Pour cela, on va créer un fichier `compose.development.yml` à la racine du projet.

```yaml
services:
  my-app:
    image: my-app:development
    build:
      context: ./my-nest-js
      dockerfile: Dockerfile.development
    ports:
      - "3000:3000"
    develop:
      watch:
        - action: sync
          path: ./my-nest-js/src
          target: /app/src
        - action: sync+restart
          path: ./my-nest-js
          target: /app
        - action: rebuild
          path: ./my-nest-js/package.json
```

Contrairement aux volumes, Docker Compose Watch permet de synchroniser les modifications avec le conteneur Docker de manière unidirectionnelle. 

On peut maintenant démarrer le conteneur Docker avec Docker Compose Watch.

```bash
docker compose --file compose.development.yml up --build --watch
```

En ignorant (via le `.dockerignore`) le dossier `node_modules`, on peut éviter de synchroniser les dépendances du conteneur Docker avec le code source (évitant les potentiels conflits).

### Action: `sync`

En synchronisant le dossier `src` du code source avec le dossier `src` du conteneur Docker, on peut voir les modifications en temps réel dans le navigateur.

### Action: `sync+restart`

En synchronisant le dossier `my-nest-js` du code source avec le dossier `app` du conteneur Docker, on peut redémarrer le conteneur Docker en cas de modification. Cela permet notamment un redémarrage lors des modifications des fichiers de configuration.

#### Action: `rebuild`

En surveillant le `package.json`, on peut reconstruire le conteneur Docker en cas de modification des dépendances. Cela permet d'avoir les dépendances automatiquement installées au sein d'une nouvelle image (construite automatiquement) lors d'une installation en local.

### Commit des modifications pour sauvegarde

Tout cela est bien pour le développement, et on peut éventuellement commit les modifications pour les sauvegarder.

```bash
docker commit <container_id> my-app:development
```

---

Lorsque l'on souhaitera déployer, on favorisera une image dédiée à la production, plus légère, contenant uniquement le résultat de la construction de l'application et le serveur web. On n'a pas besoin d'avoir les dépendances de développement dans l'image de production, ainsi que l'ensemble des outils de développement.

> 💡 Le multi-staging est utilisé pour créer des images Docker plus légères en séparant les étapes de développement et de production. Cela permet de réduire la taille des images finales en n’incluant que ce qui est nécessaire pour exécuter l’application.

### Création d'une image dédiée à la production

On va créer une image Docker pour l'application React.js en mode production. Pour cela, on crée un fichier `Dockerfile à la racine du projet.

```bash

```Dockerfile
FROM node:latest AS builder

WORKDIR /app

COPY ./package.json .

RUN npm install

COPY . .

RUN npm run build


FROM oven/bun:alpine AS server

WORKDIR /app

COPY --from=builder /app/dist ./dist

COPY ./package.json .

RUN bun install --production

CMD ["bun", "dist/main"]
```

Le premier stage correspond à l'étape de construction de l'application, et le second stage correspond à l'étape de déploiement de l'application via le runtime Bun.

> 💡 Pour tirer le meilleur parti du multi-staging, minimisez les couches dans chaque étape et utilisez des images de base légères. Assurez-vous également de nettoyer les fichiers temporaires et inutiles pour optimiser la taille de l’image.

On peut maintenant construire l'image Docker.

```bash
docker build --tag my-app:production ./my-nest-js
```

On peut maintenant démarrer un conteneur Docker avec l'image créée.

```bash
docker run --publish 3000:3000 my-app:production
```

## Comparaisons

En faisant un `docker images`, on peut comparer les images Docker créées.

```bash
docker images
```

```
REPOSITORY      TAG           IMAGE ID       CREATED              SIZE
react-app   production    ...            ...                  75.7MB
react-app   development   ...            ...                  2.03GB
```

On peut voir que l'image de production est beaucoup plus légère que l'image de développement. Seul le runtime Bun (avec l'application pré-construite) est présent dans l'image de production, alors que l'image de développement contient l'ensemble des dépendances de développement. Uniquement l'image de base pour la seconde étape (`server`) est présente dans l'image de production.

> 💡 Dans un Dockerfile traditionnel, toutes les opérations sont effectuées dans un seul conteneur, ce qui peut entraîner des images volumineuses et complexes. Le multi-staging, en revanche, permet de diviser le processus de construction en étapes distinctes, optimisant ainsi l’image finale.

## Conclusion

Le multi-staging permet de créer des images Docker plus légères et sécurisées.

En séparant les étapes de développement et de production, on optimise les performances et réduit les risques en production.

C'est une pratique essentielle pour tout développeur cherchant à améliorer ses workflows Docker.

## Exemple avec une application Python

### Création d'un Dockerfile multi-staging

Créez un premier stage pour installer les dépendances et préparer l'environnement de développement :

```Dockerfile
FROM python:3.10 AS builder

# Installer les dépendances système nécessaires :
RUN apt-get update && apt-get install -y build-essential

WORKDIR /app

COPY requirements.txt ./

# Installer les dépendances :
RUN pip install --no-cache-dir -r requirements.txt

# Copier le reste des fichiers :
COPY ./ ./

# Construire l'application (si nécessaire, par ex. compilation Cython) :
RUN python setup.py build
```

Créez un second stage minimaliste pour exécuter l'application :

```Dockerfile
FROM python:3.10-slim AS server

WORKDIR /app

# Copier uniquement les fichiers nécessaires depuis le stage précédent :
COPY --from=builder /app /app

# Installer uniquement les dépendances nécessaires à la production :
RUN pip install --no-cache-dir -r requirements.txt --only-binary=:all:

# Commande par défaut pour démarrer l'application :
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:8000", "app:app"]
```

Le premier stage utilise une image complète avec tous les outils nécessaires à la construction.
Le second stage utilise une image légère (slim) et ne conserve que ce qui est indispensable à l'exécution.

# Analyse approfondie

## Utilisation d'un unique Dockerfile

On peut utiliser un unique Dockerfile pour les environnements de développement et de production. On va simplement séparer les étapes de construction et d'exécution de manière distincte pour le développement et la production.

Dans un Dockerfile multi-étapes, le paramètre `target` dans Docker Compose ou le *flag* `--target` dans `docker build` permet de spécifier à quelle étape du processus de construction s'arrêter. 

```Dockerfile
FROM node:latest AS base

WORKDIR /app

COPY ./package.json ./

RUN npm install

COPY ./ ./


FROM base AS development

CMD ["npm", "run", "start:dev", "--", "--host", "0.0.0.0"]


FROM base AS build

RUN npm run build


FROM oven/bun:alpine AS production

COPY --from=builder /app/dist ./dist

COPY ./package.json .

RUN bun install --production

CMD ["bun", "dist/main"]
```

On a ici 4 étapes :
- `base` : étape de base pour installer les dépendances et copier le code source
- `development` : étape pour démarrer l'application en mode développement
- `build` : étape pour construire l'application
- `production` : étape pour démarrer l'application en mode production

On peut maintenant construire l'image Docker pour l'environnement de développement avec le *flag* `--target`.

```bash
docker build --tag react-app:development --target development ./react-app
```

On peut maintenant construire l'image Docker pour l'environnement de production avec le *flag* `--target`.

```bash
docker build --tag react-app:production --target production ./react-app
```

Concrètement, la construction de l'image Docker pour l'environnement de développement va s'arrêter à l'étape `development` et celle pour l'environnement de production à l'étape `production`. L'étape de production ne va même pas lancer les commandes de l'étape de développement, car elles ne sont pas nécessaires, et il n'existe aucune dépendance entre les étapes.

## Mise à jour du Docker Compose

### Utilisation de `target`

Le Docker Compose est principalement dédié à l'environnement de développement. On va donc mettre à jour le fichier `compose.development.yml` pour utiliser l'image Docker pour l'environnement de développement ou la construire si elle n'existe pas en utilisant l'attribut `target`.

```yaml
services:
  react-app:
    image: my-nest-js:development
    build:
      context: ./react-app
      dockerfile: Dockerfile
      target: development
    ports:
      - "3000:3000"
    develop:
      watch:
        - action: sync
          path: ./my-nest-js/src
          target: /app/src
        - action: sync+restart
          path: ./my-nest-js
          target: /app
        - action: rebuild
          path: ./my-nest-js/package.json
  # ...
```

### Utilisation d'une variable d'environnement

Pour l'environnement de production, on va utiliser une variable d'environnement pour spécifier l'image Docker à utiliser. On va mettre à jour le fichier `compose.production.yml` (en `compose.yml`) pour utiliser l'image Docker pour l'environnement de production.

On commence par définir la variable d'environnement dans le fichier `.env`.

```
ENVIRONMENT=production
```

On peut maintenant mettre à jour le fichier `compose.yml` pour utiliser la variable d'environnement.

```yaml
services:
  my-app:
    build:
      context: ./my-nest-js
      dockerfile: dockerfile
      target: ${ENVIRONMENT}
    ports:
      - "3000:3000"
      - "80:80"
    develop:
      watch:
        - action: sync
          path: ./my-nest-js/src
          target: /app/src
        - action: sync+restart
          path: ./my-nest-js
          target: /app
        - action: rebuild
          path: ./my-nest-js/package.json
  # ...
```

Ainsi, on peut démarrer facilement l'application en mode développement ou production en utilisant la variable d'environnement `ENVIRONMENT`.

```bash
docker-compose up --build
```

#### Utilisation d'un `Makefile`

Un `Makefile` a été ajouté pour simplifier les commandes.

```Makefile
ENV_FILE=.env

.PHONY: dev prod

watch:
	@echo "ENVIRONMENT=development" > $(ENV_FILE)
	@docker-compose up --build --watch

run:
	@echo "ENVIRONMENT=production" > $(ENV_FILE)
	@docker-compose up --build
```

On peut maintenant démarrer l'application en mode développement ou production en utilisant les commandes suivantes.

```bash
make watch
```

```bash
make run
```

## Conclusion

Le multi-staging est particulièrement efficace pour réduire la taille des images, car seule la partie nécessaire pour exécuter l’application est incluse dans l’image finale. Cela améliore également le temps de build et de déploiement, en réduisant la quantité de données à traiter. 

On peut avoir un contrôle sur cela, au sein d'un fichier unique, en ciblant précisément les étapes de construction et d'exécution pour chaque environnement.