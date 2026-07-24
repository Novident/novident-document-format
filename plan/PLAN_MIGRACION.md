# Plan de Migración: `novident_document_format`

## Objetivo

Mover **exclusivamente los nodos del árbol** y sus dependencias mínimas desde `novident_remake` hacia `novident_document_format`. Este paquete será la base más fundamental del ecosistema Novident: cualquier paquete que necesite representar o manipular documentos usará este.

**Principio rector**: `novident_document_format` define QUÉ ES un documento. No define cómo se compila, ni cómo se formatea, ni cómo se renderiza.

---

## Arquitectura destino del ecosistema

```
novident_nodes/                    ← YA EXISTE: Node, NodeContainer, NodeDetails
                                     (no se toca)

novident_document_format/          ← ESTE PAQUETE:
    tree/document.dart              → Document
    tree/folder.dart                → Folder
    tree/root_node.dart             → Root
    tree/document_resource.dart     → DocumentResource
    trash/node_trashed_options.dart → NodeTrashedOptions
    enums/folder_type.dart          → FolderType
    interfaces/                     → 7 mixins de nodo
    interfaces/counters/            → 4 mixins de conteo
    constants.dart                  → kStructuredBasedSectionId, defaults
    exceptions.dart                 → IllegalTypeConvertionException
    utils/string_utils.dart         → isChar, isPunctuation, equals

novident_compiler/                 ← FUTURO: placeholder rules, project rules,
                                     resource rules

novident_layout/                   ← FUTURO: Format, Layout, separators,
                                     SectionAttributes, secciones

novident_ast/                      ← FUTURO: LayoutDocument, DocumentPage,
                                     Paragraph, TextSpan, Image, Embed

novident_remake/                   ← APP: consume todos los anteriores
```

---

## Fase 1: Romper dependencias problemáticas (en `novident_remake`)

Antes de mover archivos, hay que resolver 3 ciclos/acoplamientos:

### 1a. `NodeTrashedOptions` ↔ `Folder` (ciclo)

**Problema**: `NodeTrashedOptions` importa `Folder` solo para usar `Folder.kDefaultEndTime = 30`.

**Solución**:
- Mover la constante `kDefaultEndTime` a `NodeTrashedOptions`:
  ```dart
  // node_trashed_options.dart
  class NodeTrashedOptions {
    static const int kDefaultExpireDays = 30;
    // ...
  }
  ```
- Actualizar `Folder` para referenciar `NodeTrashedOptions.kDefaultExpireDays`.
- Eliminar la importación de `Folder` en `node_trashed_options.dart`.

### 1b. `DocumentResource` → `ResourceRules`

**Problema**: `DocumentResource.isResource` llama a `ResourceRules.checkResource()`.

**Solución**: Hacer que `isResource` devuelva siempre `true` por ahora (el usuario lo afinará después):
```dart
// Antes:
bool get isResource => ResourceRules.checkResource(content);
// Después:
bool get isResource => true;
```

Esto elimina la dependencia de `ResourceRules`. El método `resource(ResourceType)` seguirá funcionando porque solo se llama si `isResource` es `true`.

### 1c. `Trashable` mixin → `Folder`

**Problema**: `Trashable` importa `Folder` solo para `Folder.kDefaultEndTime` como valor por defecto.

**Solución**: Cambiar la referencia a `NodeTrashedOptions.kDefaultExpireDays`:
```dart
// Antes:
mixin Trashable {
  Node setTrashState({DateTime? expire, int end = Folder.kDefaultEndTime});
}
// Después:
mixin Trashable {
  Node setTrashState({DateTime? expire, int end = NodeTrashedOptions.kDefaultExpireDays});
}
```

Eliminar la importación de `Folder` en `Trashable`.

---

## Fase 2: Archivos a mover

### Grupo A: Sin dependencias internas (mover primero)

| # | Origen (`novident_remake/lib/src/domain/`) | Destino (`novident_document_format/lib/src/`) |
|---|---|---|
| A1 | `enums/folder_type.dart` | `enums/folder_type.dart` |
| A2 | `interfaces/nodes/universal_name.dart` | `interfaces/universal_name.dart` |
| A3 | `interfaces/nodes/universal_value.dart` | `interfaces/universal_value.dart` |
| A4 | `interfaces/nodes/universal_resource.dart` | `interfaces/universal_resource.dart` |
| A5 | `interfaces/nodes/attachable_section.dart` | `interfaces/attachable_section.dart` |
| A6 | `interfaces/nodes/special_folder_behavior.dart` | `interfaces/special_folder_behavior.dart` |
| A7 | `interfaces/nodes/node_has_type.dart` | `interfaces/node_has_type.dart` |
| A8 | `interfaces/project/word_counter_mixin.dart` | `interfaces/counters/word_counter_mixin.dart` |
| A9 | `interfaces/project/character_count_mixin.dart` | `interfaces/counters/character_count_mixin.dart` |
| A10 | `interfaces/project/line_counter_mixin.dart` | `interfaces/counters/line_counter_mixin.dart` |

