type param = Param of int

let counter = ref 0

let fresh_param () =
  incr counter;
  Param !counter

type ty = IntTy | BoolTy | ArrowTy of ty * ty | ParamTy of param

let rec occurs p = function
  | IntTy | BoolTy -> false
  | ArrowTy (ty1, ty2) -> occurs p ty1 || occurs p ty2
  | ParamTy p' -> p = p'

let rec subst_ty sbst = function
  | (IntTy | BoolTy) as ty -> ty
  | ArrowTy (ty1, ty2) -> ArrowTy (subst_ty sbst ty1, subst_ty sbst ty2)
  | ParamTy p as ty -> List.assoc_opt p sbst |> Option.value ~default:ty

let fresh_ty () = ParamTy (fresh_param ())
let string_of_param (Param p) = "'a" ^ string_of_int p

let rec string_of_ty = function
  | IntTy -> "int"
  | BoolTy -> "bool"
  | ArrowTy (ty1, ty2) ->
      "(" ^ string_of_ty ty1 ^ " -> " ^ string_of_ty ty2 ^ ")"
  | ParamTy p -> string_of_param p

type ident = Ident of string

type exp =
  | Var of ident
  | Int of int
  | Plus of exp * exp
  | Minus of exp * exp
  | Times of exp * exp
  | Bool of bool
  | Equal of exp * exp
  | Less of exp * exp
  | Greater of exp * exp
  | IfThenElse of exp * exp * exp
  | Lambda of ident * exp
  | RecLambda of ident * ident * exp
  | Apply of exp * exp

let let_in (x, e1, e2) = Apply (Lambda (x, e2), e1)
let let_rec_in (f, x, e1, e2) = let_in (f, RecLambda (f, x, e1), e2)

let rec subst_exp sbst = function
  | Var x as e -> (
      match List.assoc_opt x sbst with None -> e | Some e' -> e')
  | (Int _ | Bool _) as e -> e
  | Plus (e1, e2) -> Plus (subst_exp sbst e1, subst_exp sbst e2)
  | Minus (e1, e2) -> Minus (subst_exp sbst e1, subst_exp sbst e2)
  | Times (e1, e2) -> Times (subst_exp sbst e1, subst_exp sbst e2)
  | Equal (e1, e2) -> Equal (subst_exp sbst e1, subst_exp sbst e2)
  | Less (e1, e2) -> Less (subst_exp sbst e1, subst_exp sbst e2)
  | Greater (e1, e2) -> Greater (subst_exp sbst e1, subst_exp sbst e2)
  | IfThenElse (e, e1, e2) ->
      IfThenElse (subst_exp sbst e, subst_exp sbst e1, subst_exp sbst e2)
  | Lambda (x, e) ->
      let sbst' = List.remove_assoc x sbst in
      Lambda (x, subst_exp sbst' e)
  | RecLambda (f, x, e) ->
      let sbst' = List.remove_assoc f (List.remove_assoc x sbst) in
      RecLambda (f, x, subst_exp sbst' e)
  | Apply (e1, e2) -> Apply (subst_exp sbst e1, subst_exp sbst e2)

let string_of_ident (Ident x) = x

let rec string_of_exp3 = function
  | IfThenElse (e, e1, e2) ->
      "IF " ^ string_of_exp2 e ^ " THEN " ^ string_of_exp2 e1 ^ " ELSE "
      ^ string_of_exp3 e2
  | Lambda (x, e) -> "FUN " ^ string_of_ident x ^ " -> " ^ string_of_exp3 e
  | RecLambda (f, x, e) ->
      "REC " ^ string_of_ident f ^ " " ^ string_of_ident x ^ " -> "
      ^ string_of_exp3 e
  | e -> string_of_exp2 e

and string_of_exp2 = function
  | Equal (e1, e2) -> string_of_exp1 e1 ^ " = " ^ string_of_exp1 e2
  | Less (e1, e2) -> string_of_exp1 e1 ^ " < " ^ string_of_exp1 e2
  | Greater (e1, e2) -> string_of_exp1 e1 ^ " > " ^ string_of_exp1 e2
  | Plus (e1, e2) -> string_of_exp1 e1 ^ " + " ^ string_of_exp1 e2
  | Minus (e1, e2) -> string_of_exp1 e1 ^ " - " ^ string_of_exp1 e2
  | Times (e1, e2) -> string_of_exp1 e1 ^ " * " ^ string_of_exp1 e2
  | e -> string_of_exp1 e

and string_of_exp1 = function
  | Apply (e1, e2) -> string_of_exp0 e1 ^ " " ^ string_of_exp0 e2
  | e -> string_of_exp0 e

and string_of_exp0 = function
  | Int n -> string_of_int n
  | Bool b -> if b then "TRUE" else "FALSE"
  | Var x -> string_of_ident x
  | e -> "(" ^ string_of_exp3 e ^ ")"

let string_of_exp = string_of_exp3
