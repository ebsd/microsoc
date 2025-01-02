
version 0.4                                                   2025-01-01
Information                                                       Public
				MicroSOC

Intro

   Ceci est une stack elastic - kibana - filebeat - suricata - zeek.

   En complément, comme décrit plus bas, MIPS peut être intégré afin de
   corréler des indicateurs de menaces avec le trafic réseau et ainsi
   générer des altertes via des règles Kibana quand un ioc de MIPS est
   "vu" par Zeek.

   Misp, AbuseCH et OTX sont intégrés grâce au module "Threatintel" de
   filebeat.

                 +---------+  +-----+
   ThreatIntel   | AbuseCH |  | OTX |
   sources -->   +-------+-+  +---+-+
                         |        |
			 +--+     |     +-----------+
			    |     |     |           |
		+------+  +-v-----v--+  |  Elastic  |
		| MISP +->| Filebeat +->|  Kibana   |
		+------+  +----------+  |           |
			     ^     ^    +-----------+
			     |     |                 
			     |     |                 
			+----+-+ +-+--------+        
			| Zeek | | Suritaca |        
			+------+ +----------+        

1.  Configurations

   Lire le fichier `template.env` pour quelques configs et comptes.
   Configurer l'adresse IP du serveur MISP dans MIPS_HOST=<ip>, si
   vous l'utilisez.

   Renommer template.env en .env

2.  elastic et kibana

   Le docker-compose.yml est basé sur :
   https://github.com/elastic/elasticsearch/blob/main/docs/reference\
   /setup/install/docker/docker-compose.yml

   L'autorité de certification est partagée entre les différents
   conteneurs : elastic, kibana et filebeat.

   Utilisateur / mot de passe par défaut :

      elsatic/changeme

3.  filebeat

   Le fichier `filebeat/filebat.yml` doit être possédé par root.

3.1.  Modules Suricata et Zeek

   Les logs du conteneur Suricata sont partagés avec le conteneur
   Filebeat via un volume :

      suricatadata:/var/log/suricata

   Les modules suricata et zeek de filebeat sont activés dans
   `filebeat/filebeat/modules.d/suricata.yml et zeek.yml`.

3.2. Module Threatintel

   Le module threatintel "map" les informations dans les mêmes champs
   destination.ip, source.ip, etc... quelque soit le type de threat
   intel (misp, otx, abuse...).

   Concernant le module threatintel, il existe un bug en v8.13.0, cf
   erreur : "cannot access method/field [size] from a null def
   reference". Passez la stack elastic en 8.13.3 mini dans .env.
   
   MISP
   ====

   Pour le fonctionnement avec MISP, le module threatintel.yml doit
   également être activé. La configuration se situe dans :

      filebeat/modules.d/threatintel.yml

   Modifier ce fichier en fonction des besoins. On peut par exemple
   ajouter un filtre sur les events à sélectionner :

      var.filters:
        type: ["md5", "sha256", "sha512", "url", "uri", "ip-src", \
        "ip-dst", "hostname", "domain"]
        tags: ['workflow:state="complete"']

   Concernant le filtre sur le tag "workflow:state", il faudra que ce
   tag soit créé dans MIPS (lire plus bas). On peut tout à fait s'en
   passer. A chacun son organisation.

   Pour debuguer la connexion filebeat / MIPS, entrer dans le conteneur
   filebeat dans :

      root@40a9f2825766:/usr/share/filebeat/logs

   ABUSE URL
   =========

   Le module abuse url est activé dans :

      filebeat/modules.d/threatintel.yml

   OTX
   ===

   Le module abuse url est activé dans :

      filebeat/modules.d/threatintel.yml

   Configurer votre API KEY OTX dans le fichier .env.
   Pour obtenir une clé api OTX se rendre sur [1].

   NOTES
   Quelques problèmes actuellement, OTX désactivés.
         
4.  suricata

   Tester l'IDS : 
      $ curl http://testmynids.org/uid/index.html

   En cas de modification du Dockerfile, il faudra rebuilder le conte-
   neur :
      $ docker compose up -d --build suricata

   La désactivation de règles se fait via le fichier disable.conf

5.  zeek

   Configurer l'interface d'écoute dans zeek/config/node.cfg

   Au sein du conteneur, le dossier d'installation de zeek est :
      /usr/local/zeek

   Notons que les logs doivent être au format json avant d'être transmis
   à filebeat. Ceci se configure ici :
      /usr/local/zeek/share/zeek/site/local.zeek

   Avec cette directive :

      @load policy/tuning/json-logs.zeek

   Celle-ci a été placée dans zeek/config/local.zeek

