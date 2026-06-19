# Fichaje Juan Martín — DESPUBLICADO (conservado para reactivar)

Despublicado el 19/06/2026 porque Redes gestiona su propio modelo de carteles.
Nada se ha perdido: aquí está todo para volver a activarlo cuando se acuerde.

## Qué se quitó de la web
1. La **portada** del primer equipo volvió a la foto del equipo (pretemporada).
2. La **tarjeta de noticia** del fichaje (quitada de data/noticias.json).
3. La **página de noticia** se movió aquí (`_inactivas/fichaje-juan-martin.html`).

## Qué se conserva (en esta carpeta y en la web)
- `fichaje-juan-martin.html` — la página de noticia completa (movida aquí).
- `hero-fichaje-juanmartin.html` — el hero de portada (snippet listo).
- `noticia-fichaje-juanmartin.json` — la entrada de la noticia.
- En `galeria/`: `fichaje-juan-martin.jpg` (cartel) y `juan-martin-accion.jpg` (foto).

## Cómo reactivar
Lo más fácil: pídeselo a Claude → **"reactiva el fichaje de Juan Martín"**.
Manualmente son 3 pasos:
1. Mover `fichaje-juan-martin.html` de vuelta a la raíz.
2. Volver a meter la noticia de `noticia-fichaje-juanmartin.json` en `data/noticias.json`.
3. (Opcional) Restaurar el hero de portada con `hero-fichaje-juanmartin.html` + su CSS .peh-*.
