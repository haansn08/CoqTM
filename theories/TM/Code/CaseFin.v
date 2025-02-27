(** * Constructors and Deconstructors for Finite Types *)

Require Import ProgrammingTools.

Section CaseFin.

  Variable sig : finType.
  Hypothesis defSig : inhabitedC sig.

  Definition CaseFin : pTM sig^+ sig 1 :=
    Move R;;
    Switch (ReadChar)
    (fun s => match s with
           | Some (inr x) => Return (Move R) x
           | _ => Return (Nop) default
           end).

  (** Note that [Encode_Finite] is not globally declared as an instance, because that would cause ambiguity. For example, [bool+bool] is finite, but we might want to encode it with [Encode_sum Encode_bool Encode_bool]. *)
  Local Existing Instance Encode_Finite.

  Definition CaseFin_Rel : pRel sig^+ sig 1 :=
    fun tin '(yout, tout) => forall x : sig, tin[@Fin0] ≃ x -> isRight tout[@Fin0] /\ yout = x.

  Lemma CaseFin_Sem : CaseFin ⊨c(5) CaseFin_Rel.
  Proof.
    eapply RealiseIn_monotone.
    { unfold CaseFin. TM_Correct. }
    { Unshelve. 4,8:reflexivity. all:lia. }
    {
      intros tin (yout, tout) H. intros x HEncX.
      destruct HEncX as (ls&HEncX).
      TMSimp. repeat econstructor.
    }
  Qed.

  (** There is no need for a constructor, just use [WriteValue] *)

End CaseFin.


Arguments CaseFin : simpl never.
Arguments CaseFin sig {_}. (** Default element is infered and inserted automatically *)



Ltac smpl_TM_CaseFin :=
  lazymatch goal with
  | [ |- CaseFin _ ⊨ _ ] => eapply RealiseIn_Realise; apply CaseFin_Sem
  | [ |- CaseFin _ ⊨c(_) _ ] => apply CaseFin_Sem
  | [ |- projT1 (CaseFin _) ↓ _ ] => eapply RealiseIn_TerminatesIn; apply CaseFin_Sem
  end.

Smpl Add smpl_TM_CaseFin : TM_Correct.