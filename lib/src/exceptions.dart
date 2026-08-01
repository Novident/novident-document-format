/// Thrown when a JSON map cannot be deserialized to the expected node type.
class IllegalTypeConvertionException implements Exception {
  /// The expected types.
  final List<Type> type;

  /// The type that was actually found, if any.
  final String? founded;

  const IllegalTypeConvertionException({
    required this.type,
    required this.founded,
  });

  @override
  String toString() {
    return 'IllegalTypeConvertionException: '
        'expected one of $type, but found $founded';
  }
}
