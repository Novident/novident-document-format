/// [UniversalValue] represents a [Node] that could contain a useful content value
/// that probably will used by the [Compiler] to transform projects to another
/// file type(pdf, word, latex, etc)
mixin UniversalValue<T> {
  /// The value that is contained by the [Node]
  T get value;
}
