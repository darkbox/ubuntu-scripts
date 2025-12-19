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

## Automatizar con CRON
Podemos programar la ejecución del script de forma automática con *CRON*. Para ello, primero asegúrate de que el script tenga permisos de ejecución y está en una ubicación adecuada (por ejemplo, `/usr/local/bin/` o la ruta actual).

### Configurar CRON
1. Editar el crontab de root (ya que el script requiere permisos de superusuario):
```bash
sudo crontab -e
```

2. Añadir la siguiente línea para ejecutar el script dos veces por semana (lunes y jueves) a las 5:00 AM:
```bash
0 5 * * 1,4 /ruta/completa/al/backup_docker_volume.sh /backup/docker-volumes >> /var/log/docker-backup.log 2>&1
```

### Ejemplo práctico
Si el script está en `/usr/local/bin/backup_docker_volume.sh`:
```bash
0 5 * * 1,4 /usr/local/bin/backup_docker_volume.sh /backup/docker-volumes >> /var/log/docker-backup.log 2>&1
```

### Explicación de la sintaxis CRON
- `0` = Minuto (0)
- `5` = Hora (5 AM)
- `*` = Todos los días del mes
- `*` = Todos los meses
- `1,4` = Lunes (1) y jueves (4)

> **Nota:** Puedes cambiar los días según tus necesidades. Los días de la semana van del 0 (domingo) al 6 (sábado). Por ejemplo, `0,3` ejecutaría los domingos y miércoles.

El `>> /var/log/docker-backup.log 2>&1` redirige la salida del script a un archivo de log para poder revisar el historial de ejecuciones.

### Verificar que CRON está configurado
Para listar las tareas programadas:
```bash
sudo crontab -l
```