**Archivos del Grupo A**: No importan nada de `novident_remake` (excepto A8-A10, que no tienen imports). Se copian sin cambios.

### Grupo B: Con ajustes menores (después de Fase 1)

| # | Origen (`novident_remake/lib/src/domain/`) | Destino (`novident_document_format/lib/src/`) | Ajustes necesarios |
|---|---|---|---|
| B1 | `interfaces/nodes/trashable.dart` | `interfaces/trashable.dart` | Cambiar `Folder.kDefaultEndTime` → `NodeTrashedOptions.kDefaultExpireDays` |
| B2 | `entities/trash/node_trashed_options.dart` | `trash/node_trashed_options.dart` | Añadir `kDefaultExpireDays`. Eliminar import de `Folder`. |
| B3 | `interfaces/project/default_counts_impl.dart` | `interfaces/counters/default_counts_impl.dart` | Cambiar imports a rutas locales del nuevo paquete |
| B4 | `entities/tree_node/document_resource.dart` | `tree/document_resource.dart` | `isResource` → `true`. Eliminar import de `ResourceRules`. Ajustar imports. |
| B5 | `entities/tree_node/document.dart` | `tree/document.dart` | Ajustar imports a rutas locales del nuevo paquete |
| B6 | `entities/tree_node/folder.dart` | `tree/folder.dart` | `Folder.kDefaultEndTime` → `NodeTrashedOptions.kDefaultExpireDays`. Reemplazar logger. Ajustar imports. |
| B7 | `entities/tree_node/root_node.dart` | `tree/root_node.dart` | Ajustar imports a rutas locales del nuevo paquete |

Los archivos B5-B7 forman un **ciclo de imports mutuos** (`Document` ↔ `Folder` ↔ `Root`). Deben moverse **juntos en un solo commit** y todos los imports entre ellos deben actualizarse simultáneamente.

### Grupo C: Archivos nuevos (no existen, hay que crearlos)

| # | Archivo nuevo | Contenido |
|---|---|---|
| C1 | `lib/novident_document_format.dart` | Barrel que exporta todo lo público |
| C2 | `lib/src/constants.dart` | `kStructuredBasedSectionId`, nombres por defecto |
| C3 | `lib/src/exceptions.dart` | `IllegalTypeConvertionException` |
| C4 | `lib/src/utils/string_utils.dart` | Extensiones `isChar`, `isPunctuation`, `isWhiteSpace`, `equals` |
| C5 | `lib/src/interfaces/interfaces.dart` | Barrel que re-exporta todos los mixins |

### Grupo D: NO se mueven (se quedan o van a otros paquetes)

| Archivo | Destino |
|---|---|
| `entities/object_value.dart` | → `novident_layout` (solo lo usa `NewPageOptions`) |
| `entities/project/*` (5 archivos) | → se queda en `novident_remake` |
| `entities/format/*` (3 archivos) | → `novident_layout` |
| `entities/layout/*` (13 archivos) | → `novident_layout` |
| `entities/processor/*` (3 archivos) | → `novident_ast` |
| `entities/rule/placeholder/*` (20 archivos) | → `novident_compiler` |
| `entities/rule/project_rules/*` (8 archivos) | → `novident_compiler` |
| `entities/rule/resources/*` (3 archivos) | → `novident_compiler` |
| `entities/project/section/*` (3 archivos) | → `novident_layout` |
| `entities/author/*` (1 archivo) | → se queda en `novident_remake` |
| `domain/project_defaults.dart` | → solo se extraen 3-5 constantes a `novident_document_format` |
| `domain/constants.dart` | → se queda en `novident_remake` |
| `domain/string_contants.dart` | → se queda; solo se extraen utilidades a `novident_document_format` |
| `domain/extensions/string_extension.dart` | → se queda; solo se extrae `.equals()` a `novident_document_format` |
| `domain/logger/logger.dart` | → se queda (el Folder lo reemplazará por `debugPrint`) |

---

## Fase 3: Contenido de archivos nuevos

### C1: `lib/novident_document_format.dart`

