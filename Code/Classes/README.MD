# How Classes work

This class get the content of the admx files. The format of files is XML.
The ADMX and ADML files join their informations with variable structure.

Exemple :

```XML
# Windows ADMX file :
 <categories>
    <category name="System" displayName="$(string.System)" explainText="$(string.System_Help)" />
    ...
 </categories>

# Windows ADML file :
  <resources>
    <stringTable>
      ...
      <string id="System">System</string>
      <string id="System_Help">Allows configuration of various system component settings.</string>
      ...
    </stringTable>
  </resources>
```

To resume, '$(string.System)' equals 'System', and $(string.System_Help) equals 'Allows configuration of various system component settings.'

## Class [GPOToolsADMX] (Need Update)

XML section cover by the class in ADMX file :

* [ ]  policyDefinitions
  * [x]  policyNamespaces
    * [x]  Target : the namespace of file
      * [x]  namespaces
      * [x]  prefix
    * [x]  Using : Dependence of amdx file
      * [x]  namespaces
      * [x]  prefix
  * [ ]  supersededAdm
    * [ ]  fileName
  * [ ]  resources
    * [ ]  minRequiredRevision
  * [ ]  supportedOn : List of definition SupportedOn software version
    * [ ]  definitions
      * [ ]  definition
        * [x]  name : Name of definition
        * [x]  displayname : Name to display in gpedit.msc
        * [ ]  [or]
          * [ ]  reference
          * [ ]  range
            * [ ]  ref
            * [ ]  minVersionIndex
            * [ ]  maxversionIndex
        * [ ]  [and] : definition speciale
          * [ ]  reference
            * [ ]  ref
    * [ ]  Products
      * [ ]  Product
        * [ ]  Name
        * [ ]  displayName
        * [ ]  majorVersion
          * [ ]  name
          * [ ]  displayName (Variable)
          * [ ]  VersionIndex
          * [ ]  minorVersion
            * [ ]  Name
            * [ ]  displayName
            * [ ]  versionIndex
  * [x]  categories
    * [x]  category
      * [x]  name
      * [x]  displayname
      * [x]  [explainText]
      * [x]  parentCategory
        * [x]  ref
  * [ ]  policies
    * [ ]  policy
      * [x]  name
      * [x]  class : User/Computer
      * [x]  displayName
      * [x]  explainText
      * [x]  key
      * [x]  [valueName]
      * [x]  parentCategory
        * [x]  ref
      * [x]  supportedOn
        * [x]  ref
      * [x]  [enabledValue]
        * [x]  decimal
          * [x]  value
      * [x]  [disabledValue]
        * [x]  decimal
          * [x]  value
      * [ ]  [presentation] : Variable (presentation.[..]) sans doute quelque chose en rapport avec l'affichage ex : "$(presentation.ProfileDlgTimeOut)"
      * [ ]  [clientExtension] : GUID
      * [ ]  [elements]
        * [ ]  [list]
          * [ ]  [additive]
          * [ ]  [explicitValue]
          * [ ]  id
          * [ ]  [key]
          * [ ]  [valuePrefix]
          * [ ]  [valueName]
        * [ ]  [text]
          * [ ]  id
          * [ ]  valueName
          * [ ]  [required]
          * [ ]  [expandable]
          * [ ]  [maxLength]
          * [ ]  [key]
        * [ ]  [decimal]
          * [ ]  id
          * [ ]  valueName
          * [ ]  [required]
          * [ ]  [minValue]
          * [ ]  [maxValue]
          * [ ]  [storeAsText]
          * [ ]  [clientExtension]
          * [ ]  [key]
        * [ ]  [enum]
          * [ ]  id
          * [ ]  valueName
          * [ ]  [required]
          * [ ]  [clientExtension]
          * [ ]  [key]
        * [ ]  [multiText]
          * [ ]  id
          * [ ]  valueName
          * [ ]  [required]
          * [ ]  [maxLength]
          * [ ]  [maxStrings]
        * [ ]  [boolean]
          * [ ]  id
          * [ ]  valueName
          * [ ]  [key]
          * [ ]  [falseValue]
            * [ ]  decimal
              * [ ]  value
            * [ ]  [delete]
          * [ ]  [trueValue]
            * [ ]  decimal
              * [ ]  value
          * [ ]  [key]

