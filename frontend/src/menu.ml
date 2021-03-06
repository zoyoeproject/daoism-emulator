open Common

(* Dom related operation *)
let get_menu_bg () = Document.get_by_id Document.document "menu-background"
let get_menu_assist () = Document.get_by_id Document.document "menu-assist"
let get_menu_fix () = Document.get_by_id Document.document "menu-fix"
let get_menu_ctx () = Document.get_by_id Document.document "menu-ctx"

let clear_menu_bg () =
  Document.setInnerHTML (get_menu_bg ()) ""

let clear_menu_assist () =
  Document.setInnerHTML (get_menu_assist ()) ""

let clear_menu_fix () =
  Document.setInnerHTML (get_menu_fix ()) ""

let clear_menu_ctx () =
  Document.setInnerHTML (get_menu_ctx ()) ""

let current_focus_id : (string option) ref = ref None
let is_current_focus focus_id = (!current_focus_id = Some focus_id)
let current_focus _ =
  match !current_focus_id with
  | None -> "None"
  | Some id -> id

let reset_menu () =
  current_focus_id := None;
  clear_menu_bg ();
  clear_menu_fix ();
  clear_menu_ctx ();
  clear_menu_assist ()

let reset_context_menu () =
  clear_menu_ctx ();
  clear_menu_bg ()

let build_menu_hint svg =
  Document.setInnerHTML (get_menu_assist ()) svg

(* Menu elements *)

type avatar_builder = ((int * int) -> string) * int

type label = string
type info = string

type layout_info = {
  left: int;
  top: int;
  padding: int;
  font_size: int;
}

type info_component =
  | Info of (label * info) array
  | Methods of ((string * Action.action_method) array)
  | Tree of (label * info_component) array

let mk_info infos = Info infos
let mk_methods methods = Methods methods
let dict_to_info dict to_string =
  Array.map (fun (k,v) -> (k, to_string v)) (Js.Dict.entries dict)

type ('a, 'b) field_info = {
  key_func: 'a -> string;
  dict_func: 'a -> 'b Js.Dict.t;
  to_string: 'b -> string;
}

let rules_to_tree rules =
  Tree (Array.map (fun c ->
    c |. resultGet, mk_info (dict_to_info (c |. requireGet) string_of_int)
  ) rules)

let pre_event_to_tree events =
  Tree (Array.map (fun c ->
    c |. targetGet, mk_info (dict_to_info (c |. featureGet) (fun x -> x))
  ) events)

let rules_fields = {
  key_func = resultGet;
  dict_func = requireGet;
  to_string = string_of_int;
}

let event_fields = {
  key_func = targetGet;
  dict_func = featureGet;
  to_string = (fun x -> x)
}

(* Default constants *)
let content_start = {left=20; top=20; padding=5; font_size=18}
let panel_start = {left=20; top=70; padding=5; font_size=18}
let panel_right_boundary = 180

let rec show_info_component pinfo comp outter = match comp with
  | Info infos -> show_info pinfo infos outter
  | Methods commands -> show_info_method pinfo commands outter
  | Tree infos -> show_info_tree pinfo infos outter

and show_info pinfo info outter =
  let g = Document.createElementSVG Document.document "g" in
  let left = pinfo.left + pinfo.padding in
  let info, top_offset = Array.fold_left (fun (acc,top_offset) (name, info) ->
    let c = SvgHelper.mk_text "menu-item"
        (left, top_offset + pinfo.font_size)
        (name ^ ":" ^ info)
    in
    (acc ^ c), top_offset + pinfo.font_size + pinfo.padding
  ) ("", pinfo.top + pinfo.padding) info in
  Document.setInnerHTML g info;
  Document.appendChild outter g;
  top_offset

and show_info_tree pinfo infos outter =
  let g = Document.createElementSVG Document.document "g" in
  let left_offset = pinfo.left + pinfo.padding in
  let (info, top_offset) = Array.fold_left (
    fun (acc, top) (label, info_comp) -> begin
      let top = top + pinfo.padding + pinfo.font_size in
      let c = SvgHelper.mk_text "menu-item"
          (left_offset, top)
          label
      in
      let acc = acc ^ c in
      let inner_pinfo = { pinfo with
          top = top + pinfo.font_size;
          left = left_offset + pinfo.padding
      } in
      let top_offset = show_info_component inner_pinfo info_comp outter in
      (acc, top_offset)
    end
  )  ("", pinfo.top) infos
  in
  Document.setInnerHTML g info;
  Document.appendChild outter g;
  top_offset

