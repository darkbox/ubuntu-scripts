Este script genera un inventario completo en JSON y texto, incluyendo contenedores, imágenes, redes, volúmenes, puertos, variables, mounts y configuración útil para preparar el `compose.yml`.

Ejecutar sin descargar:

```bash
curl -fsSL https://raw.githubusercontent.com/darkbox/ubuntu-scripts/refs/heads/main/docker-helpers/docker-inventory.sh | sudo bash
```

Uso:

```bash
chmod +x docker-inventory.sh
sudo ./docker-inventory.sh
```

También puedes indicar el directorio de salida:

```bash
sudo ./docker-inventory.sh /root/inventario-docker
```

Ten en cuenta que `environment.json` puede contener contraseñas, tokens y otras credenciales. Guarda el inventario con permisos restringidos:

```bash
chmod -R go-rwx docker-inventory-*
```
