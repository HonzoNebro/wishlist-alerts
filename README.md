# Wishlist Alerts para WoW Forever

[Descargar la última versión](https://github.com/HonzoNebro/wishlist-alerts/releases/latest)

Complemento independiente para WoW Forever (interfaz 16001). Consulta tus listas en el momento en que aparece el botín. Si varias listas contienen el mismo objeto, el aviso enumera las fuentes en una sola línea del chat local.

## Instalar y probar en Nobara

1. Cierra WoW y extrae el ZIP. Copia la carpeta `WishlistAlerts` a `World of Warcraft/_forever_/Interface/AddOns/`. La ruta final debe terminar en `AddOns/WishlistAlerts/WishlistAlerts.toc`.
2. Abre WoW y activa **Wishlist Alerts** y al menos uno de los addons compatibles. Puedes seguir usando el NeedRoll oficial.
3. Escribe `/wla check 6220`. Si el **Fragmento de meteorito** está en tus deseos de Forever Guild con el personaje activo, el chat local debe indicar «Listas: Forever Guild». También puedes escribir `/wla check Fragmento de meteorito` o teclear `/wla check ` y pulsar Mayús + clic sobre un enlace del chat antes de enviar el comando. La respuesta muestra el ID y las listas. Si el cliente no reconoce el nombre, usa el enlace del objeto.
4. Escribe `/wla test`. Debe aparecer un aviso en pantalla y oírse el sonido si está activado. Esta prueba funciona fuera de una mazmorra y también cuando has silenciado los avisos automáticos.
5. Escribe `/wla demo` para abrir una tirada simulada de un objeto deseado. Con los avisos activos, aparece la sugerencia al abrirla. Pasa el cursor por Codicia para ver el segundo aviso y pulsa un botón para cerrar la prueba. Puedes volver a abrirla cuantas veces quieras. Respeta tus ajustes de avisos, sonido y Codicia.
6. En una tirada real con un objeto deseado, verifica que sale el aviso cuando aparecen los botones. Si puedes tirar Necesidad, pasa el cursor por Codicia y comprueba el segundo recordatorio antes de elegir. Usa un objeto sin marcar como control y prueba también una tirada en la que Necesidad no esté disponible.
7. En saqueo directo, comprueba el aviso una vez con saqueo automático desactivado y otra con él activado. Ejecuta `/reload` para verificar que las preferencias se guardan. Puedes retirar la carpeta `WishlistAlerts` para desinstalar el complemento.

El texto grande usa la zona local de avisos de banda de Blizzard, disponible también en grupo. Los mensajes del complemento se muestran en tu pantalla y en tu chat local. El sonido se reproduce al detectar la tirada o el saqueo. El recordatorio de Codicia es visual, aparece una vez por tirada al pasar el cursor por el botón nativo y solo se muestra cuando Necesidad también está disponible. Un clic directo sigue el flujo normal del juego. El recordatorio al pasar el cursor depende de la ventana nativa de ratón y teclado. Las ventanas que la sustituyen y el modo mando quedan fuera de esa función.

## Comandos

| Comando | Acción |
| --- | --- |
| `/wla` | Mostrar qué hace cada comando y el estado de cada opción. Los subcomandos desconocidos también abren esta ayuda |
| `/wla check 6220` | Consultar por ID, nombre completo en el idioma del juego o enlace del objeto |
| `/wla test` | Probar la presentación y el sonido |
| `/wla demo` | Abrir una tirada simulada y probar los botones |
| `/wla on` o `/wla off` | Activar o desactivar los avisos automáticos |
| `/wla sound on` o `/wla sound off` | Cambiar el sonido |
| `/wla loot on` o `/wla loot off` | Cambiar los avisos de saqueo directo |
| `/wla greed on` o `/wla greed off` | Cambiar el recordatorio al pasar por Codicia |

También puedes cambiar los cuatro ajustes en **Opciones → AddOns → Wishlist Alerts**. El panel y el chat comparten los mismos ajustes. Los avisos, el sonido, el saqueo directo y el recordatorio están activados de serie. `/wishlistalerts` también funciona como alias. Los textos siguen el idioma del cliente: inglés, español (España y Latinoamérica), alemán, francés, portugués (Brasil), ruso, coreano, chino simplificado y chino tradicional. Si el cliente usa otro idioma, se muestra el inglés. Los comandos `/wla check` y `/wla test` funcionan en todos los idiomas.

## Listas y alcance

| Fuente | Qué lee | Descargas aproximadas en CurseForge |
| --- | --- | --- |
| [NeedRoll](https://www.curseforge.com/wow/addons/needroll) | Lista activa de la cuenta, comprobada en el código de v1.4.1 | 123.000 |
| [OneForAll](https://www.curseforge.com/wow/addons/oneforall-forever) | Wishlist del personaje, comprobada en el código de v6.2.2 | 896.000 |
| [Forever Guild](https://www.curseforge.com/wow/addons/forever-guild) | Tus propios Deseos del personaje activo, comprobados en el código de v0.7.3 (carpeta `LevelMates`) | 1.100 |
| [AtlasLootClassic Continued](https://www.curseforge.com/wow/addons/atlasloot-continued) / [AtlasLoot Classic Forever](https://www.curseforge.com/wow/addons/atlasloot-forever) | Adaptador experimental para las ediciones que exponen la API clásica de Favourites. Compruébalo con un favorito marcado | 8,5 M / 7,8 M |

Son descargas acumuladas consultadas el 10 de noviembre de 2026. Incluyen actualizaciones y, en los proyectos de AtlasLoot, archivos para otras versiones de WoW. Sirven para priorizar integraciones. La lista separada de [AtlasLoot Prettier](https://www.curseforge.com/wow/addons/stbu-atlasloot-classic-forever-prettier-forever) requiere su propio adaptador. [ForeverDB](https://www.curseforge.com/wow/addons/foreverdb) también tiene Wishlist (unas 5.000 descargas) y [Wishwell Forever](https://www.curseforge.com/wow/addons/wishwell-forever) ya anuncia su propia Wishlist (unas 220). Ambos quedan fuera de esta versión.

Los lectores consultan addons cargados en memoria. NeedRoll, Forever Guild y OneForAll se leen mediante sus datos guardados. AtlasLoot se consulta mediante su módulo Favourites cuando está disponible. Los únicos datos que Wishlist Alerts guarda son sus preferencias.

## Verificación

Desde la carpeta del proyecto ejecuta `luajit tests/smoke.lua`. La prueba usa las estructuras verificadas de las listas y simula los eventos de WoW, incluidos enlaces ocultos por el cliente, coincidencias de varias fuentes, separación de personajes, recordatorio de Codicia, deduplicación y opciones. La tirada real, el saqueo automático, el sonido y las ediciones actuales de AtlasLoot quedan pendientes de prueba en el cliente.

Fuentes de implementación: [Gear Planner de OneForAll](https://github.com/smoergi/OneForAll_Forever/blob/main/OneForAll/UI/GearPlanner.lua), [Favourites de AtlasLootClassic](https://github.com/Hoizame/AtlasLootClassic/blob/master/AtlasLootClassic/Addons/Favourites.lua), [eventos de saqueo de Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua) y [botones de tirada nativos de Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/GroupLootFrame.xml).

## Licencia

Wishlist Alerts se publica bajo la [licencia MIT](LICENSE).
