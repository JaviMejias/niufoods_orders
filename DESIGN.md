---
version: alpha
name: "Niu Foods · Órdenes"
description: "Panel de pedidos por restaurante con acento rojo y una tabla de lectura clara."
colors:
  canvas: "#f4f6f8"
  surface: "#ffffff"
  surface-muted: "#f8fafb"
  ink: "#202a35"
  muted: "#626d7b"
  border: "#e2e7ec"
  primary: "#a72c45"
  brand-soft: "#fbedf0"
  success: "#196442"
  success-soft: "#eaf5ee"
  warning: "#83580a"
  warning-soft: "#fff5da"
  danger: "#a52b35"
  danger-soft: "#fff0f0"
  scrollbar: "#9ba6b2"
  scrollbar-hover: "#758392"
  scrollbar-active: "#4e5d6d"
typography:
  heading:
    fontFamily: "'Trebuchet MS', 'Segoe UI', sans-serif"
  body:
    fontFamily: "'Segoe UI', Roboto, Arial, sans-serif"
    fontSize: "16px"
    lineHeight: "1.5"
  mono:
    fontFamily: "ui-monospace, 'SFMono-Regular', Consolas, monospace"
rounded:
  panel: "14px"
  small: "6px"
spacing:
  page-max: "1280px"
components:
  orders-panel:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
  dispatch-badge:
    backgroundColor: "{colors.surface-muted}"
    textColor: "{colors.muted}"
---

# Diseño del dashboard de órdenes

## Resumen

Panel para personas que consultan pedidos de los restaurantes de Niu Foods.
El enunciado de la prueba define los campos del listado: número de orden,
restaurante, total CLP, modalidad, fecha y estado del despacho. El contrato de
datos es `GET /api/v1/orders`, implementado en
`app/controllers/api/v1/orders_controller.rb` y su serializer de dashboard.
El detalle usa `GET /api/v1/orders/:id` y un serializer propio;
incluye productos, cantidades, cliente y los precios guardados en la orden.

La referencia visual es un registro de pedidos de restaurante: identificadores
como pequeñas etiquetas rojas, montos alineados y estados reconocibles. El rojo
es una elección de este proyecto; no representa una guía oficial de marca.
La lectura de datos prevalece sobre decoración, menús o métricas adicionales.

La interfaz tiene una pantalla de listado y un modal para el detalle. Usa español
de Chile, moneda CLP y la zona horaria `America/Santiago`.

**Variables de diseño:** `frontend/src/index.css` define los valores usados por
la interfaz; este documento describe sus criterios. `colors.X`
corresponde a `--color-X` (salvo `primary`, que corresponde a `--color-brand`),
`typography.X` a `--font-X`, `rounded.X` a
`--radius-X` y `spacing.page-max` a `--page-max`. `frontend/src/App.css` consume
esas variables. Al cambiar un valor, actualizar el CSS y este documento.

## Colores

Tema claro explícito con fondo gris frío, superficies blancas y texto azul grisáceo.
Rojo para identidad e identificadores. Verde para enviado, ámbar para pendiente y
rojo para error. Los estados siempre incluyen texto; un estado desconocido es
neutral. Las barras de desplazamiento usan colores del sistema cuando está
activado el modo de contraste forzado.

## Tipografía

Encabezados en Trebuchet MS con alternativas locales. Cuerpo en Segoe UI o
alternativas del sistema; identificadores y códigos en monoespaciada. No se
descargan fuentes. Montos y fechas usan cifras tabulares. Título entre 30 y 38 px,
encabezado de panel de 17 px, filas de 13 px y texto auxiliar entre 11 y 14 px.

## Distribución

Cabecera de marca y un único listado central de hasta 1280 px. Márgenes laterales
de 32 px en escritorio y 16 px en móvil. Bajo 700 px se apilan los encabezados.
La tabla conserva las seis columnas y usa scroll horizontal propio desde un ancho
mínimo de 1080 px; su región admite foco de teclado y muestra una indicación de
desplazamiento en pantallas pequeñas. La página controla el desplazamiento vertical.
Los nombres de restaurantes se muestran completos.

