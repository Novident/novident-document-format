/// Default constants for the Novident document format.
class NovidentDefaults {
  NovidentDefaults._();

  /// Special section ID that means "use the structured-based section"
  /// (i.e., determine the section from the node's tree depth).
  static const String kStructuredBasedSectionId = 'structured-based';

  /// Default name for the research folder.
  static const String kDefaultResearchName = 'Research';

  /// Default name for the trash folder.
  static const String kDefaultTrashName = 'Trash';

  /// Default name for the templates folder.
  static const String kDefaultTemplatesName = 'Templates';
}
