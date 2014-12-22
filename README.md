# Projet A&G - Parser de Partitions
___HALLAL Marwan - NOGUERON Matthieu___

## Sommaire
#### I. Principe du projet
#### II. Fonctionnalités implémentées

## I. Principe du projet

Ce projet est basé sur un système de notations suivant les différents fonctionnalités implémentées :

* 10/20 : transformation de partition en colonne vers une liste triée de sons datés

* 12/20 : précédent + gestion des fractions de tempo
```
(noire "1" = 1 temps, blanche "1o"=2 temps, ronde "1@" = 4 temps,  croche "."=1/2 temps, double croche ":" = 1/4 de temps, triolet "^" = 1/3 de temps)
```

* 14/20 : précédent + transformation de la liste triée de sons datés en une liste d'accords datés
```
au lieu de  [ (1.0,"poum") ; (1.0, "wizz") ; (1.2, "crack") ] on regoupe les sons qui doivent être joués simultanément. <br> On retourne [ (1.0, ["poum";"wizz"]) ; (1.2, ["crack"]) ]
```

* 16/20 : précédent + gestion des données longues entre accolades {}

* 18/20 : précédent + gestion des répétitions  * nombre [ mesures entre crochets ]

* 20/20 : précédent + player (graphique) après parsing de la liste triées des accords (façon karaoké)

## II. Fonctionnalités implémentées

__TODO__

