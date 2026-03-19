# Guía de Despliegue: Bacula & Bacularis con Podman en MicroOS

Esta guía detalla la preparación del sistema operativo, la configuración de seguridad y la construcción de imágenes para un entorno de respaldo robusto y contenedorizado.

## 1. Arquitectura del Sistema
Antes de entrar a los comandos, es vital entender cómo interactúan los componentes que estás configurando:

### 1.2. Preparación del Sistema Operativo (Host)
Dado que usas **openSUSE MicroOS**, todas las modificaciones al sistema de archivos raíz deben ser atómicas y requieren un reinicio para aplicarse.

#### Actualización e Instalación de Herramientas
1. **Actualizar el sistema:**
   ```bash
   sudo transactional-update dup
   reboot
   ```
2. **Instalar paquetes esenciales:**
   * `htop`: Monitoreo de recursos.
   * `firewalld`: Gestión del firewall.
   * `nvim/sudo/curl/tar`: Utilidades de administración.
   ```bash
   sudo transactional-update pkg install htop sudo nvim openssh curl tar bash-completion firewalld
   reboot
   ```

#### Configuración del Firewall
Bacula requiere puertos específicos para que los demonios se comuniquen entre sí y con la interfaz web.
```bash
# Iniciar el servicio
sudo systemctl enable --now firewalld

# Abrir servicios y puertos de Bacula
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-port=9101/tcp  # Director
sudo firewall-cmd --permanent --add-port=9102/tcp  # File Daemon
sudo firewall-cmd --permanent --add-port=9103/tcp  # Storage Daemon
sudo firewall-cmd --permanent --add-port=9097/tcp  # Bacularis API/Web

sudo firewall-cmd --reload
```

---

### 1.3. Gestión de Usuarios y Permisos
Para un entorno seguro, utilizaremos un usuario dedicado (`adrian`) con privilegios de administrador para la gestión de contenedores.

1. **Creación del usuario y grupo:**
   ```bash
   useradd -m -s /bin/bash adrian
   passwd adrian
   groupadd wheel
   usermod -aG wheel adrian
   ```

2. **Habilitar Sudo para el grupo Wheel:**
   En MicroOS, para editar `/etc/sudoers`, se recomienda usar el shell transaccional:
   ```bash
   transactional-update shell
   visudo
   # Descomenta la línea: %wheel ALL=(ALL:ALL) ALL
   exit
   reboot
   ```

---

### 1.4. Infraestructura de Podman (Rootless)
Para que los contenedores de Bacula se ejecuten bajo el usuario `adrian` sin necesidad de ser root, configuramos el modo **Rootless** y la persistencia (**Linger**).

#### Persistencia y Directorios
El comando `linger` permite que los servicios de usuario de Systemd sigan ejecutándose aunque el usuario cierre la sesión.
```bash
# Ejecutar como usuario adrian o usar sudo para habilitar
sudo loginctl enable-linger adrian

# Crear estructura de directorios para Systemd (Quadlets)
mkdir -p ~/.config/systemd/user/
mkdir -p ~/.config/containers/systemd/
```

> **Nota:** Al copiar tus archivos `.container` a estas rutas, Podman generará automáticamente las unidades de Systemd para gestionar el ciclo de vida de los contenedores de Bacula.

---

### 1.5. Construcción de Imágenes Personalizadas
Bacula requiere configuraciones específicas para el **Director** (el cerebro) y el **Storage** (donde viven los volúmenes).

Accede a tu carpeta de desarrollo y ejecuta:

| Componente | Comando de Construcción | Función |
| :--- | :--- | :--- |
| **Director** | `podman build -t bacula-director:test-1 -f ./Dockerfile.director .` | Coordina tareas y base de datos. |
| **Storage** | `podman build -t bacula-storage:test-1 -f ./Dockerfile.storage .` | Escribe los datos en el disco/nube. |

---

### Resumen de Puertos y Servicios

| Puerto | Servicio | Descripción |
| :--- | :--- | :--- |
| **9101** | `Bacula DIR` | Control y orquestación. |
| **9102** | `Bacula FD` | Agente cliente (en el host a respaldar). |
| **9103** | `Bacula SD` | Gestión del almacenamiento. |
| **9097** | `Bacularis` | Panel de control web moderno. |
