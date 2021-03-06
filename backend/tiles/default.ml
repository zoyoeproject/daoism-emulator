open Core

type tile_feature =
  | River of int list
  | Peak of int list
  | Cave of int list
  | Reef of int list
  | Grass of int list

let produce_of_feature = function
  | Peak _ -> [Feature.mk_produce (Attribute.Api.WuXing Attribute.WuXing.Jing) 1]
  | River _ -> []
  | Cave _ -> [Feature.mk_produce (Attribute.Api.WuXing Attribute.WuXing.Huo) 1]
  | Reef _ -> [Feature.mk_produce (Attribute.Api.WuXing Attribute.WuXing.Shui) 1]
  | Grass _ -> [Feature.mk_produce (Attribute.Api.WuXing Attribute.WuXing.Tu) 1]

let feature_id = function
  | River ls -> List.fold_left (fun acc c -> Printf.sprintf "%s_%d" acc c) "river" ls
  | Peak ls -> List.fold_left (fun acc c -> Printf.sprintf "%s_%d" acc c) "peak" ls
  | Cave ls -> List.fold_left (fun acc c -> Printf.sprintf "%s_%d" acc c) "cave" ls
  | Reef ls -> List.fold_left (fun acc c -> Printf.sprintf "%s_%d" acc c) "reef" ls
  | Grass ls -> List.fold_left (fun acc c -> Printf.sprintf "%s_%d" acc c) "grass" ls

type base_type =
  | Plain
  | Water
  | Grassland
  | Forest
  | Mountain

let base_id = function
  | Plain-> "plain"
  | Water-> "water"
  | Grassland -> "grassland"
  | Mountain -> "mountain"
  | Forest -> "forest"

type tile_type = {
  base: base_type;
  features: tile_feature list;
}

let init_tile base = {base=base; features=[]}

let add_feature f tile = {tile with features = f :: tile.features}

let to_json ttyp =
  `Assoc [
  ("base", `String (base_id ttyp.base))
  ; ("features", `List (List.map (fun f->
      `String (feature_id f)) ttyp.features))
  ]

let to_string = function
  | Water-> "水"
  | Grassland -> "草"
  | Mountain -> "山"
  | Forest -> "林"
  | Plain-> "无"

let tile_type_array = [|Mountain; Water; Grassland; Forest |]

let make_default_state _ ttyp timeslice = fun state _ _ ->
  let es = List.fold_left (fun acc f -> (produce_of_feature f) @ acc) [] ttyp.features in
  let t = match es with | [] -> None | _ -> Some timeslice in
  Common.Api.{ state with deliver = Array.map (fun es -> (es, None)) (Array.of_list es) }, t

let set_default_bound _ _ bound tile =
  let bounds = [|
      (Attribute.Api.WuXing Attribute.WuXing.Jing), bound
    ; (Attribute.Api.WuXing Attribute.WuXing.Shui), bound
    ; (Attribute.Api.WuXing Attribute.WuXing.Tu), bound
    ; (Attribute.Api.WuXing Attribute.WuXing.Huo), bound
    ; (Attribute.Api.WuXing Attribute.WuXing.Mu), bound
    |] in
  Array.iter (fun b -> Environ.set_bound b tile#get_env) bounds
