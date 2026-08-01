import 'package:meta/meta.dart';
import 'package:novident_document_format/src/utils/node_extensions.dart';
import 'package:novident_nodes/novident_nodes.dart';
import 'package:novident_tree_view/novident_tree_view.dart';

import '../trash/node_trashed_options.dart';
import '../exceptions.dart';
import '../constants.dart';
import '../interfaces/interfaces.dart';

/// Document represents a simple type of node
///
/// You can see this implementation as a file from a directory
/// that can contain all type data into itself
final class Document extends Node
    with
        UniversalName,
        Trashable,
        AttachableSection,
        SpecialFolderBehavior,
        DragAndDropMixin {
  final String name;
  final String attachedSection;
  final NodeTrashedOptions trashOptions;

  Document({
    required super.details,
    required this.name,
    this.attachedSection = NovidentDefaults.kStructuredBasedSectionId,
    this.trashOptions = const NodeTrashedOptions.nonTrashed(),
  });

  Document.empty({
    required super.details,
    this.name = '',
    this.attachedSection = '',
    this.trashOptions = const NodeTrashedOptions.nonTrashed(),
  });

  Document._internal()
      : attachedSection = '',
        name = '',
        trashOptions = const NodeTrashedOptions.nonTrashed(),
        super(details: NodeDetails.zero());

  @override
  String get section => attachedSection;

  @override
  bool get canMoveIntoSpecialFolders => true;

  @override
  bool get canMoveIntoAnotherFolders => true;

  @override
  NodeTrashedOptions get trashStatus => trashOptions;

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
  Document setTrashState({
    DateTime? expire,
    int end = NodeTrashedOptions.kDefaultExpireDays,
  }) {
    return copyWith(
      trashOptions: NodeTrashedOptions.fromExpireOr(
        expire: expire,
        end: end,
      ),
    );
  }

  @override
  String get objectName => name;

  @override
  Document clone({bool deep = true}) {
    return Document(
      details: details.clone(),
      name: name,
      trashOptions: trashOptions.clone(),
      attachedSection: attachedSection,
    );
  }

  @override
  Document cloneWithNewLevel(int level, {bool deep = true}) {
    return copyWith(
      details: details.cloneWithNewLevel(level),
    );
  }

  static String? __type;

  @internal
  static String get objectType =>
      __type ??= Document._internal().runtimeType.toString();

  static Document fromJson(Map<String, dynamic> json) {
    if (json['runtimeType'] != objectType) {
      throw IllegalTypeConvertionException(
        type: [Document],
        founded: json['runtimeType'],
      );
    }
    return Document(
      trashOptions: NodeTrashedOptions.fromJson(
          json['trashOptions'] as Map<String, dynamic>),
      name: json['name'] as String,
      attachedSection: json['attachedSection'] as String,
      details: NodeDetails.fromJson(json['details'] as Map<String, dynamic>),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'runtimeType': objectType,
      'details': details.toJson(),
      'attachedSection': attachedSection,
      'name': name,
      'trashOptions': trashOptions.toJson(),
    };
  }

  @override
  String toString() {
    return 'Document('
        'details: $details, '
        'attachedSection: $attachedSection,'
        'synopsis: synopsis, '
        'name: $name'
        'trashOptions: $trashOptions'
        ')';
  }

  @override
  Document copyWith({
    NodeDetails? details,
    String? name,
    String? attachedSection,
    NodeTrashedOptions? trashOptions,
  }) {
    return Document(
      details: details ?? this.details,
      attachedSection: attachedSection ?? this.attachedSection,
      name: name ?? this.name,
      trashOptions: trashOptions ?? this.trashOptions,
    );
  }

  @override
  int get hashCode =>
      details.hashCode ^
      trashOptions.hashCode ^
      attachedSection.hashCode ^
      name.hashCode;

  @override
  bool operator ==(covariant Document other) {
    if (identical(this, other)) return true;
    return other.details == details &&
        trashOptions == other.trashOptions &&
        attachedSection == other.attachedSection &&
        name == other.name;
  }
}
