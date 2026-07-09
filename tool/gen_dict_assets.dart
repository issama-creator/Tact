// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  writeSpell('en', _enWords, _enNext);
  writeSpell('ru', _ruWords, _ruNext);

  writeTypo('en', _enTypos);
  writeTypo('ru', _ruTypos);

  writePhraseSpell('en', corrections: _enPhraseCorrections, valid: _enPhraseValid);
  writePhraseSpell('ru', corrections: _ruPhraseCorrections, valid: _ruPhraseValid);

  writeMat('en', tokens: _enMatTokens, stems: {});
  writeMat('ru', tokens: _ruMatTokens, stems: _ruMatStems);

  _writeJson('assets/lexicons/en_toxic.json', _enToxic);
  _writeJson('assets/lexicons/ru_toxic.json', _ruToxic);
  _writeJson('assets/shortcuts/builtin.json', _builtinShortcuts);

  print('Dictionary JSON assets generated.');
}

const _enWords = [
  // Core function words
  'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'i',
  'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at',
  'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she',
  'or', 'an', 'will', 'my', 'one', 'all', 'would', 'their', 'what', 'so',
  'up', 'out', 'if', 'about', 'who', 'get', 'which', 'go', 'me', 'when',
  'make', 'can', 'like', 'time', 'no', 'just', 'him', 'know', 'take', 'people',
  'into', 'year', 'your', 'good', 'some', 'could', 'them', 'see', 'other', 'than',
  'then', 'now', 'look', 'only', 'come', 'its', 'over', 'think', 'also', 'back',
  'after', 'use', 'two', 'how', 'our', 'work', 'first', 'well', 'way', 'even',
  'new', 'want', 'because', 'any', 'these', 'give', 'day', 'most', 'us', 'hello',
  // Messaging / chat
  'thanks', 'thank', 'please', 'sorry', 'okay', 'yes', 'yeah', 'sure', 'fine',
  'great', 'nice', 'cool', 'awesome', 'amazing', 'perfect', 'welcome', 'bye',
  'message', 'text', 'chat', 'email', 'call', 'phone', 'meeting', 'today',
  'tomorrow', 'yesterday', 'morning', 'evening', 'night', 'week', 'month',
  'friend', 'team', 'help', 'send', 'check', 'done', 'ready', 'wait', 'soon',
  'later', 'again', 'maybe', 'really', 'very', 'much', 'more', 'less', 'still',
  'already', 'never', 'always', 'every', 'everything', 'something', 'nothing',
  'someone', 'anyone', 'everyone', 'here', 'there', 'where', 'why', 'please',
  'correct', 'wrong', 'right', 'true', 'false', 'idea', 'plan', 'project',
  'update', 'status', 'report', 'issue', 'problem', 'solution', 'answer',
  'question', 'information', 'details', 'document', 'file', 'link', 'share',
  'write', 'read', 'reply', 'forward', 'confirm', 'cancel', 'accept', 'decline',
  'happy', 'sad', 'angry', 'tired', 'busy', 'free', 'available', 'important',
  'urgent', 'quick', 'slow', 'easy', 'hard', 'simple', 'clear', 'understand',
  'agree', 'disagree', 'discuss', 'explain', 'believe', 'hope', 'wish', 'feel',
  'love', 'hate', 'miss', 'meet', 'talk', 'listen', 'hear', 'watch', 'play',
  'learn', 'teach', 'start', 'stop', 'finish', 'continue', 'try', 'need',
  'world', 'life', 'home', 'office', 'company', 'business', 'money', 'price',
  'buy', 'sell', 'pay', 'order', 'delivery', 'address', 'city', 'country',
  'travel', 'trip', 'hotel', 'food', 'water', 'coffee', 'lunch', 'dinner',
  'breakfast', 'health', 'doctor', 'weather', 'rain', 'sun', 'cold', 'warm',
  'keyboard', 'typing', 'spell', 'error', 'mistake', 'improve', 'better',
  'receive', 'believe', 'achieve', 'weird', 'piece', 'their', 'through',
  'though', 'thought', 'enough', 'beautiful', 'definitely', 'absolutely',
  // Slang / messaging (valid spell)
  'gonna', 'wanna', 'kinda', 'lit', 'yeah', 'okay', 'nvm', 'afk', 'irl',
];

