# Novident Document Format

Official document format for the **Novident** ecosystem. Defines the tree model that structures all information within the application: documents, folders, and resources. This is the canonical implementation used by the official app and the foundation on which the rest of the suite is built.

## What is `novident_document_format`?

This package provides the three core entities of the Novident data model:

| Entity | Description |
|--------|-------------|
| `Document` | A leaf node representing an editable document. It has a name, can belong to a section, and can be moved to the trash. |
| `Folder` | A container node that organizes the hierarchy. It can hold documents, other folders, and resources. Supports special types: normal, templates, research, manuscript, and trash. |
| `DocumentResource` | A leaf node representing an external resource (image, PDF, video, etc.) linked via a file path. |

All three types share common behavior through mixins: `UniversalName` (they have a name), `Trashable` (they can be trashed), `AttachableSection` (they belong to a section), `SpecialFolderBehavior` (movement rules between folders), and `DragAndDropMixin` (drag-and-drop support).

## Features

- Tree-structured document model with folders, documents, and resources
- Trash system with automatic expiration (30 days by default)
- Sections for organizing content in compilations
- Deep and shallow cloning for any node
- Full JSON serialization (`toJson` / `fromJson`) with runtime type discriminators
- Special folder types: normal, templates, research, manuscript, and trash

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  novident_document_format: <latest> 
```

## Usage

### Creating a document

```dart
// Document with a name
final document = Document(
  details: NodeDetails.zero(),
  name: 'My first chapter',
);

// Empty document (no name)
final empty = Document.empty(
  details: NodeDetails.zero(),
);

// Cloning a document
final copy = document.clone();
final shallowCopy = document.clone(deep: false);

// Immutable copy with changes
final modified = document.copyWith(
  name: 'Revised chapter',
);
```

### Creating a folder

```dart
// Normal folder with children
final folder = Folder(
  details: NodeDetails.zero(),
  name: 'My Documents',
  children: [document],
);

// Research-type folder
final research = Folder(
  details: NodeDetails.zero(),
  name: 'Research',
  folderType: FolderType.research,
  children: <Node>[],
);

// Adding children after creation
research.add(anotherDocument);
research.insert(0, aResource);

// Expanding / collapsing
folder.toggleExpand();
folder.expand(true); // Force expanded
```

### Creating a resource

```dart
final resource = DocumentResource(
  details: NodeDetails.zero(),
  name: 'reference-image',
  extension: 'png',
  path: '/assets/images/diagram.png',
);

// Check if a node is a resource
if (resource.isResource) {
  print(resource.value); // -> '/assets/images/diagram.png'
}
```

### Building a full tree

```dart
final tree = Folder(
  details: NodeDetails.zero(),
  name: 'root',
  children: [
    Folder(
      details: NodeDetails.zero(),
      name: 'Manuscript',
      folderType: FolderType.manuscript,
      children: [
        Folder(
          details: NodeDetails.zero(),
          name: 'Chapter 1',
          folderType: FolderType.manuscript,
          children: [
            Document(details: NodeDetails.zero(), name: 'Section 1.1'),
            Document(details: NodeDetails.zero(), name: 'Section 1.2'),
          ],
        ),
      ],
    ),
    Folder(
      details: NodeDetails.zero(),
      name: 'Resources',
      folderType: FolderType.research,
      children: [
        DocumentResource(
          details: NodeDetails.zero(),
          name: 'Reference',
          extension: 'pdf',
          path: '/docs/reference.pdf',
        ),
      ],
    ),
    Folder(
      details: NodeDetails.zero(),
      name: 'Trash',
      folderType: FolderType.trash,
      children: <Node>[],
    ),
  ],
);

// Deep search for a node
final exists = tree.existNodeWhere((node) => node.objectName == 'Section 1.1');
```

### JSON serialization

```dart
// Serialize to JSON
final doc = Document(
  details: NodeDetails.zero(),
  name: 'My Document',
);
final json = doc.toJson();
// {
//   "runtimeType": "Document",
//   "details": { ... },
//   "name": "My Document",
//   "attachedSection": "structured-based",
//   "trashOptions": { "trashed": false, "expire": null }
// }

// Deserialize from JSON
final reconstructed = Document.fromJson(json);

final folder = Folder(
  details: NodeDetails.zero(),
  name: 'root',
  children: [doc],
);
final folderJson = folder.toJson();
// Includes "children" with recursive serialization of each child

final folderReconstructed = Folder.fromJson(folderJson);

final resource = DocumentResource(
  details: NodeDetails.zero(),
  name: 'photo',
  extension: 'jpg',
  path: '/photos/vacation.jpg',
);
final resourceJson = resource.toJson();
final resourceReconstructed = DocumentResource.fromJson(resourceJson);
```

### Working with the trash

```dart
// Send a document to the trash
final trashed = document.setTrashState(expire: DateTime.now(), end: 30);
print(trashed.isTrashed); // -> true

// Recover from the trash
final recovered = trashed.unsetTrashState();
print(recovered.isTrashed); // -> false

// When a folder is trashed, its children are trashed too
final trashedFolder = folder.setTrashState(end: 30);
// All children of trashedFolder now have isTrashed == true

// Moving a node into a trash-type folder marks it automatically
final trash = Folder(
  details: NodeDetails.zero(),
  name: 'Trash',
  folderType: FolderType.trash,
  children: <Node>[],
);
trash.add(document); // document is now trashed
```

### Useful Node extensions

```dart
final node = someNode;

// Type checks
if (node.isDocument) { /* ... */ }
if (node.isFolder) { /* ... */ }
if (node.isDocumentResource) { /* ... */ }
if (node.isTrashFolder) { /* ... */ }

// State checks
if (node.isTrashed) { /* ... */ }
if (node.nodeHasName) { /* ... */ }
if (node.nodeHasResource) { /* ... */ }

// Deep comparison between folders
if (folderA.equals(folderB)) { /* ... */ }
```

## License

This project is part of the Novident ecosystem. See the `LICENSE` file for details.
