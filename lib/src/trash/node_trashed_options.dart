import 'package:novident_nodes/novident_nodes.dart';

class NodeTrashedOptions implements ClonableMixin<NodeTrashedOptions> {
  /// Default number of days before a trashed node expires permanently.
  static const int kDefaultExpireDays = 30;

  final bool isTrashed;

  /// The time where was converted to a trashed file
  final DateTime? expire;

  const NodeTrashedOptions({
    required this.isTrashed,
    required this.expire,
  });

  NodeTrashedOptions.fromExpireOr({
    this.isTrashed = true,
    DateTime? expire,
    int end = kDefaultExpireDays,
  }) : expire = expire ??
            DateTime.now().add(
              Duration(
                days: end,
              ),
            );

  const NodeTrashedOptions.nonTrashed()
      : isTrashed = false,
        expire = null;

  NodeTrashedOptions.now({int end = kDefaultExpireDays})
      : isTrashed = true,
        expire = DateTime.now().add(Duration(days: end));

  Map<String, dynamic> toJson() {
    return {
      'trashed': isTrashed,
      'expire': expire?.millisecondsSinceEpoch,
    };
  }

  factory NodeTrashedOptions.fromJson(Map<String, dynamic> json) {
    return NodeTrashedOptions(
      isTrashed: json['trashed'] as bool,
      expire: json['expire'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['expire'] as int),
    );
  }

  @override
  bool operator ==(covariant NodeTrashedOptions other) {
    if (identical(this, other)) return true;
    return isTrashed == other.isTrashed && expire == other.expire;
  }

  @override
  int get hashCode => isTrashed.hashCode ^ expire.hashCode;

  @override
  NodeTrashedOptions clone({bool deep = true}) {
    return NodeTrashedOptions(
      isTrashed: isTrashed,
      expire: expire,
    );
  }

  @override
  String toString() {
    return 'NodeTrashedOptions(trashed: $isTrashed, expire: $expire)';
  }
}
