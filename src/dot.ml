(* Settings for the graphviz output *)

type config = {
  external_node_color : string option;
  block_node_color : string option;
  root_node_color : string option;
  outline_color : string;
  background_color : string option;
  direction : [`Vertical | `Horizontal];
}

let config
  ?(external_node_color = Some "grey")
  ?(block_node_color = Some "lightblue")
  ?(root_node_color = Some "yellow")
  ?(outline_color = "black")
  ?(background_color = None)
  ?(direction = `Vertical)
  ()
  =
  { external_node_color;
    block_node_color;
    root_node_color;
    outline_color;
    background_color;
    direction;
  }

let styles_with_color fmt ~color (styles: string list) =
  match color with
  | None ->
    if styles = [] then ()
    else Format.fprintf fmt "style=\"%s\"" (String.concat ", " styles)
  | Some color ->
    Format.fprintf fmt "style=\"%s\" fillcolor=\"%s\""
      (String.concat ", " ("filled" :: styles)) color

(* External pointers *)

(* Global cache to avoid printing the same external twice or more. *)
let external_cache = Hashtbl.create 42

(* The cache should be cleared before each printing function,
   in order to be local to each printing function. *)
let clear_external_cache () = Hashtbl.clear external_cache

let external_id fmt e =
  Format.fprintf fmt "e%s" (Nativeint.to_string e)

let print_external_contents fmt i =
  Format.fprintf fmt "{ <head> Out of heap : 0x%nx }" i

let print_external cfg fmt i =
  if not @@ Hashtbl.mem external_cache i then begin
    Format.fprintf fmt
      "%a [label=\"%a\" shape=\"record\" %a];@\n"
      external_id i print_external_contents i
      (styles_with_color ~color:cfg.external_node_color) ["rounded"]
  end


(** Regular blocks printing *)

let node_id fmt t =
  Format.fprintf fmt "p%d" Repr.((t.block.addr :> int))

let node_anchor fmt t =
  Format.fprintf fmt "p%d:<%s>" Repr.((t.block.addr :> int))
    (match Repr.(t.offset) with
     | 0 -> "head"
     | o -> Format.asprintf "f%d" (o - 1))

let print_direct_cell fmt (c : [`Direct] Repr.cell) =
  match c with
  | Repr.Int i      -> Format.fprintf fmt "%d" i
  | Repr.Pointer _  -> Format.fprintf fmt " . "

let print_inline_cell fmt (c : [`Inline] Repr.cell) =
  match c with
  | Repr.Int i      -> Format.fprintf fmt "%d" i
  | Repr.Pointer _  -> Format.fprintf fmt " . "
  | Repr.External _ -> Format.fprintf fmt " . "
  | Repr.Double f   -> Format.fprintf fmt "%f" f
  | Repr.Infix      -> Format.fprintf fmt "Infix"

let print_block_cell fmt (c: [`Block] Repr.cell) =
  match c with
  | Repr.String s   -> Format.fprintf fmt "'%s'" s
  | Repr.Double f   -> Format.fprintf fmt "%f" f

let print_contents fmt t =
  match t.Repr.data with
  | Repr.Abstract ->
    Format.fprintf fmt {|<f0> \<Abstract\>|}
  | Repr.Block c ->
    Format.fprintf fmt "<f0> %a" print_block_cell c
  | Repr.Fields a ->
    Format.fprintf fmt "<f0> %a" print_inline_cell a.(0);
    for i = 1 to Array.length a - 1 do
      Format.fprintf fmt "| <f%d>%a" i print_inline_cell a.(i)
    done

let print_contents fmt t =
  Format.fprintf fmt "{ <head> Tag : %d | %a }"
    Repr.((t.block.tag :> int))
    print_contents t.Repr.block

let print_edges cfg fmt t =
  match Repr.(t.block.data) with
  | Repr.Abstract | Repr.Block _ -> ()
  | Repr.Fields a ->
    for i = 0 to Array.length a - 1 do
      match a.(i) with
      | Repr.Pointer b ->
        Format.fprintf fmt "%a:f%d -> %a;@\n" node_id t i node_anchor (Repr.follow b)
      | Repr.External e ->
        Format.fprintf fmt "%a:f%d -> %a:<head>;@\n" node_id t i external_id e;
        (print_external cfg) fmt e
      | _ -> ()
    done

let print_node cfg h fmt t =
  if not (Hashtbl.mem h Repr.(t.block.addr)) then begin
    Hashtbl.add h Repr.(t.block.addr) true;
    Format.fprintf fmt
      "%a [label=\"%a\" shape=\"record\" %a];@\n"
      node_id t print_contents t
      (styles_with_color ~color:cfg.block_node_color) ["rounded"];
    (print_edges cfg) fmt t
  end

let print_repr cfg h fmt n (_, t) =
  match t with
  | Repr.Pointer b ->
    let block = Repr.follow b in
    Format.fprintf fmt "entry_%d -> %a;@\n" n node_anchor block;
    Repr.walk (print_node cfg h fmt) block
  | _ -> ()

let print_roots cfg fmt l =
  let aux fmt l =
    List.iteri (fun i (name, t) ->
        Format.fprintf fmt "entry_%d [label=\"{ val : %s | %a}\" shape=\"record\" %a];@\n"
          i name print_direct_cell t
          (styles_with_color ~color:cfg.root_node_color) []
    ) l

  in
  Format.fprintf fmt "{rank=source;@\n%a@\n}" aux l

let print_list cfg fmt l =
  clear_external_cache ();
  let print_reprs fmt l =
    let h = Hashtbl.create 42 in
    List.iteri (print_repr cfg h fmt) l
  in
  Format.fprintf fmt "digraph g {@\n\
    graph [bgcolor=%s]\n\
    edge [color=%s]\n\
    node [color=%s, fontcolor=%s]\n\
    rankdir=%s\n\
    %a\n%a\n}@."
    (match cfg.background_color with None -> "transparent" | Some c -> c)
    cfg.outline_color cfg.outline_color cfg.outline_color
    (match cfg.direction with `Horizontal -> "LR" | `Vertical -> "TB")
    (print_roots cfg) l print_reprs l

let to_file cfg name l =
  let fd = Unix.openfile name [ Unix.O_CREAT; Unix.O_RDWR; Unix.O_EXCL ] 0o640 in
  let ch = Unix.out_channel_of_descr fd in
  let fmt = Format.formatter_of_out_channel ch in
  print_list cfg fmt l
