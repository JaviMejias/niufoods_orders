# Dashboard de órdenes · Niu Foods

Frontend en React y JavaScript, con Vite, pnpm y ESLint. Consulta las órdenes de
la API Rails y muestra número de orden, restaurante, total CLP, modalidad,
fecha/hora de creación y estado del envío al restaurante.

## Requisitos

- Node.js y pnpm. Versiones utilizadas: Node.js `22.22.1` y pnpm `12.8.1`.
- API Rails del proyecto con PostgreSQL configurado y los datos iniciales cargados.

En WSL, ejecutar los comandos desde Ubuntu con las instalaciones de Node.js y
pnpm de Linux, dentro de `/home/...`; no utilizar el ejecutable de pnpm de Windows.

## Ejecución local

Con el backend configurado, ejecutar desde la raíz del repositorio:

```bash
bin/rails db:prepare
bin/rails server -b 127.0.0.1 -p 3000
```

En otra terminal, también desde la raíz del repositorio:

```bash
cd frontend
pnpm install --frozen-lockfile
pnpm dev
```

Abrir la dirección que muestra Vite, normalmente `http://localhost:5173`.
Si la API ya está ejecutándose en el puerto 3000, mantener ese proceso y arrancar
únicamente el frontend.

`vite.config.js` dirige las solicitudes `/api` a `http://127.0.0.1:3000` durante
el desarrollo. React consulta rutas relativas; no requiere configurar CORS para
esta ejecución local.

Para generar nuevas órdenes con el script, iniciar también el receptor de tienda
según [la guía de simulación](../docs/store_simulation.md). El receptor no es
necesario para consultar órdenes ya guardadas.

## Listado y scroll infinito

El frontend solicita `GET /api/v1/orders?page=1&per_page=20`. Al acercarse al final
de la tabla, `IntersectionObserver` solicita la siguiente página y añade sus filas.
El botón **Cargar más** permite hacer lo mismo mediante teclado o cuando el navegador
no dispone de ese observador.

- El contador muestra las órdenes cargadas y el total informado por la API.
- Se permite una solicitud por vez y las órdenes se identifican por ID para evitar
  filas duplicadas al combinar páginas.
- Una carga fallida conserva las filas existentes y permite reintentar la misma página.
- La carga termina al alcanzar la última página; la tabla conserva sus seis columnas
  y permite desplazamiento horizontal en pantallas pequeñas.
- Los montos usan pesos chilenos y las fechas, la zona horaria `America/Santiago`.
- Los estados se presentan como **Pendiente de envío**, **Enviada al restaurante**
  y **Error de envío**. Describen el despacho al restaurante.

Al recargar se vuelve a la primera página. La API pagina por offset; si ingresan
órdenes mientras se recorre el listado, sus posiciones pueden cambiar. No se
implementa actualización en tiempo real ni una instantánea del conjunto de órdenes.

## Comprobaciones

Ejecutar desde `frontend`:

```bash
pnpm test
pnpm lint
pnpm build
```

Los tests usan el runner integrado de Node.js y respuestas HTTP simuladas. Cubren
las cinco páginas de 100 órdenes, la última página parcial de 63 órdenes, un listado
vacío, páginas superpuestas, fallo y reintento, cancelación y metadatos inesperados.
No incluyen una prueba automatizada del scroll en un navegador.

`pnpm build` genera los archivos estáticos en `dist/`. Para desplegarlos, el servidor
que los publique debe dirigir `/api` al backend Rails; el proxy de desarrollo no
forma parte de esos archivos.

## Organización

- `src/App.jsx`: tabla, estados de carga/error y coordinación del scroll infinito.
- `src/lib/orders.js`: solicitudes paginadas y combinación de órdenes por ID.
- `src/index.css`: colores, tipografía base, foco y barras de desplazamiento.
- `src/App.css`: diseño del dashboard y adaptación a pantallas pequeñas.
- `test/orders.test.js`: pruebas de la consulta paginada.
- [DESIGN.md](../DESIGN.md): criterios visuales del proyecto.

El repositorio incluye `pnpm-lock.yaml`. `node_modules/` y `dist/` se excluyen mediante
`.gitignore`. El detalle de una orden mediante modal todavía no está implementado.