const _enPhraseCorrections = {
  'thank yo': 'thank you',
  'thank u': 'thank you',
  'how ar': 'how are',
  'how are yo': 'how are you',
  'good mornin': 'good morning',
  'see yo': 'see you',
  'let me kno': 'let me know',
  'talk to yo': 'talk to you',
  'nice to met': 'nice to meet',
};

const _enPhraseValid = [
  'thank you', 'how are you', 'good morning', 'see you', 'let me know',
  'talk to you', 'nice to meet you', 'have a good day',
];

const _enNext = {
  'hello': ['world', 'there', 'everyone', 'friend', 'team'],
  'thank': ['you', 'thanks', 'so'],
  'good': ['morning', 'evening', 'night', 'luck', 'idea'],
  'how': ['are', 'about', 'much', 'long'],
  'see': ['you', 'ya', 'soon', 'later'],
  'please': ['help', 'send', 'check', 'confirm', 'let'],
  'have': ['a', 'good', 'nice', 'great', 'fun'],
  'let': ['me', 'us', 'know'],
  'looking': ['forward', 'for'],
  'talk': ['soon', 'later', 'to'],
  'nice': ['to', 'day', 'work'],
  'will': ['be', 'do', 'send', 'check', 'let'],
  'can': ['you', 'we', 'i', 'do', 'help'],
  'need': ['to', 'your', 'help', 'more', 'a'],
  'sorry': ['for', 'about', 'to'],
  'thanks': ['for', 'so', 'again'],
};

