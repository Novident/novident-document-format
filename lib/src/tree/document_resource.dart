import 'package:meta/meta.dart';
import 'package:novident_nodes/novident_nodes.dart';
import 'package:novident_tree_view/novident_tree_view.dart';

import '../trash/node_trashed_options.dart';
import '../exceptions.dart';
import '../interfaces/interfaces.dart';
import '../utils/node_extensions.dart';

/// DocumentResource represents a simple type of node
/// that just contains a resource value
final class DocumentResource extends Node
    with
        UniversalValue<String>,
        UniversalName,
        Trashable,
        UniversalResource,
        SpecialFolderBehavior,
        DragAndDropMixin {
  final String name;
  final String extension;
  final String path;
  final NodeTrashedOptions trashOptions;

  DocumentResource({
    required super.details,
    required this.path,
    required this.name,
    required this.extension,
    this.trashOptions = const NodeTrashedOptions.nonTrashed(),
  });

  DocumentResource._internal()
      : path = '',
        name = '',
        extension = '',
        trashOptions = const NodeTrashedOptions.nonTrashed(),
        super(details: NodeDetails.zero());

  @override
  NodeTrashedOptions get trashStatus => trashOptions;

  // Cannot be never into Manuscript folders
  @override
  bool get canMoveIntoSpecialFolders => false;

  @override
  bool get canMoveIntoAnotherFolders => true;

  @override
  bool isDraggable() => true;

  @override
  bool isDropIntoAllowed() => !isTrashed;

  @override
  bool isDropPositionValid(Node draggedNode, DropPosition dropPosition) {
    return dropPosition == DropPosition.above ||
        dropPosition == DropPosition.below;
  }

  @override
  bool isDropTarget() => !isTrashed;

  @override
  Node unsetTrashState() {
    return copyWith(trashOptions: NodeTrashedOptions.nonTrashed());
  }

  @override
  DocumentResource setTrashState({
    DateTime? expire,
    int end = NodeTrashedOptions.kDefaultExpireDays,
  }) {
    return copyWith(
      trashOptions: NodeTrashedOptions.fromExpireOr(expire: expire, end: end),
    );
  }

  @override
  String get objectName => name;

  @override
  String get value => path;

  @override
  DocumentResource clone({bool deep = true}) {
    return DocumentResource(
      details: details,
      extension: extension,
      name: name,
      trashOptions: trashOptions,
      path: path,
    );
  }

  @override
  DocumentResource cloneWithNewLevel(int level, {bool deep = true}) {
    return copyWith(details: details.cloneWithNewLevel(level));
  }

  static String? __type;

  @internal
  static String get objectType =>
      __type ??= DocumentResource._internal().runtimeType.toString();

  static DocumentResource fromJson(Map<String, dynamic> json) {
    if (json['runtimeType'] != objectType) {
      throw IllegalTypeConvertionException(
        type: [DocumentResource],
        founded: json['runtimeType'],
      );
    }
    return DocumentResource(
      details: NodeDetails.fromJson(json['details'] as Map<String, dynamic>),
      trashOptions: NodeTrashedOptions.fromJson(
        json['trashOptions'] as Map<String, dynamic>,
      ),
      extension: json['extension'] as String,
      name: json['name'] as String,
      path: json['path'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'runtimeType': objectType,
      'details': details.toJson(),
      'extension': extension,
      'path': path,
      'name': name,
      'trashOptions': trashOptions.toJson(),
    };
  }

  @override
  String toString() {
    return 'DocumentResource('
        'details: $details, '
        'path: $path, '
        'synopsis: synopsis, '
        'name: $name.$extension'
        'trashOptions: $trashOptions'
        ')';
  }

  @override
  DocumentResource copyWith({
    NodeDetails? details,
    String? path,
    String? name,
    String? attachedSection,
    String? synopsis,
    String? extension,
    NodeTrashedOptions? trashOptions,
  }) {
    return DocumentResource(
      details: details ?? this.details,
      extension: extension ?? this.extension,
      path: path ?? this.path,
      name: name ?? this.name,
      trashOptions: trashOptions ?? this.trashOptions,
    );
  }

  @override
  int get hashCode =>
      details.hashCode ^
      path.hashCode ^
      trashOptions.hashCode ^
      name.hashCode ^
      extension.hashCode;

  @override
  bool operator ==(covariant DocumentResource other) {
    if (identical(this, other)) return true;
    return other.details == details &&
        path == other.path &&
        extension == other.extension &&
        trashOptions == other.trashOptions &&
        name == other.name;
  }

  @override
  bool get isResource => true;

  @override
  Object? resource(ResourceType type) {
    return path;
  }
}
