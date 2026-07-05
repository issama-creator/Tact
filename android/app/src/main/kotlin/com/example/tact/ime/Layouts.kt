package com.example.tact.ime

/**
 * All built-in layouts for TACT MVP.
 *
 * Layouts are static (built at class-load time), immutable, and reused by
 * reference. Switching layers = swapping which [KeyboardLayer] the
 * [KeyGridView] renders; no allocations happen at that point.
 *
 * Long-press alternatives were picked to cover the most common diacritics /
 * variants for each locale. They stay short deliberately (≤6 entries) so the
 * accessory popup fits on screen and doesn't overwhelm the user.
 */
object Layouts {

    // ── Helpers ──────────────────────────────────────────────────────────

    private fun c(
        label: String,
        alt: List<String> = emptyList(),
        sub: String? = null,
        weight: Float = 1f,
    ): Key = Key(
        action = KeyAction.Character(label),
        weight = weight,
        longPress = alt.firstOrNull(),
        longPressAlternatives = alt,
        subLabel = sub,
    )

    private fun spacer(weight: Float): Key =
        // A zero-action "spacer" is not needed; instead we bake horizontal
        // padding into row weight by widening neighbor keys. This helper is
        // reserved for future use.
        Key(action = KeyAction.Character(" "), weight = weight)

    private val shiftKey = Key(action = KeyAction.Shift, weight = 1.5f)
    private val backspaceKey = Key(action = KeyAction.Backspace, weight = 1.5f)
    private val enterKey = Key(action = KeyAction.Enter, weight = 1.8f)
    private val languageKey = Key(action = KeyAction.LanguageSwitch, weight = 1.2f)
    private val spaceKey = Key(action = KeyAction.Space, weight = 5f)
    private val symbolsKey = Key(action = KeyAction.LayerSwitch(LayerKind.SYMBOLS), weight = 1.2f)
    private val alphaFromSymbols = Key(action = KeyAction.LayerSwitch(LayerKind.ALPHA), weight = 1.2f)
    private val symbolsAltKey = Key(action = KeyAction.LayerSwitch(LayerKind.SYMBOLS_ALT), weight = 1.2f)
    private val symbolsMainKey = Key(action = KeyAction.LayerSwitch(LayerKind.SYMBOLS), weight = 1.2f)
    private val commaKey = Key(action = KeyAction.Character(","), weight = 1f, subLabel = null)
    private val periodKey = Key(
        action = KeyAction.Character("."),
        weight = 1f,
        longPress = "…",
        longPressAlternatives = listOf(".", ",", "?", "!", ";", ":"),
    )

    // ── English (QWERTY) ─────────────────────────────────────────────────

    val qwertyEn: KeyboardLayer = KeyboardLayer(
        id = "qwerty_en",
        language = LanguageKind.EN,
        kind = LayerKind.ALPHA,
        rows = listOf(
            KeyRow(
                keys = listOf(
                    c("q", sub = "1", alt = listOf("1")),
                    c("w", sub = "2", alt = listOf("2")),
                    c("e", sub = "3", alt = listOf("3", "é", "è", "ê", "ë", "ē")),
                    c("r", sub = "4", alt = listOf("4")),
                    c("t", sub = "5", alt = listOf("5")),
                    c("y", sub = "6", alt = listOf("6", "ý", "ÿ")),
                    c("u", sub = "7", alt = listOf("7", "ú", "ù", "û", "ü", "ū")),
                    c("i", sub = "8", alt = listOf("8", "í", "ì", "î", "ï", "ī")),
                    c("o", sub = "9", alt = listOf("9", "ó", "ò", "ô", "ö", "ō", "ø")),
                    c("p", sub = "0", alt = listOf("0")),
                ),
            ),
            KeyRow(
                keys = listOf(
                    c("a", alt = listOf("á", "à", "â", "ä", "ã", "å", "ā"), weight = 1f),
                    c("s", alt = listOf("ß", "ś", "š")),
                    c("d", alt = listOf("ď")),
                    c("f"),
                    c("g"),
                    c("h"),
                    c("j"),
                    c("k"),
                    c("l", alt = listOf("ł")),
                ),
            ),
            KeyRow(
                keys = listOf(
                    shiftKey,
                    c("z", alt = listOf("ž", "ź")),
                    c("x"),
                    c("c", alt = listOf("ç", "ć", "č")),
                    c("v"),
                    c("b"),
                    c("n", alt = listOf("ñ", "ń")),
                    c("m"),
                    backspaceKey,
                ),
            ),
            KeyRow(
                heightWeight = Theme.KEY_BOTTOM_ROW_HEIGHT_WEIGHT,
                keys = listOf(
                    symbolsKey,
                    languageKey,
                    commaKey,
                    spaceKey,
                    periodKey,
                    enterKey,
                ),
            ),
        ),
    )

    // ── Russian (ЙЦУКЕН, 12-11-9) ────────────────────────────────────────

