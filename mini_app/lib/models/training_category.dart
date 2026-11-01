/// Категории упражнений.
enum TrainingCategory {
  word(
    apiValue: 'word',
    label: 'Слова',
    description: '1 слово',
    title: 'Слово',
  ),
  phrase(
    apiValue: 'phrase',
    label: 'Словосочетания',
    description: '2–3 слова',
    title: 'Словосочетание',
  ),
  sentence(
    apiValue: 'sentence',
    label: 'Предложения',
    description: '4–6 слов',
    title: 'Предложение',
  );

  const TrainingCategory({
    required this.apiValue,
    required this.label,
    required this.description,
    required this.title,
  });

  final String apiValue;
  final String label;
  final String description;
  final String title;

  static TrainingCategory fromApi(Object? value) {
    for (final TrainingCategory category in TrainingCategory.values) {
      if (category.apiValue == value) {
        return category;
      }
    }
    return TrainingCategory.word;
  }
}
