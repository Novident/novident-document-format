import 'package:flutter_test/flutter_test.dart';

import 'package:novident_document_format/novident_document_format.dart';
import 'package:novident_document_format/src/utils/node_extensions.dart';
import 'package:novident_nodes/novident_nodes.dart';

void main() {
  group('Document', () {
    test('creates empty document', () {
      final doc = Document.empty(details: NodeDetails.zero());
      expect(doc.name, '');
      expect(doc.isTrashed, isFalse);
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
      expect(folder.type, FolderType.normal);
      expect(folder.expand, isFalse);
    });
  });

  group('Root', () {
    test('creates root with children', () {
      final doc = Document.empty(details: NodeDetails.zero());
      final root = Folder(
        details: NodeDetails.zero(),
        name: 'root',
        children: <Node>[doc],
      );
      expect(root.children.length, 1);
      expect(root.level, -1);
    });
  });

  group('NodeTrashedOptions', () {
    test('default expire days is 30', () {
      expect(NodeTrashedOptions.kDefaultExpireDays, 30);
    });

    test('non trashed has isTrashed false', () {
      const options = NodeTrashedOptions.nonTrashed();
      expect(options.isTrashed, isFalse);
    });
  });
}
