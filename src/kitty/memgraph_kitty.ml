(* This file is free software, part of memgraph. See file "LICENSE" for more information *)

let font_blob =
  [%blob "FiraSans-Medium.ttf"]

let font =
  let font_buf =
    Bigarray.Array1.create Bigarray.int8_unsigned Bigarray.c_layout
      (String.length font_blob)
  in
  String.iteri (fun i c -> font_buf.{i} <- Char.code c) font_blob;
  let offsets = Stb_truetype.enum font_buf in
  Stb_truetype.init font_buf (List.hd offsets) |> Option.get

type config = {
  scale : float;
  dot : Memgraph.Dot.config;
}

let config
    ?(scale = 1.1)
    ?(external_node_color = Some "darkslategray")
    ?(block_node_color = None)
    ?(root_node_color = None)
    ?(outline_color = "white")
    ?(background_color = None)
    ?(direction = `Horizontal)
    ()
  =
  { scale = scale;
    dot =
      Memgraph.Dot.config
        ~external_node_color ~block_node_color ~root_node_color
        ~outline_color ~background_color ~direction (); }

let conf = ref (config ())

let configure
    ?scale ?external_node_color ?block_node_color ?root_node_color
    ?outline_color ?background_color ?direction ()
  =
  conf :=
    config ?scale ?external_node_color ?block_node_color ?root_node_color
      ?outline_color ?background_color ?direction ()

let read_svg svgfile =
  match Nanosvg.parse_from_file ~units:Px svgfile with
  | Some img -> Ok img
  | None -> Error "Could not open or parse svg file"

let pp reprs =
  let dotfile, dotout = Filename.open_temp_file "memgraph_kitty" ".dot" in
  let svgfile = Filename.temp_file "memgraph_kitty" ".svg" in
  Memgraph.Dot.print_list ~conf:!conf.dot (Format.formatter_of_out_channel dotout) reprs;
  let _ = Sys.command (Printf.sprintf "dot -Tsvg -o%s %s" svgfile dotfile) in
  begin match read_svg svgfile with
  | Ok svg ->
    let w = int_of_float (Nanosvg.Image_data.width svg *. !conf.scale) in
    let h = int_of_float (Nanosvg.Image_data.height svg *. !conf.scale) in
    let buf = Bigarray.Array1.create Bigarray.Int8_unsigned Bigarray.C_layout (w * h * 4) in
    Bigarray.Array1.fill buf 0;
    let rast = Nanosvg.Rasterizer.create () in
    Nanosvg.rasterize rast svg ~tx:0. ~ty:0. ~scale:!conf.scale ~dst:buf ~w ~h ();
    let svg_data = Nanosvg.lift svg in
    Nanosvg_text.rasterize_text svg_data ~get_font:(fun ~family:_ -> font)
      ~dst:buf ~scale:!conf.scale ~tx:0. ~ty:0. ~w ~h ();
    Kittyimg.send_image ~w ~h ~format:`RGBA (Kittyimg.string_of_bytes_ba buf);
    print_newline ()
  | Error msg ->
    Printf.eprintf "%s\n" msg
  end;
  Sys.remove dotfile;
  Sys.remove svgfile

let show vals =
  Memgraph.Repr.context (fun ctx ->
    let reprs = List.map (fun (name, v) -> (name, ctx.mk v)) vals in
    pp reprs
  )

module Poly = struct
  type elist =
    | [] : elist
    | (::) : ((string * 'a) * elist) -> elist

  let show vals =
    Memgraph.Repr.context (fun ctx ->
      let rec reprs_of : elist -> (string * [`Direct] Memgraph.Repr.cell) list = function
        | [] -> []
        | (s, v) :: xs -> (s, ctx.mk v) :: reprs_of xs
      in
      pp (reprs_of vals)
    )
end