El listado usa scroll infinito sobre la paginación existente de la API, en lotes
de 20. Un observador al final solicita la siguiente página al acercarse al límite
visible. El contador muestra órdenes cargadas y total informado por Rails.
El botón «Cargar más» ofrece una alternativa de teclado y funciona cuando no hay
IntersectionObserver. Al recargar, la consulta comienza con las órdenes más recientes.

Se permite una sola solicitud por vez y se cancelan solicitudes al desmontar.
Las páginas se añaden al listado conservando el orden y un único registro por ID.
Un error al cargar más conserva las filas y detiene la carga automática: «Reintentar»
vuelve a solicitar la misma página. La última página muestra «Listado completo» y
detiene nuevas solicitudes. Los cambios de datos durante la consulta siguen la
paginación por offset de Rails; el listado no representa una instantánea histórica.

## Bordes y modal

Bordes y cambios de superficie separan las áreas, sin sombras grandes ni gradientes.
El hover suave de filas facilita la lectura y no implica que sean interactivas.
El número de orden es un botón con hover, estado presionado y foco visible;
la cabecera explica que permite consultar el pedido.

El modal compartido usa `<dialog>` y `showModal()`: el navegador controla su capa
superior, foco e aislamiento del fondo. No hay capas con z-index propios.
El fondo del modal usa `--color-ink` al 45 % de opacidad. El modal mide hasta
720 px, conserva 16 px de margen por lado y limita su alto al viewport. Su cuerpo
controla el desplazamiento vertical del detalle; encabezado y cierre permanecen visibles.
Los productos conservan precios completos mediante scroll horizontal propio.

Al abrir se enfoca el botón de cierre; Tab permanece dentro del modal. Escape,
la cruz, «Cerrar» y una pulsación iniciada y terminada en el fondo lo cierran.
Al cerrar se devuelve el foco al botón que lo abrió, sin cambiar el scroll.
El documento bloquea su scroll mientras el modal está abierto y lo restaura al
cerrar. El listado permanece montado y pausa nuevas cargas automáticas mientras
se consulta el detalle. La carga del detalle reserva espacio, anuncia su estado,
ofrece reintento ante errores y se cancela al cerrar; no modifica ni despacha órdenes.

## Formas

Panel de 14 px de radio; identificador, marca y modalidad de 6 px. Solo las
etiquetas de estado son completamente redondeadas. Los puntos son decorativos.

## Componentes

Los archivos de esta sección están en `frontend/src/`.

- `App.jsx`: consulta del listado, cabecera, panel y tabla semántica.
- `App.css`: distribución y estilos del panel, filas, modalidades y estados.
- `components/Modal.jsx` y `Modal.css`: modal reutilizable con control de foco,
  cierre, fondo y desplazamiento. Recibe título y contenido.
- `components/OrderDetails.jsx` y `OrderDetails.css`: consulta y contenido del
  pedido; datos del cliente, dirección para delivery y tabla de productos.
- `lib/formatters.js`: moneda, zona horaria y textos de estado compartidos.
- `index.css`: variables de diseño, tipografía base, foco visible y barras de desplazamiento.
- Carga, error y listado vacío reservan al menos 280 px y usan mensajes en español.
  El indicador de carga respeta movimiento reducido.
- Tabla con descripción accesible, encabezados con `scope="col"` y fechas con `<time>`.
- La región de carga de páginas reserva espacio. Los botones tienen hover, foco
  visible y estados de carga y deshabilitado. La carga no toma el foco de teclado.
- `sent` confirma el envío al restaurante. El pie aclara el significado del estado.

## Criterios de mantenimiento

- Conservar los seis campos de la prueba y nombrar el ID como número de orden.
- Mostrar modalidades, estados y mensajes en español; respetar CLP y hora de Chile.
- Alinear montos a la derecha y conservar valores completos accesibles en móvil.
- Evitar filtros, enlaces, botones o indicadores de tiempo real sin una función real.
- No ocultar errores ni comunicar estados únicamente mediante color.
