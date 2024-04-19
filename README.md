# MicroSOC

Ceci est une stack elastic - kibana - filebeat - suricata - zeek.
Les modules suricata et zeek de filebeat sont activés dans `filebeat/filebeat/modules.d/suricata.yml et zeek.yml`.

Lire le fichier `.env` pour quelques configs.

## elastic et kibana

Le docker-compose.yml est basé sur :
https://github.com/elastic/elasticsearch/blob/main/docs/reference/setup/install/docker/docker-compose.yml

L'autorité de certification est partagée entre les différents conteneurs : elastic, kibana et filebeat.

## filebeat

Le fichier `filebeat/filebat.yml` doit être possédé par root.

Les logs du conteneur Suricata sont partagés avec le conteneur Filebeat via un volume :
`suricatadata:/var/log/suricata`.

## suricata

Tester l'IDS : 
```
$ curl http://testmynids.org/uid/index.html
```

## zeek

Configurer l'interface d'écoute dans zeek/confg/node.cfg

## TODO MISP

> Source : https://www.misp-project.org/2024/04/05/elastic-misp-docker.html/


git clone https://github.com/MISP/misp-docker.git

Modifier les services du docker-compose.yml pour utiliser le même réseau que le conteneur docker-microsoc:

```
service:
  networks:
    - docker-microsoc_default

# et en fin de fichier
networks:
    docker-microsoc_default:
      external: true
```


Start the MISP containers.

$ cd misp-docker
$ cp template.env .env
$ docker compose up -d

Quand le conteneur MISP a terminé son 1er démarrage, créer un utilisateur MISP pour Elastic.

MISP CLI:

$ docker-compose exec misp-core app/Console/cake User create elastic@admin.test 5 1
$ docker-compose exec misp-core app/Console/cake User change_authkey elastic@admin.test
Old authentication keys disabled and new key created: 06sDmKQK3E6MSJwsOhYT3N4NzfTpe53ruV0Bydf0

Placer cette auth key dans le fichier docker-microsoc/.env
MISP_ELASTIC_API_KEY=06sDmKQK3E6MSJwsOhYT3N4NzfTpe53ruV0Bydf0

MISP est accessible sur https://localhost/
User: admin@admin.test
Password: admin

Démarrer microsoc-docker : $ docker compose up -d

Dans kibana > Security > Rules > Detection rules
Cliquer "Add Elastic Rules"
Rechercher "threat intel" et cocher les règles qui vous intéressent.
Cliquer sur "Install selected"
Revenir dans Kibana > Security > Rules > Detection rules et cliquer "Disabled rules" et activer les nouvelles règles.
