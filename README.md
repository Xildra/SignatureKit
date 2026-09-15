# SignatureKit

Capture de signatures manuscrites, **full SwiftUI** : ni `UIViewRepresentable`,
ni PencilKit, ni dépendance externe.

- iOS 18.6+
- Trait d'épaisseur variable, dérivée de la vitesse du geste
- Export PNG transparent recadré au tracé **et** tracé vectoriel maison
  (`SignatureDrawing`, du JSON, quelques Ko)
- Ne décide pas de la persistance : `Signature` est `Codable`, tu en fais
  ce que tu veux (SwiftData, JSON, API, ou rien du tout)

## Installation

Xcode → File → Add Package Dependencies → l'URL de ton dépôt, ou en local :
File → Add Package Dependencies → Add Local… → ce dossier.

```swift
.package(url: "https://…/SignatureKit.git", from: "1.0.0")
```

## Usage

```swift
import SignatureKit

struct CrewSignaturesView: View {
    let crew: [Person]
    @State private var signatures: [Person.ID: Signature] = [:]
    @State private var cdbSignature = Signature()
    @State private var target: SigningTarget?

    var body: some View {
        List {
            ForEach(crew) { person in
                HStack {
                    Text(person.fullNameWithRank)
                    Spacer()
                    if let signature = signatures[person.id], signature.isSigned {
                        SignatureThumbnail(signature)
                            .onTapGesture { target = .member(person) }
                    } else {
                        Button("Signature") { target = .member(person) }
                    }
                }
            }
        }
        .signaturePrivacyScreen()
        .signaturePad(item: $target) { target in
            switch target {
            case .member(let person):
                // le nom est connu : pas de saisie
                SignaturePadConfiguration(title: person.fullNameWithRank,
                                          signerName: person.fullNameWithRank,
                                          asksForName: false,
                                          existing: signatures[person.id])
            case .cdb:
                // on ignore qui est le chef : champ libre + raccourcis
                SignaturePadConfiguration(title: "Commandant de bord",
                                          subtitle: "2ᵉ signature, en plus de celle de membre",
                                          suggestedNames: crew.map(\.fullNameWithRank),
                                          existing: cdbSignature)
            }
        } onValidate: { target, signature in
            switch target {
            case .member(let person): signatures[person.id] = signature
            case .cdb: cdbSignature = signature
            }
        }
    }
}
```

## Notes

- `signaturePad(item:)` est piloté par un élément, pas par un `Bool` : dans
  une liste, un booléen unique ouvre toujours la même ligne.
- `signaturePrivacyScreen()` masque l'écran quand l'app passe en arrière-plan.
  iOS en fait une capture qu'il écrit sur le disque ; une signature affichée
  s'y retrouve.
- `SignatureCanvas` se place où tu veux, `ScrollView` comprise : il n'y a
  plus de `UIScrollView` cachée pour se disputer le geste.
- Le tracé est enregistré avec la taille de la zone de saisie, donc une
  signature faite sur iPhone se recharge correctement sur iPad.
- Les libellés sont en français, en dur. Pour les localiser, remplace les
  littéraux par `Text(key, bundle: .module)` et ajoute `defaultLocalization`
  dans `Package.swift`.

## Réutilisation dans plusieurs projets

Publie une fois, tague, consomme partout :

```bash
git init && git add . && git commit -m "SignatureKit 1.0.0"
git remote add origin git@github.com:toi/SignatureKit.git
git push -u origin main
git tag 1.0.0 && git push --tags
```

Dans chaque app : **Add Package Dependencies** → l'URL → *Up to Next Major
Version*. Sans tag, Xcode ne voit aucune version et te force sur une branche,
ce qui rend les builds non reproductibles.

### Itérer sur le package depuis une app

Glisse le dossier local dans la fenêtre du projet : Xcode fait primer le
package local sur la dépendance distante, du même nom. Tu modifies, tu testes
dans l'app réelle, et tu retires le dossier une fois le tag poussé — sans
jamais toucher à la déclaration de dépendance.

### Ce qui doit rester dehors

La seule vraie menace pour un package partagé, c'est l'ajout commode :
`Person`, une notion de chef d'équipe, une règle métier « il faut deux
signatures ». Règle simple : si le code emploie le vocabulaire d'un de tes
métiers, il appartient à l'app, pas ici.

### Points d'attention

- `Package.resolved` : à committer dans les apps, pas dans le package.
- Le plancher `.iOS("18.6")` s'impose à tous les consommateurs. Rien dans
  le code n'exige iOS 26 : `onGeometryChange` (18.0) est l'API la plus
  récente utilisée. Monte-le si tes apps sont déjà plus haut.
- Les libellés français en dur deviennent bloquants dès qu'une app doit
  parler une autre langue. C'est la première dette à rembourser.

## Licence

MIT.