6.  MISP

6.1.  Mise en service

   Source : https://www.misp-project.org/2024/04/05/\
   elastic-misp-docker.html/

      $ git clone https://github.com/MISP/misp-docker.git
      $ cd misp-docker
      $ cp template.env .env
   
   Et editer .env pour configurer le BASE_URL='https://<ip>' qui devrait
   correspondre à l'interface "externe" du dockerhost.

   Sinon, il est également possible de modifier les services du
   docker-compose.yml pour utiliser le même réseau que le conteneur
   docker-microsoc :

      service:
        networks:
          - docker-microsoc_default
   
      # et en fin de fichier
      networks:
	  docker-microsoc_default:
	    external: true

   Démarrer le conteneur MISP
      $ docker compose up -d

   Quand le conteneur MISP a terminé son 1er démarrage, créer un utili-
   sateur MISP pour Elastic.

   MISP CLI
      $ docker-compose exec misp-core app/Console/cake \
      User create elastic@admin.test 5 1
      $ docker-compose exec misp-core app/Console/cake \
      User change_authkey elastic@admin.test
      Old authentication keys disabled and new key created: 
      06sDmKQK3E6MSJwsOhYT3N4NzfTpe53ruV0Bydf0
  
   Placer cette auth key dans le fichier microsoc-docker/.env
      MISP_ELASTIC_API_KEY=06sDmKQK3E6MSJwsOhYT3N4NzfTpe53ruV0Bydf0

   MISP est accessible sur https://<ip>/

      User: admin@admin.test
      Password: admin

   Démarrer microsoc-docker :
      $ docker compose up -d

6.2.  Configurer une première règle de détection

   Dans kibana (https://<ip>:5601/) > Security > Rules > Detection rules
   Cliquer "Add Elastic Rules"
   Rechercher "threat intel" et cocher les règles qui vous intéressent.
   Cliquer sur "Install selected"
   Revenir dans Kibana > Security > Rules > Detection rules et cliquer
   "Disabled rules" et activer les nouvelles règles.

6.3.  Ajouter un indicateur de compromission dans MISP

   - Se rendre dans MISP et créer un event en lui affectant un attribut 
   ip-dst.
      Menu add event
      Puis menu gauche Add Attribute
      Category : network activity
      Type: ip-dst
      Value: 185.194.93.14
      For intrusion detection system : cochée
      Bouton "submit"

   - Optionnel : Ajouter le tag workflow:state="complete" dans Event 
   Action > Add Tag
      Puis affecter ce tag sur notre event

   - Filebeat va insérer cette IP dans le champ : threat.indicator.ip

   - Depuis un hôte monitoré par Zeek :
      $ curl -I https://circl.lu

   - Dans Kibana > Security > Alerts on obtient une alerte suite à
   l'accès à l'IP malveillante.
   Par defaut cette règle de détection s'active toute les heures.

   La configuration de MISP se fait dans le module threat intel de
   filebeat : filebeat/modules.d/threatintel.yml

6.4.  Feeds

   MISP est livré avec des feeds par défaut. Activez ceux qui vous conv-
   iennent le mieux. Menu "Sync Actions > Feeds".

   FEED PERSO

   Il est également possible d'ajouter un feed perso, par exemple une
   liste d'adresses IP au format texte. Menu "Sync Actions > Feeds > Add
   Feed".
      - Cocher la case "Enabled",
      - fournir l'URL du fichier texte,
      - sélectionner une source de type "CSV",
      -  indiquer un Target Event de type "Fixed Event",
      -  indiquer 1 seul champ dans "Value fields in the CSV".
      -  Sélectionner enfin "auto publish" et "delta merge".
   Ne pas cocher "Override IDS flag" sinon les adresses ip ne seront pas
   remontées par le module ThreatIntel de Filebeat.

   MISES A JOUR DES FEEDS

   Il semblerait q'il existe un problème avec les mises à jour automati-
   que des feeds.
   Il convient d'utiliser l'API via un cron pour mettre à jour des feeds.
 
      00 6 * * *  curl -k --header "Authorization: <APIKEY>" \
      --header "Accept: application/json" \
      --header "Content-Type: application/json" \
      https://192.168.1.10/feeds/fetchFromAllFeeds

6.5.  Debug

   Les logs dans le conteneurs sont situés dans :
      /var/www/MISP/app/tmp/logs

-----------------------------------------------------------------------
Références
   [1]  https://otx.alienvault.com/api
