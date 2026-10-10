<h1 align="center">TechfiXhub</h1>

<p align="center">
  <b>Le menu rapide de la clé TechFixer — pensé pour le dépannage PC.</b><br>
  Lanceur d'outils portables avec mises à jour automatiques, auto-réparation et panneau d'état système en direct.
</p>

<p align="center">
  <a href="#-prérequis"><img src="https://img.shields.io/badge/platform-Windows-0B0C14?style=flat-square&labelColor=0B0C14&color=00D4FF" alt="Platform"></a>
  <a href="#-prérequis"><img src="https://img.shields.io/badge/.NET_Framework-4.8-0B0C14?style=flat-square&labelColor=0B0C14&color=7B4FFF" alt=".NET"></a>
  <a href="#-installation"><img src="https://img.shields.io/badge/clé_TechFixer-2608-0B0C14?style=flat-square&labelColor=0B0C14&color=41B375" alt="Clé TechFixer"></a>
  <a href="https://ofbridgelab.blogspot.com/2026/10/techfixhub-le-nouveau-menu-de-la-cle.html"><img src="https://img.shields.io/badge/blog-Ofbridge_Lab-0B0C14?style=flat-square&labelColor=0B0C14&color=FF8C00" alt="Blog"></a>
</p>

<p align="center">
  <a href="https://github.com/user-attachments/assets/1540a3c1-97e7-4f3a-86dc-30069c933674">
    <img width="550" alt="TechfiXhub — fenêtre principale" src="https://github.com/user-attachments/assets/1540a3c1-97e7-4f3a-86dc-30069c933674" />
  </a>
</p>

---

## 💡 Pourquoi TechfiXhub ?

Le menu de la clé TechFixer reposait jusqu'ici sur **Appetizer**, un lanceur portable qui n'est plus maintenu. En atelier, ses limites devenaient gênantes :

- certains programmes ne se lançaient pas toujours correctement ;
- avec le durcissement de Windows Defender, des outils de la clé étaient supprimés — il fallait les retélécharger et les replacer à la main ;
- les mises à jour étaient manuelles, et mettre à jour un seul outil obligeait souvent à refaire toute la clé.

TechfiXhub remplace Appetizer par un menu conçu pour le terrain : plus rapide au lancement, capable de se mettre à jour et de se réparer seul.

---

## 🗂️ Outils classés par usage

Chaque outil affiche sa vraie icône, une courte description et sa version. Un clic sur **Lancer** suffit.

| Catégorie | Outils |
|---|---|
| **Suite Ofbridge Lab** | CyclObs · WinMedic · TechMis |
| **Infos sur le PC** | Battery Monitor · BlueScreenView · ShowKeyPlus · HWiNFO |
| **Stockage** | CrystalDiskInfo · HDDScan · TreeSize |
| **Benchmark** | OCCT · UserDiag · FurMark 2 · RealBench · Final Fantasy XV Benchmark |
| **Réseaux** | 3DP Net · Complete Internet Repair |
| **Désinstallation** | Antivirus Removal Tool · Display Driver Uninstaller · Revo Uninstaller |

**Nouveau : la catégorie Suite Ofbridge Lab**, qui regroupe mes propres outils, nés de cas rencontrés en atelier :

- **CyclObs** — Observateur d'événements avancé : fait ressortir les événements utiles pour comprendre une panne.
- **WinMedic** — Réparation de Windows automatisée : enchaîne les commandes DISM à ta place.
- **TechMis** — Validation d'intervention par tests interactifs, avant de rendre la machine.

---

## 🔄 Mises à jour automatiques

TechfiXhub compare les versions présentes sur la clé aux dernières versions disponibles. Le nombre de mises à jour s'affiche sur chaque catégorie et en haut de la fenêtre. Un clic ouvre la liste (version actuelle → nouvelle version) : mise à jour outil par outil, ou **Tout mettre à jour**.

> Fini de refaire la clé pour mettre à jour un seul logiciel.

---

