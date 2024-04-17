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

## TODO
MISP

Create the .env file:

$ cp template.env .env

Start the MISP containers.

$ docker compose up -d

When MISP containers finish starting, create a sync user for Elastic on MISP.

Using MISP CLI:

$ docker-compose exec misp-core app/Console/cake User create elastic@admin.test 5 1
$ docker-compose exec misp-core app/Console/cake User change_authkey elastic@admin.test
Old authentication keys disabled and new key created: 06sDmKQK3E6MSJwsOhYT3N4NzfTpe53ruV0Bydf0

