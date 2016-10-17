xquery version '3.0' ;

declare namespace tei = 'http://www.tei-c.org/ns/1.0';
declare namespace m = 'http://www.loc.gov/mods/v3';

declare variable $bdd := ""; (: donner le nom de la base de données avec vos références au format MODS :)

declare variable $surname := ""; (: donner le nom de famille de l'auteur du document :)
declare variable $forename := ""; (: donner le prénom de l'auteur du document :)
declare variable $halauthor := ""; (: donner l'identifiant de l'auteur du document: cf. https://aurehal.archives-ouvertes.fr/author :) 
declare variable $idhal := ""; (: donner l'identifiant hal de l'auteur du document :) (: FACULTATIF :)
declare variable $email := ""; (: donner l'adresse mail de l'auteur du document :) (: FACULTATIF :)
declare variable $lien := ""; (: donner l'URL de votre page personnelle  :) (: FACULTATIF :)
declare variable $affiliation := ""; (: donner l'identifiant hal de votre institution de rattachement: cf. https://aurehal.archives-ouvertes.fr/structure :) (: FACULTATIF :)

declare variable $surnameD := ""; (: donner le nom du déposant du document (si différent de l'auteur) :)
declare variable $forenameD := ""; (: donner le prénom du déposant du document (si différent de l'auteur) :)
declare variable $halauthorD := ""; (: donner l'identifiant du déposant du document :) 
declare variable $idhalD := ""; (: donner l'identifiant hal du déposant du document: cf. https://aurehal.archives-ouvertes.fr/author :) 
declare variable $emailD := ""; (: donner l'adresse mail du déposant du document :) (: FACULTATIF :)
declare variable $affiliationD := ""; (: donner l'identifiant hal de l'institution de rattachement du déposant: cf. https://aurehal.archives-ouvertes.fr/structure :) (: FACULTATIF :)

declare function local:getAut() {
  <author role="aut">
    <persName>
      <forename>{ $forename }</forename>
      <surname>{ $surname }</surname>
    </persName>
    { local:getComplementAut() }
  </author>
};

declare function local:getComplementAut() {
  if ( $email = '' ) then () else <email>{ $email }</email>,
  if ( $lien = '' ) then () else <ptr type="url" target="{ $lien }"/>,
  <idno type="halauthor">{ $halauthor }</idno>,
  if ( $idhal = '' ) then () else <idno type="idhal">{ $idhal }</idno>, 
  if ( $affiliation = '' ) then () else <affiliation ref="{ $affiliation }"/>  
};

declare function local:getDeposant() {
  <author role="depositor">
    <persName>
      <forename>{ if ( $forenameD = '' ) then $forename else $forenameD }</forename>
      <surname>{ if ( $surnameD = '' ) then $surname else $surnameD }</surname>
    </persName>
    { local:getComplementDep() }
  </author>
};

declare function local:getComplementDep() {
  if ( $emailD = '' ) 
  then 
    if ( $email = '' )
    then ()
    else <email>{ $email }</email> 
  else <email>{ $emailD }</email>,
  <idno type="halauthor">{ if ( $halauthorD = '' ) then $halauthor else $halauthorD }</idno>,
  if ( $idhalD = '' ) 
  then 
    if ( $idhal = '' )
    then ()
    else <idno type="idhal">{ $idhal }</idno>
  else <idno type="idhal">{ $idhalD }</idno>, 
  if ( $affiliationD = '' ) 
  then 
    if ( $affiliation = '' )
    then ()
    else <affiliation ref="{ $affiliation }"/>
  else <affiliation ref="{ $affiliationD }"/>  
};

declare function local:getTitles($node as element(m:titleInfo)*, $options as xs:string?) {    
  for $title in $node
  let $lang := $title/@lang
  return
    switch ($options)
    case ($options[. = 'titleStmt']) return 
       if ($title[not(@type = 'abbreviated')])
       then <title xml:lang="{$lang}">{ normalize-space($title[not(@type = 'abbreviated')]/m:title) }</title>
       else ()
    case ($options[. = 'analytic']) return
      if ($title[not(@type = 'abbreviated')])
      then <title xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
      else <title type="sub" xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    case ($options[. = "book"]) return <title xml:lang="{$lang}">{ normalize-space($node[1]/m:title) }</title>
    case ($options[. = 'series']) return <title level="s" xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    case ($options[. = 'monogr']) return <title level="m" xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    case ($options[. = 'magazineArticle']) return <title level="j" xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    case ($options[. = 'journalArticle']) return <title level="j" xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    case ($options[. = 'conferencePaper']) return <title xml:lang="{$lang}">{ normalize-space($title/m:title) }</title>
    default return <title>{ normalize-space($title/m:title) }</title>
};

declare function local:getAuthors($node as element(m:name)*, $options as xs:string) {
  for $name in $node
  let $role := $name/m:role/m:roleTerm
  return
    switch ($role)
    case ($role[. = 'aut']) return 
      <author role="aut">{ local:getName($name) }</author>
    case ($role[. = 'ctb']) return
      <author role="ctb">{ local:getName($name) }</author>
    case ($role[. = 'edt']) return
      switch ($options) 
      case ($options[. = "titulaires"]) return <author role="edt">{ local:getName($name) }</author> 
      case ($options[. = "analytic"]) return <author role="edt">{ local:getName($name) }</author> 
      default return <editor>{ local:getName($name) }</editor>
    case ($role[. = 'trl']) return
      <author role="trl">{ local:getName($name) }</author>
    default return $name
};

declare function local:getName($node as element(m:name)*) { 
  element 
    {if ($node[@type = 'personal']) then 'persName' else 'orgName'} 
    {
    let $langName := $node/@lang
    return
      (: Attention: $langName à revoir: attribut sur m:name ou sur m:namePart? :)
      (if ( empty($langName) ) then () else attribute xml:lang {$langName},
       if ($node/m:namePart[@type = 'given'])
       then 
         for $forename in $node/m:namePart[@type = 'given'] 
         return local:getForename($forename)
       else 
         if ($node[@type = 'personal'])
         then <forename type="first"/>
         else (),
       for $surname in $node/m:namePart[@type = 'family'] return local:getSurname($surname),
       for $name in $node/m:namePart[not(@type)]
       return normalize-space($name)
      )
    },
    if ($node/m:namePart[@type = 'family'] = $surname) then local:getComplementAut() else ()
};

declare function local:getForename($node as element(m:namePart)*) {
  <forename type="first">{ normalize-space($node[@type = 'given']) }</forename> 
};

declare function local:getSurname($node as element(m:namePart)*) {
  if ($node[@type = 'family']) 
  then <surname>{ normalize-space($node[@type = 'family']) }</surname>
  else ()
};

declare function local:getWhenWritten($node as element()*, $option as xs:string?) {
  switch ($option)
  case ($option[. = 'book']) return <date type="whenWritten">{ normalize-space($node/m:originInfo/m:copyrightDate) }</date>
  case ($option[. = 'bookSection']) return <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:originInfo/m:copyrightDate) }</date>
  case ($option[. = 'journalArticle' or . = "magazineArticle"]) return <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:part/m:date) }</date>
  case ($option[. = 'magazineArticle']) return <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:part/m:date) }</date>
  case ($option[. = 'conferencePaper']) return <date type="whenWritten">{ normalize-space($node/m:relatedItem/m:originInfo/m:dateCreated) }</date>
  default return ()
    
};

declare function local:getDate($node as element(m:mods)*, $option as xs:string?) {
  switch ($option)
  case ($option[. = 'book']) return <date type="datePub">{ normalize-space($node/m:originInfo/m:copyrightDate) }</date>
  case ($option[. = 'bookSection']) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:originInfo/m:copyrightDate) }</date>
  case ($option[. = "magazineArticle"]) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:part/m:date) }</date>
  case ($option[. = "journalArticle"]) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:part/m:date) }</date>
  case ($option[. = 'conferencePaper']) return <date type="datePub">{ normalize-space($node/m:relatedItem/m:originInfo/m:dateCreated) }</date> 
  default return ()
    
};

declare function local:getAnalytic($node as element(m:mods)*, $options as xs:string) {
  switch ($options)
  case ($options[. = 'book']) return 
    ( local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, 'analytic') )
  case ($options[. = 'bookSection']) return 
    ( local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
  case ($options[. = 'magazineArticle']) return
    (local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
  case ($options[. = 'journalArticle']) return
    (local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
    case ($options[. = 'conferencePaper']) return
    (local:getTitles($node/m:titleInfo, 'analytic'), local:getAuthors($node/m:name, '') )
  default return ()
};

declare function local:getMonogr($node as element(m:mods)*, $options as xs:string) {
  if ($node//m:identifier[@type = 'issn' or @type = 'isbn']) then local:getIdentifier($node//m:identifier) else (),
  switch ($options)
  case ($options[. = 'book']) return
    (local:getTitles($node/m:titleInfo[1], 'book'),
    if ($node/m:name/m:role/m:roleTerm = 'edt') then local:getAuthors($node/m:name[m:role/m:roleTerm = 'edt'], '') else (),
    if ($node/m:originInfo/m:edition) then local:getEdition($node/m:originInfo) else (),
    local:getImprint($node/m:originInfo, $options) )
  case ($options[. = 'bookSection']) return 
    (local:getTitles($node/m:relatedItem/m:titleInfo, 'monogr'),
    local:getAuthors($node/m:relatedItem/m:name, ''), 
    if ($node/m:relatedItem/m:originInfo/m:edition) then local:getEdition($node/m:relatedItem/m:originInfo) else (),
    if ($node/m:relatedItem/m:originInfo) then local:getImprint($node/m:relatedItem/m:originInfo, $options) else ())
  case ($options[. = 'magazineArticle']) return
    (local:getTitles($node/m:relatedItem/m:titleInfo, 'magazineArticle'),
    if ($node/m:relatedItem/m:originInfo/m:edition) then local:getEdition($node/m:relatedItem/m:originInfo) else (),
    local:getImprint($node/m:relatedItem, $options) )
  case ($options[. = "journalArticle"]) return
    (local:getTitles($node/m:relatedItem/m:titleInfo, 'journalArticle'),
    if ($node/m:relatedItem/m:name) then local:getAuthors($node/m:relatedItem/m:name, '') else (),
    if ($node/m:relatedItem/m:originInfo/m:edition) then local:getEdition($node/m:relatedItem/m:originInfo) else (),
    local:getImprint($node/m:relatedItem, $options) )
  case ($options[. = "conferencePaper"]) return (local:getMeeting($node, $options), local:getImprint($node/m:relatedItem, $options) )
  default return ()
  (: Voir avec HAL comment encoder cette information? 
  if ($node//m:physicalDescription) then local:getExtent($node/m:physicalDescription) else () :)
};

declare function local:getEdition($node as element(m:originInfo)*) {
  (: Voir avec HAL comment encoder cette information? 
  <edition>{ normalize-space($node/m:edition) }</edition> :)
};

declare function local:getImprint($node as element()*, $options as xs:string) {
  <imprint>{
    switch ($options)
    case ($options[. = "book"]) return
      (if ($node/m:publisher) then local:getPublisher($node/m:publisher) else (),
      if ($node/m:place) then local:getPubPlace($node/m:place) else (),
      if ($node/parent::node()/m:part) then local:getBiblScope($node/parent::node()/m:part) else (),
      local:getDate($node/ancestor::m:mods, $options) )
    case ($options[. = "bookSection"]) return
      (if ($node/m:publisher) then local:getPublisher($node/m:publisher) else (),
      if ($node/m:place) then local:getPubPlace($node/m:place) else (),
      if ($node/parent::node()/m:part) then local:getBiblScope($node/parent::node()/m:part) else (),
      local:getDate($node/ancestor::m:mods, $options) )
    case ($options[. = "magazineArticle"]) return
      ( local:getBiblScope($node/m:part),
      if ($node/m:part/m:date) then local:getDate($node/ancestor::m:mods, $options) else () )
    case ($options[. = "journalArticle"]) return
      ( local:getBiblScope($node/m:part),
      if ($node/m:part/m:date) then local:getDate($node/ancestor::m:mods, $options) else () )
    case ($options[. = "conferencePaper"]) return
      (if ($node/m:originInfo/m:publisher) then local:getPublisher($node/m:originInfo/m:publisher) else (), 
      if ($node/m:part) then local:getBiblScope($node/m:part) else (),
      if ($node/m:date) then local:getDate($node/ancestor::m:mods, $options) else () )
    default return ()
  }</imprint>
};

declare function local:getMeeting($node as element(m:mods)*, $options as xs:string) {
  <meeting>{
    local:getTitles($node/m:relatedItem/m:titleInfo, $options),
    if ($node/m:relatedItem/m:originInfo/m:dateCreated) then <date type="datePub">{ normalize-space($node/m:relatedItem/m:originInfo/m:dateCreated) }</date> else (),
    if ($node/m:relatedItem/m:originInfo/m:place) 
    then <settlement>{ normalize-space($node/m:relatedItem/m:originInfo/m:place) }</settlement> 
    else ()
  }</meeting>
};

declare function local:getPubPlace($node as element(m:place)*) {
  for $place in $node
  return 
    <pubPlace>{ normalize-space($place) }</pubPlace>
};

declare function local:getPublisher($node as element(m:publisher)*) {
  for $publisher in $node
  return 
    <publisher>{ normalize-space($publisher) }</publisher>
};

declare function local:getLanguage($node) {
  if ($node/@lang) 
  then $node/@lang 
  else 
    if ($node/parent::m:mods//m:name/m:namePart[1]/@lang)
    then $node/parent::m:mods//m:name/m:namePart[1]/@lang 
    else 'fr'
};

declare function local:getKeywords($node as element()*) {
  <keywords scheme="author">{
    for $key in $node/m:subject
    return
      <term xml:lang="{ local:getLanguage($node[1]) }">{ normalize-space($key) }</term>
  }</keywords>
};

declare function local:getAbstract($node as element(m:abstract)*) {
  <abstract xml:lang="{ local:getLanguage($node[1]) }">{ if ($node) then normalize-space($node) else 'no abstract' }</abstract>
};

declare function local:getExtent($node as element(m:physicalDescription)*) {
  <extent>{ normalize-space($node) }</extent>
};

declare function local:getSeries($node as element(m:relatedItem)*) {
  <series>{
    if ($node/m:titleInfo) then local:getTitles($node/m:titleInfo, 'series') else ()
    (: Voir avec Hal où mettre cette information? 
    if ($node/m:part) then local:getBiblScope($node/m:part) else () :)
  }</series>
};

declare function local:getBiblScope($node as element(m:part)*) {
  local:getDetail($node/m:detail),
  local:getPages($node/m:extent)    
};

declare function local:getDetail($node as element(m:detail)*) {
  for $biblScope in $node
  let $unit := $biblScope/@type
  return 
    switch ($unit)
    case ($unit[. = "issue"]) return <biblScope unit="issue">{ normalize-space( $biblScope ) }</biblScope>
    case ($unit[. = "volume"]) return <biblScope unit="volume">{ normalize-space( $biblScope ) }</biblScope>
    default return <biblScope unit="{ $unit }">{ normalize-space( $biblScope ) }</biblScope>
};

declare function local:getPages($node as element(m:extent)*) {
  for $page in $node
  let $unit := $page/@unit
  return
    if ($unit = 'pages') 
    then
      if ($page/m:start = $page/m:end)
      then <biblScope unit="pp">{ local:getStartPage($page/m:start) }</biblScope>
      else <biblScope unit="pp">{ concat(local:getStartPage($page/m:start), '-', local:getEndPage($page/m:end)) }</biblScope>
    else 
      <biblScope unit='{ $unit }'>{ concat(local:getStartPage($page/m:start), '-', local:getEndPage($page/m:end)) }</biblScope>
};

declare function local:getStartPage($node as element(m:start)*) {
  normalize-space($node)
};

declare function local:getEndPage($node as element(m:end)*) {
  normalize-space($node)
};

declare function local:getNotes($node as element(m:note)*) {
  for $note in $node 
  return
    <note type="commentary">{ normalize-space($note) }</note>
};

declare function local:getIdentifier($node as element(m:identifier)*) {
  for $identifier in $node
  let $type := $identifier/@type
  return
   <idno type="{ $type }">{ normalize-space($identifier) }</idno>
};

declare function local:getLocation($node as element(m:location)*) {
  for $location in $node
  return
    <ref type="publisher">{ normalize-space($location) }</ref>
};

declare function local:getHalTypology($node as xs:string) {
  switch ($node)
  case ($node[. = "book"]) return <classCode scheme="halTypology" n="OUV">Books</classCode>
  case ($node[. = "bookSection"]) return <classCode scheme="halTypology" n="COUV">Book section</classCode>
  case ($node[. = "magazineArticle"]) return <classCode scheme="halTypology" n="ART">Magazine article</classCode> (: Attention, à revoir :)
  case ($node[. = "journalArticle"]) return <classCode scheme="halTypology" n="ART">Journal articles</classCode>
  default return <classCode scheme="halTypology">{ $node }</classCode>
};

declare function local:getTEI($node as element(m:mods)*, $options as xs:string) {
  <TEI>
    <teiHeader>
      <fileDesc>
        <titleStmt>
          <title>HAL TEI import</title>
        </titleStmt>
        <publicationStmt>
          <distributor>Philippe Pons</distributor>
          <availability status="restricted">
            <licence target="http://creativecommons.org/licenses/by/4.0/">Distributed under a Creative Commons Attribution 4.0 International License</licence>
          </availability>
          <date when="{ current-dateTime() }"/>
        </publicationStmt>
        <sourceDesc>
          <p part="N">HAL API platform</p>
        </sourceDesc>
      </fileDesc>
    </teiHeader>
    <text>
      <body>
        <listBibl>{
          <biblFull>
            <titleStmt>{ 
              local:getTitles($node/m:titleInfo, 'titleStmt'), 
              local:getAut(),
              local:getDeposant()
            }</titleStmt>
            <editionStmt>
              <edition>{
                local:getWhenWritten($node, $options)
              }</edition>
            </editionStmt>
            <publicationStmt>
              <availability>
                <licence target="http://creativecommons.org/licenses/by-nc/"/>
              </availability>
            </publicationStmt>
            (: <seriesStmt>
              <idno type="stamp" n="SHS">Sciences de l&#39;Homme et de la Société</idno>
            </seriesStmt> :)
            {if ($node/m:note) 
            then
              <notesStmt>{
                local:getNotes($node/m:note)
              }</notesStmt>
            else () }
            <sourceDesc>
              <biblStruct>
                <analytic>{
                  local:getAnalytic($node, $options)
                }</analytic>
                <monogr>{
                  local:getMonogr($node, $options)
                }</monogr>
                { if ($node/m:relatedItem[@type = "series"]) then local:getSeries($node/m:relatedItem[@type = "series"]) else () }
                { if ($node/m:location) then local:getLocation($node/m:location) else () }
              </biblStruct>
            </sourceDesc>
            <profileDesc>{
              <langUsage>
                <language ident="{ local:getLanguage($node/m:name[1]/m:namePart[1]) }"/>
              </langUsage>,
              <textClass>
                { if ($node/m:subject) then local:getKeywords($node) else () }
                { local:getHalTypology($options) }
              </textClass>,
              local:getAbstract($node/m:abstract)
            }</profileDesc>
          </biblFull>
        }</listBibl>
      </body>
    </text>
  </TEI>
};
   
for $bibl in db:open($bdd)/m:modsCollection/m:mods
let $genre := $bibl/m:genre[@authority='zotero']
let $path := file:create-dir('bibliographie')
return
  file:write( concat( file:current-dir(), '/bibliographie/', $surname, '-', $genre, '-',  generate-id($bibl), '.xml' ), local:getTEI($bibl, $genre) )
  




