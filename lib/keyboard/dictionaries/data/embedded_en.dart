/// Embedded English dictionary — sync fallback, expand via assets/dictionaries/en_spell.json.
library;

/// High-frequency English tokens for membership + prefix autocomplete (~200).
const List<String> embeddedEnWords = [
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
  // greetings / goo* / tha* / hel*
  'hi', 'hey', 'thanks', 'thank', 'please', 'sorry', 'welcome', 'bye', 'goodbye',
  'goodmorning', 'goodevening', 'goodnight', 'goodness', 'goodbye',
  'morning', 'evening', 'night', 'today', 'tomorrow', 'yesterday',
  'help', 'helpful', 'helping', 'hello', 'hell',
  // common verbs
  'send', 'sending', 'sent', 'check', 'checking', 'call', 'calling', 'called',
  'write', 'writing', 'written', 'read', 'reading', 'reply', 'replied',
  'meet', 'meeting', 'wait', 'waiting', 'need', 'needed', 'needs',
  'want', 'wanted', 'wants', 'know', 'known', 'knows', 'think', 'thinking',
  'look', 'looking', 'come', 'coming', 'going', 'gone', 'make', 'making',
  'take', 'taking', 'give', 'giving', 'find', 'finding', 'found',
  // adjectives
  'great', 'greater', 'greatest', 'nice', 'nicer', 'okay', 'ok', 'fine',
  'important', 'urgent', 'ready', 'busy', 'free', 'available', 'possible',
  'better', 'best', 'worse', 'worst', 'small', 'smaller', 'large', 'larger',
  'quick', 'quickly', 'slow', 'slowly', 'easy', 'hard', 'sure', 'maybe',
  // nouns / messaging
  'message', 'messages', 'text', 'email', 'mail', 'phone', 'number', 'chat',
  'question', 'answer', 'problem', 'solution', 'idea', 'plan', 'project',
  'team', 'office', 'home', 'street', 'city', 'country', 'friend', 'family',
  'mom', 'dad', 'brother', 'sister', 'colleague', 'client', 'boss',
  'file', 'document', 'link', 'photo', 'video', 'money', 'price', 'order',
  'week', 'month', 'year', 'hour', 'minute', 'monday', 'tuesday', 'wednesday',
  'thursday', 'friday', 'saturday', 'sunday',
  // more prefixes
  'something', 'someone', 'somewhere', 'sometime', 'somehow',
  'everything', 'everyone', 'everywhere', 'nothing', 'nobody',
  'because', 'before', 'between', 'behind', 'beyond',
  'through', 'though', 'thought', 'together', 'toward', 'towards',
  'really', 'right', 'wrong', 'already', 'always', 'never', 'often',
  'should', 'would', 'could', 'shall', 'might', 'must',
  'information', 'details', 'update', 'status', 'report',
];

const Map<String, List<String>> embeddedEnNext = {
  'hello': ['world', 'there', 'everyone', 'friend'],
  'thank': ['you', 'thanks', 'so'],
  'good': ['morning', 'evening', 'night', 'luck'],
  'how': ['are', 'about', 'much'],
  'see': ['you', 'ya', 'soon'],
  'please': ['help', 'send', 'check'],
};
