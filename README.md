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
docker build --tag my-app:development --file ./my-nest-js/Dockerfile.development ./my-app
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
docker-compose --file compose.development.yml up --build --watch
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