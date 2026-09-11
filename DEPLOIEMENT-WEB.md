# Publier la version web de Maboko sur Vercel

Vercel ne connaît pas Flutter : aucun de ses environnements ne le fournit. Le
SDK est donc récupéré pendant la construction par `outils/build-vercel.sh`,
qui compile ensuite `build/web` — le dossier que `vercel.json` publie.

## Mise en place

1. **Vercel → Add New → Project**, importez le dépôt `maboko-mobile`.
2. **Framework Preset** : *Other*. Ne touchez pas aux commandes : `vercel.json`
   les impose déjà.
3. **Environment Variables** — facultatives, la valeur compilée s'applique
   sans elles :

   | Variable | Valeur |
   |---|---|
   | `API_BASE_URL` | `https://maboko-api.onrender.com/api/v1` |
   | `GOOGLE_CLIENT_ID` | l'identifiant OAuth, si la connexion Google est active |
   | `VERSION_FLUTTER` | `3.44.1` par défaut ; à changer pour suivre une autre version |

4. **Deploy**. La première construction dure plusieurs minutes : le SDK Flutter
   est téléchargé. Les suivantes réutilisent le cache de Vercel.

## Pourquoi la version de Flutter est figée

Le script clone une **version précise**, pas la branche `stable`. Une
construction qui suit une branche mobile change de compilateur sans prévenir :
une mise en ligne qui fonctionnait hier peut échouer demain sans qu'une seule
ligne du projet ait bougé.

## Les photos doivent venir de Supabase

C'est le point à ne pas manquer. Un navigateur qui affiche une image venue
d'un autre domaine exige que ce domaine l'autorise, par un en-tête CORS. Le
moteur de rendu de Flutter web est encore plus strict : il charge les images
par `fetch`, donc **sans cet en-tête, rien ne s'affiche**.

| Source | En-tête CORS | Résultat sur le web |
|---|---|---|
| Supabase Storage | `access-control-allow-origin: *` | les photos s'affichent |
| `/storage` sur Render | aucun | **images invisibles** |

Sur un téléphone cette règle ne s'applique pas, et les deux sources marchent.
Mais dès que la version web est en ligne, le passage à Supabase
(`FILESYSTEM_DISK=supabase`) cesse d'être un confort : il conditionne
l'affichage des photos.

## Poids du premier chargement

| Fichier | Poids |
|---|---|
| `canvaskit.wasm` | 6,9 Mo |
| `main.dart.js` | 3,3 Mo |

Une dizaine de mégaoctets à la première visite, mis en cache ensuite pour un
an par les en-têtes de `vercel.json`. C'est le prix de Flutter sur le web, et
c'est beaucoup sur une connexion 3G dégradée — la version web est un complément
utile pour une démonstration ou un poste de bureau, pas un remplacement de
l'application installée.

## L'autre méthode : publier une construction locale

Si vous préférez ne pas faire construire Vercel :

```
flutter build web --release --dart-define=API_BASE_URL=https://maboko-api.onrender.com/api/v1
npx vercel deploy build/web --prod
```

Vercel publie alors le dossier tel quel. Plus rapide, mais la mise en ligne
n'est plus automatique à chaque poussée sur le dépôt.

## Vérifier après publication

Ouvrez l'adresse fournie par Vercel et contrôlez :

- l'onglet affiche **Maboko** avec le logo ;
- la connexion avec un compte existant aboutit ;
- une page rechargée en profondeur ne renvoie pas une erreur 404 — c'est le
  rôle de la règle de réécriture vers `index.html`.