```dart
/// Novident Document Format
///
/// Core document tree model for the Novident writing ecosystem.
/// Defines the fundamental node types that make up a Novident project:
/// [Document], [Folder], [Root], and [DocumentResource].
library novident_document_format;

// Tree nodes
export 'src/tree/document.dart';
export 'src/tree/folder.dart';
export 'src/tree/root_node.dart';
export 'src/tree/document_resource.dart';

// Trash
export 'src/trash/node_trashed_options.dart';

// Enums
export 'src/enums/folder_type.dart';

// Interfaces
export 'src/interfaces/universal_name.dart';
export 'src/interfaces/universal_value.dart';
export 'src/interfaces/universal_resource.dart';
export 'src/interfaces/trashable.dart';
export 'src/interfaces/attachable_section.dart';
export 'src/interfaces/special_folder_behavior.dart';
export 'src/interfaces/node_has_type.dart';

// Counter interfaces
export 'src/interfaces/counters/word_counter_mixin.dart';
export 'src/interfaces/counters/character_count_mixin.dart';
export 'src/interfaces/counters/line_counter_mixin.dart';
export 'src/interfaces/counters/default_counts_impl.dart';

// Constants
export 'src/constants.dart';

// Exceptions
export 'src/exceptions.dart';
```

### C2: `lib/src/constants.dart`

```dart
/// Default constants for the Novident document format.
class NovidentDefaults {
  NovidentDefaults._();

  /// Special section ID that means "use the structured-based section"
  /// (i.e., determine the section from the node's tree depth).
  static const String kStructuredBasedSectionId = 'structured-based';

  /// Default name for new documents.
  static const String kDefaultDocumentName = 'Untitled Document';

  /// Default name for new folders.
  static const String kDefaultFolderName = 'Untitled Folder';

  /// Default name for the manuscript/draft folder.
  static const String kDefaultManuscriptName = 'Draft';

  /// Default name for the research folder.
  static const String kDefaultResearchName = 'Research';

  /// Default name for the trash folder.
  static const String kDefaultTrashName = 'Trash';

  /// Default name for the templates folder.
  static const String kDefaultTemplatesName = 'Templates';
}
```

### C3: `lib/src/exceptions.dart`

```dart
/// Thrown when a JSON map cannot be deserialized to the expected node type.
class IllegalTypeConvertionException implements Exception {
  /// The expected types.
  final List<Type> type;

  /// The type that was actually found, if any.
  final Type? founded;

  const IllegalTypeConvertionException({
    required this.type,
    required this.founded,
  });

  @override
  String toString() {
    return 'IllegalTypeConvertionException: '
        'expected one of $type, but found $founded';
  }
}
```

### C4: `lib/src/utils/string_utils.dart`

```dart
/// Character classification extensions for [String].
extension StringCharUtils on String {
  /// True if the string is exactly one character and it's a letter.
  bool get isChar {
    if (length != 1) return false;
    final code = codeUnitAt(0);
    return (code >= 65 && code <= 90) ||   // A-Z
           (code >= 97 && code <= 122);     // a-z
  }

  /// True if the string is exactly one punctuation character.
  bool get isPunctuation {
    if (length != 1) return false;
    final code = codeUnitAt(0);
    return (code >= 33 && code <= 47) ||   // ! " # $ % & ' ( ) * + , - . /
           (code >= 58 && code <= 64) ||   // : ; < = > ? @
           (code >= 91 && code <= 96) ||   // [ \ ] ^ _ `
           (code >= 123 && code <= 126);   // { | } ~
  }

  /// True if the string is exactly one whitespace character.
  bool get isWhiteSpace {
    if (length != 1) return false;
    final code = codeUnitAt(0);
    return code == 32 ||                   // space
           code == 9 ||                    // tab
           code == 10 ||                   // newline
           code == 13;                     // carriage return
  }
}

/// Null-safe equality extension.
extension StringEquals on String? {
  /// Compares two nullable strings for equality.
  bool equals(String? other) => this == other;
}
```

### C5: `lib/src/interfaces/interfaces.dart`

```dart
/// Barrel file for all node interfaces/mixins.
library;

export 'universal_name.dart';
export 'universal_value.dart';
export 'universal_resource.dart';
export 'trashable.dart';
export 'attachable_section.dart';
export 'special_folder_behavior.dart';
export 'node_has_type.dart';
```

---

## Fase 4: Ajustes detallados en archivos movidos

### B1: `interfaces/trashable.dart`

```dart
// imports ajustados
import 'package:novident_nodes/novident_nodes.dart';
import 'package:novident_document_format/src/trash/node_trashed_options.dart';

