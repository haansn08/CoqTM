Require Import CodeTM.
Require Import TM.Basic.WriteString.
Require Import Basic.Mono.


Lemma WriteString_L_right (sig : Type) (str : list sig) t :
  right (WriteString_Fun L t str) = rev str ++ right t.
Proof.
  revert t. induction str; intros; cbn in *.
  - reflexivity.
  - rewrite IHstr. simpl_tape. rewrite <- app_assoc. reflexivity.
Qed.

Arguments WriteString_Fun : simpl never.

Section WriteValue.

  Variable (sig: finType) (X: Type) (cX: codable sig X).

  Definition WriteValue (x:X) : { M : mTM sig^+ 1 & states M -> unit } :=
    WriteString L (inl STOP :: rev (encode x));; Write (inl START) tt.

  Definition WriteValue_Rel (x : X) : Rel (tapes sig^+ 1) (unit * tapes sig^+ 1) :=
    Mk_R_p (ignoreParam (fun tin tout => isRight tin -> tout ≃ x)).


  Lemma WriteValue_Sem (x : X) :
    WriteValue x ⊨c(5 + 3 * length (cX x)) WriteValue_Rel x.
  Proof.
    eapply RealiseIn_monotone.
    { unfold WriteValue. repeat TM_Correct. eapply WriteString_Sem. }
    { cbn. rewrite rev_length, map_length. apply Nat.eq_le_incl. omega. }
    {
      intros tin ((), tout) H. intros HRight.
      TMSimp; clear_trivial_eqs.
      repeat econstructor. f_equal. rewrite WriteString_L_right. cbn.
      rewrite <- app_assoc. rewrite rev_involutive. rewrite isRight_right; auto.
    }
  Qed.

End WriteValue.