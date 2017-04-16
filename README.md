mongodb_conistent_backup Ansible playbook
=========================================

This role will deploy `mcbackup.sh`, a script that relies on [mongodb_conistent_backup](https://github.com/Percona-Lab/mongodb_consistent_backup) to backup a MongoDB Cluster and ReplicaSet.

Requirements
------------

Requires docker on the machine (not listed as a dependency). See [ansible-docker](https://github.com/leucos/ansible-docker) if you need a Docker role.

Role Variables
--------------

Beside deploying the script, this role will manage your backup crontab for you if you populate `mcb_backup_crons`:

  - `mcb_backup_crons`: list of dicts containing the following items:
    - `name`: a unique name for the backup (mandatory)
    - `source`: server name or IP address of a shard router (mandatory)
    - `port`: port for the above shart router (mandatory)
    - `destination`: destination directory to put
      backups in; backups will be put in `destination/source` (mandatory)
    - `day`: cron-compatible day specification (mandatory)
    - `hour`: cron-compatible hour specification (mandatory)
    - `minute`: cron-compatible minute specification (mandatory)
    - `keep`: number of previous backups to keep (default: 10)
    - `log`: log file name relative to /var/log/mongodb-consistent-backup/ (will be rotated, default: mcbackup.log)

Example
-------

```
mcb_backup_crons:
  - name: Dev server
    source: localhost
    port: 27019
    destination: /backup
    keep: 3
    day: "*"
    hour: 5
    minute: 15
    log: dev.log
  - name: Production server
    source: prod.example.com
    port: 27019
    destination: /backups/mongo
    keep: 30
    day: "*"
    hour: 1
    minute: 5
    log: production.log
```

Tags
----

  - `mongodb_consistent_backup`: whole role
  - `check`: variables check

Dependencies
------------

- [ansible-docker](https://github.com/leucos/ansible-docker)

Example Playbook
----------------

Specs
-----

To run tests locally in a Vagrant machine, just hit:

    vagrant up
    vagrant ssh -c specs

If you want to run the test playbook fast (i.e., without re-installing Ansible),
just run:

    vagrant ssh -c 'specs -p'

License
-------

MIT

Author Information
------------------

@leucos.

