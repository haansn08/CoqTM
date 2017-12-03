Require Export Shared.FiniteTypes.FinTypes Shared.FiniteTypes.BasicFinTypes Shared.FiniteTypes.CompoundFinTypes Shared.FiniteTypes.VectorFin  Shared.Tactics.AutoIndTac.
Require Export Shared.Extra Shared.Base.
Require Export Program.Equality.

Require Export smpl.Smpl.


(* Instance fin_eq_dec (A: finType) : eq_dec A. *)
(* Proof. *)
(*   now destruct A, type.  *)
(* Qed. *)

(* Definition graph_of := fun A B => fun (f:A -> B) => { p: A * B & f (fst p) = snd p}. *)
(* Definition graph_enum := fun (A B : finType) => fun (f : A -> B) => filter (fun (p : A * B) => Dec (f (fst p) = snd p)) (elem (A (x) B)). *)

Fixpoint loop (A:Type) n (f:A -> A) (p : A -> bool) a {struct n}:=
  if p a then Some a  else
    match n with
      O => None
    | S m => loop m f p (f a)
    end.

Lemma loop_functional A n1 n2 f p (a : A) c1 c2 : loop n1 f p a = Some c1 -> loop n2 f p a = Some c2 -> c1 = c2.
Proof.
  revert n2 c1 c2 a. induction n1; intros; cbn in *.
  - destruct (p a) eqn:E; inv H.
    destruct n2; cbn in H0; rewrite E in H0; now inv H0.
  - destruct (p a) eqn:E.
    + inv H. destruct n2; cbn in H0; rewrite E in H0; now inv H0.
    + destruct n2; cbn in H0; rewrite E in H0; try now inv H0.
      eauto.
Qed.
  
Lemma loop_fulfills_p A n f p (a : A) c : loop n f p a = Some c -> p c.
Proof.
  revert a; induction n; intros; inv H; destruct (p a) eqn:E; inv H1; eauto.
Qed.

Lemma loop_fulfills_p_0 A n f p (a : A) : p a = true -> loop n f p a = Some a.
Proof.
  intros. destruct n; cbn; now rewrite H.
Qed.

Fixpoint loop_informative (A : Type) (n : nat) (f : A -> A) (p : A -> bool) a : A + A :=
  if p a then inr a else
    match n with
    | 0 => inl a
    | S n => loop_informative n f p (f a)
    end.

Lemma loop_informative_spec A n f p (a : A) r : loop_informative n f p a = inr r <-> loop n f p a = Some r.
Proof.
  revert a r. induction n; intros; cbn in *.
  - destruct (p a) eqn:E; firstorder congruence.
  - destruct (p a) eqn:E.
    + firstorder congruence.
    + now rewrite IHn.
Qed.

