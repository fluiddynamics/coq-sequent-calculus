Require Export PropLang.
Require Export List.
Require Export Subcontext.

Section SequentCalculus.

Context {atom : Type}.

Reserved Notation "Γ ⇒ P" (no associativity, at level 61).

Inductive SC_proves : list (prop atom) -> prop atom -> Prop :=
| SC_init {P Γ} : In P Γ -> Γ ⇒ P
| SC_bot_elim {P Γ} : In ⊥ Γ -> Γ ⇒ P
| SC_top_intro {Γ} : Γ ⇒ ⊤
| SC_and_intro {Γ P Q} : Γ ⇒ P -> Γ ⇒ Q -> Γ ⇒ P ∧ Q
| SC_and_elim {Γ P Q R} : In (P ∧ Q) Γ -> P :: Q :: Γ ⇒ R -> Γ ⇒ R
| SC_or_introl {Γ P Q} : Γ ⇒ P -> Γ ⇒ P ∨ Q
| SC_or_intror {Γ P Q} : Γ ⇒ Q -> Γ ⇒ P ∨ Q
| SC_or_elim {Γ P Q R} : In (P ∨ Q) Γ -> P :: Γ ⇒ R -> Q :: Γ ⇒ R ->
  Γ ⇒ R
| SC_impl_intro {Γ P Q} : P :: Γ ⇒ Q -> Γ ⇒ P ⊃ Q
| SC_impl_elim {Γ P Q R} : In (P ⊃ Q) Γ -> Γ ⇒ P -> Q :: Γ ⇒ R ->
  Γ ⇒ R
where "Γ ⇒ P" := (SC_proves Γ P).

Proposition SC_consistent : ~ (nil ⇒ ⊥).
Proof.
intro. inversion H; repeat match goal with
       | H0 : In _ nil |- _ => destruct H0
       end.
Qed.

Global Instance SC_context_extension :
  Proper (subcontext ++> eq ==> Basics.impl) SC_proves.
Proof.
intros Γ₁ Γ₂ ? P Q [] ?. clear Q; revert Γ₂ H.
induction H0; eauto using SC_proves.
+ intros. apply @SC_and_elim with (P := P) (Q := Q); auto.
  apply IHSC_proves. repeat f_equiv. assumption.
+ intros. apply @SC_or_elim with (P := P) (Q := Q); auto.
  - apply IHSC_proves1. f_equiv; assumption.
  - apply IHSC_proves2. f_equiv; assumption.
+ intros. apply SC_impl_intro. apply IHSC_proves. f_equiv; assumption.
+ intros. apply @SC_impl_elim with (P := P) (Q := Q); auto.
  apply IHSC_proves2. f_equiv; assumption.
Qed.

Inductive subterm : prop atom -> prop atom -> Prop :=
| subterm_and_l {P Q} : subterm P (P ∧ Q)
| subterm_and_r {P Q} : subterm Q (P ∧ Q)
| subterm_or_l {P Q} : subterm P (P ∨ Q)
| subterm_or_r {P Q} : subterm Q (P ∨ Q)
| subterm_impl_l {P Q} : subterm P (P ⊃ Q)
| subterm_impl_r {P Q} : subterm Q (P ⊃ Q).

