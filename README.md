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