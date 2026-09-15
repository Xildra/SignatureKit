# Changelog

Versionnage sémantique. Une fois que deux projets en dépendent, la règle
compte plus que le numéro :

- **majeure** : une API publique renommée, supprimée, ou dont la signature
  change. Casse la compilation chez les autres.
- **mineure** : ajout purement additif (nouveau paramètre avec valeur par
  défaut, nouveau type, nouvelle vue).
- **corrective** : correction de comportement, API inchangée.

## [2.0.0]

**Cassant.** Passage en full SwiftUI : PencilKit est retiré.

- `SignatureCanvas` devient une `View` SwiftUI ; plus de `UIViewRepresentable`.
- Nouveau modèle de tracé `SignatureStroke` / `SignatureDrawing` (JSON).
  Les `strokeData` produits par la 1.0 (format `PKDrawing`) ne sont plus
  relus — les PNG déjà enregistrés, eux, restent valides.
- `SignaturePadConfiguration.strokeWidth` remplacé par `minimumWidth` et
  `maximumWidth`.
- Plancher relevé à iOS 18.6.

## [1.0.0]

- `Signature` : PNG + tracé vectoriel `PKDrawing`, `Codable`.
- `SignaturePadView` et `SignaturePadConfiguration`.
- `SignatureCanvas` et `SignatureCanvasController` pour composer soi-même.
- `SignatureThumbnail`.
- Modificateurs `signaturePad(item:)` et `signaturePrivacyScreen()`.
