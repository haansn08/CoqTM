Require Import TM.Prelim.
Require Import TM.Basic.Mono.
Require Import TM.Combinators.Match TM.Combinators.While TM.Combinators.SequentialComposition.
Require Import TM.Mirror.
Require Import TM.Compound.TMTac.

Require Import FunInd.
Require Import Recdef.

Section move_to_symbol.
  
  Variable sig : finType.
  Variable f : sig -> bool.

  (*
   * One Step:
   * Read one symbol.  If there was no symbol, return [ None ].
   * If the read symbol fulfills [ f ], return [ Some true ].
   * Else move one to the right and return [ Some false ].
   *)
  Definition M1 : { M : mTM sig 1 & states M -> bool * bool} :=
    MATCH (Read_char _)
          (fun b : option sig =>
             match b with
             | Some x => if f x
                        then mono_Nop _ (false, true) (* found the symbol, break and return true *)
                        else Move _ R (true, false) (* wrong symbol, move right and continue *)
             | _ => mono_Nop _ (false, false) (* there is no such symbol, break and return false *)
             end).

  Definition M1_Fun : tape sig -> tape sig :=
    fun t1 =>
      match t1 with
      | midtape ls x rs => if (f x) then t1 else tape_move_right t1
      | _ => t1
      end.

  Definition M1_Rel : Rel (tapes sig 1) (bool * bool * tapes sig 1) :=
    Mk_R_p (fun tin '(yout, tout) =>
              tout = M1_Fun tin /\
              (
                (yout = (false, true)  /\ exists s, current tin = Some s /\ f s = true ) \/
                (yout = (true, false)  /\ exists s, current tin = Some s /\ f s = false) \/
                (yout = (false, false) /\ current tin = None)
              )
           ).  

  Lemma M1_Rel_functional : functional M1_Rel.
  Proof. hnf. TMCrush idtac; auto. Qed.

  Lemma M1_RealiseIn :
    M1 ⊨c(3) M1_Rel.
  Proof.
    eapply RealiseIn_monotone.
    {
      unfold M1. eapply Match_RealiseIn. eapply read_char_sem. cbn.
      instantiate (2 := fun o : option sig => match o with Some x => if f x then _ else _ | None => _ end).
      intros [ | ]; cbn.
      - destruct (f e). 
        + instantiate (1 := 1). eapply mono_Nop_Sem.
        + eapply Move_Sem.
      - eapply mono_Nop_Sem.
    }
    {
      (cbn; omega).
    }
    {
      unfold M1_Rel, M1_Fun.
      TMCrush idtac; TMSolve 6.
    }
  Qed.

  (*
   * The main loop of the machine.
   * Execute M1 in a loop until M1 returned [ None ] or [ Some true ]
   *)
  Definition MoveToSymbol : { M : mTM sig 1 & states M -> bool } := WHILE M1.
      
  Definition rlength (t : tape sig) :=
    match t with
    | niltape _ => 0
    | rightof _ _ => 0
    | midtape ls m rs => 1 + length rs
    | leftof r rs => 2 + length rs
    end.

  (* Function of M2 *)
  Function MoveToSymbol_Fun (t : tape sig) { measure rlength t } : tape sig :=
    match t with
    | midtape ls m rs => if f m then t else MoveToSymbol_Fun (tape_move_right t)
    | _ => t
    end.
  Proof.
    all: (intros; try now (cbn; omega)). destruct rs; cbn; omega.
  Qed.

  Lemma M1_Fun_M2_None t :
    current t = None ->
    MoveToSymbol_Fun t = M1_Fun t.
  Proof.
    intros H1. destruct t; cbn in *; inv H1; rewrite MoveToSymbol_Fun_equation; auto.
  Qed.

  Lemma M1_None t :
    current t = None ->
    M1_Fun t = t.
  Proof.
    intros H1. unfold M1_Fun. destruct t; cbn in *; inv H1; auto.
  Qed.

  Lemma M1_true t x :
    current t = Some x ->
    f x = true ->
    M1_Fun t = t.
  Proof.
    intros H1 H2. unfold M1_Fun. destruct t; cbn in *; inv H1. rewrite H2. auto.
  Qed.
  
  Lemma M1_Fun_M2_true t x :
    current t = Some x ->
    f x = true ->
    MoveToSymbol_Fun t = M1_Fun t.
  Proof.
    intros H1 H2. destruct t; cbn in *; inv H1. rewrite MoveToSymbol_Fun_equation, H2. auto.
  Qed.

  Lemma MoveToSymbol_M1_false t x :
    current t = Some x ->
    f x = false ->
    MoveToSymbol_Fun (M1_Fun t) = MoveToSymbol_Fun t.
  Proof.
    intros H1 H2. functional induction MoveToSymbol_Fun t; cbn.
    - rewrite e0. rewrite MoveToSymbol_Fun_equation. rewrite e0. reflexivity.
    - rewrite e0. destruct rs; auto.
    - destruct _x; rewrite MoveToSymbol_Fun_equation; cbn; auto.
  Qed.

  
  Definition MoveToSymbol_Rel : Rel (tapes sig 1) (bool * tapes sig 1) :=
    Mk_R_p (fun tin '(yout, tout) =>
              tout = MoveToSymbol_Fun tin /\
              (
                (yout = true  /\ exists s, current tout = Some s /\ f s = true ) \/
                (yout = false /\ current tout = None)
              )
           ).

  Lemma MoveToSymbol_WRealise :
    MoveToSymbol ⊫ MoveToSymbol_Rel.
  Proof.
    eapply WRealise_monotone.
    {
      unfold MoveToSymbol. eapply While_WRealise. eapply Realise_WRealise, RealiseIn_Realise. eapply M1_RealiseIn.
    }
    {

      hnf. intros tin (y1&tout) H. hnf in *. destruct H as (t1&H&H2). hnf in *.
      induction H as [x | x y z IH1 _ IH2].
      {
        TMCrush idtac; TMSolve 6.
        all: repeat progress (unfold M1_Fun, M1_Rel, MoveToSymbol_Rel, Mk_R_p in *).
        all: try rewrite MoveToSymbol_Fun_equation; auto.
        all: TMCrush idtac; TMSolve 6.
      }
      {
        TMCrush idtac; TMSolve 6.
        all:
          try now
              (
                rewrite MoveToSymbol_Fun_equation; TMSimp; auto
              ).
        all: erewrite <- MoveToSymbol_M1_false; eauto.
      }
    }
  Qed.


  Lemma MoveToSymbol_Fun_tapesToList t : tapeToList (MoveToSymbol_Fun t) = tapeToList t .
  Proof.
    functional induction MoveToSymbol_Fun t; auto; simpl_tape in *; cbn in *; congruence.
  Qed.
  Hint Rewrite MoveToSymbol_Fun_tapesToList : tape.

  Lemma tape_move_niltape (t : tape sig) (D : move) : tape_move t D = niltape _ -> t = niltape _.
  Proof. destruct t, D; cbn; intros; try congruence. destruct l; congruence. destruct l0; congruence. Qed.

  Lemma MoveToSymbol_Fun_niltape t : MoveToSymbol_Fun t = niltape _ -> t = niltape _.
  Proof.
    intros H. remember (niltape sig) as N. functional induction MoveToSymbol_Fun t; subst; try congruence.
    - specialize (IHt0 H). destruct rs; cbn in *; congruence.
    (* - specialize (IHt0 H). destruct rs; cbn in *; congruence. *)
  Qed.


  (** Termination *)

  Function MoveToSymbol_TermTime (t : tape sig) { measure rlength t } : nat :=
    match t with
    | midtape ls m rs => if f m then 4 else S (S (S (S (MoveToSymbol_TermTime (tape_move_right t)))))
    | _ => 4
    end.
  Proof.
    all: (intros; try now (cbn; omega)). destruct rs; cbn; omega.
  Qed.


  (* Idee: Lösung des Problems kanonische Relation ranklatschen, damit die relation funktional wird. *)
  Lemma MoveToSymbol_terminates :
    projT1 MoveToSymbol ↓ (fun tin k => k = MoveToSymbol_TermTime (tin[@Fin.F1])).
  Proof.
    eapply While_terminatesIn.
    1-2: eapply Realise_total; eapply M1_RealiseIn.
    {
      eapply functional_functionalOn. apply M1_Rel_functional.
    }
    {
      intros tin k ->. destruct_tapes. cbn.
      destruct h eqn:E; cbn.
      - rewrite MoveToSymbol_TermTime_equation. exists [|h|], false. cbn. do 2 eexists; split; eauto.
      - rewrite MoveToSymbol_TermTime_equation. exists [|h|], false. cbn. do 2 eexists; split; eauto.
      - rewrite MoveToSymbol_TermTime_equation. exists [|h|], false. cbn. do 2 eexists; split; eauto.
      - destruct (f e) eqn:E2; cbn.
        + rewrite MoveToSymbol_TermTime_equation. exists [|h|], false. cbn. rewrite E2. do 2 eexists; split; eauto 6.
        + rewrite MoveToSymbol_TermTime_equation. exists [|tape_move_right h|], true. cbn. rewrite E2.
          destruct l0; rewrite E; cbn in *; do 2 eexists; split; eauto 7.
    }
  Qed.
  
    
    

  (** Move to left *)

  Definition MoveToSymbol_L := Mirror MoveToSymbol.

  
  (*

  Definition llength (t : tape sig) :=
    match t with
    | niltape _ => 0
    | leftof _ _ => 0
    | midtape ls m rs => 1 + length ls
    | rightof l ls => 2 + length ls
    end.

  Function MoveToSymbol_L_Fun (t : tape sig) { measure llength t } : tape sig :=
    match t with
    | midtape ls m rs => if f m then t else MoveToSymbol_L_Fun (tape_move_left t)
    | _ => t
    end.
  Proof.
    all: (intros; try now (cbn; omega)). destruct ls; cbn; omega.
  Qed.

  Lemma moveToSymbol_mirror t t' :
    MoveToSymbol_Fun (mirror_tape t) = mirror_tape t' -> MoveToSymbol_L_Fun t = t'.
  Proof.
    functional induction MoveToSymbol_L_Fun t; intros H; cbn in *; try reflexivity;
      rewrite MoveToSymbol_Fun_equation in H; cbn; auto.
    - rewrite e0 in *; cbn in *; destruct t'; cbn in *; congruence.
    - rewrite e0 in *; cbn in *. destruct ls; cbn in *; rewrite MoveToSymbol_Fun_equation, MoveToSymbol_L_Fun_equation in *.
      + destruct t'; cbn in *; now inv H.
      + destruct (f e) eqn:E1; cbn in *; eauto.
    - destruct t, t'; cbn in *; auto; congruence.
  Qed.

  Definition MoveToSymbol_L_Rel : Rel (tapes sig 1) (FinType (EqType bool) * tapes sig 1) :=
    Mk_R_p ((if? (fun t t' => exists s, current t' = Some s /\ f s = true)
               ! (fun t t' => current t' = None)) ∩ ignoreParam (fun t t' => moveToSymbol_L t = t')).


  Definition MoveToSymbol_L := Mirror MoveToSymbol_R.

  (* TODO: Reduce Termination, from termination of MoveTosymbol_R *)
  Lemma MoveToSymbol_L_WRealise :
    MoveToSymbol_L ⊫ MoveToSymbol_L_Rel.
  Proof.
    eapply WRealise_monotone.
    - eapply Mirror_WRealise. eapply MoveToSymbol_R_WRealise.
    - intros tin (y&tout) H. hnf in *. destruct_tapes; cbn in *. destruct H as (H1&H2); hnf in *.
      split; hnf.
      + now rewrite mirror_tape_current in H1.
      + clear H1. now apply moveToSymbol_mirror.
  Qed.

*)

End move_to_symbol.