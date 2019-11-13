# PSGPOTool

![Build Status](https://build.status.url.here)

## Description

This module administrate the local GPO and the export of domain GPO

Authored by NicolasB

## RoadMap
On référence ici les éléments les plus importants à prendre en compte pour une première version.
### Classe GPOToolsAdmx
* [x]  La classe récupère bien le FilePath
* [x]  La classe contient le nom du fichier en BaseName
* [x]  La classe contient le Target : Utilisation de la classe [AdmxNamespace]
* [x]  La classe contient le using : Utilisation de la classe [AdmxNamespace]
* [ ]  La classe récupère bien les éléments SupportedOn du fichier
Utilisation de la classe [AdmxSupportedOn]
    * [x]  Name
    * [x]  displayName
    * [ ]  or
* [x]  La classe récupère bien les éléments Categories
Utilisation de la classe [AdmxCategory]
    * [x]  Name
    * [x]  displayName
    * [x]  ParentCategory
    * [x]  explaintext
* [ ]  La classe récupère bien les éléments policy constants
Utilisation de la classe [AdmxPolicy]
    * [x]  Name
    * [x]  Classe
    * [x]  displayName
    * [x]  explainText
    * [ ]  key
    * [x]  parentCategory
    * [x]  SupportedOn

### Classe GPOToolsAdml
* [x]  La classe récupère bien le FilePath
* [x]  La classe contient le nom du fichier en BaseName
* [x]  La classe récupère bien les éléments de StringTable
    * [x]  id
    * [x]  #text
La prise en compte de la section presentation peut avoir un intérêt ?

### Classe GPOToolsPolicy
Cette classe est utilisée pour joindre les information des classes GPOToolsAdmx et GPOToolsADML.
* [ ]  creation du champ Name avec l'affichage contenu dans le fichier adml
* [ ]  Le champ Path devra contenir l'arborescence des categories au format string
* [ ]  on peut rajouter dans le champ path le scope : user/computer
* [ ]  le champ FullName contiendra le path + le Name
* [ ]  le champ state permettra de voir si le parametre est desactivé\acrivé ou non configuré. Pour ce cas il sera necessaire de créer une méthode capable de checker la conf en fonction des elements de la policy
* [ ]  le champ id contiendra l'id du parametre
* [ ]  le champ category contiendra la category d'apartenance du parametre. L'objet category devra contenir son objet parent pour pouvoir determiner son path complet. Pour cela, la propriete static Categories contiendra l'ensemble des categorie des fichier admx.
* [ ]  Voir si les proprietes Options et Registry son adapté pour tous les cas et si il ne faut pas adapter en fonction. Traité en premier lieu les cas les plus simples


### Futur upates
* [ ]  Prevoir la mise en place d'un provider pour explorer les parametres de maniere simple, commes un systeme de fichier.
* [ ]  Lire le contenu d'un fichier .pol et interpreter les clefs qu'il contient en fonction des admx et adml.
* [ ]  etre capable de comparer plusieurs centaines de gpo .pol
* [ ]  pouvoir explorer les gpos de domaine simplement avec un provider
* [ ]  rendre compatible avec Transaction sur le registre pour faciliter le retour arriere.
* [ ]  donner un avertissement a l'utilisateur quand le paramètre que l'on cherche a configurer n'est pas supporté.
* [ ]  Prévoir une fonction qui listes toutes les catégories

### On casse tous et on recommence
* [ ]  On créé un classe GPOToolsUtility à peu prês semblable à GPOToolsPolicy
    * [x]  Cette classe contiendra des membres static qui auront pour but :
        * [x]  Méthode de chargement à partir d'un dossier comme PolicyDefinitions
        * [x]  Méthode de chargement à parti d'un fichier seul avec prise en compte des dépendance
        * [x]  Méthode de vérification des dépendances et de chargement si jamais elles existent
        * [x]  La classe disposera de l'ensemble des catégories dans une propriété statique et invisible
        * [x]  Les objets categories devront avoir une notion de parent enfant
        * [x]  La classe disposera de l'ensemble des SupportedOn dans une propriété statique et invisible
        * [ ]  La classe disposera de l'ensemble des Policy dans une propriété statique et invisible
        * [x]  La classe pourra recharger un ou plusieurs fichier et donc écraser ses données
* [ ] Mise en place de script de test pour valider les différentes méthodes
    * [x] InitiateAdmxAdml Folder/File
    * [x] GetADMLPathFromADMX
    * [x] CheckAndInitiateDependency
    * [x] FindDependancyFile
    * [ ]
* [ ] Prise en compte des champs namespace dans les categories parents

* [ ]  Créer une classe enum pour chaque option de chaque élément ?


## Installing

~~The easiest way to get PSGPOTool is using the [PowerShell Gallery](https://powershellgallery.com/packages/PSGPOTool/)!~~

### Inspecting the module

~~Best practice is that you inspect modules prior to installing them. You can do this by saving the module to a local path:~~

``` PowerShell
PS> Save-Module -Name PSGPOTool -Path <path>
```

### Installing the module

~~Once you trust a module, you can install it using:~~

``` PowerShell
PS> Install-Module -Name PSGPOTool
```

### Updating PSGPOTool

~~Once installed from the PowerShell Gallery, you can update it using:~~

``` PowerShell
PS> Update-Module -Name PSGPOTool
```

### Uninstalling PSGPOTool

~~To uninstall PSGPOTool:~~

``` PowerShell
PS> Uninstall-Module -Name PSGPOTool
```

## Contributing to PSGPOTool

Interested in contributing? Read how you can [Contribute](contributing.md) to PSGPOTool

This project maintains a [Code of Conduct](code-of-conduct.md) that establishes how the project is governed and how everyone involved is expected to behave. You can report unacceptable behavior to [baudin.nicolas@outlook.fr](mailto:baudin.nicolas@outlook.fr).

## Release History

A detailed release history is contained in the [Change Log](CHANGELOG.md).

## License

PSGPOTool is provided under the [MIT license](LICENSE.md).
