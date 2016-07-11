
let node_id fmt t =
  Format.fprintf fmt "p%d" Repr.((t.addr :> int))

let print_cell fmt = function
  | Repr.Abstract -> Format.fprintf fmt "?"
  | Repr.Int i -> Format.fprintf fmt "%d" i
  | Repr.Double f -> Format.fprintf fmt "%f" f
  | Repr.String s -> Format.fprintf fmt "'%s'" s
  | Repr.Pointer _ -> Format.fprintf fmt " . "

let print_cell_array fmt a =
  Format.fprintf fmt "<f0> %a" print_cell a.(0);
  for i = 1 to Array.length a - 1 do
    Format.fprintf fmt "| <f%d>%a" i print_cell a.(i)
  done

let print_contents fmt t =
  Format.fprintf fmt "{ <head> Tag : %d | %a }" (t.Repr.tag :> int) print_cell_array t.Repr.fields

let print_edges fmt t =
  for i = 0 to Array.length t.Repr.fields - 1 do
    match t.Repr.fields.(i) with
    | Repr.Pointer b ->
      Format.fprintf fmt "%a:f%d -> %a:<head>;@\n" node_id t i node_id (Repr.follow b)
    | _ -> ()
  done

let rec print_node h fmt t =
  if not (Hashtbl.mem h Repr.(t.addr)) then begin
    Hashtbl.add h Repr.(t.addr) true;
    Format.fprintf fmt "%a [label=\"%a\" shape=\"record\" style=\"rounded, filled\" fillcolor=\"lightblue\"];@\n" node_id t print_contents t;
    Array.iter (function Repr.Pointer b -> print_node h fmt (Repr.follow b) | _ -> ()) t.Repr.fields;
    print_edges fmt t
  end

let entry_id =
  let c = ref 0 in
  (function () -> incr c; !c)

let print_repr h fmt (name, t) =
  let n = entry_id () in
  Format.fprintf fmt "entry_%d [label=\"{ val : %s | %a}\" shape=\"record\" style=\"filled\" fillcolor=\"yellow\"];@\n"
    n name print_cell t;
  match t with
  | Repr.Pointer b ->
    let block = Repr.follow b in
    Format.fprintf fmt "entry_%d -> %a;@\n" n node_id block;
    print_node h fmt block
  | _ -> ()

let print_list fmt l =
  let h = Hashtbl.create 42 in
  Format.fprintf fmt "digraph g {@\n";
  List.iter (print_repr h fmt) l;
  Format.fprintf fmt "}@."

let to_file name l =
  let fd = Unix.openfile name [ Unix.O_CREAT; Unix.O_RDWR; Unix.O_EXCL ] 0o640 in
  let ch = Unix.out_channel_of_descr fd in
  let fmt = Format.formatter_of_out_channel ch in
  print_list fmt l