## 📊 SysOverlay — le PC en un coup d'œil

Un panneau latéral affiche en direct l'état de la machine :

- version de Windows et temps depuis le démarrage ;
- CPU : charge et température ;
- GPU : charge, température, VRAM ;
- RAM : quantité, barrettes, fréquence, occupation ;
- carte mère et version du BIOS ;
- espace libre par disque ;
- niveau de batterie.

Le panneau peut être **détaché en fenêtre flottante**, pour le garder sous les yeux pendant un test de stress.

> ℹ️ Le bouton **Enregistrer** du SysOverlay est réservé à une fonction à venir. Il est inactif pour l'instant — ce n'est pas un bug.

---

## ⚡ Raccourcis système

En bas du Hub, les actions qu’on refait à chaque dépannage :

-Connexion Wi-Fi auto : injecte le profil Wi-Fi du dossier WLANProfile et se connecte.
-Redémarrer vers le BIOS : redémarre directement dans les paramètres UEFI.
-Panneau de configuration : pour les réglages que l’application Paramètres ne propose plus.
-Gestion de l’ordinateur : disques, services, Observateur d’événements, au même endroit.

## ➕ Tes propres applications

En **mode édition**, un bouton **+ Ajouter** apparaît dans chaque catégorie et un crayon permet de modifier chaque outil. Pour chaque appli :

- fichier à lancer (`.exe`, `.bat`, `.cmd`), nom et description ;
- icône — laisse vide et le Hub récupère celle de l'exécutable ;
- lien de téléchargement, ouvert automatiquement si l'appli a disparu de la clé ;
- catégorie et tag ;
- option **Lancer en administrateur**.

Les modifications sont validées ou annulées d'un clic et **stockées à part** : une mise à jour de la clé ne les efface pas.

---

## 🛠️ Réglages et maintenance

- Options d'affichage : SysOverlay au démarrage, catégories dépliées ou non.
- **Réparer une application** : supprime l'outil et le retélécharge. Si Defender a mangé un programme, c'est réglé en un clic.
- Réinitialiser le cache d'icônes.
- **Exporter / Importer** tes personnalisations pour les retrouver sur une autre clé.

---

## 🩹 Une clé qui se répare toute seule

À la racine de la clé, un seul lanceur : **Menu rapide**. Il ouvre TechfiXhub avec les droits administrateur. Si le Hub a été supprimé ou endommagé, le lanceur le restaure automatiquement :

1. depuis une sauvegarde présente sur la clé ;
2. à défaut, en le retéléchargeant depuis ce dépôt GitHub.

---

## 📦 Installation

TechfiXhub est inclus dans la **clé TechFixer à partir de la version 2608** (qui remplace la 2511).

- **Nouvelle clé** : prépare-la avec [TechFixer Installer](https://ofbridgelab.blogspot.com/2026/09/techfixer-installer.html).
- **Clé existante** : relance l'installeur **sans cocher « Reformater »** — seuls les fichiers nouveaux ou modifiés sont copiés.

---

## 🖥️ Prérequis

- Windows
- .NET Framework 4.8

---

## 🤝 Contribuer

Une idée d'outil à intégrer, un bug ? Ouvre une [issue](https://github.com/ofbridge-lab/TechFixer-HUB/issues) ou laisse un commentaire sur [l'article du blog](https://ofbridgelab.blogspot.com/2026/10/techfixhub-le-nouveau-menu-de-la-cle.html).

---

## 📄 Licence

<!-- TODO : confirmer — GPL v3 / licence commerciale -->

Les outils tiers lancés par TechfiXhub restent la propriété de leurs éditeurs respectifs et sont soumis à leurs propres licences.

---

<p align="center">
  <b><a href="https://ofbridgelab.blogspot.com/">Ofbridge Lab</a></b> ·
  <a href="https://ofbridgelab.blogspot.com/p/telechargement.html">Téléchargement</a> ·
  <a href="https://linktr.ee/ofbridgelab">Linktree</a>
</p>

---
