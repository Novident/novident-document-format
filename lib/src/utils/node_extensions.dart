import 'package:collection/collection.dart';
import 'package:novident_nodes/novident_nodes.dart';

import '../tree/document.dart';
import '../tree/document_resource.dart';
import '../tree/folder.dart';
import '../enums/folder_type.dart';
import '../interfaces/interfaces.dart';
import 'cast_extension.dart';

extension EasyTypeNodeExtension on Node {
  // folder
  bool get isFolder => this is Folder;
  bool get isNormalFolder => isFolder && cast<Folder>().type.isNormalFolder;

  /// As the name suggests, the Draft folder is where you place all of the files you want
  /// to include in the actual work that others will read.
  bool get isManuscriptFolder =>
      isFolder && cast<Folder>().type.isManuscriptFolder;

  /// Whenever you delete a file in Novident, the file is not actually
  /// removed from the project but is instead moved to the special Trash folder just
  /// like the Trash in the Dock. You can tell at a glance when items are in the trash
  /// folder as its icon will appear like an overflowing trash can. Permanently purge all
  /// trashed files from the project with the Project ▸ Empty Trash... menu command.
  bool get isTrashFolder => isFolder && cast<Folder>().type.isTrashFolder;

  /// The Research folder is the default import location for non-text documents such
  /// as images, PDF files and so on (although it can hold text files too).
  bool get isResearchFolder => isFolder && cast<Folder>().type.isResearchFolder;
  bool get isTemplatesSheetFolder =>
      isFolder && cast<Folder>().type.isTemplatesSheetFolder;

  // docs
  bool get isDocument => this is Document;
  bool get isDocumentResource => this is DocumentResource;

  // mixins
  bool get isTrashed =>
      this is Trashable && cast<Trashable>().trashStatus.isTrashed;
  bool get nodeHasName => this is UniversalName;
  bool get nodeHasResource => this is UniversalResource;
  bool get nodeCanBeTrashed => this is Trashable;
  bool get nodeCanAttachSections => this is AttachableSection;

  bool equals(Node node) => node.isFolder && isFolder
      ? _equality.equals(cast<Folder>().children, node.cast<Folder>().children)
      : node == this;
}

const ListEquality<Node> _equality = ListEquality<Node>();
