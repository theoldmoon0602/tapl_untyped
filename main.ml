open Syntax

let position_to_string pos = 
  "file:" ^ pos.Lexing.pos_fname ^ ", line:" ^ string_of_int(pos.Lexing.pos_lnum) ^ ", col:" ^ string_of_int(pos.Lexing.pos_cnum)

(* 環境。名前と term を紐付ける *)
let empty_context : (string * term) list = []

exception LambdaError of string

let rec term_to_string term =
  match term with
  |TmVar(_, v) -> v
  |TmAbs(_, v, t) -> "(λ" ^ v ^ ". " ^ term_to_string t ^ ")"
  |TmApp(_, t1, t2) -> "(" ^ (term_to_string t1) ^ " " ^ (term_to_string t2) ^ ")"

(* 関数の適用 *)
let rec apply ctx t1 t2 =
  match t1 with
  |TmAbs(_, v, t) ->
      let ctx' = (v, t2)::ctx in
      eval ctx' t
  |_ ->
      (* t1 がλ抽象出ないときはそっともとに戻しておく *)
      (ctx, TmApp(Lexing.dummy_pos, t1, t2))
  
and eval ctx term =
  match term with
  |TmVar(_, v) ->
      begin
        try
          let v' = List.assoc v ctx in
          (ctx, v')
        (* 見つからなかったときに id 関数のように振る舞うことで未定義の変数を使えて便利 *)
        with Not_found -> (ctx, term)
      end
  |TmApp(_, t1, t2) ->
      let _, t2' = eval ctx t2 in
      let ctx', t1' = eval ctx t1 in
      apply ctx' t1' t2'
  |TmAbs(p, v, t) ->
      (* 関数の中身を簡約する。引数が環境に結びついてないけどうまく動く *)
      let _, t' = eval ctx t in
      (ctx, TmAbs(p, v, t'))


let () =
  let ctx = ref [] in
  while true do
    print_string ">";
    flush stdout;
    let stmt = Parser.parse Lexer.main (Lexing.from_channel stdin) in
    match stmt with
    |Term(t) ->
        begin
          print_endline ("->" ^ term_to_string t);
          let _, r = eval !ctx t in 
          print_endline ("->" ^ term_to_string r);
        end
    |Assign(_, v, t) ->
        begin
          print_endline ("->" ^ term_to_string t);
          let _, r = eval !ctx t in 
          print_endline ("->" ^ term_to_string r);
          ctx := (v, r)::!ctx;
        end
  done

