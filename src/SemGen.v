Require Import ZArith List ssreflect ssrbool ssrnat.
Require Import Axioms RoseTrees Random Gen.
Import ListNotations.

Set Implicit Arguments.

(* Set of outcomes semantics for generators *)
Require Import Ensembles.

(* also fixing counterintuitive order of arguments *)
Definition unGen {A : Type} (g : Gen A) : nat -> RandomGen -> A :=
  match g with MkGen f => fun n r => f r n end.

Definition semSize {A : Type} (g : RandomGen -> A) : Ensemble A :=
  fun a => exists seed, g seed = a.

Definition semGen {A : Type} (g : Gen A) : Ensemble A :=
  fun a => exists size, semSize ((unGen g) size) a.

(* Equivalence on sets of outcomes *)
Definition set_eq {A} (m1 m2 : Ensemble A) :=
  forall A, m1 A <-> m2 A.

Infix "<-->" := set_eq (at level 70, no associativity) : sem_gen_scope.

(* the set f outcomes m1 is a subset of m2 *)
Definition set_incl {A} (m1 m2 : Ensemble A) :=
  forall A, m1 A -> m2 A.

Infix "-->" := set_incl (at level 70, no associativity) : sem_gen_scope.

Open Scope sem_gen_scope.

(* We clearly need to reason about sizes:
   generators need to be size-monotonous functions *)
(* Went for the most explicit way of doing this,
   could later try to use type classes to beautify/automate things *)
Definition sizeMon {A : Type} (g : Gen A) := forall size1 size2,
  (size1 <= size2)%coq_nat ->
  semSize ((unGen g) size1) --> semSize ((unGen g) size2).

