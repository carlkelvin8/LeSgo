/// How IBOW feels about what was just said. Drives the avatar's face.
enum IbowExpression { neutral, happy, sad, surprised, love, wink, sleepy }

/// Parses a tag like "happy" or "[mood:sad]". Unknown tags return null.
IbowExpression? ibowExpressionFromTag(String? tag) {
  if (tag == null) return null;
  final t = tag
      .toLowerCase()
      .replaceAll(RegExp(r'[\[\]\s]'), '')
      .replaceFirst('mood:', '');
  for (final e in IbowExpression.values) {
    if (e.name == t) return e;
  }
  return null;
}

/// Splits a leading "[mood:happy]" tag off a model reply.
({IbowExpression? mood, String text}) splitMoodTag(String reply) {
  final m = RegExp(r'^\s*\[mood:\s*([a-z]+)\s*\]\s*', caseSensitive: false)
      .firstMatch(reply);
  if (m == null) return (mood: null, text: reply.trim());
  return (
    mood: ibowExpressionFromTag(m.group(1)),
    text: reply.substring(m.end).trim(),
  );
}

/// A reasonable face for a reply when nothing set one explicitly.
IbowExpression guessExpression(String text) {
  final t = text.toLowerCase();
  bool has(List<String> words) => words.any(t.contains);
  if (has(['sorry', 'unfortunately', 'could not', "couldn't", 'cannot', "can't",
      'hindi ko', 'pasensya', 'failed', 'no active'])) {
    return IbowExpression.sad;
  }
  if (has(['congrat', 'enjoy', 'love', 'salamat', 'thank you', 'thanks'])) {
    return IbowExpression.love;
  }
  if (has(['done', 'cancelled', 'canceled', 'placed', 'success', 'all set',
      'great', 'glad', 'welcome', 'hi!', 'hello', 'kumusta'])) {
    return IbowExpression.happy;
  }
  if (has(['wow', 'whoa', 'surpris'])) return IbowExpression.surprised;
  return IbowExpression.neutral;
}
