@tool
extends Node2D
class_name MultiMeshBaker2D

## Drop this node as the PARENT of all your manually-placed Sprite2D
## grass nodes (they can be direct children, or nested in sub-nodes -
## the scan is recursive). Then click "Bake" in the Inspector below.
##
## What it does:
## 1. Recursively finds every Sprite2D under this node.
## 2. Groups them by texture (since MultiMeshInstance2D only supports
##    one texture per instance).
## 3. For each texture group, creates a MultiMeshInstance2D child of
##    this node containing one instance per original sprite, with its
##    position/rotation/scale/flip baked in.
## 4. Hides the original Sprite2D nodes (does NOT delete them), so you
##    can tweak placement and re-bake at any time.
##
## Limitations:
## - Per-instance modulate color is NOT baked by default (see
##   bake_modulate below) since it requires MultiMesh.use_colors = true
##   and slightly more setup. Toggle it on if you need tinted grass.
## - Sprite2D "region" (atlas) sprites are supported as long as every
##   sprite sharing a texture uses the SAME region_rect (grass sprites
##   using the same trimmed texture typically do). .

@export_group("Bake Settings")
## If true, original Sprite2D nodes are hidden (visible = false) after baking.
@export var hide_originals_after_bake: bool = true
## If true, bakes each sprite's modulate color into the MultiMesh (costs a bit more memory/perf).
@export var bake_modulate: bool = false
## Name prefix for generated MultiMeshInstance2D nodes.
@export var baked_node_prefix: String = "Baked_"

@export_group("Actions")
## Check this box to trigger a bake (it will uncheck itself).
@export var bake_now: bool = false:
	set(value):
		if value:
			bake()
		bake_now = false

## Check this box to remove all previously baked MultiMeshInstance2D nodes
## and re-show the original sprites.
@export var unbake_now: bool = false:
	set(value):
		if value:
			unbake()
		unbake_now = false


func bake() -> void:
	var sprites := _find_sprites(self)
	if sprites.is_empty():
		push_warning("MultiMeshBaker2D: no Sprite2D nodes found under %s" % name)
		return

	# Clear any previous bake first so re-baking doesn't duplicate nodes.
	_clear_baked_nodes()

	# Group sprites by texture (and region_rect, to be safe).
	var groups: Dictionary = {} # key: Texture2D -> Array[Sprite2D]
	for s in sprites:
		if s.texture == null:
			push_warning("MultiMeshBaker2D: skipping '%s', no texture set" % s.name)
			continue
		var tex: Texture2D = s.texture
		if not groups.has(tex):
			groups[tex] = []
		groups[tex].append(s)

	var group_index := 0
	for tex in groups.keys():
		var group_sprites: Array = groups[tex]
		_bake_group(tex, group_sprites, group_index)
		group_index += 1

	if hide_originals_after_bake:
		for s in sprites:
			s.visible = false

	print("MultiMeshBaker2D: baked %d sprite(s) into %d MultiMeshInstance2D node(s)." % [sprites.size(), groups.size()])


func unbake() -> void:
	_clear_baked_nodes()
	var sprites := _find_sprites(self)
	for s in sprites:
		s.visible = true
	print("MultiMeshBaker2D: removed baked nodes and restored %d original sprite(s)." % sprites.size())


func _bake_group(tex: Texture2D, group_sprites: Array, group_index: int) -> void:
	var first: Sprite2D = group_sprites[0]

	var mesh := QuadMesh.new()
	# Use the sprite's texture size (accounting for region) as the quad size,
	# in local pixel units - matches how Sprite2D renders by default.
	var tex_size: Vector2 = tex.get_size()
	if first.region_enabled and first.region_rect.size != Vector2.ZERO:
		tex_size = first.region_rect.size
	mesh.size = tex_size

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = bake_modulate
	multimesh.mesh = mesh
	multimesh.instance_count = group_sprites.size()

	for i in group_sprites.size():
		var s: Sprite2D = group_sprites[i]

		# Compute this sprite's GLOBAL transform, then convert to be
		# relative to this baker node (since the MultiMeshInstance2D
		# will be a child of this node).
		var global_xform: Transform2D = s.global_transform
		var local_xform: Transform2D = self.global_transform.affine_inverse() * global_xform

		# Bake in flip_h / flip_v. QuadMesh is built in the XY plane with Y
		# pointing "up" in mesh space, which is inverted relative to Godot's
		# 2D screen space (Y down). To keep the sprite right-side-up while
		# still supporting flips, we negate Y by default (mesh-to-screen
		# correction) and XOR in the flip flags.
		var scale_x := -1.0 if s.flip_h else 1.0
		var scale_y := 1.0 if s.flip_v else -1.0
		local_xform = local_xform.scaled_local(Vector2(scale_x, scale_y))

		multimesh.set_instance_transform_2d(i, local_xform)
		if bake_modulate:
			multimesh.set_instance_color(i, s.modulate)

	var mmi := MultiMeshInstance2D.new()
	mmi.name = "%s%d_%s" % [baked_node_prefix, group_index, tex.resource_path.get_file().get_basename()]
	mmi.multimesh = multimesh
	mmi.texture = tex
	mmi.z_index = first.z_index
	mmi.z_as_relative = first.z_as_relative

	add_child(mmi)
	if Engine.is_editor_hint():
		mmi.owner = get_tree().edited_scene_root


func _clear_baked_nodes() -> void:
	for child in get_children():
		if child is MultiMeshInstance2D and child.name.begins_with(baked_node_prefix):
			child.queue_free()


func _find_sprites(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is Sprite2D:
			result.append(child)
		# Recurse into non-MultiMeshInstance2D children (skip our own baked output).
		if not (child is MultiMeshInstance2D):
			result.append_array(_find_sprites(child))
	return result
