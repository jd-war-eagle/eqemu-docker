# eqemu-docker

A docker-compose configuration for quickly bringing up a private eqemu server and loginserver for the Titanium Client. Made mostly for fun.

## Quickstart

* **FIRST:** Update usernames and passwords contained in the `docker-compose.yml` file. These values will be used to configure the server. Even though the default configuration is only accessible locally it is **STRONGLY ADVISED** to update these values.

* Build and run server

```
docker-compose build && docker-compose up -d
```
* Update `eqhost.txt` in your EQ directory to point to localhost port 5998

```
[LoginServer]
Host=127.0.0.1:5998
```
* Launch EQ and login with the admin username and password specified in the `docker-compose.yml`

* After initial login proceed to character creation to create account, then logout and flag the account as a GM.

```
docker exec eqemu-server /bin/bash -c "cd /root/server && ./world flag \$EQ_SERVER_ADMIN_USERNAME 250"
```
* Login and play!

## Info

The default configuration *should* work out of the box to bring up a locally (only) accessible eqemu server for the Titanium client by just running `docker-compose build && docker-compose up -d`.

After buildling, the first run will take a bit of time as the database is initialized from the peqdb. Check the initialization status using the `docker logs` command:

```
docker logs eqemu-server
```

In theory, the configuration can be modified to work with the main eqemu login server and/or an external database, but current design is based on localhost access only.


### Spells File

The `spells_us.txt` is straight from the Titanium client. If you want to use a different once just replace this file when building.

### Database Volume

The database in the eqemu-db container persists via a docker volume. If you want to delete this database for any reason just run

```
docker volume rm eqemudocker_db_data
```

### Zones

The default configuration only create 2 zone instances. If you have problems zoning a lot have multiple characters/clients, simply increase the `numprocs` number in the `zone.conf` supervisor config and build again.

### peqphpeditor

The peqphpeditor can optionally be enabled. Just set the `PEQEDITOR_PORT` variable in the docker config file. When the container is run the editor will be available at `http://127.0.0.1:8080` by default.
