open Global
module Npc = struct

  type environ = {
    features:int Js.Dict.t
  }[@@bs.deriving abstract]

  type location = {
    x:int;
    y:int;
  }[@@bs.deriving abstract]

  type state = {
    description:string;
    extra: string Js.Dict.t;
  }[@@bs.deriving abstract]

  type t = {
    name:string;
    state:state;
    loc:location;
    env:environ;
    command:string Js.Dict.t;
  }[@@bs.deriving abstract]

end

let npc_map = Js.Dict.fromList []

let build_npc_avatar info layout =
  let open Npc in
  let name = info |. nameGet in
  let svg_name = List.hd @@ String.split_on_char '.' name in
  SvgHelper.mk_use svg_name layout

let display_info info =
  let open Npc in
  let avatar = build_npc_avatar info in
  let i = Js.Dict.fromList @@
    [
      "name", info |. nameGet;
      "state", info |. stateGet |. descriptionGet;
    ]
    @ (Array.to_list (Js.Dict.entries (info |. stateGet |. extraGet)))
  in
  let attrs = info |. envGet |. featuresGet in
  let methods = info |. commandGet in
  Js.log methods;
  Menu.mk_menu (avatar, 40) i attrs methods

let candidate_builder uinfo info command_string =
  let open Npc in
  let module HexCoordinate = HexCoordinate.Make (struct
    let width = (uinfo |. widthGet)
    let height = (uinfo |. heightGet)
  end) in
  let tile_cor = info |. locGet in
  let name = info |. nameGet in
  let cor = (tile_cor |. xGet), (tile_cor |. yGet) in
  let cands = HexCoordinate.siblings cor in
  let ids, svg = Array.fold_left (fun (ids, svg) cor ->
    let id = Printf.sprintf "tile_%d" (HexCoordinate.get_index cor) in
    let layout = HexCoordinate.layout cor in
    let command = Action.mk_command_info command_string name in
    let svg = svg ^ (SvgHelper.mk_rectangle command_string (5,5) layout) in
    (id,cor,command) :: ids, svg
  ) ([], "") cands in
  Action.({ids=ids; svg=svg})

let handle_click name uinfo () =
  let open Npc in
  let info = Js.Dict.get npc_map name in
  match info with
  | None -> assert false
  | Some info -> begin
      let cor = (info |. locGet |. xGet), (info |. locGet |. yGet) in
      if (Action.feed_state (info |. nameGet) cor) then
        Menu.reset_assist_menu ()
      else begin
        Action.reset_state ();
        Menu.build_menu (display_info info) (candidate_builder uinfo info)
      end
    end

let build_npc_content info uinfo =
  let open Npc in
  let module HexCoordinate = HexCoordinate.Make (struct
    let width = (uinfo |. widthGet)
    let height = (uinfo |. heightGet)
  end) in
  let tile_cor = info |. locGet in
  let cor = (tile_cor |. xGet), (tile_cor |. yGet) in
  let layout = HexCoordinate.layout cor in
  (*
  let state = info |. stateGet in
  let desc = state |. descriptionGet in
  let hint = SvgHelper.mk_text layout desc in
  *)
  build_npc_avatar info layout

let add_npc info uinfo container =
  let open Npc in
  let item = Document.createElementSVG Document.document "g" in
  let name = info |. nameGet in
  item |. Document.setAttribute "id" name;
  Js.Dict.set npc_map name info;
  Document.appendChild container item;
  Document.setInnerHTML item (build_npc_content info uinfo);
  Document.add_event_listener item "click" (handle_click name uinfo)

let update_npc info uinfo container =
  let open Npc in
  let name = info |. nameGet in
  match (Js.Dict.get npc_map name) with
  | None -> add_npc info uinfo container
  | Some _ -> begin
      Js.Dict.set npc_map name info;
      let item = Document.get_by_id Document.document name in
      Document.setInnerHTML item (build_npc_content info uinfo)
    end

let build_npcs npcs uinfo container =
  let _ = Array.mapi (fun i _ ->
    let info = npcs.(i) in
    add_npc info uinfo container
  ) npcs in ()