const _ruWords = [
  // Core
  'и', 'в', 'не', 'на', 'я', 'что', 'он', 'с', 'как', 'а',
  'то', 'все', 'она', 'так', 'но', 'да', 'ты', 'к', 'у', 'же',
  'вы', 'за', 'бы', 'по', 'только', 'мне', 'было', 'вот', 'от', 'меня',
  'еще', 'нет', 'о', 'из', 'ему', 'теперь', 'когда', 'даже', 'ну', 'вам',
  'лет', 'где', 'надо', 'два', 'раз', 'мог', 'себя', 'ничего', 'или', 'их',
  'уже', 'под', 'нам', 'если', 'время', 'очень', 'есть', 'этот', 'тоже', 'жизнь',
  'может', 'без', 'при', 'ладно', 'привет', 'мир', 'спасибо', 'пожалуйста', 'извини', 'хорошо',
  'утро', 'день', 'вечер', 'ночь', 'сегодня', 'завтра', 'друг', 'работа', 'дом', 'город',
  'семья', 'люблю', 'дело', 'человек', 'знаю', 'думаю', 'хочу', 'могу', 'буду', 'здесь',
  'там', 'сейчас', 'потом', 'всегда', 'никогда', 'много', 'мало', 'нужно', 'можно', 'дела',
  // Messaging / chat
  'приветствую', 'здравствуйте', 'доброе', 'добрый', 'доброй', 'пока', 'до', 'свидания',
  'спасибо', 'благодарю', 'извините', 'простите', 'пожалуйста', 'конечно', 'хорошо', 'отлично',
  'супер', 'класс', 'понял', 'поняла', 'ясно', 'окей', 'ок', 'давай', 'ладно', 'хорошо',
  'сообщение', 'текст', 'чат', 'почта', 'звонок', 'телефон', 'встреча', 'неделя', 'месяц',
  'команда', 'помощь', 'отправить', 'проверить', 'готово', 'готов', 'подожди', 'скоро',
  'позже', 'снова', 'может', 'реально', 'очень', 'больше', 'меньше', 'уже', 'еще', 'всегда',
  'никогда', 'каждый', 'все', 'ничего', 'что-то', 'кто-то', 'здесь', 'там', 'где', 'зачем',
  'правильно', 'неправильно', 'верно', 'идея', 'план', 'проект', 'обновление', 'статус',
  'отчет', 'проблема', 'решение', 'ответ', 'вопрос', 'информация', 'детали', 'документ',
  'файл', 'ссылка', 'поделиться', 'написать', 'прочитать', 'ответить', 'переслать',
  'подтвердить', 'отменить', 'принять', 'отказать', 'рад', 'грустно', 'злой', 'устал',
  'занят', 'свободен', 'важно', 'срочно', 'быстро', 'медленно', 'легко', 'сложно',
  'просто', 'понятно', 'согласен', 'обсудить', 'объяснить', 'верю', 'надеюсь', 'чувствую',
  'люблю', 'скучаю', 'встретиться', 'поговорить', 'слушать', 'слышать', 'смотреть', 'играть',
  'учиться', 'начать', 'остановить', 'закончить', 'продолжить', 'попробовать', 'нужен',
  'жизнь', 'офис', 'компания', 'бизнес', 'деньги', 'цена', 'купить', 'продать', 'оплатить',
  'заказ', 'доставка', 'адрес', 'страна', 'путешествие', 'отель', 'еда', 'вода', 'кофе',
  'обед', 'ужин', 'завтрак', 'здоровье', 'врач', 'погода', 'дождь', 'солнце', 'холодно',
  'тепло', 'клавиатура', 'набор', 'ошибка', 'опечатка', 'улучшить', 'лучше', 'получить',
  'красивый', 'определенно', 'абсолютно', 'вообще', 'короче', 'типа', 'норм', 'нормально',
  'ребята', 'друзья', 'коллеги', 'начальник', 'клиент', 'заказчик', 'сервис', 'поддержка',
  // Slang / abbreviations (valid spell)
  'красава', 'чет', 'мск', 'спб', 'рф', 'имхо', 'лол', 'ок',
];

const _ruPhraseCorrections = {
  'как дла': 'как дела',
  'как дел': 'как дела',
  'как ты': 'как дела',
  'добры день': 'добрый день',
  'добро утро': 'доброе утро',
  'спасиб большое': 'спасибо большое',
  'до свидан': 'до свидания',
  'на связ': 'на связи',
};

const _ruPhraseValid = [
  'как дела', 'добрый день', 'доброе утро', 'спасибо большое',
  'до свидания', 'на связи', 'до связи', 'хорошего дня',
];

const _ruNext = {
  'привет': ['мир', 'друг', 'всем', 'как', 'тебя'],
  'доброе': ['утро'],
  'добрый': ['день', 'вечер'],
  'спасибо': ['большое', 'тебе', 'вам', 'за'],
  'как': ['дела', 'ты', 'нас', 'тебя'],
  'буду': ['ждать', 'рад', 'дома', 'скоро'],
  'мне': ['нужно', 'нравится', 'жаль', 'кажется'],
  'до': ['свидания', 'встречи', 'завтра'],
  'хорошего': ['дня', 'вечера'],
  'будет': ['хорошо', 'готово', 'завтра'],
  'давай': ['сделаем', 'попробуем', 'встретимся'],
  'можно': ['попросить', 'уточнить', 'отправить'],
};

