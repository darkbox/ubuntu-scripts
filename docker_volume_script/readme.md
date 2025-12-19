# Script respaldo volumenes Docker
> Tener en cuenta, que esto solo se encarga de los volumenes de Docker. No respalda variables de entorno (.env), *bindings*, archivos de *stack.yml* u otras configuraciones relacionadas con Docker.

Descargar directamente con `wget` o `curl`:
```bash
wget https://raw.githubusercontent.com/darkbox/ubuntu-scripts/main/docker_volume_script/backup_docker_volume.sh
```

```bash
curl -O https://raw.githubusercontent.com/darkbox/ubuntu-scripts/main/docker_volume_script/backup_docker_volume.sh
```


## Uso
Ejecutar el script `docker-volumes-backup.sh`. No es necesario indicar el directorio de destino, por defecto lo guarda en `/backup/docker-volumes`.

```bash
chmod +x docker-volumes-backup.sh
sudo ./docker-volumes-backup.sh /backup/docker-volumes
```
> A ser posible, ejecutar con los contenedores parados.

## Restaurar un volumen (ejemplo)
> **OJO: esto sobrescribe el contenido del volume**
```bash
sudo rsync -a --delete /backup/docker-volumes/<BACKUP_DIR>/<VOLUME_NAME>/ "$(docker info --format '{{.DockerRootDir}}')/volumes/<VOLUME_NAME>/_data/"
```

> **IMPORTANTE:** para evitar problemas con base de datos, mejor parar el contenedor, ejecutar la restauración y volver a levantar.

## Borrar backups
El script está preparado para mantener siempre los últimos dos respaldos (anteriores son eliminados de forma automática).
En caso de necesitar eliminar todos los respaldos (Ya no son necesarios o liberar espacio), ejecutar:
```bash
sudo rm -r /backup/docker-volumes/
```