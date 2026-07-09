/// Embedded mat and toxic lexicons — normalized tokens, O(1) membership.
library;

import '../../engines/shortcut_table.dart';
import '../mat_lexicon.dart';
import '../toxic_category.dart';

/// Profanity lexicon — exact tokens (EN mild words moved to toxic only).
const Set<String> embeddedMatEn = {
  'crap',
  'shit',
  'fuck',
  'fuk',
  'fck',
  'ass',
  'bitch',
  'bastard',
  'dick',
  'piss',
  'slut',
  'whore',
  'bollocks',
  'wanker',
  'arse',
  'twat',
  'cock',
  'cunt',
};

const Set<String> embeddedMatEnStems = {};

/// RU exact profanity tokens.
const Set<String> embeddedMatRu = {
  'хуй',
  'хуи',
  'хуя',
  'хуе',
  'хуем',
  'блядь',
  'блят',
  'сука',
  'суки',
  'пизда',
  'ебать',
  'ебал',
  'ебло',
  'ебли',
  'мудак',
  'мудил',
  'чмо',
  'пидор',
  'пидр',
};

/// RU morphological stems — prefix match via [MatLexicon].
const Set<String> embeddedMatRuStems = {
  'пизд',
  'ебан',
  'говн',
  'дерьм',
  'залуп',
  'шлюх',
  'мраз',
  'бля',
  'сук',
};

final MatLexicon embeddedMatEnLexicon = MatLexicon.fromParts(
  tokens: embeddedMatEn,
  stems: embeddedMatEnStems,
);

final MatLexicon embeddedMatRuLexicon = MatLexicon.fromParts(
  tokens: embeddedMatRu,
  stems: embeddedMatRuStems,
);

final ToxicLexicon embeddedToxicEnLexicon = ToxicLexicon.fromEntries(
  {
    'stupid': const ToxicEntry(score: 55, category: ToxicCategory.insult),
    'idiot': const ToxicEntry(score: 70, category: ToxicCategory.insult),
    'moron': const ToxicEntry(score: 65, category: ToxicCategory.insult),
    'kill': const ToxicEntry(score: 78, category: ToxicCategory.hostile),
    'loser': const ToxicEntry(score: 58, category: ToxicCategory.insult),
    'shutup': const ToxicEntry(score: 52, category: ToxicCategory.dismissive),
    'dumb': const ToxicEntry(score: 54, category: ToxicCategory.insult),
    'trash': const ToxicEntry(score: 56, category: ToxicCategory.insult),
    'worthless': const ToxicEntry(score: 68, category: ToxicCategory.insult),
    'pathetic': const ToxicEntry(score: 62, category: ToxicCategory.insult),
    'disgusting': const ToxicEntry(score: 57, category: ToxicCategory.insult),
    'freak': const ToxicEntry(score: 59, category: ToxicCategory.insult),
    'jerk': const ToxicEntry(score: 53, category: ToxicCategory.insult),
    'nasty': const ToxicEntry(score: 55, category: ToxicCategory.aggressive),
    'damn': const ToxicEntry(score: 42, category: ToxicCategory.aggressive),
    'hell': const ToxicEntry(score: 40, category: ToxicCategory.aggressive),
  },
  phrases: {
    'shut up': const ToxicEntry(score: 55, category: ToxicCategory.dismissive),
    'go die': const ToxicEntry(score: 80, category: ToxicCategory.hostile),
    'hate you': const ToxicEntry(score: 72, category: ToxicCategory.hostile),
  },
);

