# Dockerized Yumsync

This docker image is a wrapper around the tool [yumsync](https://github.com/jrwesolo/yumsync). `yumsync` is useful for mirroring remote or local repositories. By default, it will created versioned snapshots of repository metadata. For more information, please see its [README.md](https://github.com/jrwesolo/yumsync/blob/master/README.md).

Persistent Data
---------------

In order for data to persist after syncing, a data-only container is needed:

```bash
# With no local repositories
docker create --name yumsync_data jrwesolo/yumsync:latest

# If local repositories will be managed, be sure to mount the directory with the local packages
docker create \
  --name yumsync_data \
  -v /path/on/host:/path/in/container:ro \
  jrwesolo/yumsync:latest
```

This will create a container whose volumes can be shared with other containers.

Modes
-----

There are three modes that this container can run in:

- sync (default if none specified)
- archive
- restore

If the first parameter is any of the above, yumsync will switch into that mode. All other parameters are passed through. This allows flags to be passed to the actual yumsync script when running the docker container.

Sync
----

The sync mode requires that `/etc/yumsync/repos.yml` exists in the container. This can be accomplish by mounting that configuration file when running the container:

```bash
docker run --rm \
  --volumes-from yumsync_data \
  --volume /path/on/host/repos.yml:/etc/yumsync/repos.yml:ro \
  jrwesolo/yumsync:latest
```

Any parameters passed to docker will also be passed to `yumsync`. Please see its [README.md](https://github.com/jrwesolo/yumsync/blob/master/README.md) for more details of usage or run with `--help`.

**_Note about hard links: DO NOT use hard links with local repositories and Docker. The mounted local directory and the yumsync data directory will reside on different devices. Hard linked files must exist on the same device. Yumsync will throw a helpful error if this is detected._**

Archive
-------

The archive mode will archive all of the yumsync data directory to a compress file and drop it into the `/archive` directory. It is required to mount a host directory to `/archive`. The volumes from the data container will also need to be mounted:

```bash
docker run --rm \
  --volumes-from yumsync_data \
  -v $PWD:/archive \
  jrwesolo/yumsync:latest archive
```

This will result in an archive file residing in whatever host directory that was mounted to `/archive`:

```bash
ls -lhgo yumsync_*
# -rw-r--r-- 1  18M Jan 20 09:40 yumsync_20160120.tar
```

_This archive can grow to be **very large** (tens or hundreds of GiB) depending on the number of repositories and packages that are being mirrored._

Restore
-------

The restore mode will restore all of the yumsync data to a data-only container. When restoring, a fresh data-only container is advised. Otherwise, the yumsync data directory in the data-only container needs to be empty (usually this is `/data`):

```bash
# Please see the 'Persistent Data' section above if local repositories will be managed
# Create a fresh data-only container
docker create --name yumsync_data_2 jrwesolo/yumsync:latest
```

When executing a restore, it is required to mount an archive file to `/restore` in the restore container. Be sure to also mount the volumes from the fresh data-only container created earlier:

```bash
docker run --rm \
  --volumes-from yumsync_data_2 \
  -v $PWD/yumsync_20160120.tar:/restore:ro \
  jrwesolo/yumsync:latest restore
```

Now the fresh data-only container will have the restored data and can be used for future syncs.

Full Example with Nginx
-----------------------

#### Create Data-Only Container

The first thing needed is a data-only container that will house the persistent data:

```bash
docker create --name yumsync_data jrwesolo/yumsync:latest
```

#### Create Yumsync Configuration

Yumsync needs `repos.yml` file available to configure which repositories are to be mirrored. Create `$PWD/repos.yml` with the following content:

```yaml
---
centos/6/extras/x86_64:
  mirrorlist: 'http://mirrorlist.centos.org/?release=6&repo=extras&arch=x86_64'
  gpgkey: 'http://mirror.centos.org/centos/6/os/x86_64/RPM-GPG-KEY-CentOS-6'
```

#### First Synchronization

Now it's time to do the first sync using the previously created data-only container and config file:

```bash
docker run --rm \
  --volumes-from yumsync_data \
  -v $PWD/repos.yml:/etc/yumsync/repos.yml:ro \
  jrwesolo/yumsync:latest
```

#### Create Nginx Configuration

All of the data generated can now be served up with any webserver. Nginx will be used for this example. Create `$PWD/nginx.conf` with the following content:

```
# this can be optimized to your needs
user nginx;
worker_processes auto;

events { worker_connections 1024; }

http {
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  types { text/plain log; }

  server {
    listen 80 default_server;
    root /data/public;
    autoindex on;
    autoindex_exact_size off;
  }
}
```

#### Serve It Up!

All the pieces are in place now. The Nginx container can be ran with the Nginx config file and data-only container volumes mounted:

```bash
docker run --rm \
  --volumes-from yumsync_data \
  -v $PWD/nginx.conf:/etc/nginx/nginx.conf:ro \
  -p 80:80 \
  nginx:1.9
```

If you are using another machine or VM as your docker host, you will need to use that ip address to access Nginx. Otherwise, use `127.0.0.1`. Determine what ip address Nginx will be accessible at using the following:

```bash
[[ $DOCKER_HOST ]] \
&& sed 's|^.*://\(.*\):.*|\1|' <<< "${DOCKER_HOST}" \
|| echo 127.0.0.1
```

Now you can navigate to `http://${ip}` and see all of the synchronized data available in a friendly and organized fashion.