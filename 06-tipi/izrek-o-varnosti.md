# Izrek o varnosti za λ-račun

## Definicija jezika

### Sintaksa

Vzemimo λ-račun z logičnimi vrednostmi:

    M ::= x
        | true
        | false
        | if M then M1 else M2
        | λx. M
        | M1 M2

### Operacijska semantika

Za vrednosti vzamemo:

    V ::= true
        | false
        | λx. M

Operacijsko semantiko podamo z malimi koraki:

    M  ↝  M'
    ----------------------------------------------
    if M then M1 else M2  ↝  if M' then M1 else M2

    ------------------------------
    if true then M1 else M2  ↝  M1

    -------------------------------
    if false then M1 else M2  ↝  M2

    M1  ↝  M1'
    ----------------
    M1 M2  ↝  M1' M2

    M2  ↝  M2'
    ----------------
    V1 M2  ↝  V1 M2'

    ----------------------
    (λx. M) V  ↝  M[V / x]

### Tipi

Tipi so:

    A, B ::= bool
           | A → B

Pravila za določanje tipov pa so:

    (x : A) ∈ Γ
    -----------
    Γ ⊢ x : A

    ---------------
    Γ ⊢ true : bool

    ----------------
    Γ ⊢ false : bool

    Γ ⊢ M : bool   Γ ⊢ M1 : A   Γ ⊢ M2 : A
    ---------------------------------------
    Γ ⊢ if M then M1 else M2 : A

    Γ, x : A ⊢ M : B
    -----------------
    Γ ⊢ λx. M : A → B

    Γ ⊢ M1 : A → B   Γ ⊢ M2 : A
    ----------------------------
    Γ ⊢ M1 M2 : B

## Izrek o varnosti

### Lema (o substituciji)

Če velja `Γ ⊢ M : A` in `Γ, x : A ⊢ N : B` in , tedaj velja `Γ ⊢ N[M / x] : B`.

#### Dokaz

Z indukcijo na izpeljavo `Γ, x : A ⊢ N : B`.

### Trditev (napredek)

Če velja `⊢ M : A`, tedaj:
1. je `M` vrednost ali
2. obstaja `M'`, da velja `M ↝ M'`.

#### Dokaz

Z indukcijo na predpostavko o določenem tipu.
Če je zaključek zadnjega uporabljenega pravila:

* `⊢ x : A`, imamo protislovje, saj je kontekst prazen.

* `⊢ true : bool`, imamo vrednost (1).

* `⊢ false : bool`, imamo vrednost (1).

* `⊢ if M then M1 else M2 : A`, mora veljati `⊢ M : bool`.
    Po indukciji dobimo dva primera:
    1. `M` je vrednost, torej `true`, `false` ali `λx. M`.
    Ker velja `⊢ M : bool`, zadnja možnost odpade.
    Če je `M = true`, velja `if M then M1 else M2 ↝ M1`,
    če je `M = false`, velja `if M then M1 else M2 ↝ M2`.
    2. Obstaja `M'`, da velja `M ↝ M'`, zato velja tudi `if M then M1 else M2 ↝ if M' then M1 else M2`.

    V vseh primerih izraz torej lahko naredi korak (2).

* `⊢ λx. M : A → B`, imamo vrednost (1).

* `⊢ M1 M2 : B`, mora veljati `⊢ M1 : A → B` in `⊢ M2 : A` za nek `A`.
    Po indukciji za `M1` dobimo dva primera:
    1. `M1` je vrednost `V1`. V tem primeru po indukciji za `M2` dobimo dva primera:
        1. Tudi `M2` je vrednost `V2`. Ker velja `⊢ M1 : A → B`, mora veljati `M1 = λx. M` za neka `x` in `M`. Tedaj velja `M1 M2 = (λx. M) V2 ↝ M[V2 / x]`.
        2. Obstaja `M2'`, da velja `M2 ↝ M2'`, zato velja tudi `M1 M2 = V1 M2 ↝ V1 M2'`.
    2. Obstaja `M1'`, da velja `M1 ↝ M1'`, zato velja tudi `M1 M2 ↝ M1' M2`.

    V vseh primerih izraz torej lahko naredi korak (2).

### Trditev (ohranitev)

Če velja `Γ ⊢ M : A` in `M ↝ M'`, tedaj velja tudi `Γ ⊢ M' : A`.

#### Dokaz

Z indukcijo na predpostavko o koraku.
Če je zaključek zadnjega uporabljenega pravila:

* `if M then M1 else M2 ↝ if M' then M1 else M2`, mora veljati `M ↝ M'`,
  iz `Γ ⊢ if M then M1 else M2 : A` pa sledi
  `Γ ⊢ M : bool`, `Γ ⊢ M1 : A` in `Γ ⊢ M2 : A`.
  Po indukcijski predpostavki velja `Γ ⊢ M' : bool`, iz česar sledi tudi
  `Γ ⊢ if M' then M1 else M2 : A`.

* `if true then M1 else M2 ↝ M1`,
  iz `Γ ⊢ if M then M1 else M2 : A` sledi `Γ ⊢ M1 : A`, kar želimo.

* `if false then M1 else M2 ↝ M2`
  iz `Γ ⊢ if M then M1 else M2 : A` sledi `Γ ⊢ M2 : A`, kar želimo.

* `M1 M2 ↝ M1' M2`, mora veljati `M1 ↝ M1'`,
  iz `Γ ⊢ M1 M2 : A` pa sledi
  `Γ ⊢ M1 : B → A` in `Γ ⊢ M2 : B` za nek `B`.
  Po indukcijski predpostavki velja `Γ ⊢ M1' : B → A`, iz česar sledi tudi
  `Γ ⊢ M1' M2 : A`.

* `V1 M2 ↝ V1 M2'`, mora veljati `M2 ↝ M2'`,
  iz `Γ ⊢ V1 M2 : A` pa sledi
  `Γ ⊢ V1 : B → A` in `Γ ⊢ M2 : B` za nek `B`.
  Po indukcijski predpostavki velja `Γ ⊢ M2' : B`, iz česar sledi tudi
  `Γ ⊢ V M2' : A`.

* `(λx. M) V ↝ M[V / x]`,
  iz `Γ ⊢ (λx. M) V : A` sledi
  `Γ ⊢ (λx. M) : B → A` in `Γ ⊢ V : B` za nek `B`.
  Iz prvega sledi `Γ, x : B ⊢ M : A`,
  z drugim pa prek leme o substituciji izpeljemo `Γ ⊢ M[V / x] : A`.