const _enTypos = {
  'helo': 'hello', 'helol': 'hello', 'hallo': 'hello', 'teh': 'the',
  'thier': 'their', 'recieve': 'receive', 'becuase': 'because',
  'tommorow': 'tomorrow', 'tommorrow': 'tomorrow', 'gud': 'good',
  'mornin': 'morning', 'thnks': 'thanks', 'thx': 'thanks', 'pls': 'please',
  'plz': 'please', 'sory': 'sorry', 'freind': 'friend', 'wolrd': 'world',
  'peopel': 'people', 'becasue': 'because', 'adn': 'and', 'taht': 'that',
  'wiht': 'with', 'yuo': 'you', 'knwo': 'know', 'wokr': 'work',
  'mesage': 'message', 'keybord': 'keyboard', 'typng': 'typing', 'chekc': 'check',
  'corect': 'correct', 'realy': 'really', 'verry': 'very', 'greate': 'great',
  'agin': 'again', 'sooon': 'soon', 'definately': 'definitely', 'seperate': 'separate',
  'occured': 'occurred', 'accomodate': 'accommodate', 'neccessary': 'necessary',
  'wierd': 'weird', 'beleive': 'believe', 'acheive': 'achieve', 'untill': 'until',
  'alot': 'a lot', 'u': 'you', 'ur': 'your', 'r': 'are',
  'tmrw': 'tomorrow', 'msg': 'message', 'thnx': 'thanks',
  'probly': 'probably', 'prolly': 'probably',
  'afk': 'afk', 'irl': 'irl', 'dm': 'dm', 'pm': 'pm', 'ttyl': 'ttyl',
};

const _ruTypos = {
  'превед': 'привет', 'привте': 'привет', 'привтеи': 'привет', 'прив': 'привет',
  'спосибо': 'спасибо', 'спосиба': 'спасибо', 'спсибо': 'спасибо',
  'пожалуста': 'пожалуйста', 'пожалйста': 'пожалуйста', 'извените': 'извините',
  'извени': 'извини', 'сегодн': 'сегодня', 'завтр': 'завтра', 'собщение': 'сообщение',
  'сообщене': 'сообщение', 'отправит': 'отправить', 'клавиатур': 'клавиатура',
  'проверк': 'проверка', 'ошбика': 'ошибка', 'добро': 'доброе', 'добры': 'добрый',
  'утр': 'утро', 'вечр': 'вечер', 'ноч': 'ночь', 'длеа': 'дела', 'хорош': 'хорошо',
  'потмо': 'потом', 'всегад': 'всегда', 'никогад': 'никогда', 'работ': 'работа',
  'горд': 'город', 'любл': 'люблю', 'дума': 'думаю', 'зна': 'знаю', 'хоч': 'хочу',
  'буд': 'буду', 'здраствуйте': 'здравствуйте', 'здраствуй': 'здравствуй',
  'пожалуйсто': 'пожалуйста', 'инфа': 'информация', 'щас': 'сейчас', 'чё': 'что',
  'чо': 'что', 'норм': 'нормально',   'спс': 'спасибо', 'пж': 'пожалуйста', 'мск': 'мск', 'спб': 'спб', 'рф': 'рф',
};

const _enMatTokens = {
  'crap', 'shit', 'fuck', 'fuk', 'fck', 'ass', 'bitch', 'bastard',
  'dick', 'piss', 'slut', 'whore', 'bollocks', 'wanker', 'arse', 'twat', 'cock', 'cunt',
};

const _ruMatTokens = {
  'хуй', 'хуи', 'хуя', 'хуе', 'хуем', 'блядь', 'блят', 'сука', 'суки',
  'пизда', 'ебать', 'ебал', 'ебло', 'ебли', 'мудак', 'мудил', 'чмо', 'пидор', 'пидр',
};

const _ruMatStems = {
  'пизд', 'ебан', 'говн', 'дерьм', 'залуп', 'шлюх', 'мраз', 'бля', 'сук',
};

