Require Import Prelim TM.Relations TM Shared.Tactics.AutoIndTac Compound Injection.

Section Suffix.
  Variable X : Type.

  Definition suffix (a b : list X) : Prop := exists i, List.skipn i a = b.

End Suffix.


Section In_Inductive.
  Variable X : Type.
  
  Inductive In_ind (x : X) : list X -> Type :=
  | In_ind_1 (xs : list X) : In_ind x (x :: xs)
  | In_ind_2 (y : X) (xs : list X) : x <> y -> In_ind x xs -> In_ind x (y::xs).

  Variable X_dec : eq_dec X.

  Lemma nth_error_In_ind xs n y : nth_error xs n = Some y -> In_ind y xs.
  Proof.
    revert y xs. induction n as [ | n IH]; intros y xs H; cbn in *.
    - destruct xs as [ | x xs].
      + discriminate.
      + inv H. constructor. 
    - destruct xs as [ | x xs].
      + discriminate.
      + decide (x = y) as [->|H1].
        * constructor.
        * constructor; auto.
  Qed.

  Lemma In_ind_In (x : X) (xs : list X) :
    In_ind x xs -> In x xs.
  Proof. induction 1; cbn; auto. Qed.

End In_Inductive.



Section MapOptBreak.
  Variable X Y : finType.
  Variable f : X -> option Y.

  Fixpoint mapOptBreak (xs : list X) : list Y :=
    match xs with
    | nil => nil
    | x :: xs' => match (f x) with
                 | None => nil
                 | Some y => y :: mapOptBreak xs'
                 end
    end.
  
  Lemma mapOpt_correct_Some (xs : list X) :
    let ys := mapOptBreak xs in
    forall (i : nat) (y : Y), List.nth_error ys i = Some y ->
                       { x : X | f x = Some y }.
  Proof.
    cbn. induction xs; intros ***; cbn in *.
    - now apply nth_error_nil in H.
    - destruct (f a) as [y' | ] eqn:E.
      + pose proof H as H'.
        apply nth_error_In_ind in H. inversion H; subst.
        * eexists. eapply E.
        * apply In_ind_In in X0.
          destruct i; cbn in *.
          -- inv H'. eauto.
          -- now apply IHxs in H'.
        * auto.
      + now apply nth_error_nil in H.
  Qed.

  Lemma mapOpt_correct_find_cut (x : X) (xs : list X) (i : nat) :
    List.nth_error (x :: xs) i = None -> |mapOptBreak xs| < |x :: xs|.
  Proof.
    revert i x. induction xs as [ | x xs IH]; intros ***; cbn in *.
    - omega.
    - destruct (f x); cbn.
      + enough (|mapOptBreak xs| < S (|xs|)) by omega. eapply IH with (x := x).
        apply List.nth_error_None in H. apply List.nth_error_None. eauto.
      + omega.
  Qed.

  (*
  Lemma mapOpt_correct_None (xs : list X) :
    mapOptBreak xs = [] -> forall x, In x xs ->
  *)

End MapOptBreak.


Section Filter_First.

  Variable X : Type.
  Variable P : X -> bool.

  (* Return the elements from the first element for that P does not hold *)
  Definition filter_first : list X -> list X.
  Proof.
    intros xs.
    destruct (find_i (fun e => P e = false) xs).
    - apply (List.skipn n xs).
    - apply nil.
  Defined.

End Filter_First.


Section Surject.
  Variable sig tau : finType.
  Variable g : tau -> option sig.
  Variable n : nat.

  Definition surject : tape tau -> tape sig.
  Proof.
    destruct 1.
    - apply niltape.
    - destruct (g e).
      + apply leftof. apply e0. apply (mapOptBreak g), l.
      + apply niltape.
    - destruct (g e).
      + apply rightof. apply e0. apply (mapOptBreak g), l.
      + apply niltape.
    - destruct (g e).
      + apply midtape. apply (mapOptBreak g), l. apply e0. apply (mapOptBreak g), l0.
      + apply niltape. (* TODO ? *)
  Defined.

  Definition surjectn : Vector.t (tape tau) n -> Vector.t (tape sig) n := Vector.map surject.

End Surject.

Section lift_sigma_tau.
  Variable n : nat.
  Variable sig tau : finType.
  Variable g : tau -> option sig.
  Variable Z : Type.
  
  Definition lift_sigma_tau (R : Rel (Vector.t (tape sig) n) (Vector.t (tape sig) n)) :
    Rel (Vector.t (tape tau) n) (Vector.t (tape tau) n) :=
    fun x y => R (surjectn g x) (surjectn g y).

  Definition lift_sigma_tau_p (R : Rel (Vector.t (tape sig) n) (Z * Vector.t (tape sig) n)) :
    Rel (Vector.t (tape tau) n) (Z * Vector.t (tape tau) n) :=
    fun x p => let (z,y) := p in R (surjectn g x) (z, surjectn g y).    

  Definition convertable : tau -> bool := fun t => match g t with None => false | Some _ => true end.

  Definition lift_not_convertable : relation (tape tau).
  Proof.
    intros x y.
    destruct y as [ | ey ly | ey ly | ey ly1 ly2] eqn:E.
    - apply (x = niltape tau).
    - destruct (g ey).
      + destruct x as [ | ex lx | _ _ | _ _ _ ]; [exact False| | exact False | exact False].
        destruct (g ex) as [_ | ]; [ | exact False].
        pose (lx' := filter_first convertable lx).
        pose (ly' := filter_first convertable ly).
        exact (suffix lx' ly').
      + destruct x as [ | ex lx | _ _ | _ _ _ ]; [exact False| | exact False | exact False].
  Admitted.

  Definition lift_not_convertable_n : relation (Vector.t (tape tau) n) :=
    fun xt yt => forall (i : Fin.t n), lift_not_convertable (Vector.nth xt i) (Vector.nth yt i).

  Definition lift_sigma_tau_eq (R : Rel (Vector.t (tape sig) n) (Vector.t (tape sig) n)) :
    Rel (Vector.t (tape tau) n) (Vector.t (tape tau) n) :=
    lift_sigma_tau R ∩ lift_not_convertable_n.
  
  Definition lift_sigma_tau_eq_p (R : Rel (Vector.t (tape sig) n) (Z * Vector.t (tape sig) n)) :
    Rel (Vector.t (tape tau) n) (Z * Vector.t (tape tau) n) :=
    lift_sigma_tau_p R ∩ ignoreParam (lift_not_convertable_n).
  
End lift_sigma_tau.
      

Section LiftSigmaTau.
  Variable sig tau : finType.
  Variable n : nat.
  Variable F : finType.
  Variable pMSig : { M : mTM sig n & states M -> F}.

  Variable I : injection_fun sig tau.
  Notation "'f'" := (inj_f I).
  Notation "'g'" := (inj_g I).

  Definition lift_trans :=
    fun '(q, symm) =>
      let (q', act) := trans (m := projT1 pMSig) (q, Vector.map (fun a => let try a' := a in g a') symm) in
      let act' := Vector.map (fun '(w, m) => (let try w' := w in Some (f w'), m)) act in
      (q', act').

  Definition liftM : mTM tau n.
  Proof.
    econstructor.
    exact lift_trans.
    exact (start (projT1 pMSig)).
    exact (halt (m := projT1 pMSig)).
  Defined.

  Definition Lift := (liftM; projT2 pMSig).

  Ltac dup H := let H' := fresh H in pose proof H as H'.

  Lemma surject_step :
    forall (tape : tape tau) (act : option sig * move),
      tape_move_mono (surject g tape) act =
      surject (inj_g I)
              (tape_move_mono tape
                              (let '(w, m) := act in (let try w' := w in Some (f w'), m))).
  Proof.
    intros tape act. destruct act as (w,m) eqn:E0.
    destruct tape eqn:E1; cbn.
    - destruct w as [w'| ]; cbn.
      + unfold tape_move_mono, tape_move, tape_write. cbn. destruct m; cbn; now rewrite inj_g_adjoint.
      + unfold tape_move_mono, tape_move, tape_write. cbn. destruct m; cbn; auto; now rewrite inj_g_adjoint.
    - destruct w as [w'| ] eqn:E2; cbn.
      + destruct (inj_g I e) eqn:E3.
        * unfold tape_move_mono, tape_move, tape_write; cbn. destruct m eqn:E4; cbn; now rewrite inj_g_adjoint, E3.
        * unfold tape_move_mono, tape_move, tape_write; cbn. destruct m eqn:E4; cbn; rewrite inj_g_adjoint, E3; auto.
          admit.
      + unfold tape_move_mono, tape_move, tape_write; cbn. destruct m; cbn; destruct (inj_g I e); auto.
    - destruct w as [w'| ] eqn:E2; cbn.
      + destruct (inj_g I e) eqn:E3.
        * unfold tape_move_mono, tape_move, tape_write; cbn. destruct m eqn:E4; cbn; now rewrite inj_g_adjoint, E3.
        * unfold tape_move_mono, tape_move, tape_write; cbn. destruct m eqn:E4; cbn; rewrite inj_g_adjoint, E3; auto.
          admit.
      + unfold tape_move_mono, tape_move, tape_write; cbn. destruct m; cbn; destruct (inj_g I e); auto.
    - destruct w as [w'| ] eqn:E2; cbn.
      + destruct (inj_g I e) eqn:E3.
        * unfold tape_move_mono, tape_move, tape_write; cbn. destruct m eqn:E4; cbn; try rewrite inj_g_adjoint, E3; admit.
        * unfold tape_move_mono, tape_move, tape_write; cbn. destruct m eqn:E4; cbn; try rewrite !inj_g_adjoint; try rewrite E3; auto; f_equal; admit.
      + unfold tape_move_mono, tape_move, tape_write; cbn. destruct m; cbn; destruct (inj_g I e); auto; admit.
  Admitted.

  Lemma sim_step (c1 c2 : mconfig tau (states (projT1 pMSig)) n) :
    step (M := liftM) c1 = c2 ->
    step (M := projT1 pMSig) (mk_mconfig (cstate c1) (surjectn g (ctapes c1))) =
    (mk_mconfig (cstate c2) (surjectn g (ctapes c2))).
  Proof.
    intros H. cbn.
    destruct c1 as [state1 tapes1] eqn:E1, c2 as [state2 tapes2] eqn:E2.
    unfold step in *. cbn in *.
    replace (fun a : option tau =>
                match a with
                | Some a0 => g a0
                | None => None
                end) with (fun a : option tau => let try a' := a in inj_g I a') in H by reflexivity.

    destruct (trans
                (state1, Vector.map (fun a : option tau => let try a' := a in g a')
                                    (Vector.map (current (sig:=tau)) tapes1))) as (q, act) eqn:E3.
    inv H.
    destruct (trans (state1, Vector.map (current (sig:=sig)) (surjectn (inj_g I) tapes1))) as (q', act') eqn:E4.
    enough ((state2, act) = (q', act')) as X.
    {
      inv X. f_equal.
      rewrite <- E3 in E4.

      unfold surjectn. apply Vector.eq_nth_iff. intros p ? <-.
      erewrite Vector.nth_map, Vector.nth_map2, Vector.nth_map; eauto.
      erewrite !Vector.nth_map2, !Vector.nth_map; eauto.
      (* again, stick to notations *)
      change (tape_move_mono (surject (inj_g I) tapes1[@p]) act'[@p] =
              surject g (tape_move_mono tapes1[@p]
                                        (let '(w, m) := act'[@p] in
                                         (let try w' := w in Some (f w'), m )))).
      (* generalize (act'[@p]) as act. generalize (tapes1[@p]) as tape. *)
      apply surject_step.
    }
    rewrite <- E3, <- E4. do 2 f_equal.
    apply Vector.eq_nth_iff. intros p ? <-.
    erewrite !Vector.nth_map; eauto.
    unfold surjectn, current. erewrite Vector.nth_map; eauto.
    destruct (tapes1[@p]) eqn:E5; cbn; auto; destruct g eqn:E6; cbn; auto.
  Qed.

  Lemma sim_loop (c1 c2 : mconfig tau (states liftM) n) (i : nat) :
    loopM (M := liftM) i c1 = Some c2 ->
    loopM (M := projT1 pMSig) i (mk_mconfig (cstate c1) (surjectn g (ctapes c1))) =
    Some (mk_mconfig (cstate c2) (surjectn g (ctapes c2))).
  Proof.
    unfold loopM in *. revert c2 c1. induction i; intros c2 c1 H; cbn in *.
    - destruct (halt _) eqn:E; now inv H.
    - destruct (halt _) eqn:E; inv H; auto.
      rewrite sim_step with (c1 := c1) (c2 := step (M := liftM) c1); [ | reflexivity]. apply IHi. apply H1.
  Qed.


  Lemma Lift_sem (R : Rel (tapes sig (S n)) (F * tapes sig (S n))) :
    pMSig ⊫ R ->
    Lift ⊫ lift_sigma_tau_eq_p g R.
  Proof.
    intros H. split.
    - apply (H (surjectn g t) i (mk_mconfig (cstate outc) (surjectn g (ctapes outc)))). now apply (@sim_loop (initc liftM t) outc i).
    - cbn. intros j.
  Admitted.
    

End LiftSigmaTau.
