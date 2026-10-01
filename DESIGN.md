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

## Overview

Panel para personas que consultan pedidos de los restaurantes de Niu Foods.
El PDF `Prueba_Niufoods_Ordenes.pdf` es la referencia funcional: número de orden,
restaurante, total CLP, modalidad, fecha y estado del despacho. El contrato de
datos es `GET /api/v1/orders`, implementado en
`app/controllers/api/v1/orders_controller.rb` y su serializer de dashboard.

La referencia visual es un registro de pedidos de restaurante: identificadores
como pequeñas etiquetas rojas, montos alineados y estados reconocibles. El rojo
es una elección de este proyecto; no representa una guía oficial de marca.
La lectura de datos prevalece sobre decoración, menús o métricas adicionales.

Interfaz de producto de una sola pantalla en español de Chile, moneda CLP y
zona horaria `America/Santiago`. No hay pantallas hermanas ni componentes previos.
No se requiere un UX-CONTRACT independiente para esta única vista de consulta.

**Fuente de tokens:** `frontend/src/index.css` es el dueño de los valores en
ejecución; este documento refleja esos valores y su intención. `colors.X`
corresponde a `--color-X` (salvo `primary`, que corresponde a `--color-brand`),
`typography.X` a `--font-X`, `rounded.X` a
`--radius-X` y `spacing.page-max` a `--page-max`. `frontend/src/App.css` consume
esas variables. Los cambios de tokens actualizan CSS y documentación juntos.
No hay generación de tokens ni otra biblioteca de temas.

## Colors

Tema claro explícito con fondo gris frío, superficies blancas y texto azul grisáceo.
Rojo para identidad e identificadores. Verde para enviado, ámbar para pendiente y
rojo para error. Los estados siempre incluyen texto; un estado desconocido es
neutral. Scrollbars globales con colores del sistema en contraste forzado.

## Typography

Encabezados en Trebuchet MS con alternativas locales. Cuerpo en Segoe UI o
alternativas del sistema; identificadores y códigos en monoespaciada. No se
descargan fuentes. Montos y fechas usan cifras tabulares. Título entre 30 y 38 px,
encabezado de panel de 17 px, filas de 13 px y texto auxiliar entre 11 y 14 px.

## Layout

Cabecera de marca y un único listado central de hasta 1280 px. Márgenes laterales
de 32 px en escritorio y 16 px en móvil. Bajo 700 px se apilan los encabezados.
La tabla conserva las seis columnas y usa scroll horizontal propio desde un ancho
mínimo de 1080 px; su región admite foco de teclado y muestra una indicación de
desplazamiento en pantallas pequeñas. El documento es dueño del scroll vertical.
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

## Elevation & Depth

Bordes y cambios de superficie separan las áreas, sin sombras grandes ni gradientes.
El hover suave de filas facilita la lectura y no implica que sean interactivas.

## Shapes

Panel de 14 px de radio; identificador, marca y modalidad de 6 px. Solo las
etiquetas de estado son completamente redondeadas. Los puntos son decorativos.

## Components

- `App.jsx`: consulta existente, cabecera, panel y tabla semántica.
- `App.css`: layout y variantes visuales del panel, filas, modalidades y estados.
- `index.css`: tokens, tipografía base, foco visible y scrollbars globales.
- Carga, error y listado vacío reservan al menos 280 px y usan mensajes en español.
  El indicador de carga respeta movimiento reducido.
- Caption accesible, encabezados con `scope="col"` y fechas con `<time>`.
- La región de carga de páginas reserva espacio. Los botones tienen hover, foco
  visible y estados de carga y deshabilitado. La carga no toma el foco de teclado.
- `sent` confirma el envío al restaurante. El pie aclara el significado del estado.

## Do's and Don'ts

- Conservar los seis campos del PDF y nombrar el ID como número de orden.
- Mostrar modalidades, estados y mensajes en español; respetar CLP y hora de Chile.
- Alinear montos a la derecha y conservar valores completos accesibles en móvil.
- Evitar filtros, enlaces, botones o indicadores de tiempo real sin una función real.
- No ocultar errores ni comunicar estados únicamente mediante color.
