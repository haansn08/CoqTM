Require Import TM.

Section Nop.

  Variable n : nat.
  Variable sig : finType.

  Definition null_action m := repeatVector m (@None sig, N).

  Lemma tape_move_null_action m tapes :
    tape_move_multi tapes (null_action m) = tapes.
  Proof.
    induction tapes; cbn in *; eauto using f_equal.
  Qed.

  Definition nop_trans := fun (p : (FinType (EqType unit)) * Vector.t (option sig) n)  => let (q,a) := p in (q, null_action n).

  Definition nop : mTM sig n :=
    Build_mTM nop_trans tt (fun _ => true).

  Variable F : finType.
  Variable f : F.

  Definition Nop := (nop; fun _ => f).

  Lemma Nop_total: Nop ⊨(0) (↑ (=f) ⊗ (@IdR _)).
  Proof.
    intros ?. exists (initc nop t). cbn. firstorder.
  Qed.

  Lemma Nop_sem: Nop ⊫ (↑ (=f) ⊗ (@IdR _)).
  Proof.
    intros ? ? ? ?. hnf. destruct i; cbn in *; now inv H.
  Qed.

  Lemma terminates_nop : terminatesIn nop (fun x i => True).
  Proof.
    intros ? ? ?. exists (initc nop t). now destruct i.
  Qed.

End Nop.
Arguments null_action {_ _}.