    val jcukenRu: KeyboardLayer = KeyboardLayer(
        id = "jcuken_ru",
        language = LanguageKind.RU,
        kind = LayerKind.ALPHA,
        rows = listOf(
            KeyRow(
                keys = listOf(
                    c("й", sub = "1", alt = listOf("1")),
                    c("ц", sub = "2", alt = listOf("2")),
                    c("у", sub = "3", alt = listOf("3")),
                    c("к", sub = "4", alt = listOf("4")),
                    c("е", sub = "5", alt = listOf("5", "ё")),
                    c("н", sub = "6", alt = listOf("6")),
                    c("г", sub = "7", alt = listOf("7")),
                    c("ш", sub = "8", alt = listOf("8", "щ")),
                    c("щ", sub = "9", alt = listOf("9")),
                    c("з", sub = "0", alt = listOf("0")),
                    c("х", alt = listOf("ъ")),
                    c("ъ"),
                ),
            ),
            KeyRow(
                keys = listOf(
                    c("ф"),
                    c("ы"),
                    c("в"),
                    c("а"),
                    c("п"),
                    c("р"),
                    c("о"),
                    c("л"),
                    c("д"),
                    c("ж"),
                    c("э"),
                ),
            ),
            KeyRow(
                keys = listOf(
                    shiftKey,
                    c("я"),
                    c("ч"),
                    c("с"),
                    c("м"),
                    c("и"),
                    c("т"),
                    c("ь", alt = listOf("ъ")),
                    c("б"),
                    c("ю"),
                    backspaceKey,
                ),
            ),
            KeyRow(
                heightWeight = Theme.KEY_BOTTOM_ROW_HEIGHT_WEIGHT,
                keys = listOf(
                    symbolsKey,
                    languageKey,
                    commaKey,
                    spaceKey,
                    periodKey,
                    enterKey,
                ),
            ),
        ),
    )

    // ── Symbols (page 1) ─────────────────────────────────────────────────

    val symbols: KeyboardLayer = KeyboardLayer(
        id = "symbols",
        language = LanguageKind.EN,
        kind = LayerKind.SYMBOLS,
        rows = listOf(
            KeyRow(
                keys = listOf(
                    c("1"), c("2"), c("3"), c("4"), c("5"),
                    c("6"), c("7"), c("8"), c("9"), c("0"),
                ),
            ),
            KeyRow(
                keys = listOf(
                    c("@"), c("#"), c("$"), c("_"), c("&"),
                    c("-"), c("+"), c("("), c(")"), c("/"),
                ),
            ),
            KeyRow(
                keys = listOf(
                    symbolsAltKey,
                    c("*"), c("\""), c("'"), c(":"), c(";"),
                    c("!"), c("?"),
                    backspaceKey,
                ),
            ),
            KeyRow(
                heightWeight = Theme.KEY_BOTTOM_ROW_HEIGHT_WEIGHT,
                keys = listOf(
                    alphaFromSymbols,
                    languageKey,
                    commaKey,
                    spaceKey,
                    periodKey,
                    enterKey,
                ),
            ),
        ),
    )

    // ── Symbols (page 2 / alt) ───────────────────────────────────────────

    val symbolsAlt: KeyboardLayer = KeyboardLayer(
        id = "symbols_alt",
        language = LanguageKind.EN,
        kind = LayerKind.SYMBOLS_ALT,
        rows = listOf(
            KeyRow(
                keys = listOf(
                    c("~"), c("`"), c("|"), c("•"), c("√"),
                    c("π"), c("÷"), c("×"), c("§"), c("Δ"),
                ),
            ),
            KeyRow(
                keys = listOf(
                    c("£"), c("¥"), c("€"), c("^"), c("°"),
                    c("="), c("{"), c("}"), c("\\"), c("%"),
                ),
            ),
            KeyRow(
                keys = listOf(
                    symbolsMainKey,
                    c("<"), c(">"), c("["), c("]"),
                    c("©"), c("®"), c("™"),
                    backspaceKey,
                ),
            ),
            KeyRow(
                heightWeight = Theme.KEY_BOTTOM_ROW_HEIGHT_WEIGHT,
                keys = listOf(
                    alphaFromSymbols,
                    languageKey,
                    commaKey,
                    spaceKey,
                    periodKey,
                    enterKey,
                ),
            ),
        ),
    )

    // ── Numbers (for number-only text fields) ────────────────────────────

    val numbers: KeyboardLayer = KeyboardLayer(
        id = "numbers",
        language = LanguageKind.EN,
        kind = LayerKind.NUMBERS,
        rows = listOf(
            KeyRow(keys = listOf(c("1"), c("2"), c("3"))),
            KeyRow(keys = listOf(c("4"), c("5"), c("6"))),
            KeyRow(keys = listOf(c("7"), c("8"), c("9"))),
            KeyRow(
                keys = listOf(
                    c(","),
                    c("0"),
                    Key(action = KeyAction.Backspace),
                ),
            ),
        ),
    )

    // ── Resolvers ────────────────────────────────────────────────────────

    fun alphaLayerFor(lang: LanguageKind): KeyboardLayer = when (lang) {
        LanguageKind.EN -> qwertyEn
        LanguageKind.RU -> jcukenRu
    }

    fun layerFor(state: KeyboardState): KeyboardLayer = when (state.layer) {
        LayerKind.ALPHA -> alphaLayerFor(state.language)
        LayerKind.SYMBOLS -> symbols
        LayerKind.SYMBOLS_ALT -> symbolsAlt
        LayerKind.NUMBERS -> numbers
    }
}
