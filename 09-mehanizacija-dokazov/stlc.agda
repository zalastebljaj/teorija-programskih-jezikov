data Ty : Set where
    BOOL : Ty
    _⇒_ : Ty → Ty → Ty

data Ctx : Set where
    ∅ : Ctx
    _,_ : Ctx → Ty → Ctx

data _∈_ : Ty → Ctx → Set where
    Z : {A : Ty} {Γ : Ctx} → A ∈ (Γ , A)
    S : {A B : Ty} {Γ : Ctx} → A ∈ Γ → A ∈ (Γ , B)

data _⊢_ : Ctx → Ty → Set where

    VAR : {Γ : Ctx} {A : Ty} →
        A ∈ Γ →
        -----
        Γ ⊢ A

    TRUE : {Γ : Ctx} →
        --------
        Γ ⊢ BOOL

    FALSE : {Γ : Ctx} →
        --------
        Γ ⊢ BOOL

    IF_THEN_ELSE_ : {Γ : Ctx} {A : Ty} →
        Γ ⊢ BOOL →
        Γ ⊢ A →
        Γ ⊢ A →
        -----
        Γ ⊢ A

    _∙_ : {Γ : Ctx} {A B : Ty} →
        Γ ⊢ (A ⇒ B) →
        Γ ⊢ A →
        -----
        Γ ⊢ B

    ƛ : {Γ : Ctx} {A B : Ty} →
        (Γ , A) ⊢ B →
        -----------
        Γ ⊢ (A ⇒ B)

data _⇉_ : Ctx → Ctx → Set where
    [] : {Δ : Ctx} → ∅ ⇉ Δ
    _,_ : {Γ Δ : Ctx} (σ : Γ ⇉ Δ) {A : Ty} → Δ ⊢ A → (Γ , A) ⇉ Δ

lookup : {Γ Δ : Ctx} {A : Ty} → Γ ⇉ Δ → A ∈ Γ → Δ ⊢ A
lookup (σ , M) Z = M
lookup (σ , _) (S x) = lookup σ x

subst : {Γ Δ : Ctx} {A : Ty} → Γ ⇉ Δ → Γ ⊢ A → Δ ⊢ A
subst σ (VAR x) = lookup σ x
subst σ TRUE = TRUE
subst σ FALSE = TRUE
subst σ (IF M THEN M₁ ELSE M₂) = IF (subst σ M) THEN (subst σ M₁) ELSE (subst σ M₂)
subst σ (M ∙ N) = (subst σ M) ∙ subst σ N
subst σ (ƛ {A = A} M) = ƛ (subst {!   !} M)

data value : {Γ : Ctx} {A : Ty} → Γ ⊢ A → Set where
    value-TRUE : {Γ : Ctx} →
        ----------------
        value (TRUE {Γ})
    value-FALSE : {Γ : Ctx} →
        -----------------
        value (FALSE {Γ})
    value-LAMBDA : {Γ : Ctx} {A B : Ty} {M : (Γ , A) ⊢ B} →
        -----------
        value (ƛ M)

data _↝_ : {A : Ty} → ∅ ⊢ A → ∅ ⊢ A → Set where
    IF-TRUE : {A : Ty} {M₁ M₂ : ∅ ⊢ A} →
        ------------------------------
        (IF TRUE THEN M₁ ELSE M₂) ↝ M₁
    IF-FALSE : {A : Ty} {M₁ M₂ : ∅ ⊢ A} →
        ------------------------------
        (IF FALSE THEN M₁ ELSE M₂) ↝ M₂
    IF-STEP : {A : Ty} {M M' : ∅ ⊢ BOOL} {M₁ M₂ : ∅ ⊢ A} →
        M ↝ M' →
        ------------------------------------------------
        (IF M THEN M₁ ELSE M₂) ↝ (IF M' THEN M₁ ELSE M₂)
    APP-STEP1 : {A B : Ty} {M M' : ∅ ⊢ (A ⇒ B)} {N : ∅ ⊢ A} →
        M ↝ M' →
        ------------------------------------------------
        (M ∙ N) ↝ (M' ∙ N)
    APP-STEP2 : {A B : Ty} {M : ∅ ⊢ (A ⇒ B)} {N N' : ∅ ⊢ A} →
        value M →
        N ↝ N' →
        ------------------------------------------------
        (M ∙ N) ↝ (M ∙ N')
    APP-BETA : {A B : Ty} {M : (∅ , A) ⊢ B} {N : ∅ ⊢ A} →
        value N →
        ------------------------------------------------
        ((ƛ M) ∙ N) ↝ subst ([] , N) M

data Progress : {A : Ty} → ∅ ⊢ A → Set where
    is-value : {A : Ty} {M : ∅ ⊢ A} →
        value M →
        ----------
        Progress M
    steps : {A : Ty} {M M' : ∅ ⊢ A} →
        M ↝ M' →
        ----------
        Progress M

progress : {A : Ty} → (M : ∅ ⊢ A) → Progress M
progress TRUE = is-value value-TRUE
progress FALSE = is-value value-FALSE
progress (IF M THEN M₁ ELSE M₂) with progress M
... | is-value value-TRUE = steps IF-TRUE
... | is-value value-FALSE = steps IF-FALSE
... | steps M↝M' = steps (IF-STEP M↝M')
progress (M ∙ N) with progress M
... | steps M↝M' = steps (APP-STEP1 M↝M')
... | is-value value-LAMBDA with progress N
...     | is-value V = steps (APP-BETA V)
...     | steps N↝N' = steps (APP-STEP2 value-LAMBDA N↝N')
progress (ƛ M) = is-value value-LAMBDA
