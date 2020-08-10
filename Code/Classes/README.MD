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
      * [ ]  [enabledList]
        * [ ]  item
        * [ ]  Key
        * [ ]  valueName
        * [ ]  value
          * [ ]  decimal
            * [ ]  value
      * [ ]  [disabledList]
        * [ ]  item
        * [ ]  Key
        * [ ]  valueName
        * [ ]  value
          * [ ]  decimal
            * [ ]  value
      * [x]  [enabledValue]
        * [x]  decimal
          * [x]  value
      * [x]  [disabledValue]
        * [x]  decimal
          * [x]  value
      * [x]  [presentation] : Variable (presentation.[..])
      * [ ]  [clientExtension] : GUID
      * [x]  [elements]
        * [x]  [list]
          * [x]  [additive]
          * [x]  [explicitValue]
          * [x]  id
          * [x]  [key] # If no key, that is the key of policy who content the list value in property
          * [x]  [valuePrefix] # Need to see in the registry
          * [x]  [valueName]
        * [x]  [text]
          * [x]  id
          * [x]  valueName
          * [x]  [required]
          * [x]  [expandable]
          * [x]  [maxLength]
          * [x]  [key]
        * [x]  [decimal]
          * [x]  id
          * [x]  valueName
          * [x]  [required]
          * [x]  [minValue]
          * [x]  [maxValue]
          * [x]  [storeAsText]
          * [x]  [clientExtension] # ???
          * [x]  [key]
        * [x]  [enum]
          * [x]  id
          * [x]  valueName
          * [x]  [required]
          * [x]  [clientExtension] # ???
          * [x]  [key]
          * [x] item
            * [x] displayName
              *[x] value
                *[x] decimal
                  *[x] value
        * [x]  [multiText]
          * [X]  id
          * [X]  valueName
          * [X]  [required]
          * [X]  [maxLength]
          * [X]  [maxStrings]
        * [x]  [boolean]
          * [X]  id
          * [X]  valueName
          * [X]  [key]
          * [X]  [falseValue]
            * [X]  decimal
              * [X]  value
            * [X]  [delete]
          * [X]  [trueValue]
            * [X]  decimal
              * [X]  value

## Classe [GPOToolsADML]

Cette classe va récupérer les informations des fichiers adml basés sur un format XML.
Section que l'on retrouve dans un fichier Adml :

* [ ]  PolicyDefinitionResources
  * [ ]  displayName
  * [ ]  description
  * [x]  resources
    * [x]  stringTable
      * [x]  string
        * [x]  id
        * [x]  #text
    * [x]  [presentationTable]
      * [x]  presentation
        * [x]  id
        * [x]  [checkbox] (Object[] ou XmlElement)
          * [x]  #text
          * [x]  [defaultchecked] : valeur true/false
          * [x]  refid
        * [x]  [dropdownlist] (Object[] ou XmlElement)
          * [x]  #text
          * [x]  refid
          * [x]  [defaultItem]
          * [x]  [noSort] : valeur true/false
          * [x]  [oSort] : valeur true/false
          * [x]  [Sort] : valeur true/false
        * [x]  [text] ( string ou Object[])
        * [x]  [textbox] (Object[] ou XmlElement)
          * [x]  label
          * [x]  refId
          * [x]  [defaultValue]
        * [x]  [decimalTextBox] (Object[] ou XmlElement)
          * [x]  [defaultValue]
          * [x]  [#cdata-section]
        * [x]  [multitextbox] (Object[] ou XmlElement)
          * [x]  refId
          * [x]  #text
        * [x]  [listbox]
          * [x]  refId
          * [x]  #text
          * [x]  [required] valeur true/false

## Relation between xml presentation section in ADMX and AMDL Files

ADMX | ADML
--- | ---
list | listbox
text | textbox
decimal | decimaltextbox
enum | dropdownlist
multiText | multitextbox
boolean | checkbox

The 'text' champ in ADML file is hazardous. It's not referring a registry key or other xml section listed in the table. And it can place after or before the xml section that his concerned.
Look at [#issue4](https://github.com/NicolasBn/PSGPOTools/issues/4)

## Classe GPOToolsUtility

The utility class groups static member to manage the other classes.

* [ ]  Properties
  * [x]  SupportOnTable : Contains all Support reference in ADMX files
  * [x]  Categories : Contains all Category reference in ADMX files
  * [x]  Policies : Contains all Policies reference un ADMX files
  * [x]  TargetLoad : Contains all ADMX files initiate by InitiateAdmxAdml method
* [ ]  Method
  * [x]  InitiateAdmxAdml ([System.IO.DirectoryInfo], [cultureinfo])
  * [x]  InitiateAdmxAdml ([System.IO.FileInfo], [cultureinfo])
  * [x]  GetNamespaceAdmx ([System.IO.FileInfo])
  * [x]  GetADMLPathFromADMX ([System.IO.FileInfo], [cultureinfo])
  * [x]  CheckAndInitiateDependancy ([GpoToolsAdmx], [cultureinfo])
  * [x]  FindDependancyFile ([string], [string])
  * [x]  CheckCategoryPresence ([string], [hashtable])
  * [x]  CheckCategoryPresence ([string], [string])
  * [x]  RemoveAll() : Empty static Properties : SupportOnTable, Categories, Policies, TargetLoad


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