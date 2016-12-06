
let node_id fmt t =
  Format.fprintf fmt "p%d" Repr.((t.addr :> int))

let print_direct_cell fmt (c : [`Direct] Repr.cell) =
  match c with
  | Repr.Int i      -> Format.fprintf fmt "%d" i
  | Repr.Pointer _  -> Format.fprintf fmt " . "

let print_inline_cell fmt (c : [`Inline] Repr.cell) =
  match c with
  | Repr.Int i      -> Format.fprintf fmt "%d" i
  | Repr.Pointer _  -> Format.fprintf fmt " . "
  | Repr.Double f   -> Format.fprintf fmt "%f" f

let print_block_cell fmt (c: [`Block] Repr.cell) =
  match c with
  | Repr.String s   -> Format.fprintf fmt "'%s'" s
  | Repr.Double f   -> Format.fprintf fmt "%f" f

let print_contents fmt t =
  match t.Repr.data with
  | Repr.Abstract ->
    Format.fprintf fmt "<f0> \<Abstract\>"
  | Repr.Block c ->
    Format.fprintf fmt "<f0> %a" print_block_cell c
  | Repr.Fields a ->
    Format.fprintf fmt "<f0> %a" print_inline_cell a.(0);
    for i = 1 to Array.length a - 1 do
      Format.fprintf fmt "| <f%d>%a" i print_inline_cell a.(i)
    done

let print_contents fmt t =
  Format.fprintf fmt "{ <head> Tag : %d | %a }"
    (t.Repr.tag :> int) print_contents t

let print_edges fmt t =
  match t.Repr.data with
  | Repr.Abstract | Repr.Block _ -> ()
  | Repr.Fields a ->
    for i = 0 to Array.length a - 1 do
      match a.(i) with
      | Repr.Pointer b ->
        Format.fprintf fmt "%a:f%d -> %a:<head>;@\n" node_id t i node_id (Repr.follow b)
      | _ -> ()
    done

let print_node h fmt t =
  if not (Hashtbl.mem h Repr.(t.addr)) then begin
    Hashtbl.add h Repr.(t.addr) true;
    Format.fprintf fmt
      "%a [label=\"%a\" shape=\"record\" style=\"rounded, filled\" fillcolor=\"lightblue\"];@\n"
      node_id t print_contents t;
    print_edges fmt t
  end

let print_repr h fmt n (name, t) =
  match t with
  | Repr.Pointer b ->
    let block = Repr.follow b in
    Format.fprintf fmt "entry_%d -> %a;@\n" n node_id block;
    Repr.walk (print_node h fmt) block
  | _ -> ()

let print_roots fmt l =
  let aux fmt l =
    List.iteri (fun i (name, t) ->
        Format.fprintf fmt "entry_%d [label=\"{ val : %s | %a}\" shape=\"record\" style=\"filled\" fillcolor=\"yellow\"];@\n"
          i name print_direct_cell t) l
  in
  Format.fprintf fmt "{rank=source;@\n%a@\n}" aux l

let print_list fmt l =
  let print_reprs fmt l =
    let h = Hashtbl.create 42 in
    List.iteri (print_repr h fmt) l
  in
  Format.fprintf fmt "digraph g {@\n%a\n%a\n}@." print_roots l print_reprs l

let to_file name l =
  let fd = Unix.openfile name [ Unix.O_CREAT; Unix.O_RDWR; Unix.O_EXCL ] 0o640 in
  let ch = Unix.out_channel_of_descr fd in
  let fmt = Format.formatter_of_out_channel ch in
  print_list fmt l

