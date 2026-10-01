# Instalación y configuración

La aplicación se ejecuta en Linux. En Ubuntu, usar una terminal Bash. En Windows,
usar Ubuntu dentro de WSL 2; PowerShell se utiliza únicamente para preparar WSL.
El entorno de desarrollo fue Ubuntu 26.04 con WSL 2.

Elegir el punto de partida:

- [Ubuntu](#ubuntu): instalar las herramientas directamente en Linux.
- [Windows con WSL 2](#windows-con-wsl-2): preparar Ubuntu y seguir los pasos de Linux.
- [Configurar el proyecto](#configurar-el-proyecto): continuar si las herramientas ya están instaladas.

Las versiones usadas en el proyecto están en el [README](../README.md#requisitos).
Las rutas a archivos del proyecto son relativas al repositorio `niufoods_orders`.

## Ubuntu

Estos pasos se ejecutan en la terminal de Ubuntu, tanto en una instalación directa
como dentro de WSL. Si una herramienta ya está instalada, comprobar su versión
antes de continuar.

### Paquetes del sistema

```bash
sudo apt update
sudo apt install git curl ca-certificates build-essential \
  libssl-dev libreadline-dev zlib1g-dev libyaml-dev libffi-dev \
  postgresql postgresql-client libpq-dev
```

Las bibliotecas de desarrollo permiten compilar Ruby y la gema `pg`. El paquete
`postgresql` instala la versión disponible para esa edición de Ubuntu. Para
instalar otra versión, seguir la [guía de PostgreSQL para Ubuntu](https://www.postgresql.org/download/linux/ubuntu/).

Iniciar PostgreSQL y comprobar su estado:

```bash
sudo service postgresql start
pg_isready
```

`pg_isready` debe indicar que el servidor acepta conexiones. En WSL puede ser
necesario iniciar PostgreSQL nuevamente después de apagar la distribución.

### Ruby

Instalar [rbenv](https://github.com/rbenv/rbenv#installation), que permite usar la
versión de Ruby indicada por el proyecto. Para una instalación nueva:

```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
~/.rbenv/bin/rbenv init
```

Abrir una terminal nueva para cargar rbenv y luego instalar Ruby:

```bash
rbenv install 3.4.11
```

Al entrar al repositorio, rbenv selecciona esta versión mediante `.ruby-version`.
Si ya se usa otro administrador de versiones de Ruby, basta con instalar y
seleccionar Ruby 3.4.11 con esa herramienta.

### Node.js y pnpm

Para una instalación nueva, usar el instalador de
[nvm para Linux](https://github.com/nvm-sh/nvm#installing-and-updating):

```bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | bash
```

Abrir una terminal nueva para cargar nvm y ejecutar:

```bash
nvm install 22.22.1
nvm use 22.22.1
npm install -g pnpm@12.8.1
```

pnpm se instala en el entorno de Node.js seleccionado por nvm; este método está
descrito en la [documentación de pnpm](https://pnpm.io/installation).
Si Node.js ya está instalado por otro método, comprobar que sea la versión
utilizada por el proyecto e instalar pnpm en ese mismo entorno.
Si otra terminal de nvm selecciona una versión distinta, ejecutar
`nvm use 22.22.1` en esa terminal antes de iniciar el frontend.

Continuar con [configurar el proyecto](#configurar-el-proyecto).

## Windows con WSL 2

Los comandos de instalación de WSL requieren Windows 11 o Windows 10 versión 2004
o posterior. Seguir la [guía de Microsoft](https://learn.microsoft.com/en-us/windows/wsl/install)
si la instalación requiere pasos adicionales.

### Instalar Ubuntu

Si WSL y Ubuntu aún no están instalados, abrir **PowerShell como administrador**:

```powershell
wsl --install -d Ubuntu
```

Reiniciar Windows si lo solicita el instalador. Abrir Ubuntu y crear el usuario y
la contraseña de Linux cuando aparezca la solicitud.

Si Ubuntu ya está instalado, abrirlo desde el menú Inicio o desde PowerShell:

```powershell
wsl -d Ubuntu
```

Para comprobar qué distribuciones están instaladas y su versión de WSL, ejecutar
en PowerShell:

```powershell
wsl --list --verbose
```

La columna `VERSION` de Ubuntu debe indicar `2`. Si indica `1`, convertirla con
`wsl --set-version Ubuntu 2` antes de continuar. Si la distribución tiene otro
nombre, usar el que aparece en el listado.

### Preparar las herramientas dentro de Ubuntu

Seguir los pasos de [Ubuntu](#ubuntu) desde su terminal. Instalar Ruby, Node.js,
pnpm y PostgreSQL dentro de la misma distribución. Clonar también el proyecto
desde esa terminal, en una carpeta del sistema de archivos de Linux.

Para comprobar qué ejecutables se están usando:

```bash
command -v ruby
command -v node
command -v pnpm
```

Las rutas deben corresponder a las instalaciones de Linux. Una ruta que comienza
con `/mnt/c/` puede estar usando una herramienta de Windows; en ese caso, revisar
la instalación de la herramienta en Ubuntu y abrir una terminal nueva.

El navegador puede abrirse desde Windows. Los servidores y el script de simulación
se ejecutan desde las terminales de Ubuntu.

## Configurar el proyecto

Desde aquí, todos los comandos se ejecutan en **Bash dentro de Ubuntu**, ya sea
directamente o mediante WSL.

### Clonar e instalar las dependencias

Desde la carpeta donde se guardará el repositorio:

```bash
git clone https://github.com/JaviMejias/niufoods_orders.git
cd niufoods_orders
ruby --version
node --version
pnpm --version
gem install bundler -v 4.0.21
bundle install
```

Si el repositorio ya está clonado, entrar en su raíz y continuar desde la
comprobación de versiones. Ruby debe mostrar `3.4.11`, Node.js `22.22.1` y pnpm
`12.8.1`.

Instalar las dependencias del frontend y volver a la raíz:

```bash
cd frontend
pnpm install --frozen-lockfile
cd ..
```

### Configurar PostgreSQL

[config/database.yml](../config/database.yml) usa una conexión local mediante
socket Unix y el rol de PostgreSQL con el mismo nombre que el usuario de Linux.
Si ese rol todavía no existe, crearlo una vez:

```bash
sudo -u postgres createuser --createdb "$USER"
```

El permiso `--createdb` permite que Rails cree las bases de desarrollo y pruebas.
Si el rol ya existe, comprobar que tenga ese permiso.

| Entorno | Base de datos |
| --- | --- |
| Desarrollo | `niufoods_orders_development` |
| Pruebas | `niufoods_orders_test` |

Si PostgreSQL usa otro usuario o servidor, ajustar `username`, `password`, `host`
y `port` en `config/database.yml` para ambos entornos. También se puede usar
`DATABASE_URL`, según la [configuración de conexiones de Rails](https://guides.rubyonrails.org/configuring.html#connection-preference).
Al ejecutar pruebas, esa variable debe apuntar a la base de pruebas.

### Crear las bases y cargar el catálogo

Desde la raíz del repositorio:

```bash
bin/rails db:prepare
bin/rails db:seed
```

Los seeds cargan los tres restaurantes y los diez productos de la prueba, con
sus códigos, SKU y precios en CLP. Buscan por código y SKU, de modo que repetir
`db:seed` actualiza el catálogo sin duplicarlo. No crean ni borran órdenes.

En una base nueva, el dashboard estará vacío hasta crear pedidos con la API o el
script de simulación.

Las variables de entorno, como `STORE_BASE_URL`, se asignan en la terminal donde
se inicia el proceso. El proyecto no carga archivos `.env` automáticamente.

La instalación queda lista para [iniciar los servidores y el dashboard](../README.md#ejecutar-la-solución).
