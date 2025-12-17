## Traductor de Markdown a LaTeX
Autores: Estevo Aldea Arias y Javier Carballal Morgade

### ¿Qué es y para qué sirve?
Herramienta que convierte documentos Markdown en un fichero LaTeX listo para compilar. Genera un documento latex con soporte para enlaces e imágenes, reproduciendo la estructura y el formato del Markdown original.

### Funcionalidades implementadas
- Encabezados `#` … `######` y sintaxis alternativa con líneas `===`/`---`, mapeados a secciones latex.
- Párrafos con gestión de saltos de línea suaves (espacios dobles) y creación automática de `\newline` entre párrafos.
- Énfasis: cursiva, negrita y negrita+cursiva anidada, además de combinaciones anidadas de estas.
- Citas con `>` soportando líneas en blanco internas y cierre automático del entorno `quote`.
- Listas ordenadas y no ordenadas con anidamiento por indentación; apertura/cierre correcto de `itemize`/`enumerate` según el nivel.
- Bloques de código con vallas de dos tipos, convertidos a `verbatim`, y líneas horizontales (`***`, `___`, `---`).
- Enlaces (`[texto](url "título")`), autoenlaces `<http://...>`/`<mail@...>` e imágenes `![]()` renderizadas a ancho de texto.

### Archivos principales
- `practica3.l`: analizador léxico (Flex). Define estados para citas (`BQ`), listas (`LIST`) y bloques de código (`CFENCE`); normaliza los encabezados, calcula la profundidad de las listas y extrae los enlaces/imágenes.
- `practica3.y`: gramática y acciones de Bison. Construye la salida latex, gestiona la pila de listas, encapsula formatos (funciones auxiliares `wrap`, `join`) y añade el preámbulo y cierre del documento.
- `Makefile`: automatiza `flex`, `bison` y la compilación con `gcc`.
- `tests/`: casos de ejemplo en Markdown que cubren encabezados, listas, citas, formato, enlaces, imágenes, código y saltos de línea.
- Archivos generados (`lex.yy.c`, `practica3.tab.c`, `practica3.tab.h`) y binario `practica3`: se crean al compilar y pueden eliminarse con `make clean`.

### Explicación técnica
- Flujo: Flex tokeniza la entrada Markdown y asigna los valores semánticos (texto limpio, profundidad de lista, structs para enlaces/imágenes). Bison consume estos tokens y emite directamente el código latex correspondiente.
- Manejo de listas: se usa `list_stack` y `list_depth` para abrir/cerrar `itemize`/`enumerate` según cambios de nivel o de tipo de lista, evitando desajustes al anidar.
- Anidamiento recursivo: las reglas `strong_content`, `emph_content` y `triple_content` se llaman mutuamente, permitiendo combinaciones como negrita dentro de cursiva (`**_texto_**`) administrados en el parser directamente.
- Citas y párrafos: el estado `BQ` asegura que líneas consecutivas con `>` formen un único bloque.
- Salida: `main` imprime el preámbulo latex al inicio y `\end{document}` al terminar el `yyparse`, manteniendo la generación interactiva sin ficheros intermedios.

### Compilación y ejecución
Requisitos: `flex`, `bison`, `gcc` y `make` instalados; opcionalmente un motor LaTeX para compilar el `.tex` resultante.

- Compilar: `make compile`
- Ejecutar todos los tests y guardar sus `.tex`: `make runall`
- Ejecutar con el test por defecto (definible en el makefile): `make run`. Genera un archivo `.tex` con el mismo nombre.
- Ejecutar manualmente con cualquier entrada: `./practica3 < tests/archivo.md > salida.tex`
- Limpiar binarios y generados: `make clean`

Para obtener un PDF, compilar el `.tex` resultante con Overleaf o la herramienta a elección.
