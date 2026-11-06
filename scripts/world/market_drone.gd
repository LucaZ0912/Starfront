extends Node2D
## A trader's cargo drone (0.4.25.41): flies from the trader to the pilot's market ship, comes in over the
## stern and lands on the flight deck, picks up the wares (the trade happens on deck), takes off down the
## runway past the bow and flies back to its trader. Only one drone uses the runway at a time.

const SPEED := 320.0
const DECK_SPEED := 140.0          # touch-down speed on the deck
const APPROACH := 520.0           # the approach point lies this far behind the runway's rear end
const LOAD_TIME := 2.5            # loading on deck
const STOP_AT := 0.6              # it rolls out at this point of the deck

var view                           # SystemView
var trader: Ship
var host: Ship                     # the pilot's market ship
var paint := "civilian"
var state := "fly_in"              # fly_in → wait → final → loading → takeoff → fly_out
var velocity := Vector2.ZERO
var heading := 0.0
var t := 0.0
var traded := -1                   # credits of the trade (-1 = not yet)
var loaded := false
var fade := 1.0


func setup(p_view, p_trader: Ship, p_host: Ship) -> void:
	view = p_view
	trader = p_trader
	host = p_host
	paint = String(p_trader.paint)
	position = p_trader.position
	heading = p_trader.heading


func _fwd() -> Vector2:
	return Vector2.from_angle(host.heading)


## The market ship can take the drone: still there, in space, standing still.
func _host_ok() -> bool:
	return host != null and is_instance_valid(host) and not host.dying and not host.is_docked() and not host.in_warp() \
		and host.velocity.length() < 40.0 and host.has_deck()


func _runway_free() -> bool:
	return (view.market_runway == null or view.market_runway == self) and int(host.deck_queue) == 0


func _release() -> void:
	if view != null and view.market_runway == self:
		view.market_runway = null


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	t += delta
	if state in ["fly_in", "wait", "final", "loading", "takeoff"] and not _host_ok():
		_release()
		state = "fly_out"                          # the market ship left – back to the trader
	match state:
		"fly_in", "wait":
			var ap: Vector2 = host.deck_point(0.0) - _fwd() * APPROACH
			_fly_to(ap, delta, SPEED)
			if position.distance_to(ap) < 40.0:
				if _runway_free():
					view.market_runway = self
					state = "final"
				else:
					state = "wait"                     # circles at the approach point until the runway is free
		"final":
			# along the runway centre line, slowing down to the touch-down and rolling out
			var start: Vector2 = host.deck_point(0.0)
			var stop: Vector2 = host.deck_point(STOP_AT)
			var along := (position - start).dot(_fwd())
			var stop_along := (stop - start).dot(_fwd())
			var spd := lerpf(DECK_SPEED, 25.0, clampf(along / maxf(stop_along, 1.0), 0.0, 1.0))
			if along < 0.0:
				spd = lerpf(SPEED * 0.6, DECK_SPEED, clampf(1.0 + along / APPROACH, 0.0, 1.0))
			var side := (position - start).dot(_fwd().orthogonal())
			velocity = host.velocity + _fwd() * spd - _fwd().orthogonal() * side * 4.0
			position += velocity * delta
			heading = lerp_angle(heading, host.heading, clampf(delta * 8.0, 0.0, 1.0))   # swings onto the runway
			if along >= stop_along:
				state = "loading"
				t = 0.0
		"loading":
			position = host.deck_point(STOP_AT)
			velocity = host.velocity
			heading = host.heading
			if traded < 0:
				traded = view.market_trade(trader)     # the wares change hands on deck
				loaded = traded > 0
			if t >= LOAD_TIME:
				state = "takeoff"
		"takeoff":
			var start2: Vector2 = host.deck_point(0.0)
			var deck_len: float = host.deck_point(1.0).distance_to(start2)
			var along2 := (position - start2).dot(_fwd())
			var side2 := (position - start2).dot(_fwd().orthogonal())
			var rel := (velocity - host.velocity).dot(_fwd())
			rel = minf(rel + SPEED * 1.4 * delta, SPEED)
			velocity = host.velocity + _fwd() * rel - _fwd().orthogonal() * side2 * 4.0
			position += velocity * delta
			heading = host.heading
			if along2 >= deck_len + 60.0:
				_release()
				state = "fly_out"
		"fly_out":
			if trader == null or not is_instance_valid(trader) or trader.dying:
				fade -= delta * 1.5                   # its trader is gone: it fades away
				position += velocity * delta
				if fade <= 0.0:
					_finish()
				return
			_fly_to(trader.position, delta, SPEED)
			if position.distance_to(trader.position) < 60.0:
				_finish()
	queue_redraw()


func _fly_to(p: Vector2, delta: float, spd: float) -> void:
	var to := p - position
	var d := to.length()
	var want := to.normalized() * minf(spd, d * 2.0) if d > 0.5 else Vector2.ZERO
	velocity = velocity.lerp(want, clampf(delta * 3.0, 0.0, 1.0))
	position += velocity * delta
	if velocity.length() > 5.0:
		heading = lerp_angle(heading, velocity.angle(), clampf(delta * 6.0, 0.0, 1.0))


func _finish() -> void:
	_release()
	if view != null:
		view.market_drone_back(self)
	queue_free()


func _exit_tree() -> void:
	_release()


func _draw() -> void:
	var tex := PixelArt.ship_texture("drone", paint)
	var size := Vector2(tex.get_width(), tex.get_height()) * PixelArt.SCALE
	draw_set_transform(Vector2.ZERO, heading, Vector2.ONE)
	if state in ["fly_in", "wait", "takeoff", "fly_out", "final"]:
		var ex := -size.x * 0.5
		draw_circle(Vector2(ex - 2.0, 0.0), size.y * 0.22, Color(0.55, 0.85, 1.0, 0.35 * fade))
		draw_circle(Vector2(ex, 0.0), size.y * 0.12, Color(1, 1, 1, 0.8 * fade))
	draw_texture_rect(tex, Rect2(-size * 0.5, size), false, Color(1, 1, 1, fade))
	if loaded and state != "loading":
		# the wares it picked up: a small crate slung under the drone
		draw_rect(Rect2(Vector2(-PixelArt.SCALE * 1.5, -PixelArt.SCALE), Vector2(PixelArt.SCALE * 2.5, PixelArt.SCALE * 2.0)), Color(0.85, 0.65, 0.3, fade))
	elif state == "loading":
		# loading: a crate slides in from the deck
		var k := clampf(t / LOAD_TIME, 0.0, 1.0)
		draw_rect(Rect2(Vector2(-PixelArt.SCALE * 1.5, -PixelArt.SCALE + (1.0 - k) * PixelArt.SCALE * 4.0), Vector2(PixelArt.SCALE * 2.5, PixelArt.SCALE * 2.0)), Color(0.85, 0.65, 0.3, k))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