final _enToxic = {
  'v': 1,
  'locale': 'en',
  'warning': 50,
  'conflict': 75,
  'entries': {
    'stupid': {'s': 55, 'c': 'insult'},
    'idiot': {'s': 70, 'c': 'insult'},
    'moron': {'s': 65, 'c': 'insult'},
    'kill': {'s': 78, 'c': 'hostile'},
    'loser': {'s': 58, 'c': 'insult'},
    'shutup': {'s': 52, 'c': 'dismissive'},
    'dumb': {'s': 54, 'c': 'insult'},
    'trash': {'s': 56, 'c': 'insult'},
    'worthless': {'s': 68, 'c': 'insult'},
    'pathetic': {'s': 62, 'c': 'insult'},
    'disgusting': {'s': 57, 'c': 'insult'},
    'freak': {'s': 59, 'c': 'insult'},
    'jerk': {'s': 53, 'c': 'insult'},
    'nasty': {'s': 55, 'c': 'aggressive'},
    'damn': {'s': 42, 'c': 'aggressive'},
    'hell': {'s': 40, 'c': 'aggressive'},
  },
  'phrases': {
    'shut up': {'s': 55, 'c': 'dismissive'},
    'go die': {'s': 80, 'c': 'hostile'},
    'hate you': {'s': 72, 'c': 'hostile'},
    'kill yourself': {'s': 90, 'c': 'hostile'},
    'you suck': {'s': 62, 'c': 'insult'},
    'get lost': {'s': 58, 'c': 'dismissive'},
    'nobody cares': {'s': 60, 'c': 'dismissive'},
  },
};

final _ruToxic = {
  'v': 1,
  'locale': 'ru',
  'warning': 50,
  'conflict': 75,
  'entries': {
    'дурак': {'s': 60, 'c': 'insult'},
    'идиот': {'s': 75, 'c': 'insult'},
    'тупой': {'s': 58, 'c': 'insult'},
    'тупица': {'s': 56, 'c': 'insult'},
    'ненавижу': {'s': 70, 'c': 'hostile'},
    'убью': {'s': 85, 'c': 'hostile'},
    'сдохни': {'s': 88, 'c': 'hostile'},
    'урод': {'s': 65, 'c': 'insult'},
    'отвали': {'s': 55, 'c': 'dismissive'},
    'заткнись': {'s': 62, 'c': 'dismissive'},
    'мразь': {'s': 72, 'c': 'insult'},
    'скотина': {'s': 68, 'c': 'insult'},
    'придурок': {'s': 64, 'c': 'insult'},
    'козел': {'s': 58, 'c': 'insult'},
    'дебил': {'s': 66, 'c': 'insult'},
    'лох': {'s': 54, 'c': 'insult'},
    'жалкий': {'s': 57, 'c': 'insult'},
    'гад': {'s': 59, 'c': 'insult'},
    'ублюдок': {'s': 80, 'c': 'hostile'},
    'мерзавец': {'s': 63, 'c': 'insult'},
    'долбоеб': {'s': 82, 'c': 'insult'},
    'кретин': {'s': 60, 'c': 'insult'},
  },
  'phrases': {
    'ненавижу тебя': {'s': 78, 'c': 'hostile'},
    'иди нахуй': {'s': 90, 'c': 'hostile'},
    'заткнись уже': {'s': 60, 'c': 'dismissive'},
    'ты идиот': {'s': 76, 'c': 'insult'},
    'пошел вон': {'s': 58, 'c': 'dismissive'},
    'отстань': {'s': 62, 'c': 'dismissive'},
    'надоел уже': {'s': 65, 'c': 'dismissive'},
  },
};

