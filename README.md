# MicroSOC

Ceci est une stack elastic - kibana - filebeat - suricata - zeek.

Elle peut être interfacée avec MISP (lire plus bas).

Lire le fichier `template.env` pour quelques configs. Il faudra le renommer en `.env` avant tout.

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
Concernant le module threatintel, il existe un bug eb 8.13.0, cf erreur : "cannot access method/field [size] from a null def reference". Passez en 8.13.3 dans .env.


## suricata

Tester l'IDS : 
```
$ curl http://testmynids.org/uid/index.html
```

## zeek

Avant de démarrer, configurer l'interface d'écoute dans zeek/confg/node.cfg

## misp

> Source : https://www.misp-project.org/2024/04/05/elastic-misp-docker.html/

Cloner le repo MISP :
```
$ git clone https://github.com/MISP/misp-docker.git
```

Démarrer les conteneurs MISP.
```
$ cd misp-docker
$ cp template.env .env
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
$ cd docker-microsoc
$ docker compose up -d
```
Dans kibana > Security > Rules > Detection rules
Cliquer "Add Elastic Rules"
Rechercher "threat intel" et cocher les règles qui vous intéressent.
Cliquer sur "Install selected"
Revenir dans Kibana > Security > Rules > Detection rules et cliquer "Disabled rules" et activer les nouvelles règles.

### Tester la détection elastic sur les events misp

1. Se rendre dans MISP et créer un event en lui affectant un attribut ip-dst.
Category : network activity
Type: ip-dst
For intrusion detection system : cochée
Bouton "submit"
Value: 185.194.93.14

2. Ajouter le tag workflow:state="complete" dans Event Action > Add Tag
Puis affecter ce tag sur notre event

3. Filebeat va insérer cette IP dans le champ : threat.indicator.ip

4. Depuis un hôte monitoré par Zeek :
```
curl -I https://circl.lu
```

5. Dans Kibana > Security > Alerts on obtient une alerte conernant l'accès à l'IP malveillante.
Par defaut cette règle de détection s'active toute les heures.

