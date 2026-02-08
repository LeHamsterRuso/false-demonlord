# The False Overlord

## Propósito
Este proyecto no tiene ánimo de lucro y fue creado como tutorial para enseñar a programar en MS-DOS. Más información en: [Tutorial en El General Failure](https://www.elgeneralfailure.com/2026/01/aprendiendo-programar-para-ms-dos-con.html). Ejemplo de gameplay: [https://x.com/Hamster_ruso/status/2011198674219462792/video/1](https://x.com/Hamster_ruso/status/2011198674219462792/video/1)

## Inspiración
El juego está inspirado en 'How not to summon a demon lord' (aka 'Isekai Maou') de Yukiya Murasaki, y en el estilo de juego de Dragon Quest, adaptando elementos de narrativa, exploración de mundos y combates por turnos a un entorno retro de MS-DOS.

## Descripción
The False Overlord es un JRPG desarrollado para MS-DOS, que incluye un sistema de batalla por turnos, exploración de mapas, interacciones con NPCs, sistema de quests, inventario, y guardado/carga de partida. El juego captura la esencia de los JRPGs clásicos en un formato retro.

## Créditos
Este juego ha sido programado por Sebastián J. Moncho Maquet, aka Le hamster_ruso ([@hamster_ruso en X](https://x.com/hamster_ruso)), en enero de 2026.

## Requisitos
Para compilar y ejecutar este juego, necesitas:
- Sistema operativo MS-DOS o compatible (Windows 95, Windows 98, DOSBox, etc).
- Div 2 Games Studio instalado, incluyendo sus ejemplos.
- 16 MB de RAM (28 MB si deseas debugear el juego)
- Procesador Pentium 100 MHz o superior.
- Tarjeta gráfica VGA/SVGA.
- Tarjeta de sonido SB16 o compatible.
- Disco duro con 200 MB aprox de espacio libre disponible.

Para jugar, necesitas:
- Sistema operativo MS-DOS o compatible (Windows 95, Windows 98, DOSBox, etc).
- 12 MB de RAM.
- Procesador Pentium 100 MHz o superior.
- Tarjeta gráfica VGA/SVGA.
- Tarjeta de sonido SB16 o compatible.
- Disco duro con 10 MB de espacio libre disponible.

## Compilación
1. Instala Div 2 Games Studio con todos sus ejemplos.
2. Ejecuta MAPGEN05.PRG primero para generar los archivos de datos MapsV5.dat, ItemsV5.dat, Monsters.dat y HeroesV5.dat.
3. Abre el proyecto en Div 2 Games Studio.
4. Compila el archivo principal `PRG/FALSEDL.PRG`.

## Tildes y formatos
Al estar el código en español, dependiendo de si estás en un entorno MS-DOS real o en un DOSBox, puedes tener problemas con las tildes. Esto puede causar problemas de visualización en los diálogos (carácteres raros) o de overflow (strings más largos de la talla permitida). En la raíz del proyecto deja una herramienta build_msdos.sh para Linux/MacOS que permite convertir el fichero de UTF8 al formato esperado por DOS. Esta herramienta no machaca el fichero original, si no que crea una copia FALSEDL.PRG convertida.

## Configuración para DOSBox
Para que el audio se escuche correctamente en DOSBox en Windows, es necesario configurar `core=dynamic` y `cycles=95000`. En principio, esta configuración no es necesaria en Linux/Mac.

## Notas sobre archivos
- El juego utiliza la paleta `DIV2.PAL`, que viene preinstalada en el framework de Div Games Studio 2 y no se incluye aquí.
- Los archivos de gráficos están en la carpeta `FPG/DIABLO/`.
- Los archivos de música y sonido empleados son de los ejemplos disponibles en Div 2 Games Studio y no se suministran en este GitHub.
- Los archivos de datos generados por MAPGEN05.PRG: `MapsV5.dat`, `ItemsV5.dat`, `Monsters.dat`, `HeroesV5.dat`.
- El archivo de guardado se genera en `save.dat`, en la raíz del juego.

## Assets
Para los assets del juego, se han utilizado:
- Todos los sprites han sido generados haciendo uso de IA generativas, con especial mención a Meshy.AI (personajes 3D renderizados con Blender) y ChatGPT.