import 'package:novident_nodes/novident_nodes.dart';

import '../trash/node_trashed_options.dart';

/// [NodeHasName] represents a [Node] that could be into the trash folder
///
/// This is useful when we need to know what will be removed and ignored
mixin Trashable {
  NodeTrashedOptions get trashStatus;
  Node setTrashState({
    DateTime? expire,
    int end = NodeTrashedOptions.kDefaultExpireDays,
  });
  Node unsetTrashState();
}
