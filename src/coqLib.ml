open Decl_kinds
open Pp
open Term
open Loc
open Names
open Tacmach
open Entries
open Declarations
open Declare
open Libnames
open Util
open Constrintern
open Topconstr
open Constrexpr
open Constrexpr_ops
open Ppconstr
open Context
open GenericLib

let gExIntro_impl (witness : coq_expr) (proof : coq_expr) : coq_expr =
  gApp (gInject "ex_intro") [hole; witness; proof]

let gExIntro (x : string) (pred : var -> coq_expr) (witness : coq_expr) (proof : coq_expr) : coq_expr =
  gApp (gInject "ex_intro") [(gFun [x] (fun [x] -> pred x)); witness; proof]

let gEx (x : string) (pred : var -> coq_expr) : coq_expr =
  gApp (gInject "ex") [(gFun [x] (fun [x] -> pred x))]

let gConjIntro p1 p2 =
  gApp (gInject "conj") [p1; p2]

let gEqType e1 e2 =
  gApp (gInject "eq") [e1; e2]

let gConj p1 p2 =
  gApp (gInject "and") [p1; p2]

let gImpl p1 p2 =
  gApp (gInject "Basics.impl") [p1; p2]

let gForall typ f =
  gApp (gInject "all") [typ; f]

let gProd e1 e2 =
  gApp (gInject "prod") [e1; e2]

let gLeq e1 e2 =
  gApp (gInject "leq") [e1; e2]

let gIsTrueLeq e1 e2 =
  gApp
    (gInject "is_true")
    [gApp (gInject "leq") [e1; e2]]

let gOrIntroL p =
  gApp (gInject "or_introl") [p]

let gOrIntroR p =
  gApp (gInject "or_intror") [p]

let gEqRefl p =
  gApp (gInject "Logic.eq_refl") [p]

let gI = gInject "I"

let gT = gInject "True"

let gTrueb = gInject "true"

let gFalseb = gInject "false"

let gTrue = gInject "True"

let gFalse = gInject "False"

let gIff p1 p2 =
  gApp (gInject "iff") [p1; p2]

let gIsTrueTrue =
  gApp (gInject "is_true") [gInject "true"]

let false_ind x1 x2 =
  gApp (gInject "False_ind") [x1; x2]

let gfalse = gInject "False"

(* TODO extend gMatch to write the return type? *)
let discriminate h =
  false_ind hole
    (gMatch h [(injectCtr "erefl", [], fun [] -> gI)])

let rewrite h hin =
  gApp (gInject "eq_ind") [hole; hole; hin; hole; h]
  (* gMatch h [(injectCtr "erefl", [], fun [] -> hin)] *)

let eq_symm p =
  gApp (gInject "eq_symm") [hole; hole; p]

let rewrite_symm h hin =
  gMatch (eq_symm h) [(injectCtr "erefl", [], fun [] -> hin)]

let lt0_False hlt =
  gApp (gInject "lt0_False") [hlt]

let nat_ind ret_type base_case ind_case =
  gApp (gInject "nat_ind") [ret_type; base_case; ind_case]

let appn fn n arg =
  gApp (gInject "appn") [fn; n; arg]

let matchDec c left right =
  gMatch c [ (injectCtr "left" , ["eq" ], left)
           ; (injectCtr "right", ["neq"], right)
           ]

let plus x y =
  gApp (gInject "Nat.add") [x;y]

let plus_leq_compat_l p =
  gApp (gInject "plus_leq_compat_l") [hole; hole; hole; p]

let leq_addl =
  gApp (gInject "leq_addl") [hole; hole]