Lemma loop_ext A f f' p p' (a : A) k :
  (forall a, p a = false -> f a = f' a) ->
  (forall a, p a = p' a) ->
  loop k f p a = loop k f' p a.
Proof.
  intros H. revert a. induction k; intros a; cbn; auto. destruct (p a) eqn:E; auto. rewrite H; auto.
Qed.

Lemma loop_ge A f p (a c : A) k1 k2 : k2 >= k1 -> loop k1 f p a = Some c -> loop k2 f p a = Some c.
Proof.
  revert a k2; induction k1; intros; cbn in *.
  - destruct k2; cbn; destruct (p a); now inv H0.
  - destruct (p a) eqn:E; inv H0.
    + destruct k2; cbn; rewrite E; reflexivity.
    + rewrite H2. destruct k2; [omega | ].
      cbn. rewrite E. rewrite IHk1; eauto. omega.
Qed.


Lemma loop_lift A B k lift f g h hlift (c1 c2 : A):
  (forall x , hlift (lift x) = h x) ->
  (forall x, h x = false -> lift (f x) = g (lift x)) ->
  loop k f h c1 = Some c2 ->
  loop (A := B) k g hlift (lift c1) = Some (lift c2).
Proof.
  revert c1; induction k; intros; cbn in *; rewrite H; destruct h eqn:E; inv H1; rewrite <- ?H0; eauto.
Qed.

Lemma loop_merge A f p q k1 k2 (a1 a2 a3 : A):
  (forall b, p b = false -> q b = false) ->
  loop k1 f p a1 = Some a2 ->
  loop k2 f q a2 = Some a3 ->
  loop (k1+k2) f q a1 = Some a3.
Proof.
  revert a1 a2 a3 k2. induction k1; intros; cbn in *.
  - now destruct p eqn:E; inv H0.
  - destruct (p a1) eqn:E.
    + inv H0. eapply (loop_ge (k2 := S (k1 + k2))) in H1. now rewrite <- H1. omega.
    + destruct (q a1) eqn:E1; try firstorder congruence. erewrite IHk1; eauto.
Qed.

Lemma loop_split A f p q k (a1 a3 : A):
  (forall b, p b = false -> q b = false) ->
  loop k f q a1 = Some a3 -> 
  exists k1 a2 k2, loop k1 f p a1 = Some a2 /\
              loop k2 f q a2 = Some a3 /\ k=k1+k2.  
Proof.
  intros weakens. revert a1. apply complete_induction with (x:=k);clear k; intros k IH a1 E.
  destruct k.
  -simpl in *.
   eexists 0,a1,0. cbn. destruct q eqn:Eq; inv E.
   destruct (p a3) eqn:E1.
   +auto.
   +apply weakens in E1. congruence.
  -cbn in E. destruct (p a1) eqn:Eq.
   +exists 0 ,a1,(1+k). now rewrite loop_fulfills_p_0.
   +rewrite (weakens _ Eq) in E.
    eapply IH in E as (k1&a2&k2&Eq1&Eq2&->);[ |omega].
    exists (1+k1), a2, k2; intuition.
    cbn. now rewrite Eq.
Qed.

Lemma loop_unlift A B f p f' p' (unlift : B -> option A):
  (forall a b, unlift b = Some a -> p a = false -> unlift (f' b) = Some (f a)) ->
  (forall a b, unlift b = Some a -> p a = p' b) ->
  forall a b,
  unlift b = Some a -> 
  forall i x',
  loop i f' p' b = Some x' ->
  exists x, loop i f p a = Some x /\ Some x = unlift x'.
Proof.
  intros Hf Hp a b Ha i x'. revert a b Ha x'. induction i; intros a b Ha x' Hl; cbn in *.
  - destruct (p' b) eqn:E; rewrite (Hp _ _ Ha) in *; inv Hl. rewrite E. eauto.
  - destruct (p' b) eqn:E; rewrite (Hp _ _ Ha) in *; inv Hl.
    + rewrite E. eauto.
    + rewrite E. eapply IHi; eauto.
Qed.

Section Fix_X.

  Variable X : Type.
  Fixpoint inb eqb (x:X) (A: list X) :=
    match A with
      List.nil => false
    | a::A' => orb (eqb a x) (inb eqb x A')
    end.

  Lemma inb_spec eqb: (forall (x y:X), Bool.reflect (x=y) (eqb x y)) -> forall x A, Bool.reflect (List.In x A) (inb eqb x A).
  Proof.
    intros R x A. induction A; firstorder; cbn.
    destruct (R a x); inv IHA; cbn; firstorder.
    constructor; tauto.
  Qed.

End Fix_X.

Require Import Vector.

Fixpoint repeatVector (m : nat) (X : Type) (x : X) : Vector.t X m :=
  match m with
  | 0 => Vector.nil X
  | S m0 => Vector.cons X x m0 (repeatVector m0 x)
  end.

(** * Functions *)

Definition compose {A B C} (g : B -> C) (f : A -> B) :=
  fun x : A => g (f x).

Hint Unfold compose.

(*Notation " g ∘ f " := (compose g f) (at level 40, left associativity).*)


(** * Some missing Vector functions *)

Tactic Notation "dependent" "destruct'" constr(V) :=
  match type of V with
  | Vector.t ?Z 0 =>
    revert all except V;
    pattern V; revert V;
    eapply case0; intros
  | Vector.t ?Z (S ?n) =>
    revert all except V;
    pattern V; revert n V;
    eapply caseS; intros
  | Fin.t 0 => inv V
  | Fin.t (S ?n) =>
    let pos := V in
    revert all except pos;
    pattern pos; revert n pos;
    eapply Fin.caseS; intros
  | _ => fail "Wrong type"
  end.

Tactic Notation "dependent" "destruct" constr(V) :=
  match type of V with
  | Vector.t ?Z (S ?n) =>
    revert all except V;
    pattern V; revert n V;
    eapply caseS; intros
  | Fin.t 0 => inv V
  | Fin.t (S ?n) =>
    let pos := V in
    revert all except pos;
    pattern pos; revert n pos;
    eapply Fin.caseS; intros
  | _ => fail "Wrong type"
  end.


Lemma destruct_vector_nil (X : Type) :
  forall v : Vector.t X 0, v = [||]%vector_scope.
Proof.
  intros H. dependent destruction H. reflexivity.
Qed.

Lemma destruct_vector_cons (X : Type) (n : nat) :
  forall v : Vector.t X (S n), { h : X & { v' : Vector.t X n | v = h ::: v' }} % vector_scope.
Proof.
  intros H. dependent destruction H. eauto.
Qed.

(* Destruct a vector of known size *)
Ltac destruct_vector :=
  repeat match goal with
         | [ v : Vector.t ?X 0 |- _ ] =>
           let H  := fresh "Hvect" in
           pose proof (@destruct_vector_nil X v) as H;
           subst v
         | [ v : Vector.t ?X (S ?n) |- _ ] =>
           let h  := fresh "h" in
           let v' := fresh "v'" in
           let H  := fresh "Hvect" in
           pose proof (@destruct_vector_cons X n v) as (h&v'&H);
           subst v; rename v' into v
         end.

Goal True. (* test *)
Proof.
  pose proof (([|1;2;3;4;5;6|]%vector_scope)) as v.
  destruct_vector.
  pose proof (([| [ 1;2;3] ; [ 4;5;6] |]%vector_scope)) as v'.
  destruct_vector.
  pose proof (([| [ 1;2;3] |]%vector_scope)) as v''.
  destruct_vector.
Abort.

Section In_nth.
  Variable (A : Type) (n : nat).

  Lemma vect_nth_In (v : Vector.t A n) (i : Fin.t n) (x : A) :
    Vector.nth v i = x -> Vector.In x v.
  Proof.
    induction n; cbn in *.
    - inv i.
    - dependent destruct v. dependent destruct i; cbn in *; subst; econstructor; eauto.
  Qed.

  Lemma vect_nth_In' (v : Vector.t A n) (x : A) :
    Vector.In x v -> exists i : Fin.t n, Vector.nth v i = x.
  Proof.
    induction n; cbn in *.
    - inversion 1.
    - dependent destruct v. inv H.
      + apply EqdepFacts.eq_sigT_eq_dep in H3. induction H3. exists Fin.F1. auto.
      + apply EqdepFacts.eq_sigT_eq_dep in H3. induction H3. specialize (IHn0 _ H2) as (i&<-). exists (Fin.FS i). auto.
  Qed.

End In_nth.


Section tabulate_vec.

  Variable X : Type.

  Fixpoint tabulate_vec' (n : nat) (f : Fin.t n -> X) {struct n} : Vector.t X n.
  Proof.
    destruct n.
    - apply Vector.nil.
    - apply Vector.cons.
      + apply f, Fin.F1.
      + apply tabulate_vec'. intros m. apply f, Fin.FS, m.
  Defined.

  Lemma nth_tabulate' n (f : Fin.t n -> X) (m : Fin.t n) :
    Vector.nth (tabulate_vec' f) m = f m.
  Proof.
    induction m.
    - cbn. reflexivity.
    - cbn. rewrite IHm. reflexivity.
  Qed.
  
  Lemma in_tabulate' n (f : Fin.t n -> X) (x : X) :
    In x (tabulate_vec' (n := n) f) -> exists i : Fin.t n, x = f i.
  Proof.
    Require Import Program.Equality.
    revert f x. induction n; intros f x H.
    - cbn in *. inv H.
    - cbn in *. dependent induction H.
      + eauto.
      + specialize (IHn (fun m => f (Fin.FS m)) _ H) as (i&IH). eauto.
  Qed.
  
  Definition tabulate_vec (n : nat) (f : nat -> X) : Vector.t X n :=
    @tabulate_vec' n (fun n => f (proj1_sig (Fin.to_nat n))).

  Lemma nth_tabulate n (f : nat -> X) m (H : m < n) :
    VectorDef.nth (tabulate_vec n f) (Fin.of_nat_lt H) = f m.
  Proof.
    unfold tabulate_vec. rewrite nth_tabulate'. f_equal.
    symmetry. rewrite Fin.to_nat_of_nat. reflexivity.
  Qed.

  Lemma in_tabulate n (f : nat -> X) m (H : m < n) (x : X) :
    In x (tabulate_vec n f) -> exists i : nat, i < n /\ x = f i.
  Proof.
    unfold tabulate_vec. intros H1.
    pose proof (in_tabulate' H1). cbn in *.
    destruct H0 as (i&Hi). exists (proj1_sig (Fin.to_nat i)). split; auto.
    destruct (Fin.to_nat i); cbn; auto.
  Qed.

End tabulate_vec.

Section get_at.

  Variable n : nat.
  Variable m : nat.
  Hypothesis itape : m < n.
  
  Definition get_at (X : Type) (V : Vector.t X n) : X := Vector.nth V (Fin.of_nat_lt itape).

  Lemma get_at_map (X : Type) (Y : Type) (f : X -> Y) (t : Vector.t X n) :
    get_at (Vector.map f t) = f (get_at t).
  Proof.
    now eapply Vector.nth_map.
  Qed.
  
  Lemma get_at_tabulate X (f : nat -> X) :
    get_at (tabulate_vec n f) = f m.
  Proof.
    unfold get_at. eapply nth_tabulate.
  Qed.

  Lemma get_at_nth X (t : Vector.t X n) x :
    get_at t = x -> Vector.nth t (Fin.of_nat_lt itape) = x.
  Proof.
    intros H. unfold get_at in H. now rewrite H.
  Qed.

End get_at.

Lemma get_at_eq_iff X n (t t' : Vector.t X n) : (forall m (itape : m < n) (itape' : m < n), get_at itape t = get_at itape' t') <-> t = t'.
Proof.
  split.
  - intros H.
    eapply VectorSpec.eq_nth_iff. intros. unfold get_at in H.
    subst.
    specialize (H (proj1_sig (Fin.to_nat p2)) (proj2_sig (Fin.to_nat p2)) (proj2_sig (Fin.to_nat p2))).
    now rewrite Fin.of_nat_to_nat_inv in H.
  - intros <- ? ? ?. unfold get_at.
    eapply VectorSpec.eq_nth_iff. reflexivity.
    eapply Fin.of_nat_ext.
Qed.

Lemma get_at_ext X n (t : Vector.t X n) m (itape : m < n) (itape' : m < n) :
  get_at itape t = get_at itape' t.
Proof.
  unfold get_at.
  eapply VectorSpec.eq_nth_iff.
  reflexivity.
  eapply Fin.of_nat_ext.
Qed.  


Lemma nth_map {A B} (f: A -> B) {n} v (p1 p2: Fin.t n) (eq: p1 = p2):
  (map f v) [@ p1] = f (v [@ p2]).
Proof.
  subst p2; induction p1; dependent destruct v; now simpl.
Qed.

Lemma vec_replace_nth X x n (t : Vector.t X n) (i : Fin.t n) :
  x = Vector.nth (Vector.replace t i x) i.
Proof.
  induction i; dependent destruct t; simpl; auto.
Qed.

Lemma vec_replace_nth_nochange X x n (t : Vector.t X n) (i j : Fin.t n) :
  Fin.to_nat i <> Fin.to_nat j -> Vector.nth t i = Vector.nth (Vector.replace t j x) i.
Proof.
  revert j. induction i; dependent destruct t; dependent destruct j; simpl; try tauto.
  apply IHi. contradict H. cbn. now rewrite !H.
Qed.

(* Apply functions in typles, options, etc. *)
Section Translate.
  Variable X Y Z : Type.
  Definition map_opt : (X -> Y) -> option X -> option Y :=
    fun f a =>
      match a with
      | Some x => Some (f x)
      | None => None
      end.

  Definition map_inl : (X -> Y) -> X + Z -> Y + Z :=
    fun f a =>
      match a with
      | inl x => inl (f x)
      | inr y => inr y
      end.

  Definition map_inr : (Y -> Z) -> X + Y -> X + Z :=
    fun f a =>
      match a with
      | inl y => inl y
      | inr x => inr (f x)
      end.

  Definition map_left  : (X -> Z) -> X * Y -> Z * Y := fun f '(x,y) => (f x, y).
  Definition map_right : (Y -> Z) -> X * Y -> X * Z := fun f '(x,y) => (x, f y).
End Translate.

(* Show the non-dependent hypothesis of a hypothesis that is a implication and specialize it *)
Tactic Notation "spec_assert" hyp(H) :=
  let H' := fresh in
  match type of H with
  | ?A -> _ =>
    assert A as H'; [ | specialize (H H'); clear H']
  end.

Tactic Notation "spec_assert" hyp(H) "by" tactic(T) :=
  let H' := fresh in
  match type of H with
  | ?A -> _ =>
    assert A as H' by T; specialize (H H'); clear H'
  end.


(* Dupfree vector *)

Open Scope vector_scope.

Inductive dupfree X : forall n, Vector.t X n -> Prop :=
  dupfreeVN :
    dupfree (@Vector.nil X)
| dupfreeVC n (x : X) (V : Vector.t X n) :
    ~ Vector.In x V -> dupfree V -> dupfree (x ::: V).

Ltac vector_not_in_step :=
  match goal with
  | _ => progress destruct_vector
  | [ H: Vector.In ?X ?Y |- False ] => inv H
  | [ H: existT ?X1 ?Y1 ?Z1 = existT ?X2 ?Y2 ?Z2 |- False] =>
    apply EqdepFacts.eq_sigT_iff_eq_dep in H; inv H; clear H
  end.

Ltac vector_not_in := intro; repeat vector_not_in_step.

Goal ~ Vector.In 10 [|1;2;4|].
Proof.
  vector_not_in.
Qed.

Ltac vector_dupfree :=
  match goal with
  | [ |- dupfree (Vector.nil _) ] =>
    constructor
  | [ |- dupfree (?a ::: ?bs)%vector_scope ] =>
    constructor; [vector_not_in | vector_dupfree]
  end.

Goal dupfree [| 4; 8; 15; 16; 23; 42 |].
Proof. vector_dupfree. Qed.

Goal dupfree [| Fin.F1 (n := 1) |].
Proof. vector_dupfree. Qed.