(* One alternative (that doesn't really seem to work)
   is to add size-monotonicity directly into semGen *)
Definition semGenMon {A : Type} (g : Gen A) : Ensemble A :=
  fun a => exists size, forall size',
   (size <= size')%coq_nat ->
   semSize ((unGen g) size') a.

(* Sanity check: the size-monotonic semantics corresponds to the
   natural one on all size-monotonic generators *)
Lemma semGenSemGenMon : forall A (g : Gen A),
  sizeMon g ->
  semGen g <--> semGenMon g.
Proof.
  rewrite /semGen /semGenMon /sizeMon.
  move => A g Mon a. split.
  - move => [size H]. exists size => size' Hsize'.
    eapply Mon. exact Hsize'. exact H.
  - move => [size H]. specialize (H size (le_refl _)). eexists. exact H.
Qed.

Axiom randomSeedInhabitant : RandomGen.

Lemma semReturn : forall A (x : A),
  semGen (returnG x) <--> eq x.
Proof.
  move => A x a. rewrite /semGen. split.
  - move => [size [seed H]] //.
  - move => H /=. rewrite H.
    exists 0. exists randomSeedInhabitant. reflexivity.
Qed.

Lemma semReturnMon : forall A (x : A),
  semGenMon (returnG x) <--> eq x.
Proof.
  move => A x a. rewrite /semGenMon. split.
  - move => [size H]. specialize (H size (le_refl _)). by move : H => /= [_ H].
  - move => H /=. rewrite H.
    exists 0 => [size _]. exists randomSeedInhabitant. reflexivity.
Qed.

(* This seems like a very strong assumption;
   for cardinality reasons it requires RandomGen to be infinite *)
Axiom rndSplitAssumption :
  forall s1 s2 : RandomGen, exists s, rndSplit s = (s1,s2).

Lemma semBind : forall A B (g : Gen A) (f : A -> Gen B),
  sizeMon g ->
  (forall a, sizeMon (f a)) ->
  semGen (bindG g f) <--> fun b => exists a, (semGen g) a /\ (semGen (f a)) b.
Proof.
  move => A B g f MonG MonF b. rewrite /semGen /bindG => /=. split.
  - move : MonG. case : g => [g] MonG /= [size [seed H]]. move : H.
    case (rndSplit seed) => [seed1 seed2].
    exists (g seed1 size). split; do 2 eexists. reflexivity.
    rewrite <- H. case (f (g seed1 size)). reflexivity.
  - move => [a [[size1 H1] [size2 H2]]].
    assert (Hs1 : (size1 <= max size1 size2)%coq_nat) by apply Max.le_max_l.
    case (MonG _ _ Hs1 _ H1) => [seed1' H1'].
    assert (Hs2 : (size2 <= max size1 size2)%coq_nat) by apply Max.le_max_r.
    case (MonF _ _ _ Hs2 _ H2) => [seed2' H2'].
    exists (max size1 size2). clear H1 H2.
    case (rndSplitAssumption seed1' seed2') => [seed Hs].
    exists seed.
    move : H1' H2'. move : MonG. case : g => [g] MonG /= H1' H2'.
    rewrite Hs. rewrite H1'. move : H2'. by case (f a).
Qed.

Lemma semBindMon : forall A B (g : Gen A) (f : A -> Gen B),
  semGenMon (bindG g f) <-->
  fun b => exists a, (semGenMon g) a /\ (semGenMon (f a)) b.
Proof.
  move => A B g f b. rewrite /semGenMon /bindG => /=. split.
  - (* couldn't prove this (previously easy) case any more;
       the quantifier alternation is bad, we can no longer choose a so early *)
    case : g => [g] /= [size H]. pose proof (H size (le_refl _)) as H'.
    move : H' => [seed H']. move : H'.
    case (rndSplit seed) => [seed1 seed2].
    exists (g seed1 size). split; exists size => size' Hsize'.
    compute. admit. (* stuck *)
    rewrite <- H'. case (f (g seed1 size)). compute. admit. (* stuck *)
  - (* this other case got easier, and it holds unconditionally *)
    move => [a [[size1 H1] [size2 H2]]].
    exists (max size1 size2) => size Hsize.
    assert (Hs1 : (size1 <= max size1 size2)%coq_nat) by apply Max.le_max_l.
    assert (Hs2 : (size2 <= max size1 size2)%coq_nat) by apply Max.le_max_r.
    specialize (H1 size (le_trans _ _ _ Hs1 Hsize)).
    specialize (H2 size (le_trans _ _ _ Hs2 Hsize)).
    case H1 => [seed1' H1'].
    case H2 => [seed2' H2']. clear H1 H2.
    case (rndSplitAssumption seed1' seed2') => [seed Hs].
    exists seed.
    move : H1' H2'. case : g => [g] /= H1' H2'.
    rewrite Hs. rewrite H1'. move : H2'. by case (f a).
Abort.

Lemma semFMap : forall A B (f : A -> B) (g : Gen A),
  semGen (fmapG f g) <-->
    (fun b => exists a, (semGen g) a /\ b = f a).
Proof.
  move => A B f [g] b. rewrite /semGen /semSize /fmapG => /=. split.
  - move => [size [seed [H]]]. exists (g seed size). by eauto.
  - move => [a [[size [seed [H1]]] H2]].
    do 2 eexists. rewrite H2. rewrite <- H1. reflexivity.
Qed.

(* This seems like a reasonable thing to assume of randomR,
   why not add it directly to the Random type class? *)
Axiom randomRAssumption : forall A `{Random A} (a1 a2 a : A),
  (exists seed, fst (randomR (a1, a2) seed) = a) <->
  leq a1 a /\ leq a a2.

Lemma semChoose : forall A `{Random A} a1 a2,
  semGen (chooseG (a1,a2)) <--> (fun a => Random.leq a1 a /\ Random.leq a a2).
Proof.
  move => A R a1 a2 a. rewrite /semGen /semSize. simpl. split.
  - move => [_ [seed H]]. rewrite <- randomRAssumption. by eauto.
  - move => H. exists 0. by rewrite randomRAssumption.
Qed.  

(* This has the nice abstract conclusion we want, but a super gory premise *)
Lemma semSized1 : forall A (f : nat -> Gen A),
  (forall size1 size1' size2,
    (size1 <= size2)%coq_nat ->
    (size1' <= size2)%coq_nat ->
    (semSize (unGen (f size1) size1') -->
     semSize (unGen (f size2) size2))) ->
  semGen (sizedG f) <--> (fun a => exists n, semGen (f n) a).
Proof.
  move => A f Mon a. rewrite /semGen /sizedG => /=. split.
  - rewrite /semSize => /=.
    move => [size [seed H]]. exists size. move : H.
    case (f size) => g H. rewrite /semSize. by eauto.
  - move => [n [size H]]. exists (max n size).
    assert (MaxL : (n <= max n size)%coq_nat) by apply Max.le_max_l.
    assert (MaxR : (size <= max n size)%coq_nat) by apply Max.le_max_r.
    case (Mon _ _ _ MaxL MaxR _ H) => [seed H'].
    exists seed. move : H'. by case (f (max n size)).
Qed.

(* This is a stronger (i.e. unconditionally correct) spec, but still
   not as abstract as I was hoping for (and in particular not as
   abstract at what we have in SetOfOutcomes.v). C'est la vie?
   Should we just give up on completely abstracting away the sizes? *)
Lemma semSized2 : forall A (f : nat -> Gen A),
  semGen (sizedG f) <--> (fun a => exists n, semSize (unGen (f n) n) a).
Proof.
  move => A f a. rewrite /semGen /semSize /sizedG => /=. split.
  - move => [size [seed H]]. exists size. move : H.
    case (f size) => g H. rewrite /semSize. by eauto.
  - move => [size [seed H]]. exists size. exists seed.
    move : H. case (f size) => g H. rewrite /semSize. by eauto.
Qed.

Lemma semSuchThatMaybe : forall A (g : Gen A) (f : A -> bool),
  semGen (suchThatMaybeG g f) <-->
  (fun o => (o = None) \/ (exists y, o = Some y /\ semGen g y /\ f y)).
Proof.
  move => A g f a. rewrite /suchThatMaybeG.
  admit. (* looks a bit scarry *)
Admitted.

Definition roseRoot {A : Type} (ra : Rose A) : A :=
  match ra with
    | MkRose r _ => r
  end.

Lemma semPromote : forall A (m : Rose (Gen A)),
  semGen (promoteG m) <-->
  fun b => exists a, semGen (roseRoot m) a /\ b = (MkRose a (lazy nil)).
Proof.
  move => A m a. rewrite /promoteG /fmapRose.
  admit. (* looks a bit scarry *)
Admitted.