mixin Trashable {
  NodeTrashedOptions get trashStatus;
  Node setTrashState({
    DateTime? expire,
    int end = NodeTrashedOptions.kDefaultExpireDays,  // ← cambiado
  });
  Node unsetTrashState();
}
```

### B2: `trash/node_trashed_options.dart`

Añadir:
```dart
class NodeTrashedOptions implements ClonableMixin<NodeTrashedOptions> {
  /// Default number of days before a trashed node expires permanently.
  static const int kDefaultExpireDays = 30;
  // ...
```

Eliminar: `import '../tree_node/folder.dart';`

Actualizar referencias internas: `Folder.kDefaultEndTime` → `kDefaultExpireDays`.

### B3: `interfaces/counters/default_counts_impl.dart`

```dart
// imports ajustados
import 'package:novident_document_format/src/interfaces/counters/character_count_mixin.dart';
import 'package:novident_document_format/src/interfaces/counters/line_counter_mixin.dart';
import 'package:novident_document_format/src/interfaces/counters/word_counter_mixin.dart';
import 'package:novident_document_format/src/utils/string_utils.dart';
```

### B4: `tree/document_resource.dart`

Cambios:
1. `isResource` → `true`
2. Eliminar import de `ResourceRules`
3. Actualizar todos los imports:

```dart
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:novident_nodes/novident_nodes.dart';
import 'package:novident_document_format/src/tree/folder.dart';
import 'package:novident_document_format/src/tree/root_node.dart';
import 'package:novident_document_format/src/trash/node_trashed_options.dart';
import 'package:novident_document_format/src/exceptions.dart';
import 'package:novident_document_format/src/utils/string_utils.dart';
import 'package:novident_document_format/src/interfaces/interfaces.dart';
```

### B5: `tree/document.dart`

Ajustar imports:
```dart
import 'package:dart_quill_delta/dart_quill_delta.dart' show Delta;
import 'package:dart_quill_delta_simplify/dart_quill_delta_simplify.dart';
import 'package:novident_nodes/novident_nodes.dart';
import 'package:novident_document_format/src/tree/folder.dart';
import 'package:novident_document_format/src/tree/root_node.dart';
import 'package:novident_document_format/src/trash/node_trashed_options.dart';
import 'package:novident_document_format/src/exceptions.dart';
import 'package:novident_document_format/src/constants.dart';
import 'package:novident_document_format/src/utils/string_utils.dart';
import 'package:novident_document_format/src/interfaces/interfaces.dart';
import 'package:novident_document_format/src/interfaces/counters/character_count_mixin.dart';
import 'package:novident_document_format/src/interfaces/counters/default_counts_impl.dart';
import 'package:novident_document_format/src/interfaces/counters/line_counter_mixin.dart';
import 'package:novident_document_format/src/interfaces/counters/word_counter_mixin.dart';
```

Referencias a `ProjectDefaults.kStructuredBasedSectionId` → `NovidentDefaults.kStructuredBasedSectionId`.

### B6: `tree/folder.dart`

Ajustar imports (similar a B5).
Cambios de código:
- `Folder.kDefaultEndTime` → `NodeTrashedOptions.kDefaultExpireDays`
- `ProjectDefaults.kStructuredBasedSectionId` → `NovidentDefaults.kStructuredBasedSectionId`
- `NovidentLogger.treeView.info(...)` → `debugPrint('[Folder] ...')`
- Importar `package:flutter/foundation.dart` solo para `debugPrint`

### B7: `tree/root_node.dart`

Ajustar imports (más simple que B5/B6, solo depende de Document y Folder):
```dart
import 'dart:convert';
import 'package:novident_nodes/novident_nodes.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:novident_document_format/src/tree/document.dart';
import 'package:novident_document_format/src/tree/folder.dart';
import 'package:novident_document_format/src/exceptions.dart';
```

---

## Fase 5: Dependencias del nuevo paquete

```yaml
# novident_document_format/pubspec.yaml
name: novident_document_format
description: Core document tree model for the Novident writing ecosystem.
version: 0.1.0

environment:
  sdk: ^3.11.3

dependencies:
  flutter:
    sdk: flutter
  novident_nodes: ^1.2.4
  dart_quill_delta: ^10.8.3
  dart_quill_delta_simplify: ^10.9.0
  collection: ^1.19.1
  meta: ^1.16.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

---

## Fase 6: Actualizar `novident_remake`

### 6a. Añadir dependencia

```yaml
# novident_remake/pubspec.yaml
dependencies:
  novident_document_format:
    path: ../../novident-document-format/novident_document_format
```

### 6b. Actualizar imports en novident_remake

Archivos afectados (19 dependientes externos detectados):

| Archivo en `novident_remake` | Cambio de import |
|---|---|
| `entities/project/project.dart` | `tree_node/root_node.dart` → `package:novident_document_format/...` |
| `entities/project/project_cache.dart` | `tree_node/root_node.dart` → `package:novident_document_format/...` |
| `entities/layout/layout.dart` | `tree_node/document.dart` → `package:novident_document_format/...` |
| `entities/layout/options/new_page_options.dart` | No usa tree nodes (usa ObjectValue, que no se mueve) |
| `entities/processor/processor_context.dart` | `tree_node/document.dart` + `document_resource.dart` → `package:novident_document_format/...` |
| `data/processors/project_processor.dart` | `document.dart` + `folder.dart` → `package:novident_document_format/...` |
| `data/processors/processor_result.dart` | `document.dart` → `package:novident_document_format/...` |
| `extensions/nodes_extensions.dart` | `document.dart` + `folder.dart` + `document_resource.dart` → `package:novident_document_format/...` |
| `extensions/project_extensions.dart` | `folder.dart` + `document_resource.dart` → `package:novident_document_format/...` |
| `services/character_count_service.dart` | `universal_value.dart` → `package:novident_document_format/...` |
| `services/word_count_service.dart` | `universal_value.dart` → `package:novident_document_format/...` |
| `rule/project_rules/rules/ensure_manuscript_existence_rule.dart` | `folder.dart` → `package:novident_document_format/...` |
| `rule/project_rules/rules/ensure_trash_has_no_duplicates_rule.dart` | `folder.dart` → `package:novident_document_format/...` |
| `rule/project_rules/rules/ensure_research_existence_rule.dart` | `folder.dart` → `package:novident_document_format/...` |
| `rule/project_rules/rules/ensure_trash_folder_existence_rule.dart` | `folder.dart` → `package:novident_document_format/...` |
| `rule/placeholder/rules/replace_image_placeholder_rule.dart` | `document_resource.dart` → `package:novident_document_format/...` |

### 6c. Eliminar archivos movidos del tree de `novident_remake`

Después de verificar que todo compila, eliminar:
- `lib/src/domain/entities/tree_node/` (los 4 archivos)
- `lib/src/domain/entities/trash/node_trashed_options.dart`
- `lib/src/domain/enums/folder_type.dart`
- `lib/src/domain/interfaces/nodes/` (los 7 mixins)
- `lib/src/domain/interfaces/project/word_counter_mixin.dart`
- `lib/src/domain/interfaces/project/character_count_mixin.dart`
- `lib/src/domain/interfaces/project/line_counter_mixin.dart`
- `lib/src/domain/interfaces/project/default_counts_impl.dart`

---

## Fase 7: Actualizar otros paquetes afectados

### `novident_tree_view` y `novident_editor`

Estos paquetes definen sus propios `Document`, `Folder`, `Root` en tests. Después de esta migración, deberían:
1. Añadir dependencia a `novident_document_format`
2. Reemplazar sus implementaciones de prueba con las oficiales

---

## Resumen de cambios

| Categoría | Cantidad |
|---|---|
| Archivos movidos sin cambios de lógica | 10 (Grupo A) |
| Archivos movidos con ajustes de imports/código | 7 (Grupo B) |
| Archivos nuevos creados | 5 (Grupo C) |
| Dependencias circulares rotas | 3 (1a, 1b, 1c) |
| Constantes extraídas | 5 (a `constants.dart`) |
| Utilidades extraídas | 4 métodos (a `string_utils.dart`) |
| Imports actualizados en `novident_remake` | 19 archivos |
| Archivos eliminados de `novident_remake` | 16 |
| Nuevas dependencias del paquete | 5 (`novident_nodes`, `dart_quill_delta`, `dart_quill_delta_simplify`, `collection`, `meta`) |

---

## Orden de ejecución recomendado

```
Paso 1: Fase 1a — Mover kDefaultEndTime a NodeTrashedOptions
Paso 2: Fase 1b — DocumentResource.isResource → true
Paso 3: Fase 1c — Actualizar Trashable
Paso 4: Fase 3 — Crear archivos nuevos (C1-C5) en novident_document_format
Paso 5: Fase 2 Grupo A — Copiar 10 archivos sin cambios
Paso 6: Fase 2 Grupo B — Copiar 7 archivos con ajustes
Paso 7: Fase 5 — Actualizar pubspec.yaml de novident_document_format
Paso 8: Fase 6a — Añadir dependencia en novident_remake
Paso 9: Fase 6b — Actualizar 19 imports en novident_remake
Paso 10: Compilar y correr tests en ambos paquetes
Paso 11: Fase 6c — Eliminar archivos movidos de novident_remake
Paso 12: Fase 7 — Actualizar novident_tree_view y novident_editor
```
