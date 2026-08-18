/// The three static Training rows from CLAUDE.md. Copy and links sourced
/// from grieffirstaid.au/training/ — update here if the source page changes.
class TrainingRow {
  const TrainingRow({required this.title, required this.description, required this.url});

  final String title;
  final String description;
  final String url;
}

const trainingRows = [
  TrainingRow(
    title: 'For individuals',
    description: 'Public courses teaching compassionate, non-clinical support skills for '
        'people experiencing loss.',
    url: 'https://grieffirstaid.au/training/#individuals',
  ),
  TrainingRow(
    title: 'For workplaces',
    description: 'Team and manager training focused on confident, consistent grief '
        'response, aligned with psychosocial safety standards.',
    url: 'https://grieffirstaid.au/training/#workplaces',
  ),
  TrainingRow(
    title: 'For instructors',
    description: 'Licensed Instructor accreditation with curriculum, resources, and '
        'marketing support.',
    url: 'https://grieffirstaid.au/training/#instructors',
  ),
];
