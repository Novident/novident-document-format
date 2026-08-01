import 'package:novident_nodes/novident_nodes.dart';
import 'package:flutter/foundation.dart';
import 'package:novident_tree_view/novident_tree_view.dart';

import '../../novident_document_format.dart';
import '../utils/cast_extension.dart';
import '../utils/node_extensions.dart';

/// [Folder] represents a node that can contains all
/// types of Nodes as its children
///
/// You can take this implementation as a directory from your
/// local storage that can contains a wide variety of file types
final class Folder extends NodeContainer
    with
        UniversalName,
        Trashable,
        AttachableSection,
        SpecialFolderBehavior,
        NodeHasType<FolderType>,
        DragAndDropMixin {
  final FolderType folderType;
  final NodeTrashedOptions trashOptions;
  final String attachedSection;
  final String name;

  /// If expanded is true the [Folder]
  /// should show the children into it
  bool _isExpanded;

  Folder({
    required super.children,
    required this.name,
    required super.details,
    this.attachedSection = NovidentDefaults.kStructuredBasedSectionId,
    this.folderType = FolderType.normal,
    this.trashOptions = const NodeTrashedOptions.nonTrashed(),
    bool isExpanded = false,
    bool doRedepthCheck = false,
  }) : _isExpanded = isExpanded {
    for (final Node child in super.children) {
      child.owner = this;
    }
    if (doRedepthCheck) {
      redepthDescendants(
        propagate: false,
        shouldNotify: false,
      );
    }
  }

  @visibleForTesting
  Folder.testing({
    required super.children,
    required this.name,
    required super.details,
    this.attachedSection = '',
    this.folderType = FolderType.normal,
    this.trashOptions = const NodeTrashedOptions.nonTrashed(),
    bool isExpanded = false,
  }) : _isExpanded = isExpanded;

  Folder._internal()
      : attachedSection = '',
        folderType = FolderType.normal,
        trashOptions = const NodeTrashedOptions.nonTrashed(),
        _isExpanded = false,
        name = '',
        super(
          children: [],
          details: NodeDetails.zero(),
        );

  @override
  bool get isExpanded => _isExpanded;

  void expand(bool expand) {
    _isExpanded = expand;
    notify();
  }

  @override
  FolderType get type => folderType;

  @override
  String get section => attachedSection;

  @override
  bool get canMoveIntoSpecialFolders =>
      isTrashFolder || isManuscriptFolder ? false : true;

  @override
  bool get canMoveIntoAnotherFolders =>
      isTrashFolder || isManuscriptFolder ? false : true;

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
  Folder unsetTrashState() {
    if (!isTrashed) return this;
    return copyWith(
      children: <Node>[
        ...children.map(
          (Node e) =>
              e is Trashable ? e.cast<Trashable>().unsetTrashState() : e,
        )
      ],
      trashOptions: NodeTrashedOptions.nonTrashed(),
    );
  }

  @override
  Folder setTrashState({
    DateTime? expire,
    int end = NodeTrashedOptions.kDefaultExpireDays,
  }) {
    // can't be trashed if there is no folder
    // or if this is the [Trash] one
    if (owner == null || isTrashFolder || isTrashed) {
      return this;
    }

    if (owner!.isTrashed) {
      final DateTime? endOfOwner = owner!.cast<Folder>().trashStatus.expire;
      assert(endOfOwner != null,
          'trashed Node owner with no end time was founded: ${owner.runtimeType}(${owner!.id})');
      return copyWith(
        children: <Node>[
          ...children.map<Node>((Node e) => e.nodeCanBeTrashed
              ? e.cast<Trashable>().setTrashState(
                    expire: endOfOwner ?? expire,
                    end: end,
                  )
              : e)
        ],
        trashOptions: NodeTrashedOptions.fromExpireOr(
          expire: endOfOwner ?? expire,
          end: end,
        ),
      );
    }
    return copyWith(
      children: <Node>[
        ...children.map<Node>((Node e) => e.nodeCanBeTrashed
            ? e.cast<Trashable>().setTrashState(
                  expire: expire,
                  end: end,
                )
            : e)
      ],
      trashOptions: NodeTrashedOptions.fromExpireOr(
        expire: expire,
        end: end,
      ),
    );
  }

  @override
  String get objectName => name;

  void toggleExpand({bool forceOpen = false}) =>
      expand(forceOpen ? true : !isExpanded);

  @override
  void add(
    Node element, {
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    // is we are into trash or a owner that is already trashed
    if (isTrashFolder || isTrashed) {
      if (!element.isTrashed) {
        final Node effectiveTrashedEl = applyTrashingFeature(element);
        super.add(
          effectiveTrashedEl,
          shouldNotify: shouldNotify,
          propagateNotifications: propagateNotifications,
        );
        return;
      }
    } else if (!(isTrashFolder || isTrashed) && element.isTrashed) {
      final Node effectiveTrashedEl = unApplyTrashingFeature(element);
      super.add(
        effectiveTrashedEl,
        shouldNotify: shouldNotify,
        propagateNotifications: propagateNotifications,
      );
      return;
    }
    super.add(
      element,
      shouldNotify: shouldNotify,
      propagateNotifications: propagateNotifications,
    );
  }

  @override
  void insert(
    int index,
    Node element, {
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    if (isTrashFolder || trashOptions.isTrashed) {
      if (!element.isTrashed) {
        final Node effectiveTrashedEl = applyTrashingFeature(element);
        super.insert(
          index,
          effectiveTrashedEl,
          shouldNotify: shouldNotify,
          propagateNotifications: propagateNotifications,
        );
        return;
      }
    } else if (!(isTrashFolder || isTrashed) && element.isTrashed) {
      final Node effectiveTrashedEl = unApplyTrashingFeature(element);
      super.add(
        effectiveTrashedEl,
        shouldNotify: shouldNotify,
        propagateNotifications: propagateNotifications,
      );
      return;
    }
    super.insert(
      index,
      element,
      shouldNotify: shouldNotify,
      propagateNotifications: propagateNotifications,
    );
  }

  Node unApplyTrashingFeature(Node node) {
    if (node is! Trashable) {
      return this;
    }
    final Node effectiveTrashedEl = node.cast<Trashable>().unsetTrashState();
    // notifies about the update of the trash options
    // for the editor listeners (to avoid outdated versions
    // during editing files)
    onChange(
      NodeUpdate(
        oldState: node.clone(),
        newState: effectiveTrashedEl.clone(),
      ),
    );
    return effectiveTrashedEl;
  }

  Node applyTrashingFeature(Node node) {
    if (node is! Trashable) {
      return this;
    }
    final Node effectiveTrashedEl = node.cast<Trashable>().setTrashState();
    // notifies about the update of the trash options
    // for the editor listeners (to avoid outdated versions
    // during editing files)
    onChange(
      NodeUpdate(
        oldState: node.clone(),
        newState: effectiveTrashedEl.clone(),
      ),
    );
    return effectiveTrashedEl;
  }

  @override
  Folder copyWith({
    NodeDetails? details,
    String? name,
    FolderType? folderType,
    String? attachedSection,
    NodeTrashedOptions? trashOptions,
    List<Node>? children,
    bool? isExpanded,
  }) {
    return Folder(
      children: children ?? this.children,
      details: details ?? this.details,
      folderType: folderType ?? this.folderType,
      trashOptions: trashOptions ?? this.trashOptions,
      attachedSection: attachedSection ?? this.attachedSection,
      isExpanded: isExpanded ?? this.isExpanded,
      name: name ?? this.name,
    );
  }

  @override
  Folder clone({bool deep = true}) {
    return Folder(
      children: deep
          ? children
              .map<Node>(
                (e) => e.clone(
                  deep: deep,
                ),
              )
              .toList()
          : children,
      name: name,
      trashOptions: trashOptions.clone(),
      folderType: folderType,
      attachedSection: attachedSection,
      details: details.clone(),
      isExpanded: isExpanded,
    );
  }

  @override
  Folder cloneWithNewLevel(int level, {bool deep = true}) {
    return copyWith(
      details: details.cloneWithNewLevel(level),
    );
  }

  /// Check if the id of the node exist into the [Folder]
  /// checking in its children using a custom predicate passed by the dev
  ///
  /// This operation could be heavy based on the deep of the nodes
  /// into the [Folder]
  bool existNodeWhere(bool Function(Node node) predicate) {
    for (int i = 0; i < children.length; i++) {
      final node = children.elementAt(i);
      if (predicate(node)) {
        return true;
      } else if (node is Folder && node.isNotEmpty) {
        final foundedNode = node.existNodeWhere(predicate);
        if (foundedNode) return true;
      }
    }
    return false;
  }

  static String? __type;

  @internal
  static String get objectType =>
      __type ??= Folder._internal().runtimeType.toString();

  static Folder? fromJson(Map<String, dynamic> json) {
    if (json['runtimeType'] != objectType) {
      throw IllegalTypeConvertionException(
        type: [Folder],
        founded: json['runtimeType'],
      );
    }
    return Folder(
      details: NodeDetails.fromJson(
        json['details'] as Map<String, dynamic>,
      ),
      trashOptions: NodeTrashedOptions.fromJson(
          json['trashOptions'] as Map<String, dynamic>),
      name: json['name'] as String,
      isExpanded: json['expanded'] as bool,
      folderType: FolderType.values[json['type'] as int? ?? 0],
      attachedSection: json['attachedSection'] as String,
      children: List<Node>.from(
        (json['children'] as List<Map<String, dynamic>>).map(
          (el) {
            if (json['runtimeType'] != Document.objectType) {
              return Document.fromJson(el);
            }
            if (json['runtimeType'] != Folder.objectType) {
              return Folder.fromJson(el);
            }
            if (json['runtimeType'] != DocumentResource.objectType) {
              return DocumentResource.fromJson(el);
            }
            throw Exception(
              'The element $el does not contain knowed '
              'types supported. Expected Document or Folder types',
            );
          },
        ),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'runtimeType': objectType,
      'details': details.toJson(),
      'type': folderType.index,
      'name': name,
      'attachedSection': attachedSection,
      'trashOptions': trashOptions.toJson(),
      'children': children
          .map(
            (Node e) => e.toJson(),
          )
          .toList(),
      'expanded': _isExpanded,
    };
  }

  @override
  void dispose() {
    super.dispose();
    for (final Node e in children) {
      ChangeNotifier.debugAssertNotDisposed(e);
      e.dispose();
    }
  }

  @override
  int get hashCode =>
      details.hashCode ^
      isExpanded.hashCode ^
      children.hashCode ^
      attachedSection.hashCode ^
      name.hashCode ^
      folderType.hashCode ^
      trashOptions.hashCode;

  @override
  bool operator ==(covariant Folder other) {
    if (identical(this, other)) return true;
    return details == other.details &&
        isExpanded == other.isExpanded &&
        attachedSection == other.attachedSection &&
        equals(other) &&
        name == other.name &&
        folderType == other.folderType &&
        trashOptions == other.trashOptions;
  }

  @override
  String toString() {
    return 'Folder('
        'details: $details, '
        'isExpanded: $isExpanded, '
        'trashOptions: $trashOptions, '
        'attachedSection: $attachedSection, '
        'name: $name, '
        'type: ${folderType.name},'
        'children: $children'
        ')';
  }
}
