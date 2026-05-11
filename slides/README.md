# Slides

Deck de la presentacion en formato Slidev.

## Desarrollo

```bash
cd slides
npm install
npm run dev
```

Abre:

```text
http://localhost:3030
```

Si corre dentro de WSL y Windows no abre `localhost`, usa la IP de WSL:

```bash
hostname -I
```

## Build estatico

```bash
cd slides
npm run build
```

Salida:

```text
dist/slides
```

## Export PDF

```bash
cd slides
npm run export
```

Salida:

```text
dist/jakartaee-nomad-arch.pdf
```
