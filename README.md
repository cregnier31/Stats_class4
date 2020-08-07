# TEP_CLASS4 

## Installation
### SVN 

svn co https://svn.mercator-ocean.fr/svnroot/mo/TEP/TEP_CLASS4/branches/V6/

## Git 
git clone  https://gitlab.mercator-ocean.fr/mercator/qualif/TEP_CLASS4.git

## Description

Le code est maintenant tout écrit en python, l'interpolation, la recherche des points dans la grille, l'écriture des fichiers de sortie

Le code principal est `script/TEP_CLASS4_kdtree.py`. Il y a aussi une version multiprocs à tester `script/TEP_CLASS4_kdtree_multiproc.py`

Le code se lance avec une série de paramètres et un fichier de configuration qui contient des paramètres et des paths. 

Les fichiers de configurations sont là : `script/cfg/config_...`

Les modules qui servent au code principal sont rangés dans le répertoire `module`

J'ai codé une série de tests unitaires pour les différents cas dans le répertoire 'script/test/'


# Exemple de launcher
```
CONFIG="PSY4QV3R1"
DATE1="20200710"
DATE2="20200710"
typedata="profile"
typemod="pgn"
srcdata="GODAE"
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} --src=${srcdata} --data=${typedata} --typemod=${typemod}
```

# Adaptation profiles de BIO 

- Creation d'une nouvlle config dans `script/cfg/`

- Dans cette nouvelle config créer un nouveau type de donnée dans la section [input_dir] => PREFIX = 

- Ce préfix va être lu dans le Loader.py après la recherche du fichier correspondant au bon jour et à la bonne variable va se faire dans `modules/Extractor.py` 
il va falloir coder une nouvelle fonction qui fait ça ` if type == "....": return Extract...  `, là ça sera simple ça sera juste une recherche et copie de fichier

- Normalement après y a pas de difficulté, le code va passer dans Interpolator.py pour rechercher les 4 points de grille et interpoler 

- Pour le cas d'un profile 3d il va passer dans la fonction interp_3D de Interpolator.py (là que se fait l'interpolation verticale sur les niveaux des profiles).

- Pour verifier l'interpolation verticale il faut sauvegarder les matrices  **tab_interp_tmp[:,ind_prof]**  et  **values_interp[ind_prof,:]**  dans Interpolator.py

- Les données sont là /dataref/opr/DATA/INSITU/HYDRO/BGC_ARGO/daily, le code pour extraire est là `script/extract_BGC.py`, y a parfois plusieurs profiles par jour il sont 
nommés BGC_ARGO...prof..nc si nécessaire il faudra faire un autre script pour le reconcaténer (les profiles du même jour ne sont pas dans l'ordre donc un ncks multiple ne marche pas) avec ncrcat

- Good luck!  :)
