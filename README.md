# MicroSOC

Ceci est une stack elastic - kibana - filebeat - suricata - zeek.

Lire le fichier `.env` pour quelques configs et mots de passe.

## elastic et kibana

Le docker-compose.yml est basé sur :
https://github.com/elastic/elasticsearch/blob/main/docs/reference/setup/install/docker/docker-compose.yml

L'autorité de certification est partagée entre les différents conteneurs : elastic, kibana et filebeat.

## filebeat

Le fichier `filebeat/filebat.yml` doit être possédé par root.

Les logs du conteneur Suricata sont partagés avec le conteneur Filebeat via un volume :
`suricatadata:/var/log/suricata`.

### Modules filebeat
Les modules suricata et zeek de filebeat sont activés dans `filebeat/filebeat/modules.d/suricata.yml et zeek.yml`.

Pour le fonctionnement avec MISP, le module threatintel.yml doit également être activé.
Concernant le module threatintel, il existe un bug eb 8.13.0, cf erreur : "cannot access method/field [size] from a null def reference". Passez en 8.13.3 mini dans .env.



## suricata

Tester l'IDS : 
```
$ curl http://testmynids.org/uid/index.html
```

## zeek

Configurer l'interface d'écoute dans zeek/confg/node.cfg

## MISP (à terminer)

> Source : https://www.misp-project.org/2024/04/05/elastic-misp-docker.html/

```
$ git clone https://github.com/MISP/misp-docker.git
```

```
$ cd misp-docker
$ cp template.env .env
```
Et editér .env pour configurer le BASE_URL='https://<ip>'

Démarrer le conteneur MISP
```
$ docker compose up -d
```

Quand le conteneur MISP a terminé son démarrage, créer un utilisateur MISP pour Elastic.

MISP CLI:
```
$ docker-compose exec misp-core app/Console/cake User create elastic@admin.test 5 1
$ docker-compose exec misp-core app/Console/cake User change_authkey elastic@admin.test
Old authentication keys disabled and new key created: 06sDmKQK3E6MSJwsOhYT3N4NzfTpe53ruV0Bydf0
```

Placer cette auth key dans le fichier docker-microsoc/.env
MISP_ELASTIC_API_KEY=06sDmKQK3E6MSJwsOhYT3N4NzfTpe53ruV0Bydf0

MISP est accessible sur https://localhost/
User: admin@admin.test
Password: admin

Démarrer microsoc-docker :
```
$ docker compose up -d
```
Dans kibana (https://<ip>:5601/) > Security > Rules > Detection rules
Cliquer "Add Elastic Rules"
Rechercher "threat intel" et cocher les règles qui vous intéressent.
Cliquer sur "Install selected"
Revenir dans Kibana > Security > Rules > Detection rules et cliquer "Disabled rules" et activer les nouvelles règles.

### Tester

Activer les workflows de MISP dans Administration > Server Settings and Maintenance > Plugin > Workflow. Configurer Plugin.Workflow_enable à true.
1. Se rendre dans MISP et créer un event en lui affectant un attribut ip-dst.
Menu add event
Puis menu gauche Add Attribute
Category : network activity
Type: ip-dst
Value: 185.194.93.14
For intrusion detection system : cochée
Bouton "submit"

2. Ajouter le tag workflow:state="complete" dans Event Action > Add Tag
Puis affecter ce tag sur notre event

3. Filebeat va insérer cette IP dans le champ : threat.indicator.ip

4. Depuis un hôte monitoré par Zeek :
```
curl -I https://circl.lu
```

5. Dans Kibana > Security > Alerts on obtient une alerte conernant l'accès à l'IP malveillante.
Par defaut cette règle de détection s'active toute les heures.