final ToxicLexicon embeddedToxicRuLexicon = ToxicLexicon.fromEntries(
  {
    'дурак': const ToxicEntry(score: 60, category: ToxicCategory.insult),
    'идиот': const ToxicEntry(score: 75, category: ToxicCategory.insult),
    'тупой': const ToxicEntry(score: 58, category: ToxicCategory.insult),
    'тупица': const ToxicEntry(score: 56, category: ToxicCategory.insult),
    'ненавижу': const ToxicEntry(score: 70, category: ToxicCategory.hostile),
    'убью': const ToxicEntry(score: 85, category: ToxicCategory.hostile),
    'сдохни': const ToxicEntry(score: 88, category: ToxicCategory.hostile),
    'урод': const ToxicEntry(score: 65, category: ToxicCategory.insult),
    'отвали': const ToxicEntry(score: 55, category: ToxicCategory.dismissive),
    'заткнись': const ToxicEntry(score: 62, category: ToxicCategory.dismissive),
    'мразь': const ToxicEntry(score: 72, category: ToxicCategory.insult),
    'скотина': const ToxicEntry(score: 68, category: ToxicCategory.insult),
    'придурок': const ToxicEntry(score: 64, category: ToxicCategory.insult),
    'козел': const ToxicEntry(score: 58, category: ToxicCategory.insult),
    'дебил': const ToxicEntry(score: 66, category: ToxicCategory.insult),
    'лох': const ToxicEntry(score: 54, category: ToxicCategory.insult),
    'жалкий': const ToxicEntry(score: 57, category: ToxicCategory.insult),
    'гад': const ToxicEntry(score: 59, category: ToxicCategory.insult),
    'ублюдок': const ToxicEntry(score: 80, category: ToxicCategory.hostile),
    'мерзавец': const ToxicEntry(score: 63, category: ToxicCategory.insult),
  },
  phrases: {
    'ненавижу тебя': const ToxicEntry(score: 78, category: ToxicCategory.hostile),
    'иди нахуй': const ToxicEntry(score: 90, category: ToxicCategory.hostile),
    'заткнись уже': const ToxicEntry(score: 60, category: ToxicCategory.dismissive),
  },
);

/// Built-in shortcuts — user hotwords always override these.
const Map<String, TextShortcut> embeddedBuiltinShortcuts = {
  'др': TextShortcut(
    trigger: 'др',
    expansions: ['Добрый день', 'Доброе утро', 'Добрый вечер'],
  ),
  'пж': TextShortcut(trigger: 'пж', expansions: ['пожалуйста']),
  'спс': TextShortcut(trigger: 'спс', expansions: ['спасибо']),
  'имхо': TextShortcut(trigger: 'имхо', expansions: ['имхо']),
  'кст': TextShortcut(trigger: 'кст', expansions: ['кстати']),
  'лол': TextShortcut(trigger: 'лол', expansions: ['лол']),
  'омг': TextShortcut(trigger: 'омг', expansions: ['о боже']),
  'т.к.': TextShortcut(trigger: 'т.к.', expansions: ['так как']),
  'т.д.': TextShortcut(trigger: 'т.д.', expansions: ['так далее']),
  'т.п.': TextShortcut(trigger: 'т.п.', expansions: ['тому подобное']),
  'thx': TextShortcut(trigger: 'thx', expansions: ['thanks']),
  'pls': TextShortcut(trigger: 'pls', expansions: ['please']),
  'btw': TextShortcut(trigger: 'btw', expansions: ['by the way']),
  'imo': TextShortcut(trigger: 'imo', expansions: ['in my opinion']),
  'omg': TextShortcut(trigger: 'omg', expansions: ['oh my god']),
  'lol': TextShortcut(trigger: 'lol', expansions: ['lol']),
  'brb': TextShortcut(trigger: 'brb', expansions: ['be right back']),
  'idk': TextShortcut(trigger: 'idk', expansions: ['I do not know']),
  'tbh': TextShortcut(trigger: 'tbh', expansions: ['to be honest']),
  'np': TextShortcut(trigger: 'np', expansions: ['no problem']),
};

/// Legacy thresholds — prefer [ToxicLexicon] per-locale thresholds.
const int toxicWarningThreshold = 50;
const int toxicConflictThreshold = 75;
