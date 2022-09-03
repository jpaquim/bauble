(import ./glslisp/src/comp-state :as comp-state)
(import ./glslisp/src/index :as glslisp)
(import ./glsl-helpers)
(import ./globals)

(def debug? false)

(defn compile-function [{:name name :params params :body body :return-type return-type}]
  (string/format "%s %s(%s) {\n%s\n}" return-type name (string/join params ", ") body))

# TODO: this is duplicated
(defn- float [n]
  (if (int? n) (string n ".0") (string n)))

(defn compile-fragment-shader [expr]
  (var animated? false)
  (def comp-state (comp-state/new glsl-helpers/functions))

  (when debug?
    (pp (:compile expr (:new-scope comp-state)))
    (pp (:surface expr (:new-scope comp-state))))
  (def distance-scope (:new-scope comp-state))
  (def color-scope (:new-scope comp-state))
  (def [distance-statements distance-expression] (:compile-distance distance-scope expr))

  (def [color-statements color-expression] (:compile-color color-scope expr))
  (def function-defs (string/join (map compile-function (comp-state :functions)) "\n"))

  (def distance-prep-statements @[])
  (each free-variable (keys (distance-scope :free-variables))
    (case free-variable
      globals/p nil
      globals/t (set animated? true)
      globals/camera nil
      globals/world-p (array/push distance-prep-statements "vec3 world_p = p;")
      (errorf "cannot use %s in a distance expression" (free-variable :name))))

  (def color-prep-statements @[])
  # this statement must come first so that the light intensity can see it
  (if (or ((color-scope :free-variables) globals/normal)
          ((color-scope :free-variables) globals/light-intensities))
    (array/push color-prep-statements "vec3 normal = calculate_normal(p);"))
  (each free-variable (keys (color-scope :free-variables))
    (case free-variable
      globals/p nil
      globals/t (set animated? true)
      globals/camera nil
      globals/normal nil
      globals/world-p (array/push color-prep-statements "vec3 world_p = p;")
      globals/light-intensities (do
        # Array initialization syntax doesn't work on the Google
        # Pixel 6a, so we do this kinda dumb thing. Also a simple
        # for loop doesn't work on my mac. So I dunno.
        (array/push color-prep-statements "float light_intensities[3];")
        # A for loop would be obvious, but it doesn't work for some reason.
        (for i 0 3
          (array/push color-prep-statements
            (string `light_intensities[`i`] = cast_light(p + 2.0 * MINIMUM_HIT_DISTANCE * normal, lights[`i`].position, lights[`i`].radius);`))))
      (errorf "unexpected free variable %s" (free-variable :name))))

  (when debug?
    (print
      (string function-defs "\n"
        "float nearest_distance(vec3 p) {\n"
        (string/join distance-prep-statements "\n  ")"\n"
        (string/join distance-statements "\n  ")"\n"
        "return "distance-expression";\n}"))
    (print
      (string
        "vec3 nearest_color(vec3 p) {\n"
        (string/join color-prep-statements "\n  ") "\n"
        (string/join color-statements "\n  ") "\n"
        "return "color-expression";\n}")))

  [animated? (string `
#version 300 es
precision highp float;

uniform vec3 camera_origin;
uniform mat3 camera_matrix;
uniform float t;

out vec4 frag_color;

const int MAX_STEPS = 256;
const float MINIMUM_HIT_DISTANCE = 0.1;
const float NORMAL_OFFSET = 0.005;
const float MAXIMUM_TRACE_DISTANCE = 8.0 * 1024.0;

struct Light {
  vec3 position;
  vec3 color;
  float radius;
};

// TODO: obviously these should be user-customizable,
// but it's kind of a whole thing and I'm working on
// it okay
const Light lights[3] = Light[3](
  Light(vec3(512.0, 512.0, 256.0), vec3(1.0), 2048.0),
  Light(vec3(0.0, 0.0, -512.0), vec3(0.0), 2048.0),
  Light(vec3(0.0, 0.0, 256.0), vec3(0.0), 2048.0)
);

vec3 calculate_normal(vec3 p);
float cast_light(vec3 destination, vec3 light, float radius);

`
function-defs
`
float nearest_distance(vec3 p) {
  `
  (string/join distance-prep-statements "\n  ") "\n  "
  (string/join distance-statements "\n  ")
  `
  return `distance-expression`;
}

vec3 nearest_color(vec3 p) {
  `
  (string/join color-prep-statements "\n  ") "\n  "
  (string/join color-statements "\n  ")
  `
  return `color-expression`;
}

vec3 calculate_normal(vec3 p) {
  const vec3 step = vec3(NORMAL_OFFSET, 0.0, 0.0);

  return normalize(vec3(
    nearest_distance(p + step.xyy) - nearest_distance(p - step.xyy),
    nearest_distance(p + step.yxy) - nearest_distance(p - step.yxy),
    nearest_distance(p + step.yyx) - nearest_distance(p - step.yyx)
  ));
}

float cast_light(vec3 p, vec3 light, float radius) {
  vec3 direction = normalize(light - p);
  float light_distance = distance(light, p);

  float light_brightness = 1.0 - (light_distance / radius);
  if (light_brightness <= 0.0) {
    return 0.0;
  }

  float in_light = 1.0;
  float sharpness = 16.0;

  float last_distance = 1e20;
  // TODO: It would make more sense to start at
  // the light and cast towards the point, so that
  // we don't have to worry about this nonsense.
  float progress = MINIMUM_HIT_DISTANCE;
  for (int i = 0; i < MAX_STEPS; i++) {
    if (progress > light_distance) {
      return in_light * light_brightness;
    }

    float distance = nearest_distance(p + progress * direction);

    if (distance < MINIMUM_HIT_DISTANCE) {
      // we hit something
      return 0.0;
    }

    float intersect_offset = distance * distance / (2.0 * last_distance);
    float intersect_distance = sqrt(distance * distance - intersect_offset * intersect_offset);
    if (distance < last_distance) {
      in_light = min(in_light, sharpness * intersect_distance / max(0.0, progress - intersect_offset));
    }
    progress += distance;
    last_distance = distance;
  }
  // we never reached the light
  return 0.0;
}

vec3 march(vec3 ray_origin, vec3 ray_direction, out int steps) {
  float distance = 0.0;

  for (steps = 0; steps < MAX_STEPS; steps++) {
    vec3 p = ray_origin + distance * ray_direction;

    float nearest = nearest_distance(p);

    // TODO: this attenuation only works when we're
    // using march to render from the camera's point
    // of view, so we can't use the march function
    // as-is to render reflections. I don't know if
    // it's worth having.
    // if (nearest < distance * MINIMUM_HIT_DISTANCE * 0.01) {
    if (nearest < MINIMUM_HIT_DISTANCE || distance > MAXIMUM_TRACE_DISTANCE) {
      return p + nearest * ray_direction;
    }

    distance += nearest;
  }
  return ray_origin + distance * ray_direction;
}

const float PI = 3.14159265359;
const float DEG_TO_RAD = PI / 180.0;

vec3 ray_dir(float fov, vec2 size, vec2 pos) {
  vec2 xy = pos - size * 0.5;

  float cot_half_fov = tan((90.0 - fov * 0.5) * DEG_TO_RAD);
  float z = size.y * 0.5 * cot_half_fov;

  return normalize(vec3(xy, -z));
}

void main() {
  const float gamma = 2.2;
  const vec2 resolution = vec2(1024.0, 1024.0);

  vec3 dir = camera_matrix * ray_dir(45.0, resolution, gl_FragCoord.xy);
  vec3 eye = camera_origin;

  const vec3 fog_color = vec3(0.15);
  const vec3 abort_color = vec3(1.0, 0.0, 1.0);

  // TODO: we only need the steps out parameter when
  // we're rendering the debug view. Should try to
  // see if there's any performance difference between
  // an out parameter and a local variable.
  int steps;
  vec3 hit = march(eye, dir, steps);

  vec3 color = nearest_color(hit);
  float depth = length(hit - eye);
  float attenuation = depth / MAXIMUM_TRACE_DISTANCE;
  color = mix(color, fog_color, clamp(attenuation * attenuation, 0.0, 1.0));

  // This is a view for debugging convergence, but it also just...
  // looks really cool on its own:
  // if (steps == MAX_STEPS) {
  //   color = abort_color;
  // } else {
  //   color = vec3(float(steps) / float(MAX_STEPS));
  // }

  // This is a good view for debugging overshooting.
  // float distance = nearest_distance(hit);
  // float overshoot = max(-distance, 0.0) / MINIMUM_HIT_DISTANCE;
  // float undershoot = max(distance, 0.0) / MINIMUM_HIT_DISTANCE;
  // color = vec3(overshoot, 1.0 - undershoot - overshoot, 0.0);

  frag_color = vec4(pow(color, vec3(1.0 / gamma)), 1.0);
}
`)])

# surely I can do better
(defn is-good-value? [value]
  (and (struct? value)
       (not (nil? (value :compile)))))

# absolutely no reason for this to be a fiber anymore;
# this can just be a function that we invoke, and we
# can just hold onto the previous expression in C code

(fiber/new (fn []
  (var last-expr nil)
  # TODO: should also say whether or not it's an
  # animated image?
  (var response nil)
  (while true
    (let [expr (yield response)]
      (if (is-good-value? expr)
        (try
          # TODO: sadly this does not work;
          # will need to look into it
          (if (and false (= expr last-expr))
            (do
              (print "skipping compilation")
              (set response nil))
            (do
              (set last-expr expr)
              (set response (compile-fragment-shader expr))))
          ([err fiber]
            (set response nil)
            (debug/stacktrace fiber err "")))
        (eprintf "cannot compile %p" expr))))))
