enum Profession {
  psychologist('psychologist', 'Psychologist'),
  counsellor('counsellor', 'Counsellor'),
  psychotherapist('psychotherapist', 'Psychotherapist'),
  socialWorker('social_worker', 'Social Worker'),
  griefEducator('grief_educator', 'Grief Educator'),
  other('other', 'Other');

  const Profession(this.key, this.label);

  final String key;
  final String label;

  static Profession fromKey(String key) => Profession.values.firstWhere((profession) => profession.key == key);
}
