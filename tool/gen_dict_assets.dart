// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  writeSpell('en', [
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
  ], {
    'hello': ['world', 'there', 'everyone', 'friend'],
    'thank': ['you', 'thanks', 'so'],
    'good': ['morning', 'evening', 'night', 'luck'],
    'how': ['are', 'about', 'much'],
    'see': ['you', 'ya', 'soon'],
    'please': ['help', 'send', 'check'],
  });

  writeSpell('ru', [
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
  ], {
    'привет': ['мир', 'друг', 'всем', 'как'],
    'доброе': ['утро'],
    'добрый': ['день', 'вечер'],
    'спасибо': ['большое', 'тебе', 'вам'],
    'как': ['дела', 'ты', 'нас'],
    'буду': ['ждать', 'рад', 'дома'],
    'мне': ['нужно', 'нравится', 'жаль'],
  });

  writeTypo('en', {
    'helo': 'hello', 'helol': 'hello', 'hallo': 'hello', 'teh': 'the',
    'thier': 'their', 'recieve': 'receive', 'becuase': 'because',
    'tommorow': 'tomorrow', 'tommorrow': 'tomorrow', 'gud': 'good',
    'mornin': 'morning', 'thnks': 'thanks', 'thx': 'thanks', 'pls': 'please',
    'plz': 'please', 'sory': 'sorry', 'freind': 'friend', 'wolrd': 'world',
    'peopel': 'people', 'becasue': 'because', 'adn': 'and', 'taht': 'that',
    'wiht': 'with', 'yuo': 'you', 'dont': 'done', 'knwo': 'know', 'wokr': 'work',
    'mesage': 'message', 'keybord': 'keyboard', 'typng': 'typing', 'chekc': 'check',
    'corect': 'correct', 'realy': 'really', 'verry': 'very', 'greate': 'great',
    'agin': 'again', 'sooon': 'soon',
  });

  writeTypo('ru', {
    'превед': 'привет', 'привте': 'привет', 'привтеи': 'привет', 'прив': 'привет',
    'спосибо': 'спасибо', 'спосиба': 'спасибо', 'спсибо': 'спасибо',
    'пожалуста': 'пожалуйста', 'пожалйста': 'пожалуйста', 'извените': 'извините',
    'извени': 'извини', 'сегодн': 'сегодня', 'завтр': 'завтра', 'собщение': 'сообщение',
    'сообщене': 'сообщение', 'отправит': 'отправить', 'клавиатур': 'клавиатура',
    'проверк': 'проверка', 'ошбика': 'ошибка', 'добро': 'доброе', 'добры': 'добрый',
    'утр': 'утро', 'вечр': 'вечер', 'ноч': 'ночь', 'длеа': 'дела', 'хорош': 'хорошо',
    'потмо': 'потом', 'всегад': 'всегда', 'никогад': 'никогда', 'работ': 'работа',
    'горд': 'город', 'любл': 'люблю', 'дума': 'думаю', 'зна': 'знаю', 'хоч': 'хочу',
    'буд': 'буду',
  });

  writeMat('en', {
    'damn', 'hell', 'crap', 'shit', 'fuck', 'fuk', 'fck', 'ass', 'bitch', 'bastard',
    'dick', 'piss', 'slut', 'whore', 'bollocks', 'wanker', 'arse', 'twat', 'cock', 'cunt',
  });
  writeMat('ru', {
    'хуй', 'хуи', 'хуя', 'хуе', 'хуем', 'бля', 'блядь', 'блят', 'сука', 'суки', 'сук',
    'пизд', 'пизда', 'ебан', 'ебать', 'ебал', 'ебло', 'ебли', 'мудак', 'мудил', 'дерьм',
    'говн', 'залуп', 'чмо', 'пидор', 'пидр', 'шлюх', 'мраз',
  });

  _writeJson('assets/lexicons/en_toxic.json', {
    'v': 1,
    'locale': 'en',
    'warning': 50,
    'conflict': 75,
    'entries': {
      'stupid': {'s': 55, 'c': 'insult'},
      'idiot': {'s': 70, 'c': 'insult'},
      'moron': {'s': 65, 'c': 'insult'},
      'hate': {'s': 60, 'c': 'hostile'},
      'kill': {'s': 75, 'c': 'hostile'},
      'die': {'s': 72, 'c': 'hostile'},
      'loser': {'s': 58, 'c': 'insult'},
      'ugly': {'s': 50, 'c': 'insult'},
      'shutup': {'s': 52, 'c': 'dismissive'},
      'dumb': {'s': 54, 'c': 'insult'},
      'trash': {'s': 56, 'c': 'insult'},
      'worthless': {'s': 68, 'c': 'insult'},
      'pathetic': {'s': 62, 'c': 'insult'},
      'disgusting': {'s': 57, 'c': 'insult'},
      'annoying': {'s': 51, 'c': 'dismissive'},
      'freak': {'s': 59, 'c': 'insult'},
      'jerk': {'s': 53, 'c': 'insult'},
      'nasty': {'s': 55, 'c': 'aggressive'},
      'rude': {'s': 52, 'c': 'aggressive'},
    },
  });

  _writeJson('assets/lexicons/ru_toxic.json', {
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
    },
  });

  _writeJson('assets/shortcuts/builtin.json', {
    'v': 1,
    'locale_default': 'ru',
    'shortcuts': [
      {'trigger': 'др', 'expansions': ['Добрый день', 'Доброе утро', 'Добрый вечер']},
      {'trigger': 'пж', 'expansions': ['пожалуйста']},
      {'trigger': 'спс', 'expansions': ['спасибо']},
      {'trigger': 'имхо', 'expansions': ['имхо']},
      {'trigger': 'кст', 'expansions': ['кстати']},
      {'trigger': 'лол', 'expansions': ['лол']},
      {'trigger': 'омг', 'expansions': ['о боже']},
      {'trigger': 'т.к.', 'expansions': ['так как']},
      {'trigger': 'т.д.', 'expansions': ['так далее']},
      {'trigger': 'т.п.', 'expansions': ['тому подобное']},
      {'trigger': 'thx', 'expansions': ['thanks']},
      {'trigger': 'pls', 'expansions': ['please']},
      {'trigger': 'btw', 'expansions': ['by the way']},
      {'trigger': 'imo', 'expansions': ['in my opinion']},
      {'trigger': 'omg', 'expansions': ['oh my god']},
      {'trigger': 'lol', 'expansions': ['lol']},
      {'trigger': 'brb', 'expansions': ['be right back']},
      {'trigger': 'idk', 'expansions': ['I do not know']},
      {'trigger': 'tbh', 'expansions': ['to be honest']},
      {'trigger': 'np', 'expansions': ['no problem']},
    ],
  });

  print('Dictionary JSON assets generated.');
}

void writeSpell(
  String locale,
  List<String> words,
  Map<String, List<String>> next,
) {
  _writeJson('assets/dictionaries/${locale}_spell.json', {
    'v': 1,
    'locale': locale,
    'words': words,
    'next': next,
  });
}

void writeTypo(String locale, Map<String, String> corrections) {
  _writeJson('assets/dictionaries/${locale}_typo.json', {
    'v': 1,
    'locale': locale,
    'corrections': corrections,
  });
}

void writeMat(String locale, Set<String> tokens) {
  final list = tokens.toList()..sort();
  _writeJson('assets/lexicons/${locale}_mat.json', {
    'v': 1,
    'locale': locale,
    'tokens': list,
  });
}

void _writeJson(String path, Object data) {
  File(path).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
}