## Classe [GPOToolsADML]

Cette classe va récupérer les informations des fichiers adml basés sur un format XML.
Section que l'on retrouve dans un fichier Adml :

* [ ]  PolicyDefinitionResources
  * [ ]  displayName
  * [ ]  description
  * [ ]  resources
    * [ ]  stringTable
      * [ ]  string
        * [ ]  id
        * [ ]  #text
    * [ ]  [presentationTable]
      * [ ]  presentation
        * [ ]  id
        * [ ]  [checkbox] (Object[] ou XmlElement)
          * [ ]  #text
          * [ ]  [defaultchecked] : valeur true/false
          * [ ]  refid
        * [ ]  [dropdownlist] (Object[] ou XmlElement)
          * [ ]  #text
          * [ ]  refid
          * [ ]  [defaultItem]
          * [ ]  [noSort] : valeur true/false
          * [ ]  [oSort] : valeur true/false
          * [ ]  [Sort] : valeur true/false
        * [ ]  [text] ( string ou Object[])
        * [ ]  [textbox] (Object[] ou XmlElement)
          * [ ]  label
          * [ ]  refId
          * [ ]  [defaultValue]
        * [ ]  [decimalTextBox] (Object[] ou XmlElement)
          * [ ]  [#cdata-section]
        * [ ]  [multitextbox] (Object[] ou XmlElement)
          * [ ]  refId
          * [ ]  #text
        * [ ]  [listbox]
          * [ ]  refId
          * [ ]  #text
          * [ ]  [required] valeur true/false

## Classe GPOToolsUtility

The utility class groups static member to manage the other classes.
* [ ]  Properties
  * [ ]  SupportOnTable : Contains all Support reference in ADMX files
  * [ ]  Categories : Contains all Category reference in ADMX files
  * [ ]  Policies : Contains all Policies reference un ADMX files
  * [ ]  TargetLoad : Contains all ADMX files initiate by InitiateAdmxAdml method
* [ ]  Method
  * [ ]  InitiateAdmxAdml ([System.IO.DirectoryInfo], [cultureinfo])
  * [ ]  InitiateAdmxAdml ([System.IO.FileInfo], [cultureinfo])
  * [ ]  GetNamespaceAdmx ([System.IO.FileInfo])
  * [ ]  GetADMLPathFromADMX ([System.IO.FileInfo], [cultureinfo])
  * [ ]  CheckAndInitiateDependancy ([GpoToolsAdmx], [cultureinfo])
  * [ ]  FindDependancyFile ([string], [string])
  * [ ]  CheckCategoryPresence ([string], [hashtable])
  * [ ]  CheckCategoryPresence ([string], [string])
  * [ ]  RemoveAll() : Empty static Properties : SupportOnTable, Categories, Policies, TargetLoad


## Classe GPOToolsCategory

## Classe GPOToolsSupportedOn

## Classe GPOToolsPolicy

Cette classe est utilisée pour joindre les information des classes GPOToolsAdmx et GPOToolsADML.

* [x]  creation du champ Name avec l'affichage contenu dans le fichier adml
* [x]  Le champ Path devra contenir l'arborescence des categories au format string
* [x]  on peut rajouter dans le champ path le scope : user/computer
* [ ]  le champ FullName contiendra le path + le Name
* [x]  le champ state permettra de voir si le parametre est desactivé\acrivé ou non configuré. Pour ce cas il sera necessaire de créer une méthode capable de checker la conf en fonction des elements de la policy
* [x]  le champ id contiendra l'id du parametre
* [x]  le champ category contiendra la category d'apartenance du parametre. L'objet category devra contenir son objet parent pour pouvoir determiner son path complet. Pour cela, la propriete static Categories contiendra l'ensemble des categorie des fichier admx.
* [ ]  Voir si la proprietes Registry son adapté pour tous les cas et si il ne faut pas adapter en fonction. Traité en premier lieu les cas les plus simples