and show_info_method pinfo methods outter =
  (* Dynamic buttons with event handler *)
  let top_offset = pinfo.top + pinfo.padding in
  let left_offset = pinfo.left + pinfo.padding in
  let left_boundary = pinfo.left + panel_right_boundary in
  let button_width = 30 in
  let line = ref (1, true) in
  let br () = let (l, _) = !line in line := (l, true) in
  let push () = let (l, b) = !line in line := (if b then l + 1 else l), false in
  let (_, top_offset) = Array.fold_left (fun (left, top) (name, m) ->
    let open Action in
    let command () = begin
      match m with
      | Fixed cmd -> Action.send_command cmd
      | Transitive (svg, state) ->
        build_menu_hint svg;
        Action.push_state state
    end in
    let _ = SvgHelper.mk_button_in outter ("btn-move") (button_width, button_width)
      (left, top) name command in
    let (left, top) =
      if (left + pinfo.padding * 2 + button_width < left_boundary) then
        let _ = push () in
        (left + pinfo.padding + button_width , top)
      else
        let _ = br () in
        (left_offset, top + button_width + pinfo.padding)
    in
    (left, top)
  ) (left_offset, top_offset) methods in
  let (l, br) = !line in
  if
    br then top_offset
  else
    top_offset + button_width + pinfo.padding

type panel_content =
  avatar_builder * (info_component list)

let mk_panel avatar infos = (avatar, infos)

type panel_group =
  avatar_builder * (panel_content list)

let mk_panel_group avator panels = (avator, panels)

type menu = {
  panels: panel_group list
}

let mk_menu panels = {panels = panels}

let show_panel (info_list:info_component list) () =
  let outter = get_menu_ctx () in
  clear_menu_ctx ();
  clear_menu_bg ();
  let bg = get_menu_bg () in
  let pinfo = panel_start in
  let top_offset = List.fold_left (fun top info ->
    let p = {pinfo with top = top} in
    show_info_component p info outter
  ) panel_start.top info_list in
  let top_offset = if top_offset > 150 then top_offset else 150 in
  ignore @@ SvgHelper.mk_rectangle_in bg "menu" (panel_right_boundary,top_offset - 50)
    (panel_start.left, panel_start.top)

let build_panels (panels:panel_content list) () =
  let menu_fix = get_menu_fix () in
  let top = 50 in
  let left = panel_right_boundary + 20 in
  let offset_top = List.fold_left (fun top (avatar, p) ->
    let tab = Document.createElementSVG Document.document "g" in
    Document.appendChild menu_fix tab;
    let avatar_content, avatar_height = avatar in
    let top_center = top + avatar_height/2 in
    let left_center = left + avatar_height/2 in
    let content = avatar_content (left_center, top_center) in
    Document.setInnerHTML tab content;
    Document.add_event_listener tab "click" (show_panel p);
    top + 36
  ) (top + 20) panels in
  show_panel (snd (List.hd panels)) ();
  offset_top

let build_menu focus_id menu =
  reset_menu ();
  current_focus_id := Some focus_id;
  let top = 20 in
  let left = 20 in
  let menu_fix = get_menu_fix () in
  ignore @@ List.fold_left (fun left (((avatar:avatar_builder), (pgroup:panel_content list)):panel_group) ->
    let tab = Document.createElementSVG Document.document "g" in
    Document.appendChild menu_fix tab;
    let avatar_content, avatar_height = avatar in
    let top_center = top + avatar_height/2 in
    let left_center = left + avatar_height/2 in
    let content = avatar_content (left_center, top_center) in
    Document.setInnerHTML tab content;
    Document.add_event_listener tab "click" (build_panels pgroup);
    left + 30
  ) left menu.panels;
  ignore @@ build_panels (snd (List.hd menu.panels)) ()