final _builtinShortcuts = {
  'v': 1,
  'locale_default': 'ru',
  'shortcuts': [
    {'trigger': 'др', 'expansions': ['Добрый день', 'Доброе утро', 'Добрый вечер']},
    {'trigger': 'пж', 'expansions': ['пожалуйста']},
    {'trigger': 'пжлст', 'expansions': ['пожалуйста']},
    {'trigger': 'спс', 'expansions': ['спасибо']},
    {'trigger': 'спасиб', 'expansions': ['спасибо']},
    {'trigger': 'имхо', 'expansions': ['имхо']},
    {'trigger': 'кст', 'expansions': ['кстати']},
    {'trigger': 'лол', 'expansions': ['лол']},
    {'trigger': 'омг', 'expansions': ['о боже']},
    {'trigger': 'мб', 'expansions': ['может быть']},
    {'trigger': 'нзч', 'expansions': ['не за что']},
    {'trigger': 'ок', 'expansions': ['окей']},
    {'trigger': 'т.к.', 'expansions': ['так как']},
    {'trigger': 'т.д.', 'expansions': ['так далее']},
    {'trigger': 'т.п.', 'expansions': ['тому подобное']},
    {'trigger': 'т.е.', 'expansions': ['то есть']},
    {'trigger': 'thx', 'expansions': ['thanks', 'thank you']},
    {'trigger': 'pls', 'expansions': ['please']},
    {'trigger': 'ty', 'expansions': ['thank you']},
    {'trigger': 'btw', 'expansions': ['by the way']},
    {'trigger': 'imo', 'expansions': ['in my opinion']},
    {'trigger': 'omg', 'expansions': ['oh my god']},
    {'trigger': 'lol', 'expansions': ['lol']},
    {'trigger': 'brb', 'expansions': ['be right back']},
    {'trigger': 'idk', 'expansions': ['I do not know']},
    {'trigger': 'tbh', 'expansions': ['to be honest']},
    {'trigger': 'np', 'expansions': ['no problem']},
    {'trigger': 'asap', 'expansions': ['as soon as possible']},
    {'trigger': 'fyi', 'expansions': ['for your information']},
    {'trigger': 'rn', 'expansions': ['right now']},
    {'trigger': 'nvm', 'expansions': ['never mind']},
    {'trigger': 'lmk', 'expansions': ['let me know']},
    {'trigger': 'gtg', 'expansions': ['got to go']},
    {'trigger': 'ttyl', 'expansions': ['talk to you later']},
    {'trigger': 'c u', 'expansions': ['see you']},
    {'trigger': 'до связи', 'expansions': ['до связи']},
    {'trigger': 'на связи', 'expansions': ['на связи']},
  ],
};

void writeSpell(
  String locale,
  List<String> words,
  Map<String, List<String>> next,
) {
  final unique = <String>{};
  final ordered = <String>[];
  for (final w in words) {
    final key = w.toLowerCase();
    if (unique.add(key)) ordered.add(key);
  }

  final freq = <String, int>{};
  for (var i = 0; i < ordered.length; i++) {
    final w = ordered[i];
    if (i < 20) {
      freq[w] = 1000 - i * 10;
    } else if (i < 100) {
      freq[w] = 500 - (i - 20);
    } else {
      freq[w] = 200 - (i - 100).clamp(0, 150);
    }
    if (freq[w]! < 10) freq[w] = 10;
  }

  _writeJson('assets/dictionaries/${locale}_spell.json', {
    'v': 1,
    'locale': locale,
    'words': ordered,
    'next': next,
    'freq': freq,
  });
}

void writePhraseSpell(
  String locale, {
  required Map<String, String> corrections,
  required List<String> valid,
}) {
  _writeJson('assets/dictionaries/${locale}_phrases_spell.json', {
    'v': 1,
    'locale': locale,
    'corrections': corrections,
    'valid': valid,
  });
}

void writeTypo(String locale, Map<String, String> corrections) {
  _writeJson('assets/dictionaries/${locale}_typo.json', {
    'v': 1,
    'locale': locale,
    'corrections': corrections,
  });
}

void writeMat(
  String locale, {
  required Set<String> tokens,
  required Set<String> stems,
}) {
  final list = tokens.toList()..sort();
  final stemList = stems.toList()..sort();
  _writeJson('assets/lexicons/${locale}_mat.json', {
    'v': 1,
    'locale': locale,
    'tokens': list,
    if (stemList.isNotEmpty) 'stems': stemList,
  });
}

void _writeJson(String path, Object data) {
  File(path).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
}
