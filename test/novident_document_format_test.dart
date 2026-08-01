import 'package:flutter_test/flutter_test.dart';

import 'package:novident_document_format/novident_document_format.dart';
import 'package:novident_document_format/src/utils/node_extensions.dart';
import 'package:novident_nodes/novident_nodes.dart';

void main() {
  group('Document', () {
    test('creates with name and defaults', () {
      final doc = Document(
        details: NodeDetails.zero(),
        name: 'My Document',
      );
      expect(doc.name, 'My Document');
      expect(doc.objectName, 'My Document');
      expect(doc.isTrashed, isFalse);
      expect(doc.section, 'structured-based');
      expect(doc.canMoveIntoSpecialFolders, isTrue);
      expect(doc.canMoveIntoAnotherFolders, isTrue);
    });

    test('creates empty document', () {
      final doc = Document.empty(details: NodeDetails.zero());
      expect(doc.name, '');
      expect(doc.attachedSection, '');
      expect(doc.isTrashed, isFalse);
    });

    test('clone creates independent copy', () {
      final details = NodeDetails.zero();
      final original = Document(
        details: details,
        name: 'Original',
      );
      final cloned = original.clone();

      expect(cloned.name, 'Original');
      expect(cloned.details, equals(details));
      expect(identical(cloned, original), isFalse);
    });

    test('clone deep=false still copies values', () {
      final original = Document(
        details: NodeDetails.zero(),
        name: 'Original',
      );
      final cloned = original.clone(deep: false);
      expect(cloned.name, 'Original');
    });

    test('cloneWithNewLevel creates copy with updated level', () {
      final doc = Document(
        details: NodeDetails.zero(),
        name: 'Doc',
      );
      final leveled = doc.cloneWithNewLevel(3);
      expect(leveled.level, 3);
      expect(leveled.name, 'Doc');
    });

    test('copyWith returns modified copy', () {
      final doc = Document(
        details: NodeDetails.zero(),
        name: 'Old',
      );
      final updated = doc.copyWith(name: 'New');
      expect(updated.name, 'New');
      expect(doc.name, 'Old'); // original unchanged
    });

    test('toJson and fromJson round-trip', () {
      final doc = Document(
        details: NodeDetails.zero(),
        name: 'Round-trip',
        attachedSection: 'custom-section',
      );
      final json = doc.toJson();

      expect(json['runtimeType'], isA<String>());
      expect(json['name'], 'Round-trip');
      expect(json['attachedSection'], 'custom-section');
      expect(json['trashOptions'], isA<Map<String, dynamic>>());
      expect(json['details'], isA<Map<String, dynamic>>());

      final reconstructed = Document.fromJson(json);
      expect(reconstructed.name, doc.name);
      expect(reconstructed.attachedSection, doc.attachedSection);
      expect(reconstructed.details, equals(doc.details));
    });

    test('fromJson throws on wrong runtimeType', () {
      final json = {
        'runtimeType': 'Folder',
        'details': NodeDetails.zero().toJson(),
        'name': 'Nope',
        'attachedSection': '',
        'trashOptions': NodeTrashedOptions.nonTrashed().toJson(),
      };
      expect(
        () => Document.fromJson(json),
        throwsA(isA<IllegalTypeConvertionException>()),
      );
    });

    test('setTrashState marks as trashed', () {
      final doc = Document(
        details: NodeDetails.zero(),
        name: 'ToTrash',
      );
      final trashed = doc.setTrashState(end: 30);
      expect(trashed.isTrashed, isTrue);
      expect(trashed.trashOptions.expire, isNotNull);
      expect(doc.isTrashed, isFalse); // original unchanged
    });

    test('unsetTrashState removes trash state', () {
      final doc = Document(
        details: NodeDetails.zero(),
        name: 'Recovered',
      ).setTrashState(end: 30);
      expect(doc.isTrashed, isTrue);

      final recovered = doc.unsetTrashState();
      expect(recovered.isTrashed, isFalse);
      expect((recovered as Document).trashOptions.isTrashed, isFalse);
    });

    test('isDraggable returns true', () {
      final doc = Document(details: NodeDetails.zero(), name: 'Drag');
      expect(doc.isDraggable(), isTrue);
    });

    test('isDropIntoAllowed returns false when trashed', () {
      final doc = Document(
        details: NodeDetails.zero(),
        name: 'Drop',
      ).setTrashState(end: 30);
      expect(doc.isDropIntoAllowed(), isFalse);
    });
  });

  group('DocumentResource', () {
    test('creates with path, name, and extension', () {
      final resource = DocumentResource(
        details: NodeDetails.zero(),
        path: '/assets/photo.png',
        name: 'photo',
        extension: 'png',
      );
      expect(resource.name, 'photo');
      expect(resource.objectName, 'photo');
      expect(resource.path, '/assets/photo.png');
      expect(resource.extension, 'png');
      expect(resource.value, '/assets/photo.png');
      expect(resource.isResource, isTrue);
      expect(resource.isTrashed, isFalse);
      expect(resource.canMoveIntoSpecialFolders, isFalse);
      expect(resource.canMoveIntoAnotherFolders, isTrue);
    });

    test('clone creates independent copy', () {
      final original = DocumentResource(
        details: NodeDetails.zero(),
        path: '/data/file.pdf',
        name: 'file',
        extension: 'pdf',
      );
      final cloned = original.clone();
      expect(cloned.path, original.path);
      expect(cloned.name, original.name);
      expect(cloned.extension, original.extension);
      expect(cloned.details, equals(original.details));
      expect(identical(cloned, original), isFalse);
    });

    test('cloneWithNewLevel updates level', () {
      final resource = DocumentResource(
        details: NodeDetails.zero(),
        path: '/x',
        name: 'x',
        extension: 'txt',
      );
      final leveled = resource.cloneWithNewLevel(5);
      expect(leveled.level, 5);
    });

    test('copyWith returns modified copy', () {
      final resource = DocumentResource(
        details: NodeDetails.zero(),
        path: '/old/path',
        name: 'old',
        extension: 'txt',
      );
      final updated = resource.copyWith(
        name: 'new',
        path: '/new/path',
        extension: 'md',
      );
      expect(updated.name, 'new');
      expect(updated.path, '/new/path');
      expect(updated.extension, 'md');
      expect(resource.name, 'old'); // original unchanged
    });

    test('toJson and fromJson round-trip', () {
      final resource = DocumentResource(
        details: NodeDetails.zero(),
        path: '/assets/img.jpg',
        name: 'img',
        extension: 'jpg',
      );
      final json = resource.toJson();

      expect(json['runtimeType'], isA<String>());
      expect(json['path'], '/assets/img.jpg');
      expect(json['name'], 'img');
      expect(json['extension'], 'jpg');

      final reconstructed = DocumentResource.fromJson(json);
      expect(reconstructed.path, resource.path);
      expect(reconstructed.name, resource.name);
      expect(reconstructed.extension, resource.extension);
      expect(reconstructed.details, equals(resource.details));
    });

    test('fromJson throws on wrong runtimeType', () {
      final json = {
        'runtimeType': 'Document',
        'details': NodeDetails.zero().toJson(),
        'path': '/x',
        'name': 'x',
        'extension': 'txt',
        'trashOptions': NodeTrashedOptions.nonTrashed().toJson(),
      };
      expect(
        () => DocumentResource.fromJson(json),
        throwsA(isA<IllegalTypeConvertionException>()),
      );
    });

    test('setTrashState and unsetTrashState', () {
      final resource = DocumentResource(
        details: NodeDetails.zero(),
        path: '/tmp/x',
        name: 'x',
        extension: 'tmp',
      );
      final trashed = resource.setTrashState(end: 7);
      expect(trashed.isTrashed, isTrue);

      final recovered = trashed.unsetTrashState();
      expect(recovered.isTrashed, isFalse);
    });

    test('resource returns path regardless of type', () {
      final resource = DocumentResource(
        details: NodeDetails.zero(),
        path: '/doc.pdf',
        name: 'doc',
        extension: 'pdf',
      );
      expect(resource.resource(ResourceType.pdf), '/doc.pdf');
      expect(resource.resource(ResourceType.image), '/doc.pdf');
    });
  });

  group('Folder', () {
    test('creates folder with children', () {
      final folder = Folder(
        children: <Node>[],
        name: 'Test',
        details: NodeDetails.zero(),
      );
      expect(folder.name, 'Test');
      expect(folder.objectName, 'Test');
      expect(folder.type, FolderType.normal);
      expect(folder.isExpanded, isFalse);
      expect(folder.children, isEmpty);
      expect(folder.folderType.isNormalFolder, isTrue);
    });

    test('creates with doRedepthCheck', () {
      final child = Document(details: NodeDetails.zero(), name: 'Child');
      final folder = Folder(
        children: [child],
        name: 'Parent',
        details: NodeDetails.zero(),
        doRedepthCheck: true,
      );
      expect(folder.children.length, 1);
    });

    test('expand and toggleExpand', () {
      final folder = Folder(
        children: <Node>[],
        name: 'F',
        details: NodeDetails.zero(),
      );
      expect(folder.isExpanded, isFalse);

      folder.expand(true);
      expect(folder.isExpanded, isTrue);

      folder.expand(false);
      expect(folder.isExpanded, isFalse);

      folder.toggleExpand();
      expect(folder.isExpanded, isTrue);

      folder.toggleExpand(forceOpen: true);
      expect(folder.isExpanded, isTrue);
    });

    test('add child to normal folder', () {
      final folder = Folder(
        children: <Node>[],
        name: 'F',
        details: NodeDetails.zero(),
      );
      final doc = Document(details: NodeDetails.zero(), name: 'D');
      folder.add(doc);
      expect(folder.children.length, 1);
    });

    test('insert child at index', () {
      final a = Document(details: NodeDetails.zero(), name: 'A');
      final b = Document(details: NodeDetails.zero(), name: 'B');
      final folder = Folder(
        children: [a],
        name: 'F',
        details: NodeDetails.zero(),
      );
      folder.insert(0, b);
      expect(folder.children.length, 2);
      expect((folder.children[0] as Document).name, 'B');
    });

    test('add to trash folder auto-trashes child', () {
      final trash = Folder(
        children: <Node>[],
        name: 'Trash',
        details: NodeDetails.zero(),
        folderType: FolderType.trash,
      );
      final doc = Document(details: NodeDetails.zero(), name: 'Del');
      expect(doc.isTrashed, isFalse);

      trash.add(doc);
      // After adding to trash, the child should be trashed
      final child = trash.children.first;
      expect(child.isTrashed, isTrue);
    });

    test('add to normal folder untrashes child', () {
      final folder = Folder(
        children: <Node>[],
        name: 'Normal',
        details: NodeDetails.zero(),
      );
      final trashedDoc = Document(
        details: NodeDetails.zero(),
        name: 'WasTrashed',
      ).setTrashState(end: 30);
      expect(trashedDoc.isTrashed, isTrue);

      folder.add(trashedDoc);
      final child = folder.children.first;
      expect(child.isTrashed, isFalse);
    });

    test('setTrashState on folder trashes children recursively', () {
      final doc = Document(details: NodeDetails.zero(), name: 'D');
      final inner = Folder(
        children: [doc],
        name: 'Inner',
        details: NodeDetails.zero(),
      );
      // Place inner inside a root so it has an owner (required for trashing)
      final root = Folder(
        children: [inner],
        name: 'Root',
        details: NodeDetails.zero(),
      );

      // Trash the inner folder (which has an owner)
      final innerFromRoot = root.children.first as Folder;
      final trashed = innerFromRoot.setTrashState(end: 30);
      expect(trashed.isTrashed, isTrue);
      // The document inside inner is also trashed
      final trashedDoc = trashed.children.first;
      expect(trashedDoc.isTrashed, isTrue);
    });

    test('unsetTrashState recovers entire subtree', () {
      final doc = Document(
        details: NodeDetails.zero(),
        name: 'D',
      ).setTrashState(end: 30);
      final inner = Folder(
        children: [doc],
        name: 'Inner',
        details: NodeDetails.zero(),
      );
      // Give inner an owner so trashing works
      Folder(
        children: [inner],
        name: 'Root',
        details: NodeDetails.zero(),
      );
      final trashedInner = inner.setTrashState(end: 30);
      expect(trashedInner.isTrashed, isTrue);

      final recovered = trashedInner.unsetTrashState();
      expect(recovered.isTrashed, isFalse);
      final recoveredChild = recovered.children.first;
      expect(recoveredChild.isTrashed, isFalse);
    });

    test('clone deep creates independent tree', () {
      final doc = Document(details: NodeDetails.zero(), name: 'D');
      final original = Folder(
        children: [doc],
        name: 'F',
        details: NodeDetails.zero(),
      );
      final cloned = original.clone();

      expect(cloned.name, 'F');
      expect(cloned.children.length, 1);
      expect(cloned.children.first, isA<Document>());
      expect(identical(cloned.children.first, doc), isFalse);
    });

    test('clone shallow keeps same children references', () {
      final doc = Document(details: NodeDetails.zero(), name: 'D');
      final original = Folder(
        children: [doc],
        name: 'F',
        details: NodeDetails.zero(),
      );
      final cloned = original.clone(deep: false);

      expect(identical(cloned.children.first, doc), isTrue);
    });

    test('cloneWithNewLevel updates level', () {
      final folder = Folder(
        children: <Node>[],
        name: 'F',
        details: NodeDetails.zero(),
      );
      final leveled = folder.cloneWithNewLevel(2);
      expect(leveled.level, 2);
    });

    test('copyWith returns modified copy', () {
      final folder = Folder(
        children: <Node>[],
        name: 'Old',
        details: NodeDetails.zero(),
      );
      final updated = folder.copyWith(
        name: 'New',
        folderType: FolderType.research,
        isExpanded: true,
      );
      expect(updated.name, 'New');
      expect(updated.type, FolderType.research);
      expect(updated.isExpanded, isTrue);
      expect(folder.name, 'Old'); // original unchanged
    });

    test('existNodeWhere finds deep child', () {
      final deepDoc = Document(details: NodeDetails.zero(), name: 'Deep');
      final inner = Folder(
        children: [deepDoc],
        name: 'Inner',
        details: NodeDetails.zero(),
      );
      final root = Folder(
        children: [inner],
        name: 'Root',
        details: NodeDetails.zero(),
      );

      expect(
        root.existNodeWhere(
          (n) => n.nodeHasName && (n as UniversalName).objectName == 'Deep',
        ),
        isTrue,
      );
      expect(
        root.existNodeWhere(
          (n) => n.nodeHasName && (n as UniversalName).objectName == 'Nope',
        ),
        isFalse,
      );
    });

    test('toJson serializes with children', () {
      final doc = Document(details: NodeDetails.zero(), name: 'D');
      final folder = Folder(
        children: [doc],
        name: 'F',
        details: NodeDetails.zero(),
        isExpanded: true,
      );
      final json = folder.toJson();

      expect(json['runtimeType'], isA<String>());
      expect(json['name'], 'F');
      expect(json['type'], FolderType.normal.index);
      expect(json['expanded'], isTrue);
      expect(json['children'], isA<List>());
      expect((json['children'] as List).length, 1);
    });

    test('toJson contains all required keys', () {
      final folder = Folder(
        children: <Node>[],
        name: 'F',
        details: NodeDetails.zero(),
        folderType: FolderType.manuscript,
      );
      final json = folder.toJson();

      expect(json.containsKey('runtimeType'), isTrue);
      expect(json.containsKey('details'), isTrue);
      expect(json.containsKey('type'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('attachedSection'), isTrue);
      expect(json.containsKey('trashOptions'), isTrue);
      expect(json.containsKey('children'), isTrue);
      expect(json.containsKey('expanded'), isTrue);
    });

    test('FolderType enum values', () {
      expect(FolderType.values.length, 5);
      expect(FolderType.normal.index, 0);
      expect(FolderType.templatesSheet.index, 1);
      expect(FolderType.research.index, 2);
      expect(FolderType.manuscript.index, 3);
      expect(FolderType.trash.index, 4);
    });

    test('EasyFolderType extension checks', () {
      expect(FolderType.normal.isNormalFolder, isTrue);
      expect(FolderType.normal.isTrashFolder, isFalse);
      expect(FolderType.trash.isTrashFolder, isTrue);
      expect(FolderType.trash.isNotTrashFolder, isFalse);
      expect(FolderType.research.isResearchFolder, isTrue);
      expect(FolderType.manuscript.isManuscriptFolder, isTrue);
      expect(FolderType.templatesSheet.isTemplatesSheetFolder, isTrue);
    });

    test('special folder behavior restrictions', () {
      final trash = Folder(
        children: <Node>[],
        name: 'Trash',
        details: NodeDetails.zero(),
        folderType: FolderType.trash,
      );
      expect(trash.canMoveIntoSpecialFolders, isFalse);
      expect(trash.canMoveIntoAnotherFolders, isFalse);

      final manuscript = Folder(
        children: <Node>[],
        name: 'MS',
        details: NodeDetails.zero(),
        folderType: FolderType.manuscript,
      );
      expect(manuscript.canMoveIntoSpecialFolders, isFalse);
      expect(manuscript.canMoveIntoAnotherFolders, isFalse);
    });
  });

  group('NodeTrashedOptions', () {
    test('default expire days is 30', () {
      expect(NodeTrashedOptions.kDefaultExpireDays, 30);
    });

    test('nonTrashed has isTrashed false and null expire', () {
      const options = NodeTrashedOptions.nonTrashed();
      expect(options.isTrashed, isFalse);
      expect(options.expire, isNull);
    });

    test('fromExpireOr creates trashed with future expiry', () {
      final options = NodeTrashedOptions.fromExpireOr(end: 10);
      expect(options.isTrashed, isTrue);
      expect(options.expire, isNotNull);
      final diff = options.expire!.difference(DateTime.now()).inDays;
      expect(diff, greaterThanOrEqualTo(9));
      expect(diff, lessThanOrEqualTo(10));
    });

    test('now creates trashed with future expiry', () {
      final options = NodeTrashedOptions.now(end: 5);
      expect(options.isTrashed, isTrue);
      expect(options.expire, isNotNull);
    });

    test('toJson and fromJson round-trip', () {
      final original = NodeTrashedOptions.now(end: 30);
      final json = original.toJson();

      expect(json['trashed'], isTrue);
      expect(json['expire'], isA<int>());

      final reconstructed = NodeTrashedOptions.fromJson(json);
      expect(reconstructed.isTrashed, original.isTrashed);
      expect(
        reconstructed.expire?.millisecondsSinceEpoch,
        original.expire?.millisecondsSinceEpoch,
      );
    });

    test('fromJson handles null expire', () {
      final json = {'trashed': false, 'expire': null};
      final options = NodeTrashedOptions.fromJson(json);
      expect(options.isTrashed, isFalse);
      expect(options.expire, isNull);
    });

    test('clone creates equal but distinct object', () {
      final original = NodeTrashedOptions.now(end: 30);
      final cloned = original.clone();
      expect(cloned, equals(original));
      expect(identical(cloned, original), isFalse);
    });

    test('equality', () {
      const a = NodeTrashedOptions.nonTrashed();
      const b = NodeTrashedOptions.nonTrashed();
      final c = NodeTrashedOptions.now(end: 30);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('EasyTypeNodeExtension', () {
    test('isDocument detects Document nodes', () {
      final doc = Document(details: NodeDetails.zero(), name: 'D');
      expect(doc.isDocument, isTrue);
      expect(doc.isFolder, isFalse);
      expect(doc.isDocumentResource, isFalse);
    });

    test('isFolder detects Folder nodes', () {
      final folder = Folder(
        children: <Node>[],
        name: 'F',
        details: NodeDetails.zero(),
      );
      expect(folder.isFolder, isTrue);
      expect(folder.isDocument, isFalse);
    });

    test('isDocumentResource detects resource nodes', () {
      final resource = DocumentResource(
        details: NodeDetails.zero(),
        path: '/x',
        name: 'x',
        extension: 'txt',
      );
      expect(resource.isDocumentResource, isTrue);
      expect(resource.isDocument, isFalse);
    });

    test('special folder type extensions', () {
      final trash = Folder(
        children: <Node>[],
        name: 'T',
        details: NodeDetails.zero(),
        folderType: FolderType.trash,
      );
      expect(trash.isTrashFolder, isTrue);
      expect(trash.isNormalFolder, isFalse);

      final research = Folder(
        children: <Node>[],
        name: 'R',
        details: NodeDetails.zero(),
        folderType: FolderType.research,
      );
      expect(research.isResearchFolder, isTrue);

      final manuscript = Folder(
        children: <Node>[],
        name: 'M',
        details: NodeDetails.zero(),
        folderType: FolderType.manuscript,
      );
      expect(manuscript.isManuscriptFolder, isTrue);

      final templates = Folder(
        children: <Node>[],
        name: 'Tpl',
        details: NodeDetails.zero(),
        folderType: FolderType.templatesSheet,
      );
      expect(templates.isTemplatesSheetFolder, isTrue);
    });

    test('nodeHasName detects UniversalName', () {
      final doc = Document(details: NodeDetails.zero(), name: 'D');
      expect(doc.nodeHasName, isTrue);
    });

    test('nodeHasResource detects UniversalResource', () {
      final resource = DocumentResource(
        details: NodeDetails.zero(),
        path: '/x',
        name: 'x',
        extension: 'txt',
      );
      expect(resource.nodeHasResource, isTrue);
    });

    test('nodeCanBeTrashed detects Trashable', () {
      final doc = Document(details: NodeDetails.zero(), name: 'D');
      expect(doc.nodeCanBeTrashed, isTrue);
    });

    test('isTrashed reflects trash state', () {
      final doc = Document(
        details: NodeDetails.zero(),
        name: 'D',
      ).setTrashState(end: 30);
      expect(doc.isTrashed, isTrue);
    });
  });

  group('IllegalTypeConvertionException', () {
    test('toString contains expected and found types', () {
      final ex = IllegalTypeConvertionException(
        type: [Document],
        founded: Folder.objectType,
      );
      final str = ex.toString();
      expect(str, contains(Document.objectType));
      expect(str, contains(Folder.objectType));
      expect(str, contains('IllegalTypeConvertionException'));
    });
  });

  group('NovidentDefaults', () {
    test('constants have expected values', () {
      expect(NovidentDefaults.kStructuredBasedSectionId, 'structured-based');
      expect(NovidentDefaults.kDefaultResearchName, 'Research');
      expect(NovidentDefaults.kDefaultTrashName, 'Trash');
      expect(NovidentDefaults.kDefaultTemplatesName, 'Templates');
    });
  });
}