Lemma subterm_ind_scheme : forall (A : prop atom -> Prop),
  (forall P (IHP : forall P', subterm P' P -> A P'), A P) ->
  forall P, A P.
Proof.
intros A F; induction P; apply F; inversion 1; auto.
Qed.

Lemma SC_admits_cut_ext : forall P Q Γ Γ',
  Γ ⇒ P -> Γ' ⊆ P :: Γ -> Γ' ⇒ Q -> Γ ⇒ Q.
Proof.
induction P using subterm_ind_scheme. intros.
revert Γ H H0; induction H1; intros.
all: try match goal with
     | H : In _ ?Γ, H1 : ?Γ ⊆ _ |- _ => pose proof (H1 _ H)
     end.
all: repeat match goal with
     | H : In _ (_ :: _) |- _ => destruct H
     end.
all: subst.
+ assumption.
+ apply SC_init; assumption.
+ remember ⊥ as R. induction H0; try discriminate; subst.
  - apply SC_bot_elim; assumption.
  - apply SC_bot_elim; assumption.
  - apply (SC_and_elim H0). apply IHSC_proves; trivial.
    rewrite H1; prove_subcontext.
  - apply (SC_or_elim H0).
    * apply IHSC_proves1; trivial. rewrite H1; prove_subcontext.
    * apply IHSC_proves2; trivial. rewrite H1; prove_subcontext.
  - apply (SC_impl_elim H0); trivial. apply IHSC_proves2; trivial.
    rewrite H1; prove_subcontext.
+ apply SC_bot_elim; assumption.
+ apply SC_top_intro.
+ apply SC_and_intro.
  - apply IHSC_proves1; assumption.
  - apply IHSC_proves2; assumption.
+ remember (P0 ∧ Q) as S. pose proof H0; induction H0; try discriminate; subst.
  - apply (SC_and_elim H0). apply IHSC_proves; trivial.
    * do 2 rewrite <- subcontext_cons_r. assumption.
    * rewrite H2. prove_subcontext.
  - apply SC_bot_elim. assumption.
  - injection HeqS; intros; subst.
    eapply (IHP Q); trivial; [ constructor | reflexivity | idtac ].
    eapply (IHP P0); [ constructor | | reflexivity | ].
    * rewrite <- subcontext_cons_r; assumption.
    * apply IHSC_proves.
      { do 2 rewrite <- subcontext_cons_r. assumption. }
      { rewrite H2. prove_subcontext. }
  - apply (SC_and_elim H0). apply IHSC_proves0; trivial.
    rewrite H2. prove_subcontext.
  - apply (SC_or_elim H0).
    * apply IHSC_proves1; trivial. rewrite H2. prove_subcontext.
    * apply IHSC_proves2; trivial. rewrite H2. prove_subcontext.
  - apply (SC_impl_elim H0).
    * assumption.
    * apply IHSC_proves2; trivial. rewrite H2. prove_subcontext.
+ apply (SC_and_elim H3). apply IHSC_proves.
  - do 2 rewrite <- subcontext_cons_r. assumption.
  - rewrite H2. prove_subcontext.
+ apply SC_or_introl. apply IHSC_proves; trivial.
+ apply SC_or_intror. apply IHSC_proves; trivial.
+ remember (P0 ∨ Q) as S. pose proof H0; induction H0; try discriminate; subst.
  - apply (SC_or_elim H0).
    * apply IHSC_proves1; trivial.
      { rewrite <- subcontext_cons_r. assumption. }
      { rewrite H1. prove_subcontext. }
    * apply IHSC_proves2; trivial.
      { rewrite <- subcontext_cons_r. assumption. }
      { rewrite H1. prove_subcontext. }
  - apply SC_bot_elim. assumption.
  - apply (SC_and_elim H0). apply IHSC_proves; trivial.
    rewrite H1. prove_subcontext.
  - injection HeqS; intros; subst.
    eapply (IHP P0); trivial; [ constructor | reflexivity | ].
    apply IHSC_proves1; trivial.
    * rewrite <- subcontext_cons_r. assumption.
    * rewrite H1. prove_subcontext.
  - injection HeqS; intros; subst.
    eapply (IHP Q); trivial; [ constructor | reflexivity | ].
    apply IHSC_proves2; trivial.
    * rewrite <- subcontext_cons_r. assumption.
    * rewrite H1. prove_subcontext.
  - apply (SC_or_elim H0).
    * apply IHSC_proves3; trivial. rewrite H1. prove_subcontext.
    * apply IHSC_proves4; trivial. rewrite H1. prove_subcontext.
  - apply (SC_impl_elim H0); trivial.
    apply IHSC_proves4; trivial. rewrite H1. prove_subcontext.
+ apply (SC_or_elim H2).
  - apply IHSC_proves1.
    * rewrite <- subcontext_cons_r. assumption.
    * rewrite H1. prove_subcontext.
  - apply IHSC_proves2.
    * rewrite <- subcontext_cons_r. assumption.
    * rewrite H1. prove_subcontext.
+ apply SC_impl_intro. apply IHSC_proves; trivial.
  - rewrite <- subcontext_cons_r. assumption.
  - rewrite H0. prove_subcontext.
+ remember (P0 ⊃ Q) as S. pose proof H0; induction H0; try discriminate; subst.
  - apply (SC_impl_elim H0).
    * apply IHSC_proves1; trivial.
    * apply IHSC_proves2.
      { rewrite <- subcontext_cons_r. assumption. }
      { rewrite H1. prove_subcontext. }
  - apply SC_bot_elim; assumption.
  - apply (SC_and_elim H0). apply IHSC_proves; trivial.
    rewrite H1. prove_subcontext.
  - apply (SC_or_elim H0).
    * apply IHSC_proves3; trivial. rewrite H1. prove_subcontext.
    * apply IHSC_proves4; trivial. rewrite H1. prove_subcontext.
  - injection HeqS; intros; subst. clear IHSC_proves.
    eapply (IHP Q); [ constructor | | reflexivity | ].
    * eapply (IHP P0); [ constructor | | reflexivity | assumption ].
      apply IHSC_proves1; trivial.
    * apply IHSC_proves2; trivial.
      { rewrite <- subcontext_cons_r; assumption. }
      { rewrite H1. prove_subcontext. }
  - apply (SC_impl_elim H0); trivial. apply IHSC_proves4; trivial.
    rewrite H1. prove_subcontext.
+ apply (SC_impl_elim H2).
  - apply IHSC_proves1; trivial.
  - apply IHSC_proves2.
    * rewrite <- subcontext_cons_r. assumption.
    * rewrite H1. prove_subcontext.
Qed.

Theorem SC_admits_cut : forall Γ P Q,
  Γ ⇒ P -> P :: Γ ⇒ Q -> Γ ⇒ Q.
Proof.
intros. eapply SC_admits_cut_ext; (eassumption || reflexivity).
Qed.

End SequentCalculus.

Infix "⇒" := SC_proves (no associativity, at level 61).
