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

Serve with Nginx
----------------

All of the data generated can now be served up with any webserver. Nginx will be used for this example. First, the `nginx.conf` file will need to be created:

```
# $PWD/nginx.conf, this can be optimized to your needs
http {
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  
  server {
    listen 80 default_server;
    root /data/public;
    autoindex on;
    autoindex_exact_size off;
  }
}
```

Next, the Nginx container can be run with the mounted `nginx.conf` and volumes from `yumsync_data`:

```bash
docker run --rm --volumes-from yumsync_data -v $PWD:/etc/nginx/nginx.conf:ro -p 80:80 nginx:1.9
```
